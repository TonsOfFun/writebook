require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "slug is generated from title" do
    book = Book.create!(title: "Hello, World!")
    assert_equal "hello-world", book.slug
  end

  test "press a leafable" do
    leaf = books(:manual).press Page.new(body: "Important words"), title: "Introduction"

    assert leaf.page?
    assert_equal "Important words", leaf.page.body.content.to_s
    assert_equal "Introduction", leaf.title
  end
end
