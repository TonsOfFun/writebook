require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "stream endpoint with improve action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "improve",
      content: "This is a test."
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
    assert_match /writing_assistant_/, json_response["stream_id"]
  end

  test "stream endpoint with grammar action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "grammar",
      content: "This sentence has mistakes."
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint with style action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "style",
      content: "Change my writing style.",
      style_guide: "formal"
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint with summarize action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "summarize",
      content: "This is a long piece of text that needs to be summarized.",
      max_words: 50
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint with expand action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "expand",
      content: "Short text."
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint with brainstorm action returns stream_id" do
    post assistants_stream_url, params: {
      action_type: "brainstorm",
      topic: "content ideas"
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint with unknown action returns error" do
    post assistants_stream_url, params: {
      action_type: "unknown_action",
      content: "Test"
    }, as: :json

    assert_response :unprocessable_entity
    assert_not_nil json_response["error"]
    assert_includes json_response["error"], "Unknown action"
  end

  test "stream endpoint requires action_type parameter" do
    post assistants_stream_url, params: {
      content: "Test"
    }, as: :json

    assert_response :unprocessable_entity
  end

  private

  def json_response
    JSON.parse(@response.body)
  end
end
