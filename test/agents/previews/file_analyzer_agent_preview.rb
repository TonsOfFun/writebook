# Preview all agent views/prompts templates at http://localhost:3000/active_agent/agents/file_analyzer_agent
class FileAnalyzerAgentPreview < ActiveAgent::Preview
  # Preview this email at http://localhost:3000/active_agent/agents/file_analyzer_agent/analyze_pdf
  def analyze_pdf
    FileAnalyzerAgent.analyze_pdf
  end

  # Preview this email at http://localhost:3000/active_agent/agents/file_analyzer_agent/analyze_image
  def analyze_image
    FileAnalyzerAgent.analyze_image
  end

  # Preview this email at http://localhost:3000/active_agent/agents/file_analyzer_agent/extract_text
  def extract_text
    FileAnalyzerAgent.extract_text
  end

  # Preview this email at http://localhost:3000/active_agent/agents/file_analyzer_agent/summarize_document
  def summarize_document
    FileAnalyzerAgent.summarize_document
  end
end
