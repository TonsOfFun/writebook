class WritingAssistantAgent < ApplicationAgent
  
  generate_with :ollama,
    model: "gpt-oss:20b",
    base_url: "http://10.147.19.111:11434/v1",
    stream: true,
    instructions: "You are an expert writing assistant helping authors create and improve their content for books."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def improve
    setup_content_params
    @task = "improve the writing quality, clarity, and engagement"
    prompt
  end

  def grammar
    setup_content_params
    @task = "check and correct grammar, punctuation, and spelling"
    prompt
  end

  def style
    setup_content_params
    @style_guide = params[:style_guide]
    @task = "adjust the writing style and tone"
    prompt
  end

  def summarize
    setup_content_params
    @max_words = params[:max_words]
    @task = "create a concise summary"
    prompt
  end

  def expand
    setup_content_params
    @target_length = params[:target_length]
    @areas_to_expand = params[:areas_to_expand]
    @task = "expand and elaborate on the content"
    prompt
  end

  def brainstorm
    @topic = params[:topic]
    @context = params[:context]
    @full_content = params[:full_content]
    @number_of_ideas = params[:number_of_ideas]
    @task = "generate creative ideas and suggestions"
    prompt
  end

  private

  def setup_content_params
    @content = params[:content]
    @selection = params[:selection]
    @full_content = params[:full_content]
    @context = params[:context]
    @has_selection = @selection.present?
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
