require "net/http"
require "uri"
require "cgi"
require "nokogiri"

class ResearchAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: "You are a research assistant helping authors find and reference information for their writing. Use the available tools to search the web and read web pages, then synthesize your findings into a clear, well-organized summary with proper citations."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def research
    @topic = params[:topic]
    @context = params[:context]
    @full_content = params[:full_content]
    @depth = params[:depth] || "standard"

    prompt(tools: load_tools, tool_choice: "auto")
  end

  # Tool method: Search the web for a query
  def web_search(query:)
    Rails.logger.info "[ResearchAgent] Tool called: web_search(#{query})"

    encoded_query = CGI.escape(query)
    search_url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"

    response = fetch_url(search_url)
    return { error: "Search failed", results: [] } unless response[:success]

    doc = Nokogiri::HTML(response[:body])
    results = []

    doc.css(".result").first(8).each do |result|
      title_el = result.css(".result__title a").first
      snippet_el = result.css(".result__snippet").first

      next unless title_el

      url = extract_url(title_el["href"])
      next if url.blank? || url.include?("duckduckgo.com")

      results << {
        title: title_el.text.strip,
        url: url,
        snippet: snippet_el&.text&.strip || ""
      }
    end

    Rails.logger.info "[ResearchAgent] Found #{results.length} results"
    { query: query, results: results }
  rescue => e
    Rails.logger.error "[ResearchAgent] Search error: #{e.message}"
    { error: e.message, results: [] }
  end

  # Tool method: Read a single webpage
  def read_webpage(url:)
    Rails.logger.info "[ResearchAgent] Tool called: read_webpage(#{url})"

    response = fetch_url(url)
    return { error: "Failed to fetch page", url: url, content: "" } unless response[:success]

    doc = Nokogiri::HTML(response[:body])

    # Remove unwanted elements
    doc.css("script, style, nav, header, footer, aside, .sidebar, .navigation, .menu, .ad, .advertisement, .social-share, .comments, noscript").remove

    # Get main content
    main_content = doc.css("main, article, .content, .post, .entry, #content, .article-body, .post-content").first
    content_element = main_content || doc.css("body").first

    # Extract text
    text = content_element&.text&.gsub(/\s+/, " ")&.strip || ""

    # Limit content length
    text = text[0..6000] if text.length > 6000

    Rails.logger.info "[ResearchAgent] Extracted #{text.length} characters from #{url}"
    { url: url, content: text }
  rescue => e
    Rails.logger.error "[ResearchAgent] Read error for #{url}: #{e.message}"
    { error: e.message, url: url, content: "" }
  end

  # Tool method: Fetch multiple pages at once
  def fetch_top_pages(urls:)
    Rails.logger.info "[ResearchAgent] Tool called: fetch_top_pages(#{urls.length} urls)"

    # Limit to 5 pages max
    urls_to_fetch = urls.first(5)
    pages = []

    urls_to_fetch.each do |url|
      result = read_webpage(url: url)
      pages << result unless result[:content].blank?
    end

    { pages: pages, fetched_count: pages.length }
  end

  private

  # Load tool definitions from JSON view templates
  def load_tools
    tool_names = %w[web_search read_webpage fetch_top_pages]

    tool_names.map do |tool_name|
      load_tool_schema(tool_name)
    end
  end

  # Load a single tool schema from its JSON view template
  def load_tool_schema(tool_name)
    template_path = "tools/#{tool_name}"

    # Use the view rendering system to load the JSON template
    json_content = render_to_string(
      template: "research_assistant_agent/#{template_path}",
      formats: [:json],
      layout: false
    )

    JSON.parse(json_content, symbolize_names: true)
  rescue ActionView::MissingTemplate => e
    Rails.logger.error "[ResearchAgent] Missing tool template: #{template_path}"
    raise e
  rescue JSON::ParserError => e
    Rails.logger.error "[ResearchAgent] Invalid JSON in tool template: #{template_path}"
    raise e
  end

  def fetch_url(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    request["Accept-Language"] = "en-US,en;q=0.5"

    response = http.request(request)

    if response.is_a?(Net::HTTPRedirection) && response["location"]
      redirect_url = response["location"]
      redirect_url = URI.join(url, redirect_url).to_s unless redirect_url.start_with?("http")
      return fetch_url(redirect_url)
    end

    {
      success: response.is_a?(Net::HTTPSuccess),
      body: response.body&.force_encoding("UTF-8"),
      status: response.code
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Fetch error for #{url}: #{e.message}"
    { success: false, body: "", status: "error" }
  end

  def extract_url(ddg_url)
    return "" unless ddg_url

    if ddg_url.include?("uddg=")
      decoded = CGI.unescape(ddg_url)
      match = decoded.match(/uddg=([^&]+)/)
      return CGI.unescape(match[1]) if match
    end

    ddg_url
  rescue
    ddg_url
  end

  def broadcast_chunk(chunk)
    return unless chunk.delta
    return unless params[:stream_id]

    Rails.logger.info "[ResearchAgent] Broadcasting chunk to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.delta })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[ResearchAgent] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
