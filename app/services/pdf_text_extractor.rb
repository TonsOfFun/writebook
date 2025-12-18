require "pdf-reader"

class PdfTextExtractor
  class ExtractionError < StandardError; end

  attr_reader :file_path, :reader

  def initialize(file_path)
    @file_path = file_path
    @reader = PDF::Reader.new(file_path)
  rescue PDF::Reader::MalformedPDFError => e
    raise ExtractionError, "Malformed PDF: #{e.message}"
  rescue PDF::Reader::EncryptedPDFError => e
    raise ExtractionError, "Encrypted PDF: #{e.message}"
  end

  def extract
    pages = {}

    reader.pages.each_with_index do |page, index|
      page_number = index + 1
      pages[page_number.to_s] = extract_page_text(page)
    end

    {
      page_count: reader.page_count,
      pages: pages,
      metadata: extract_metadata
    }
  end

  def extract_page(page_number)
    return nil if page_number < 1 || page_number > reader.page_count

    page = reader.pages[page_number - 1]
    extract_page_text(page)
  end

  def page_count
    reader.page_count
  end

  private

  def extract_page_text(page)
    text = page.text.to_s.strip
    normalize_text(text)
  rescue => e
    Rails.logger.warn "[PdfTextExtractor] Failed to extract page text: #{e.message}"
    ""
  end

  def normalize_text(text)
    return "" if text.blank?

    text
      .gsub(/\r\n?/, "\n")
      .gsub(/[^\S\n]+/, " ")
      .gsub(/\n{3,}/, "\n\n")
      .strip
  end

  def extract_metadata
    {
      title: reader.info[:Title],
      author: reader.info[:Author],
      subject: reader.info[:Subject],
      creator: reader.info[:Creator],
      producer: reader.info[:Producer],
      creation_date: reader.info[:CreationDate],
      page_count: reader.page_count
    }.compact
  end
end
