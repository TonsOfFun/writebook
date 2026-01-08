class AssistantsController < ApplicationController
  # Authentication is handled by ApplicationController via require_authentication

  def writing_improve
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      content: params[:content],
      context: params[:context],
      stream_id: stream_id
    ).improve.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_grammar
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      content: params[:content],
      stream_id: stream_id
    ).grammar.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_style
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      content: params[:content],
      style_guide: params[:style_guide],
      stream_id: stream_id
    ).style.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_summarize
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      content: params[:content],
      max_words: params[:max_words] || 150,
      stream_id: stream_id
    ).summarize.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_expand
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      content: params[:content],
      target_length: params[:target_length],
      areas_to_expand: params[:areas_to_expand],
      stream_id: stream_id
    ).expand.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def writing_brainstorm
    stream_id = "writing_assistant_#{SecureRandom.hex(8)}"

    WritingAssistantAgent.with(
      topic: params[:topic],
      context: params[:context],
      number_of_ideas: params[:number_of_ideas] || 5,
      stream_id: stream_id
    ).brainstorm.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "AssistantsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def research
    stream_id = "research_assistant_#{SecureRandom.hex(8)}"

    # Look up the page to associate context with for references
    contextable = params[:page_id].present? ? Page.find_by(id: params[:page_id]) : nil

    ResearchAssistantAgent.with(
      topic: params[:topic],
      context: params[:context],
      full_content: params[:full_content],
      depth: params[:depth] || "standard",
      stream_id: stream_id,
      contextable: contextable
    ).research.generate_later

    render json: { stream_id: stream_id }
  rescue => e
    Rails.logger.error "ResearchAssistant error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def analyze_file
    file = params[:file]
    analysis_type = params[:analysis_type] || "general"
    stream_id = "file_analyzer_#{SecureRandom.hex(8)}"

    # Save uploaded file temporarily with unique name
    temp_filename = "upload_#{SecureRandom.hex(8)}_#{file.original_filename}"
    temp_path = Rails.root.join('tmp', temp_filename)
    File.open(temp_path, 'wb') do |f|
      f.write(file.read)
    end

    case file.content_type
    when /pdf/
      FileAnalyzerAgent.with(
        file_path: temp_path.to_s,
        analysis_type: analysis_type,
        stream_id: stream_id
      ).analyze_pdf.generate_later
    when /image/
      FileAnalyzerAgent.with(
        file_path: temp_path.to_s,
        description_detail: params[:detail_level],
        stream_id: stream_id
      ).analyze_image.generate_later
    else
      FileAnalyzerAgent.with(
        file_path: temp_path.to_s,
        format: params[:format],
        stream_id: stream_id
      ).extract_text.generate_later
    end

    render json: { stream_id: stream_id, file_type: file.content_type }
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

    stream_id = "image_caption_#{SecureRandom.hex(8)}"

    # Save uploaded file temporarily with a unique name
    temp_filename = "upload_#{SecureRandom.hex(8)}_#{file.original_filename}"
    temp_path = Rails.root.join('tmp', temp_filename)

    File.open(temp_path, 'wb') do |f|
      f.write(file.read)
    end

    FileAnalyzerAgent.with(
      file_path: temp_path.to_s,
      description_detail: params[:detail_level] || "medium",
      stream_id: stream_id
    ).analyze_image.generate_later

    render json: { stream_id: stream_id, filename: file.original_filename }
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

    # Determine what content to work on:
    # - If selection is provided, work on selection with full_content as context
    # - Otherwise, work on full_content directly
    selection = params[:selection]
    full_content = params[:full_content]
    content = selection.present? ? selection : full_content

    agent = WritingAssistantAgent.with(
      content: content,
      selection: selection,
      full_content: full_content,
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
    when 'research'
      # Research uses a different agent with browser tools
      # Look up the page to associate context with for references
      contextable = params[:page_id].present? ? Page.find_by(id: params[:page_id]) : nil

      research_agent = ResearchAssistantAgent.with(
        topic: params[:topic] || content,
        context: params[:context],
        full_content: full_content,
        depth: params[:depth] || "standard",
        stream_id: stream_id,
        contextable: contextable
      )
      research_agent.research.generate_later
    when 'extract_image_text'
      # Image text extraction uses FileAnalyzerAgent with attachment slug
      unless params[:attachment_slug].present?
        return render json: { error: "attachment_slug is required for image text extraction" }, status: :unprocessable_entity
      end

      file_agent = FileAnalyzerAgent.with(
        attachment_slug: params[:attachment_slug],
        extraction_focus: params[:extraction_focus] || "all",
        stream_id: stream_id
      )
      file_agent.extract_image_text.generate_later
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