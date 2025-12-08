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
    setup_context_and_prompt(user_message: brainstorm_user_message)
  end

  private

  def setup_content_params
    @content = params[:content]
    @selection = params[:selection]
    @full_content = params[:full_content]
    @context = params[:context]
    @has_selection = @selection.present?
  end

  # Sets up context persistence and records the user's input
  def setup_context_and_prompt(user_message: nil)
    # Create a new context, optionally associated with a contextable record
    create_context(contextable: params[:contextable])

    # Record the user's input message
    add_user_message(user_message || content_user_message)

    # Execute the prompt
    prompt
  end

  # Builds a user message for content-based actions (improve, grammar, style, etc.)
  def content_user_message
    message_parts = ["Task: #{@task}"]
    message_parts << "Content: #{@content}" if @content.present?
    message_parts << "Selection: #{@selection}" if @selection.present?
    message_parts << "Context: #{@context}" if @context.present?
    message_parts.join("\n\n")
  end

  # Builds a user message for brainstorm action
  def brainstorm_user_message
    message_parts = ["Task: #{@task}"]
    message_parts << "Topic: #{@topic}" if @topic.present?
    message_parts << "Context: #{@context}" if @context.present?
    message_parts << "Number of ideas requested: #{@number_of_ideas}" if @number_of_ideas.present?
    message_parts.join("\n\n")
  end

  def broadcast_chunk(chunk)
    return unless chunk.delta
    return unless params[:stream_id]

    Rails.logger.info "[Agent] Broadcasting chunk to stream_id: #{params[:stream_id]}, chunk length: #{chunk.delta.length}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.delta })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[Agent] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
