class SourceProcessingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(source)
    source.processing!

    case source.source_type
    when "pdf"
      process_pdf(source)
    when "image"
      process_image(source)
    when "text"
      process_text(source)
    when "url"
      process_url(source)
    else
      raise "Unknown source type: #{source.source_type}"
    end

    source.update!(
      processing_status: :completed,
      processed_at: Time.current
    )
  rescue StandardError => e
    handle_error(source, e)
    raise
  end

  private

  def process_pdf(source)
    return unless source.file.attached?

    source.file.open do |tempfile|
      extractor = PdfTextExtractor.new(tempfile.path)
      result = extractor.extract

      # Combine all pages into extracted content
      full_text = result[:pages].values.join("\n\n---\n\n")

      source.update!(
        extracted_content: full_text,
        metadata: source.metadata.merge(
          page_count: result[:page_count],
          pages: result[:pages]
        )
      )

      Rails.logger.info "[SourceProcessingJob] Extracted #{result[:page_count]} pages from PDF source #{source.id}"
    end
  end

  def process_image(source)
    return unless source.file.attached?

    # For now, just store basic metadata
    # Future: OCR integration for text extraction
    source.update!(
      metadata: source.metadata.merge(
        filename: source.file.filename.to_s,
        content_type: source.file.content_type,
        byte_size: source.file.byte_size
      ),
      extracted_content: "[Image: #{source.file.filename}]"
    )

    Rails.logger.info "[SourceProcessingJob] Processed image source #{source.id}"
  end

  def process_text(source)
    # Text content is already stored in raw_content
    # Just copy it to extracted_content if not already set
    if source.raw_content.present? && source.extracted_content.blank?
      source.update!(
        extracted_content: source.raw_content
      )
    end

    Rails.logger.info "[SourceProcessingJob] Processed text source #{source.id}"
  end

  def process_url(source)
    return if source.url.blank?

    uri = URI.parse(source.url)
    response = fetch_with_redirect(uri)

    if response.is_a?(Net::HTTPSuccess)
      html = response.body

      # Extract content and metadata
      title = extract_title(html)
      main_content = extract_main_content(html)
      description = extract_meta_content(html, "description")
      og_description = extract_meta_content(html, "og:description")

      source.update!(
        extracted_content: main_content,
        metadata: source.metadata.merge(
          title: title,
          description: description || og_description,
          og_title: extract_meta_content(html, "og:title"),
          og_image: extract_meta_content(html, "og:image"),
          fetched_at: Time.current.iso8601,
          http_status: response.code
        )
      )

      # Update name if not set and we found a title
      if source.name.blank? && title.present?
        source.update!(name: title)
      end

      Rails.logger.info "[SourceProcessingJob] Fetched URL source #{source.id}: #{source.url}"
    else
      raise "HTTP #{response.code}: #{response.message}"
    end
  end

  def fetch_with_redirect(uri, limit = 5)
    raise "Too many redirects" if limit == 0

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Dill/1.0 (Technology Diligence Platform)"
    request["Accept"] = "text/html,application/xhtml+xml"

    response = http.request(request)

    case response
    when Net::HTTPRedirection
      new_uri = URI.parse(response["location"])
      new_uri = URI.join(uri, new_uri) unless new_uri.host
      fetch_with_redirect(new_uri, limit - 1)
    else
      response
    end
  end

  def extract_title(html)
    match = html.match(/<title[^>]*>([^<]+)<\/title>/i)
    match&.[](1)&.strip&.gsub(/\s+/, " ")
  end

  def extract_meta_content(html, property)
    match = html.match(/<meta[^>]*(?:property|name)=["']#{Regexp.escape(property)}["'][^>]*content=["']([^"']+)["']/i)
    match ||= html.match(/<meta[^>]*content=["']([^"']+)["'][^>]*(?:property|name)=["']#{Regexp.escape(property)}["']/i)
    match&.[](1)
  end

  def extract_main_content(html)
    # Remove script, style, nav, header, footer tags
    content = html.dup
    content.gsub!(/<script[^>]*>.*?<\/script>/mi, "")
    content.gsub!(/<style[^>]*>.*?<\/style>/mi, "")
    content.gsub!(/<nav[^>]*>.*?<\/nav>/mi, "")
    content.gsub!(/<header[^>]*>.*?<\/header>/mi, "")
    content.gsub!(/<footer[^>]*>.*?<\/footer>/mi, "")
    content.gsub!(/<aside[^>]*>.*?<\/aside>/mi, "")

    # Try to find main content area
    main_match = content.match(/<main[^>]*>(.*?)<\/main>/mi)
    article_match = content.match(/<article[^>]*>(.*?)<\/article>/mi)

    text = if main_match
      main_match[1]
    elsif article_match
      article_match[1]
    else
      # Fall back to body content
      body_match = content.match(/<body[^>]*>(.*?)<\/body>/mi)
      body_match ? body_match[1] : content
    end

    # Strip HTML tags and clean up whitespace
    text = text.gsub(/<[^>]+>/, " ")
    text = text.gsub(/&nbsp;/, " ")
    text = text.gsub(/&amp;/, "&")
    text = text.gsub(/&lt;/, "<")
    text = text.gsub(/&gt;/, ">")
    text = text.gsub(/&quot;/, '"')
    text = text.gsub(/&#39;/, "'")
    text = text.gsub(/\s+/, " ")
    text.strip.truncate(50_000) # Limit size
  end

  def handle_error(source, error)
    Rails.logger.error "[SourceProcessingJob] Failed for source #{source.id}: #{error.message}"

    source.update!(
      processing_status: :failed,
      processing_error: error.message
    )
  end
end
