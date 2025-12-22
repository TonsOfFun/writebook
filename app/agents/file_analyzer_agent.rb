require 'base64'

class FileAnalyzerAgent < ApplicationAgent
  # Enable context persistence for tracking file analysis sessions
  has_context

  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    api_version: :chat,  # Use Chat API for vision/image support
    instructions: "You are an expert document analyzer capable of extracting insights from PDFs, images, and other file types."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def analyze_pdf
    @file_path = params[:file_path]
    # Read PDF content (would need pdf-reader gem)
    @content = extract_pdf_content(@file_path) if @file_path

    setup_context_and_prompt
  end

  def analyze_image
    Rails.logger.info "[FileAnalyzer] analyze_image called with params: #{params.inspect}"

    @description_detail = params[:description_detail] || "medium"

    # Encode image before calling prompt so it can be passed as an option
    encode_image_from_attachment

    setup_context_and_prompt_with_image
  end

  def extract_text
    @file_path = params[:file_path] if params[:file_path]
    @content = extract_file_content(@file_path) if @file_path

    setup_context_and_prompt
  end

  def summarize_document
    @file_path = params[:file_path]
    @content = extract_file_content(@file_path) if @file_path

    setup_context_and_prompt
  end

  private

  # Sets up context persistence and triggers prompt rendering
  # The after_prompt callback from SolidAgent will persist the rendered template
  def setup_context_and_prompt
    Rails.logger.info "[FileAnalyzer] setup_context_and_prompt called"

    # Create a new context with input parameters for audit trail
    create_context(
      contextable: params[:contextable],
      input_params: {
        file_path: @file_path,
        file_name: @file_path ? File.basename(@file_path) : nil,
        description_detail: @description_detail
      }.compact
    )

    Rails.logger.info "[FileAnalyzer] Calling prompt..."
    # Execute the prompt - the action template will be rendered
    result = prompt
    Rails.logger.info "[FileAnalyzer] prompt returned: #{result.class}"
    result
  end

  # Sets up context and triggers prompt with image for vision API
  def setup_context_and_prompt_with_image
    Rails.logger.info "[FileAnalyzer] setup_context_and_prompt_with_image called"
    Rails.logger.info "[FileAnalyzer] @image_data present: #{@image_data.present?}, length: #{@image_data&.length || 0}"

    # Create a new context with input parameters for audit trail
    create_context(
      contextable: params[:contextable],
      input_params: {
        attachment_slug: params[:attachment_slug],
        description_detail: @description_detail
      }.compact
    )

    Rails.logger.info "[FileAnalyzer] Calling prompt with image..."
    # Execute the prompt with image passed as an option for vision API
    result = prompt image: @image_data
    Rails.logger.info "[FileAnalyzer] prompt returned: #{result.class}"
    result
  end

  # Encode image from Active Storage attachment (for image uploads)
  def encode_image_from_attachment
    @attachment_slug = params[:attachment_slug]
    Rails.logger.info "[FileAnalyzer] encode_image_from_attachment called with slug: #{@attachment_slug.inspect}"

    unless @attachment_slug
      Rails.logger.warn "[FileAnalyzer] No attachment_slug provided!"
      return
    end

    attachment = ActiveStorage::Attachment.find_by(slug: @attachment_slug)

    unless attachment
      Rails.logger.error "[FileAnalyzer] Attachment not found for slug: #{@attachment_slug}"
      return
    end

    unless attachment.blob
      Rails.logger.error "[FileAnalyzer] Attachment has no blob: #{attachment.inspect}"
      return
    end

    Rails.logger.info "[FileAnalyzer] Found attachment: #{attachment.inspect}, blob: #{attachment.blob.filename}"

    attachment.blob.open do |tempfile|
      content_type = attachment.content_type || 'image/jpeg'
      Rails.logger.info "[FileAnalyzer] Encoding blob with content_type: #{content_type}, size: #{tempfile.size}"
      @image_data = "data:#{content_type};base64,#{Base64.strict_encode64(tempfile.read)}"
      Rails.logger.info "[FileAnalyzer] Successfully encoded image, data length: #{@image_data.length}"
    end
  rescue => e
    Rails.logger.error "[FileAnalyzer] Error encoding attachment: #{e.class} - #{e.message}"
    Rails.logger.error "[FileAnalyzer] Backtrace: #{e.backtrace.first(5).join("\n")}"
  end

  def extract_pdf_content(file_path)
    # This would require pdf-reader gem
    # For now, returning placeholder
    "PDF content extraction would go here"
  end

  def extract_file_content(file_path)
    File.read(file_path)
  rescue
    "Unable to read file content"
  end

  def broadcast_chunk(chunk)
    return unless chunk.message[:content]
    return unless params[:stream_id]

    Rails.logger.info "[FileAnalyzer] Broadcasting chunk to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.message[:content] })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[FileAnalyzer] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
