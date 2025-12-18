class DocumentProcessingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(document)
    return unless document.file.attached?

    document.processing!

    document.file.open do |tempfile|
      process_document(document, tempfile.path)
    end

    document.completed!
  rescue DocumentTextExtractor::UnsupportedFormatError => e
    handle_error(document, e, "Unsupported format")
  rescue PdfTextExtractor::ExtractionError => e
    handle_error(document, e, "PDF extraction failed")
  rescue StandardError => e
    handle_error(document, e, "Processing failed")
    raise
  end

  private

  def process_document(document, file_path)
    document_type = document.document_type || detect_type(document)

    case document_type
    when "pdf"
      process_pdf(document, file_path)
    when "pptx", "ppt"
      process_pptx(document, file_path)
    when "docx"
      process_docx(document, file_path)
    else
      raise DocumentTextExtractor::UnsupportedFormatError, "Unknown type: #{document_type}"
    end
  end

  def process_pdf(document, file_path)
    extractor = PdfTextExtractor.new(file_path)
    result = extractor.extract

    document.update!(
      page_count: result[:page_count],
      page_text: result[:pages],
      document_type: "pdf"
    )

    Rails.logger.info "[DocumentProcessingJob] Extracted #{result[:page_count]} pages from PDF #{document.id}"
  end

  def process_pptx(document, file_path)
    # Placeholder for PPTX processing
    # Would use ruby-pptx or libreoffice conversion
    Rails.logger.warn "[DocumentProcessingJob] PPTX extraction not yet implemented for document #{document.id}"

    document.update!(
      page_text: { "1" => "PPTX text extraction requires additional setup. See docs/features/pdf-ppt-support-and-context-retrieval.md" },
      page_count: 1,
      document_type: document.document_type || "pptx"
    )
  end

  def process_docx(document, file_path)
    # Placeholder for DOCX processing
    # Would use docx gem or libreoffice conversion
    Rails.logger.warn "[DocumentProcessingJob] DOCX extraction not yet implemented for document #{document.id}"

    document.update!(
      page_text: { "1" => "DOCX text extraction requires additional setup. See docs/features/pdf-ppt-support-and-context-retrieval.md" },
      page_count: 1,
      document_type: "docx"
    )
  end

  def detect_type(document)
    extension = File.extname(document.file.filename.to_s).downcase.delete(".")
    document.update!(document_type: extension) if extension.present?
    extension
  end

  def handle_error(document, error, message)
    Rails.logger.error "[DocumentProcessingJob] #{message} for document #{document.id}: #{error.message}"

    document.update!(
      processing_status: :failed,
      processing_error: "#{message}: #{error.message}"
    )
  end
end
