# FragmentReferenceDetector detects markdown links in content selections.
#
# This service parses markdown content to find embedded references (links)
# that can be used to enhance AI generation with source context.
#
# @example Detecting references in a selection
#   detector = FragmentReferenceDetector.new(selected_text)
#   references = detector.detect_references
#   # => [{ text: "OpenAI Codex", url: "https://openai.com/blog/codex", ... }, ...]
#
# @example Checking if selection has references
#   detector = FragmentReferenceDetector.new(selected_text)
#   if detector.has_references?
#     # Show reference selection UI
#   end
#
class FragmentReferenceDetector
  # Regex for standard markdown links: [text](url)
  MARKDOWN_LINK_REGEX = /\[([^\]]+)\]\(([^)]+)\)/

  # Regex for autolinks: <url>
  AUTOLINK_REGEX = /<(https?:\/\/[^>]+)>/

  # Regex for reference-style links: [text][ref]
  REFERENCE_LINK_REGEX = /\[([^\]]+)\]\[([^\]]*)\]/

  # Regex for reference definitions: [ref]: url
  REFERENCE_DEFINITION_REGEX = /^\[([^\]]+)\]:\s*(.+)$/m

  attr_reader :content

  def initialize(content)
    @content = content.to_s
  end

  # Detects all references (links) in the content
  #
  # @return [Array<Hash>] array of reference hashes with :text, :url, and metadata
  def detect_references
    references = []

    # Detect standard markdown links
    references.concat(detect_markdown_links)

    # Detect autolinks
    references.concat(detect_autolinks)

    # Detect reference-style links
    references.concat(detect_reference_links)

    # Remove duplicates by URL
    references.uniq { |ref| ref[:url] }
  end

  # Returns true if the content contains any references
  def has_references?
    detect_references.any?
  end

  # Returns the count of detected references
  def reference_count
    detect_references.count
  end

  # Enriches references with existing AgentReference data if available
  #
  # @return [Array<Hash>] references with :existing_reference data
  def detect_with_existing
    detect_references.map do |ref|
      existing = find_existing_reference(ref[:url])
      ref.merge(
        existing_reference: existing,
        has_cached_content: existing&.extracted_content.present?,
        can_fetch: fetchable_url?(ref[:url])
      )
    end
  end

  private

  # Detects standard markdown links [text](url)
  def detect_markdown_links
    @content.scan(MARKDOWN_LINK_REGEX).map do |text, url|
      build_reference(text: text, url: url, type: :markdown)
    end
  end

  # Detects autolinks <url>
  def detect_autolinks
    @content.scan(AUTOLINK_REGEX).map do |match|
      url = match[0]
      build_reference(text: nil, url: url, type: :autolink)
    end
  end

  # Detects reference-style links [text][ref] with their definitions
  def detect_reference_links
    references = []

    # First, build a map of reference definitions
    definitions = {}
    @content.scan(REFERENCE_DEFINITION_REGEX) do |ref_id, url|
      definitions[ref_id.downcase] = url.strip
    end

    # Then, find all reference usages
    @content.scan(REFERENCE_LINK_REGEX) do |text, ref_id|
      # If ref_id is empty, use the text as the reference id
      lookup_id = ref_id.empty? ? text.downcase : ref_id.downcase

      if url = definitions[lookup_id]
        references << build_reference(text: text, url: url, type: :reference)
      end
    end

    references
  end

  # Builds a reference hash with common attributes
  def build_reference(text:, url:, type:)
    {
      text: text,
      url: normalize_url(url),
      type: type,
      accepted: true  # Default to accepted; user can toggle off
    }
  end

  # Normalizes URL by removing trailing punctuation, etc.
  def normalize_url(url)
    url.to_s.strip.gsub(/[.,;:!?)\]]+$/, "")
  end

  # Finds an existing AgentReference for a URL
  def find_existing_reference(url)
    AgentReference.find_by(url: url)
  end

  # Checks if a URL can be fetched for content
  def fetchable_url?(url)
    uri = URI.parse(url)
    uri.scheme.in?(%w[http https]) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
