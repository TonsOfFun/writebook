class AssistantsController < ApplicationController
  include ActionController::Live

  # Authentication is handled by ApplicationController via require_authentication

  def writing_improve
    agent_response = WritingAssistantAgent.with(
      content: params[:content],
      context: params[:context]
    ).improve.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      improved_content: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_grammar
    agent_response = WritingAssistantAgent.with(
      content: params[:content]
    ).grammar.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      corrected_content: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_style
    agent_response = WritingAssistantAgent.with(
      content: params[:content],
      style_guide: params[:style_guide]
    ).style.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      styled_content: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_summarize
    agent_response = WritingAssistantAgent.with(
      content: params[:content],
      max_words: params[:max_words] || 150
    ).summarize.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      summary: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_expand
    agent_response = WritingAssistantAgent.with(
      content: params[:content],
      target_length: params[:target_length],
      areas_to_expand: params[:areas_to_expand]
    ).expand.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      expanded_content: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_brainstorm
    agent_response = WritingAssistantAgent.with(
      topic: params[:topic],
      context: params[:context],
      number_of_ideas: params[:number_of_ideas] || 5
    ).brainstorm.generate_now

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    render json: {
      ideas: content,
      status: :success
    }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def analyze_file
    file = params[:file]
    analysis_type = params[:analysis_type] || "general"

    # Save uploaded file temporarily
    temp_path = Rails.root.join('tmp', file.original_filename)
    File.open(temp_path, 'wb') do |f|
      f.write(file.read)
    end

    agent_response = case file.content_type
    when /pdf/
      FileAnalyzerAgent.with(
        file_path: temp_path,
        analysis_type: analysis_type
      ).analyze_pdf.generate_now
    when /image/
      FileAnalyzerAgent.with(
        file_path: temp_path,
        description_detail: params[:detail_level]
      ).analyze_image.generate_now
    else
      FileAnalyzerAgent.with(
        file_path: temp_path,
        format: params[:format]
      ).extract_text.generate_now
    end

    # Extract the content from the response
    content = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    # Clean up temp file
    File.delete(temp_path) if File.exist?(temp_path)

    render json: {
      analysis: content,
      file_type: file.content_type,
      status: :success
    }
  rescue => e
    Rails.logger.error "FileAnalyzer error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    File.delete(temp_path) if defined?(temp_path) && File.exist?(temp_path)
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # New action specifically for image captions
  def image_caption
    file = params[:file]

    unless file && file.content_type&.match?(/image/)
      return render json: { error: "Please provide an image file" }, status: :unprocessable_entity
    end

    # Save uploaded file temporarily with a unique name
    temp_filename = "upload_#{SecureRandom.hex(8)}_#{file.original_filename}"
    temp_path = Rails.root.join('tmp', temp_filename)

    File.open(temp_path, 'wb') do |f|
      f.write(file.read)
    end

    agent_response = FileAnalyzerAgent.with(
      file_path: temp_path.to_s,
      description_detail: params[:detail_level] || "medium"
    ).analyze_image.generate_now

    # Extract the content from the response
    caption = agent_response.respond_to?(:message) ? agent_response.message.content : agent_response.to_s

    # Clean up temp file
    File.delete(temp_path) if File.exist?(temp_path)

    render json: {
      caption: caption,
      filename: file.original_filename,
      status: :success
    }
  rescue => e
    Rails.logger.error "Image caption error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    File.delete(temp_path) if defined?(temp_path) && File.exist?(temp_path)
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Single streaming endpoint that routes to different agent actions
  def stream
    action = params[:action_type]
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"
    Rails.logger.info "[Streaming] Action: #{action}, stream_id: #{stream_id}"

    agent = WritingAssistantAgent.with(
      content: params[:content],
      context: params[:context],
      style_guide: params[:style_guide],
      max_words: params[:max_words] || 150,
      target_length: params[:target_length],
      areas_to_expand: params[:areas_to_expand],
      topic: params[:topic],
      number_of_ideas: params[:number_of_ideas] || 5,
      stream_id: stream_id
    )

    # Route to the appropriate agent action
    case action
    when 'improve'
      agent.improve.generate_later
    when 'grammar'
      agent.grammar.generate_later
    when 'style'
      agent.style.generate_later
    when 'summarize'
      agent.summarize.generate_later
    when 'expand'
      agent.expand.generate_later
    when 'brainstorm'
      agent.brainstorm.generate_later
    else
      return render json: { error: "Unknown action: #{action}" }, status: :unprocessable_entity
    end

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "[Streaming] Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end
end