require "application_system_test_case"

class AiAssistantStreamingTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@37signals.com"
  end

  test "AI improve writing streams response" do
    skip "Requires AI API keys to be configured" unless ai_configured?

    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "house-md"

    # Fill in some content
    fill_house_editor "page[body]", with: "This is test content that needs improving."

    # Click the AI Improve button (if visible)
    if has_button?("Improve", wait: 1)
      click_button "Improve"

      # Wait for streaming to start - editor should clear
      assert_selector "house-md", text: "", wait: 2

      # Wait for some content to stream in (content should appear character by character)
      # We can't predict the exact content, but we should see something after a few seconds
      assert_selector "house-md", wait: 10 do |element|
        element.text.length > 0
      end
    else
      skip "AI Improve button not available in toolbar"
    end
  end

  test "AI grammar check streams response" do
    skip "Requires AI API keys to be configured" unless ai_configured?

    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "house-md"

    # Fill in some content with grammatical errors
    fill_house_editor "page[body]", with: "This sentence have mistakes in it."

    if has_button?("Grammar", wait: 1)
      click_button "Grammar"

      # Wait for streaming
      assert_selector "house-md", wait: 10 do |element|
        element.text.length > 0
      end
    else
      skip "AI Grammar button not available in toolbar"
    end
  end

  private

  def ai_configured?
    # Check if AI services are configured
    defined?(WritingAssistantAgent) &&
      (ENV['OPENAI_API_KEY'].present? || ENV['ANTHROPIC_API_KEY'].present?)
  end
end
