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

    # Fetch related content from the same book for additional context
    @related_content = fetch_related_content
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

  # Sets up context persistence and triggers prompt rendering
  def setup_context_and_prompt
    # Create a new context, optionally associated with a contextable record (Page, Book, etc.)
    # Store the input parameters in context options for full audit trail
    create_context(
      contextable: params[:contextable],
      input_params: context_input_params
    )

    # The prompt method will render the action template (e.g., improve.text.erb)
    # which contains the full user message. The after_prompt callback will
    # capture the rendered content for persistence.
    prompt
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
      related_content: @related_content
    }.compact
  end

  def broadcast_chunk(chunk)
    return unless chunk.message
    return unless params[:stream_id]

    Rails.logger.info "[Agent] Broadcasting chunk to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.message[:content] })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[Agent] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
