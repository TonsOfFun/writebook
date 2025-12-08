require 'base64'

class FileAnalyzerAgent < ApplicationAgent
  # Enable context persistence for tracking file analysis sessions
  has_context

  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: "You are an expert document analyzer capable of extracting insights from PDFs, images, and other file types."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  # Defer base64 encoding until right before prompt processing
  before_prompt :encode_image_for_prompt, only: :analyze_image

  def analyze_pdf
    @file_path = params[:file_path]
    # Read PDF content (would need pdf-reader gem)
    @content = extract_pdf_content(@file_path) if @file_path

    setup_context_and_prompt("Analyze PDF: #{@file_path}")
  end

  def analyze_image
    # Store file path - encoding happens lazily in before_prompt callback
    @file_path = params[:file_path]
    @description_detail = params[:description_detail] || "medium"

    setup_context_and_prompt("Analyze image: #{@file_path}, detail level: #{@description_detail}")
  end

  def extract_text
    @file_path = params[:file_path]
    @content = extract_file_content(@file_path) if @file_path

    setup_context_and_prompt("Extract text from: #{@file_path}")
  end

  def summarize_document
    @file_path = params[:file_path]
    @content = extract_file_content(@file_path) if @file_path

    setup_context_and_prompt("Summarize document: #{@file_path}")
  end

  private

  # Sets up context persistence and records the analysis request
  def setup_context_and_prompt(user_message)
    # Create a new context, optionally associated with a contextable record
    create_context(contextable: params[:contextable])

    # Record the user's analysis request
    add_user_message(user_message)

    # Execute the prompt
    prompt
  end

  # Lazily encode image to base64 only when the prompt is about to be processed
  # This avoids holding large base64 strings in memory longer than necessary
  def encode_image_for_prompt
    return unless @file_path && File.exist?(@file_path)

    # Detect content type from file extension
    content_type = case File.extname(@file_path).downcase
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.webp' then 'image/webp'
    else 'image/jpeg'
    end

    # Encode and set as instance variable for the prompt
    @image_data = "data:#{content_type};base64,#{Base64.strict_encode64(File.binread(@file_path))}"
  end

  def extract_pdf_content(file_path)
    # This would require pdf-reader gem
    # For now, returning placeholder
    "PDF content extraction would go here"
  end

  def encode_image(file_path)
    # Base64 encode image for vision API
    Base64.strict_encode64(File.binread(file_path))
  rescue
    nil
  end

  def extract_file_content(file_path)
    File.read(file_path)
  rescue
    "Unable to read file content"
  end

  def broadcast_chunk(chunk)
    return unless chunk.delta
    return unless params[:stream_id]

    Rails.logger.info "[FileAnalyzer] Broadcasting chunk to stream_id: #{params[:stream_id]}, chunk length: #{chunk.delta.length}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.delta })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[FileAnalyzer] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
