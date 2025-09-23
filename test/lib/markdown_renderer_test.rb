require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  test "it generates unique IDs for headers" do
    markdown = MarkdownRenderer.build
    content = markdown.render("# Header 1\n\n## Duplicated Header\n\n### Duplicated header\n\n")

    assert_includes content, "id='duplicated-header'"
    assert_includes content, "id='duplicated-header-2'"
  end
end
