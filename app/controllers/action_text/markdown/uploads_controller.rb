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

    # Optionally generate caption for images using AI
    @caption = generate_image_caption(@upload) if should_generate_caption?(@upload)

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

  def generate_image_caption(upload)
    # Use Rails' temp file handling
    upload.blob.open do |temp_file|
      agent_response = FileAnalyzerAgent.with(
        file_path: temp_file.path,
        description_detail: "brief"
      ).analyze_image.generate_now

      # Extract caption from response
      agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s
    end
  rescue => e
    Rails.logger.error "[Image Caption] Failed to generate caption: #{e.message}"
    nil
  end
end
