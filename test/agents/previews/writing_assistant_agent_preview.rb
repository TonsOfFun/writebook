# Preview all agent views/prompts templates at http://localhost:3000/active_agent/agents/writing_assistant_agent
class WritingAssistantAgentPreview < ActiveAgent::Preview
  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/improve
  def improve
    WritingAssistantAgent.improve
  end

  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/grammar
  def grammar
    WritingAssistantAgent.grammar
  end

  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/style
  def style
    WritingAssistantAgent.style
  end

  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/summarize
  def summarize
    WritingAssistantAgent.summarize
  end

  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/expand
  def expand
    WritingAssistantAgent.expand
  end

  # Preview this email at http://localhost:3000/active_agent/agents/writing_assistant_agent/brainstorm
  def brainstorm
    WritingAssistantAgent.brainstorm
  end
end
