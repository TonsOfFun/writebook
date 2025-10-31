require "test_helper"

class FileAnalyzerAgentTest < ActiveAgent::TestCase
  test "analyze_pdf" do
    agent = FileAnalyzerAgent.analyze_pdf
    assert_equal "Analyze pdf", agent.prompt_context
  end

  test "analyze_image" do
    agent = FileAnalyzerAgent.analyze_image
    assert_equal "Analyze image", agent.prompt_context
  end

  test "extract_text" do
    agent = FileAnalyzerAgent.extract_text
    assert_equal "Extract text", agent.prompt_context
  end

  test "summarize_document" do
    agent = FileAnalyzerAgent.summarize_document
    assert_equal "Summarize document", agent.prompt_context
  end
end
