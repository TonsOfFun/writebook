require "net/http"
require "uri"
require "cgi"
require "nokogiri"

class ResearchAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: "You are a research assistant helping authors find and reference information for their writing. Synthesize the provided research into a clear, well-organized summary with proper citations."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def research
    @topic = params[:topic]
    @context = params[:context]
    @full_content = params[:full_content]
    @depth = params[:depth] || "standard"

    # Perform web research before AI synthesis
    @search_results = perform_web_search(@topic)
    @page_contents = fetch_top_pages(@search_results, max_pages: 3)

    prompt
  end

  private

  def perform_web_search(query)
    Rails.logger.info "[ResearchAgent] Searching for: #{query}"

    encoded_query = CGI.escape(query)
    search_url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"

    response = fetch_url(search_url)
    return [] unless response[:success]

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
    results
  rescue => e
    Rails.logger.error "[ResearchAgent] Search error: #{e.message}"
    []
  end

  def fetch_top_pages(results, max_pages: 3)
    pages = []

    results.first(max_pages).each do |result|
      content = read_webpage(result[:url])
      next if content[:content].blank?

      pages << {
        title: result[:title],
        url: result[:url],
        content: content[:content]
      }
    end

    pages
  end

  def read_webpage(url)
    Rails.logger.info "[ResearchAgent] Reading webpage: #{url}"

    response = fetch_url(url)
    return { content: "", error: "Failed to fetch page" } unless response[:success]

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
    { content: text, url: url }
  rescue => e
    Rails.logger.error "[ResearchAgent] Read error for #{url}: #{e.message}"
    { content: "", error: e.message }
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
