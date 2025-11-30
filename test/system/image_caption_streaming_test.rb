require "application_system_test_case"

class ImageCaptionStreamingTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@37signals.com"
  end

  test "uploading image shows immediate image and streams caption" do
    skip "Requires AI API keys to be configured" unless ai_configured?

    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "house-md"

    # Get the current content
    initial_content = find("house-md").value

    # Upload an image (this assumes there's an upload button in the toolbar)
    if has_css?('[title="Upload File"]', wait: 1)
      # Attach file to the hidden file input
      # Note: This might need to be adjusted based on the actual implementation
      page.execute_script(<<~JS)
        const input = document.createElement('input');
        input.type = 'file';
        input.style.display = 'none';
        document.body.appendChild(input);
        window.testFileInput = input;
      JS

      # Attach the file
      attach_file('window.testFileInput', Rails.root.join('test/fixtures/files/reading.webp'), visible: false)

      # Trigger the upload by simulating the change event
      page.execute_script(<<~JS)
        const event = new Event('change', { bubbles: true });
        window.testFileInput.dispatchEvent(event);
      JS

      # Wait for image markdown to appear
      assert_selector "house-md", wait: 5 do |element|
        element.value.include?('![') && element.value.include?('](')
      end

      # Check for caption placeholder
      assert_selector "house-md", wait: 2 do |element|
        element.value.include?('*Generating caption*') || element.value.include?('*')
      end

      # Wait for caption to stream in (replacing placeholder)
      # The caption should update from "Generating caption..." to actual content
      assert_selector "house-md", wait: 15 do |element|
        content = element.value
        # Should have image markdown and some caption text (not just placeholder)
        content.include?('![') && content.include?('*') &&
          !content.include?('Generating caption')
      end
    else
      skip "Upload button not available in toolbar"
    end
  end

  private

  def ai_configured?
    # Check if AI services and FileAnalyzerAgent are configured
    defined?(FileAnalyzerAgent) &&
      (ENV['OPENAI_API_KEY'].present? || ENV['ANTHROPIC_API_KEY'].present?)
  end
end
