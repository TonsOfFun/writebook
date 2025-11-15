class WritingAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o-mini",
    stream: true,
    instructions: "You are an expert writing assistant helping authors create and improve their content for books."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def improve
    @content = params[:content]
    @context = params[:context]
    @task = "improve the writing quality, clarity, and engagement"
    prompt
  end

  def grammar
    @content = params[:content]
    @task = "check and correct grammar, punctuation, and spelling"
    prompt
  end

  def style
    @content = params[:content]
    @style_guide = params[:style_guide]
    @task = "adjust the writing style and tone"
    prompt
  end

  def summarize
    @content = params[:content]
    @max_words = params[:max_words]
    @task = "create a concise summary"
    prompt
  end

  def expand
    @content = params[:content]
    @target_length = params[:target_length]
    @areas_to_expand = params[:areas_to_expand]
    @task = "expand and elaborate on the content"
    prompt
  end

  def brainstorm
    @topic = params[:topic]
    @context = params[:context]
    @number_of_ideas = params[:number_of_ideas]
    @task = "generate creative ideas and suggestions"
    prompt
  end

  private

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
