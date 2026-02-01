class WritingAssistantAgent < ApplicationAgent
  # Enable context persistence for tracking prompts and generations
  has_context

  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: "You are an expert writing assistant helping authors create and improve their content for books."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def improve
    setup_content_params
    @task = "improve the writing quality, clarity, and engagement"
    setup_context_and_prompt
  end

  def grammar
    setup_content_params
    @task = "check and correct grammar, punctuation, and spelling"
    setup_context_and_prompt
  end

  def style
    setup_content_params
    @style_guide = params[:style_guide]
    @task = "adjust the writing style and tone"
    setup_context_and_prompt
  end

  def summarize
    setup_content_params
    @max_words = params[:max_words]
    @task = "create a concise summary"
    setup_context_and_prompt
  end

  def expand
    setup_content_params
    @target_length = params[:target_length]
    @areas_to_expand = params[:areas_to_expand]
    @task = "expand and elaborate on the content"
    setup_context_and_prompt
  end

  def brainstorm
    @topic = params[:topic]
    @context = params[:context]
    @full_content = params[:full_content]
    @number_of_ideas = params[:number_of_ideas]
    @task = "generate creative ideas and suggestions"
    setup_context_and_prompt
  end

  private

  def setup_content_params
    @content = params[:content]
    @selection = params[:selection]
    @full_content = params[:full_content]
    @context = params[:context]
    @has_selection = @selection.present?

    # Fragment data for tracking content transformations
    @fragment_data = params[:fragment_data]
    @fragment = nil

    # Fetch related content from the same book for additional context
    @related_content = fetch_related_content

    # Build reference context from detected markdown links
    @reference_context = build_reference_context
  end

  def fetch_related_content
    contextable = params[:contextable]
    return nil unless contextable.respond_to?(:leaf)

    leaf = contextable.leaf
    return nil unless leaf

    # Use the selection or content to find related sections
    query_text = @selection.presence || @content
    leaf.related_context(limit: 3, query: query_text)
  rescue => e
    Rails.logger.warn "[WritingAssistantAgent] Failed to fetch related content: #{e.message}"
    nil
  end

  # Build context from references detected in the selection
  # This provides source information to enhance/verify the AI response
  def build_reference_context
    return nil unless @fragment_data.present?

    detected_refs = @fragment_data[:detected_references]
    return nil unless detected_refs.present? && detected_refs.any?

    # Get accepted references (those not explicitly rejected)
    accepted_refs = detected_refs.select { |ref| ref["accepted"] != false }
    return nil if accepted_refs.empty?

    context_parts = accepted_refs.map do |ref_data|
      url = ref_data["url"]
      text = ref_data["text"]

      # Try to find existing AgentReference with cached content
      existing = AgentReference.find_by(url: url)

      if existing&.extracted_content.present?
        <<~CONTEXT
          Source: #{existing.display_title}
          URL: #{url}
          #{existing.extracted_content.truncate(1000)}
        CONTEXT
      elsif existing&.og_description.present?
        <<~CONTEXT
          Source: #{existing.display_title || text}
          URL: #{url}
          #{existing.og_description}
        CONTEXT
      else
        <<~CONTEXT
          Source: #{text}
          URL: #{url}
        CONTEXT
      end
    end

    context_parts.join("\n---\n")
  end

  # Sets up context persistence and triggers prompt rendering
  def setup_context_and_prompt
    # Create a new context, optionally associated with a contextable record (Page, Book, etc.)
    # Store the input parameters in context options for full audit trail
    create_context(
      contextable: params[:contextable],
      input_params: context_input_params
    )

    # Create a fragment to track this content transformation
    create_fragment_if_applicable

    # The prompt method will render the action template (e.g., improve.text.erb)
    # which contains the full user message. The after_prompt callback will
    # capture the rendered content for persistence.
    prompt
  end

  # Creates a fragment record if we have selection data and a context
  def create_fragment_if_applicable
    return unless @fragment_data.present? && context.present?

    @fragment = context.fragments.create!(
      contextable: params[:contextable],
      fragment_type: @fragment_data[:fragment_type] || "selection",
      original_content: @fragment_data[:original_content],
      start_offset: @fragment_data[:start_offset],
      end_offset: @fragment_data[:end_offset],
      action_type: @fragment_data[:action_type],
      detected_references: @fragment_data[:detected_references],
      status: "generating"
    )

    Rails.logger.info "[WritingAssistantAgent] Created fragment #{@fragment.id} for #{@fragment.action_type}"
  rescue => e
    Rails.logger.warn "[WritingAssistantAgent] Failed to create fragment: #{e.message}"
    @fragment = nil
  end

  # Captures the relevant input parameters for context storage
  # These params are used to rehydrate the view when rendering the context as a prompt
  def context_input_params
    {
      task: @task,
      content: @content,
      selection: @selection,
      full_content: @full_content,
      context: @context,
      has_selection: @has_selection,
      style_guide: @style_guide,
      max_words: @max_words,
      target_length: @target_length,
      areas_to_expand: @areas_to_expand,
      topic: @topic,
      number_of_ideas: @number_of_ideas,
      related_content: @related_content,
      reference_context: @reference_context,
      fragment_id: @fragment&.id
    }.compact
  end

  def broadcast_chunk(chunk)
    return unless chunk.message
    return unless params[:stream_id]

    # Accumulate content for fragment tracking
    @accumulated_content ||= ""
    @accumulated_content = chunk.message[:content] if chunk.message[:content].present?

    Rails.logger.info "[Agent] Broadcasting chunk to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.message[:content] })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    # Mark the fragment as generated with the accumulated content
    mark_fragment_generated

    Rails.logger.info "[Agent] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end

  # Mark the fragment as generated with the accumulated content
  def mark_fragment_generated
    return unless @fragment.present?

    # Use accumulated content from streaming, or fall back to response message
    generated_content = @accumulated_content.presence || response&.message&.content
    return unless generated_content.present?

    @fragment.mark_generated!(generated_content)
    Rails.logger.info "[WritingAssistantAgent] Fragment #{@fragment.id} marked as generated with #{generated_content.length} chars"
  rescue => e
    Rails.logger.warn "[WritingAssistantAgent] Failed to mark fragment as generated: #{e.message}"
  end
end
