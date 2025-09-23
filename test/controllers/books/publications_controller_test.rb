require "test_helper"

class Books::PublicationsTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:manual)

    sign_in :david
  end

  test "publish a book" do
    assert_changes -> { @book.reload.published? }, from: false, to: true do
      patch book_publication_url(@book), params: { book: { published: "1" } }
    end

    @book.reload
    assert_redirected_to book_slug_url(@book)
    assert_equal "manual", @book.slug
  end

  test "edit book slug" do
    @book.update! published: true

    get edit_book_publication_url(@book)
    assert_response :success

    patch book_publication_url(@book), params: { book: { slug: "new-slug" } }

    @book.reload
    assert_redirected_to book_slug_url(@book)
    assert_equal "new-slug", @book.slug
  end
end
