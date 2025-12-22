class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show

  before_action do
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
  end

  def create
    @record = GlobalID::Locator.locate_signed params[:record_gid]
    Rails.logger.info "[Upload] params[:file] class: #{params[:file].class}"

    @markdown = @record.safe_markdown_attribute params[:attribute_name]
    Rails.logger.info "[Upload] @markdown.id: #{@markdown.id}, persisted: #{@markdown.persisted?}"

    # Create blob and attachment directly to avoid issues with pre-loaded associations
    blob = ActiveStorage::Blob.create_and_upload!(
      io: params[:file],
      filename: params[:file].original_filename,
      content_type: params[:file].content_type
    )

    # Create attachment directly instead of using attach (which has issues with pre-loaded associations)
    @upload = ActiveStorage::Attachment.create!(
      name: "uploads",
      record: @markdown,
      blob: blob
    )
    @markdown.save!

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
    Rails.logger.info "[Image Caption] Checking image type..."
    # Only generate captions for images, and could be feature-flagged
    upload.content_type&.start_with?('image/') &&
      defined?(FileAnalyzerAgent) # Check if the agent exists
  end

  def generate_image_caption_stream(upload, stream_id)
    FileAnalyzerAgent.with(
      attachment_slug: upload.slug,
      description_detail: "full",
      stream_id: stream_id
    ).analyze_image.generate_later
  rescue => e
    Rails.logger.error "[Image Caption] Failed to generate caption: #{e.message}"
    ActionCable.server.broadcast(stream_id, { error: e.message })
  end
end
