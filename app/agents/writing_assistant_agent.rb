class WritingAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o-mini",
    instructions: "You are an expert writing assistant helping authors create and improve their content for books."

  def improve
    @content = params[:content]
    @context = params[:context]
    @task = "improve the writing quality, clarity, and engagement"
    prompt(content_type: :text)
  end

  def grammar
    @content = params[:content]
    @task = "check and correct grammar, punctuation, and spelling"
    prompt(content_type: :text)
  end

  def style
    @content = params[:content]
    @style_guide = params[:style_guide]
    @task = "adjust the writing style and tone"
    prompt(content_type: :text)
  end

  def summarize
    @content = params[:content]
    @max_words = params[:max_words]
    @task = "create a concise summary"
    prompt(content_type: :text)
  end

  def expand
    @content = params[:content]
    @target_length = params[:target_length]
    @areas_to_expand = params[:areas_to_expand]
    @task = "expand and elaborate on the content"
    prompt(content_type: :text)
  end

  def brainstorm
    @topic = params[:topic]
    @context = params[:context]
    @number_of_ideas = params[:number_of_ideas]
    @task = "generate creative ideas and suggestions"
    prompt(content_type: :text)
  end
end
