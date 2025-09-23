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
end
