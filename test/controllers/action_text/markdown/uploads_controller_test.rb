require "test_helper"

class ActionText::Markdown::UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "attach a file" do
    assert_changes -> { ActiveStorage::Attachment.count }, 1 do
      post action_text_markdown_uploads_url, params: {
        record_gid: pages(:welcome).to_signed_global_id.to_s,
        attribute_name: "body",
        file: fixture_file_upload("reading.webp", "image/webp")
      }, as: :xhr
    end

    assert_response :success
  end

  test "view attached file" do
    markdown = pages(:welcome).body.tap(&:save!)
    markdown.uploads.attach fixture_file_upload("reading.webp", "image/webp")

    attachment = pages(:welcome).body.uploads.last

    get action_text_markdown_upload_url(slug: attachment.slug)

    assert_response :redirect
    assert_match /\/rails\/active_storage\/.*\/reading\.webp/, @response.redirect_url
  end

  test "attach image file returns stream_id for caption generation" do
    post action_text_markdown_uploads_url, params: {
      record_gid: pages(:welcome).to_signed_global_id.to_s,
      attribute_name: "body",
      file: fixture_file_upload("reading.webp", "image/webp")
    }, as: :xhr

    assert_response :success
    json = JSON.parse(@response.body)

    assert_not_nil json["fileUrl"], "Should return file URL"
    assert_not_nil json["fileName"], "Should return file name"

    # If FileAnalyzerAgent is defined, should return stream_id for caption
    if defined?(FileAnalyzerAgent)
      assert_not_nil json["streamId"], "Should return stream_id for caption generation"
      assert_match /image_caption_/, json["streamId"]
    end
  end

  test "attach non-image file does not return stream_id" do
    # Create a text file fixture
    post action_text_markdown_uploads_url, params: {
      record_gid: pages(:welcome).to_signed_global_id.to_s,
      attribute_name: "body",
      file: fixture_file_upload("test.txt", "text/plain")
    }, as: :xhr

    assert_response :success
    json = JSON.parse(@response.body)

    assert_not_nil json["fileUrl"]
    assert_nil json["streamId"], "Should not generate captions for non-image files"
  end
end
