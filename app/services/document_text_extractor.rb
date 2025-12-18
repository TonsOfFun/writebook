class DocumentTextExtractor
  class UnsupportedFormatError < StandardError; end
  class ExtractionError < StandardError; end

  EXTRACTORS = {
    "pdf" => "PdfTextExtractor",
    "docx" => "DocxTextExtractor",
    "pptx" => "PptxTextExtractor",
    "ppt" => "PptxTextExtractor"
  }.freeze

  attr_reader :file_path, :document_type

  def initialize(file_path, document_type: nil)
    @file_path = file_path
    @document_type = document_type || detect_type
  end

  def extract
    extractor_class = EXTRACTORS[document_type]
    raise UnsupportedFormatError, "Unsupported document type: #{document_type}" unless extractor_class

    extractor = extractor_class.constantize.new(file_path)
    extractor.extract
  rescue NameError
    raise UnsupportedFormatError, "Extractor not available for: #{document_type}. Install required gems."
  end

  def self.supported?(document_type)
    EXTRACTORS.key?(document_type)
  end

  private

  def detect_type
    extension = File.extname(file_path).downcase.delete(".")
    extension.presence || raise(UnsupportedFormatError, "Cannot detect document type")
  end
end
