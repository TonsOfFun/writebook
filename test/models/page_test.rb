require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "html preview" do
    page = Page.new(body: "# Hello\n\nWorld!")

    assert_match /<h1>Hello<\/h1>/, page.html_preview
    assert_match /<p>World!<\/p>/, page.html_preview
  end
end
