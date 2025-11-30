class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show

  before_action do
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
  end

  def create
    @record = GlobalID::Locator.locate_signed params[:record_gid]

    @markdown = @record.safe_markdown_attribute params[:attribute_name]
    @markdown.uploads.attach params[:file]
    @markdown.save!

    @upload = @markdown.uploads.attachments.last

    # Optionally generate caption for images using AI with streaming
    if should_generate_caption?(@upload)
      @stream_id = "image_caption_#{SecureRandom.hex(8)}"
      Rails.logger.info "[Upload] Starting caption generation for stream_id: #{@stream_id}"

      # Start async caption generation with streaming
      generate_image_caption_stream(@upload, @stream_id)
    end

    render :create, status: :created, formats: :json
  end

  def show
    @attachment = ActiveStorage::Attachment.find_by! slug: "#{params[:slug]}.#{params[:format]}"
    expires_in 1.year, public: true
    redirect_to @attachment.url
  end

  private

  def should_generate_caption?(upload)
    # Only generate captions for images, and could be feature-flagged
    upload.content_type&.start_with?('image/') &&
      defined?(FileAnalyzerAgent) # Check if the agent exists
  end

  def generate_image_caption_stream(upload, stream_id)
    # Use Rails' temp file handling in a background thread
    Thread.new do
      upload.blob.open do |temp_file|
        FileAnalyzerAgent.with(
          file_path: temp_file.path,
          description_detail: "brief",
          stream_id: stream_id
        ).analyze_image.generate_later
      end
    rescue => e
      Rails.logger.error "[Image Caption] Failed to generate caption: #{e.message}"
      # Broadcast error to the client
      ActionCable.server.broadcast(stream_id, { error: e.message })
    end
  end
end
