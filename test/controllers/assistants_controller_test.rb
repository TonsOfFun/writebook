require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
    @temp_dir = Rails.root.join('tmp', 'test_uploads')
    FileUtils.mkdir_p(@temp_dir)
  end

  teardown do
    FileUtils.rm_rf(@temp_dir)
  end

  # ============================================
  # Stream endpoint tests
  # ============================================

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

  test "stream endpoint accepts context parameter" do
    post assistants_stream_url, params: {
      action_type: "improve",
      content: "Test content",
      context: "This is for a technical manual"
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint accepts number_of_ideas for brainstorm" do
    post assistants_stream_url, params: {
      action_type: "brainstorm",
      topic: "Book chapter ideas",
      number_of_ideas: 10
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  test "stream endpoint accepts target_length for expand" do
    post assistants_stream_url, params: {
      action_type: "expand",
      content: "Brief introduction.",
      target_length: 500,
      areas_to_expand: "background, examples"
    }, as: :json

    assert_response :success
    assert_not_nil json_response["stream_id"]
  end

  # ============================================
  # Authentication tests
  # ============================================

  test "stream endpoint requires authentication" do
    sign_out

    post assistants_stream_url, params: {
      action_type: "improve",
      content: "Test"
    }, as: :json

    assert_response :redirect
  end

  # ============================================
  # Image caption endpoint tests
  # ============================================

  test "image_caption rejects non-image files" do
    text_file = create_test_file("test.txt", "text content", "text/plain")

    post "/assistants/image/caption", params: {
      file: text_file
    }, as: :multipart_form

    assert_response :unprocessable_entity
    assert_includes json_response["error"], "image file"
  end

  test "image_caption rejects request without file" do
    post "/assistants/image/caption", params: {}, as: :json

    assert_response :unprocessable_entity
  end

  # ============================================
  # Stream ID format tests
  # ============================================

  test "stream_id has unique suffix each time" do
    post assistants_stream_url, params: {
      action_type: "improve",
      content: "First request"
    }, as: :json
    first_stream_id = json_response["stream_id"]

    post assistants_stream_url, params: {
      action_type: "improve",
      content: "Second request"
    }, as: :json
    second_stream_id = json_response["stream_id"]

    assert_not_equal first_stream_id, second_stream_id
  end

  test "stream_id format is correct" do
    post assistants_stream_url, params: {
      action_type: "grammar",
      content: "Test"
    }, as: :json

    stream_id = json_response["stream_id"]
    assert_match /^writing_assistant_[a-f0-9]{16}$/, stream_id
  end

  # ============================================
  # Empty content handling tests
  # ============================================

  test "stream endpoint handles empty content" do
    post assistants_stream_url, params: {
      action_type: "improve",
      content: ""
    }, as: :json

    # Should still process (the agent will handle empty content)
    assert_response :success
  end

  test "stream endpoint handles whitespace only content" do
    post assistants_stream_url, params: {
      action_type: "grammar",
      content: "   \n\t  "
    }, as: :json

    assert_response :success
  end

  private

  def json_response
    JSON.parse(@response.body)
  end

  def sign_out
    delete session_url
  end

  def create_test_file(filename, content, content_type)
    path = @temp_dir.join(filename)
    File.write(path, content)

    Rack::Test::UploadedFile.new(path, content_type)
  end
end
