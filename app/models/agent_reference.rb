# AgentReference stores web references discovered during agent tool execution.
#
# When a research agent navigates to URLs and extracts content, references are
# created to track the sources. This enables users to review, cite, and link
# back to the original sources.
#
# @example Creating a reference from a navigate tool call
#   context.references.create!(
#     url: "https://example.com/article",
#     title: "Example Article",
#     agent_tool_call: tool_call
#   )
#
# @example Getting all references for a page
#   page.agent_contexts.flat_map(&:references)
#
class AgentReference < ApplicationRecord
  # Associations
  belongs_to :agent_context
  belongs_to :agent_tool_call, optional: true

  # Validations
  validates :url, presence: true
  validates :status, inclusion: { in: %w[pending fetching complete failed] }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :complete, -> { where(status: "complete") }
  scope :pending, -> { where(status: "pending") }
  scope :with_metadata, -> { where.not(og_title: nil).or(where.not(title: nil)) }

  # Callbacks
  before_create :set_position
  before_save :extract_domain

  # Returns the best available title
  #
  # @return [String, nil]
  def display_title
    og_title.presence || title.presence || domain
  end

  # Returns the best available description
  #
  # @return [String, nil]
  def display_description
    og_description.presence || description.presence
  end

  # Returns a markdown-formatted link
  #
  # @return [String]
  def to_markdown_link
    title_text = display_title || url
    "[#{title_text}](#{url})"
  end

  # Returns an HTML-formatted link
  #
  # @return [String]
  def to_html_link
    title_text = display_title || url
    %(<a href="#{url}" target="_blank" rel="noopener noreferrer">#{title_text}</a>)
  end

  # Returns a hash suitable for JSON API response
  #
  # @return [Hash]
  def as_card
    {
      id: id,
      url: url,
      domain: domain,
      title: display_title,
      description: display_description,
      image: og_image,
      site_name: og_site_name,
      favicon: favicon_url,
      markdown_link: to_markdown_link,
      extracted_content: extracted_content&.truncate(200),
      status: status,
      created_at: created_at
    }.compact
  end

  # Fetches Open Graph metadata for this reference
  # This can be called asynchronously via a job
  #
  # @return [Boolean] true if successful
  def fetch_metadata!
    return false if url.blank?

    update!(status: "fetching")

    begin
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        parse_html_metadata(response.body)
        update!(status: "complete")
        true
      else
        update!(status: "failed", error_message: "HTTP #{response.code}")
        false
      end
    rescue => e
      update!(status: "failed", error_message: e.message)
      false
    end
  end

  # Class method to extract references from tool calls in a context
  #
  # @param context [AgentContext] the context to extract from
  # @return [Array<AgentReference>] created references
  def self.extract_from_context(context)
    references = []
    seen_urls = Set.new

    # Extract from navigate tool calls
    context.tool_calls.for_tool(:navigate).completed.each do |tool_call|
      result = tool_call.parsed_result
      next unless result && result[:success] && result[:current_url]

      url = result[:current_url]
      next if seen_urls.include?(url)
      seen_urls.add(url)

      ref = context.references.find_or_initialize_by(url: url)
      ref.agent_tool_call = tool_call
      ref.title = result[:title] if result[:title].present?
      ref.save! if ref.new_record? || ref.changed?
      references << ref
    end

    # Extract content summaries from extract_main_content calls
    context.tool_calls.for_tool(:extract_main_content).completed.each do |tool_call|
      result = tool_call.parsed_result
      next unless result && result[:success] && result[:current_url]

      url = result[:current_url]
      ref = context.references.find_by(url: url)

      if ref
        updates = { extracted_content: result[:content]&.truncate(1000) }
        updates[:title] = result[:title] if result[:title].present? && ref.title.blank?
        ref.update!(updates)
      end
    end

    # Extract from extract_links tool calls (discovered but not visited links)
    context.tool_calls.for_tool(:extract_links).completed.each do |tool_call|
      result = tool_call.parsed_result
      next unless result && result[:success] && result[:links].is_a?(Array)

      result[:links].each do |link|
        next unless link[:href].present?
        next if seen_urls.include?(link[:href])
        next unless link[:href].start_with?("http")

        seen_urls.add(link[:href])

        ref = context.references.find_or_initialize_by(url: link[:href])
        ref.agent_tool_call ||= tool_call
        ref.title ||= link[:text] if link[:text].present?
        ref.save! if ref.new_record? || ref.changed?
        references << ref
      end
    end

    references
  end

  private

  def set_position
    max_position = AgentReference.where(agent_context_id: agent_context_id).maximum(:position)
    self.position = (max_position || -1) + 1
  end

  def extract_domain
    return if url.blank?

    begin
      uri = URI.parse(url)
      self.domain = uri.host
    rescue URI::InvalidURIError
      # Leave domain blank if URL is invalid
    end
  end

  def parse_html_metadata(html)
    # Simple regex-based parsing (could use Nokogiri for more robust parsing)
    # Extract Open Graph tags
    self.og_title = extract_meta_content(html, 'og:title')
    self.og_description = extract_meta_content(html, 'og:description')
    self.og_image = extract_meta_content(html, 'og:image')
    self.og_site_name = extract_meta_content(html, 'og:site_name')
    self.og_type = extract_meta_content(html, 'og:type')

    # Fallback to standard meta tags
    self.title ||= extract_title(html)
    self.description ||= extract_meta_content(html, 'description')

    # Extract favicon
    self.favicon_url ||= extract_favicon(html)
  end

  def extract_meta_content(html, property)
    # Match both property="" and name="" attributes
    match = html.match(/<meta[^>]*(?:property|name)=["']#{Regexp.escape(property)}["'][^>]*content=["']([^"']+)["']/i)
    match ||= html.match(/<meta[^>]*content=["']([^"']+)["'][^>]*(?:property|name)=["']#{Regexp.escape(property)}["']/i)
    match&.[](1)
  end

  def extract_title(html)
    match = html.match(/<title[^>]*>([^<]+)<\/title>/i)
    match&.[](1)&.strip
  end

  def extract_favicon(html)
    # Look for link rel="icon" or rel="shortcut icon"
    match = html.match(/<link[^>]*rel=["'](?:shortcut )?icon["'][^>]*href=["']([^"']+)["']/i)
    match ||= html.match(/<link[^>]*href=["']([^"']+)["'][^>]*rel=["'](?:shortcut )?icon["']/i)

    if match
      favicon_path = match[1]
      # Make absolute URL if relative
      if favicon_path.start_with?("/")
        uri = URI.parse(url)
        "#{uri.scheme}://#{uri.host}#{favicon_path}"
      else
        favicon_path
      end
    else
      # Default to /favicon.ico
      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}/favicon.ico"
    end
  rescue
    nil
  end
end
