require "test_helper"

class Books::Leaves::MovesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "moving a single item" do
    assert_equal [ leaves(:welcome_section), leaves(:welcome_page), leaves(:summary_page), leaves(:reading_picture) ], books(:handbook).leaves.positioned

    post book_leaves_moves_url(books(:handbook), id: leaves(:welcome_page).id, position: 0)
    assert_response :no_content

    assert_equal [ leaves(:welcome_page), leaves(:welcome_section), leaves(:summary_page), leaves(:reading_picture) ], books(:handbook).leaves.positioned
  end

  test "moving multiple items" do
    assert_equal [ leaves(:welcome_section), leaves(:welcome_page), leaves(:summary_page), leaves(:reading_picture) ], books(:handbook).leaves.positioned

    post book_leaves_moves_url(books(:handbook), id: leaves(:summary_page, :reading_picture).map(&:id), position: 1)
    assert_response :no_content

    assert_equal [ leaves(:welcome_section), leaves(:summary_page), leaves(:reading_picture), leaves(:welcome_page) ], books(:handbook).leaves.positioned
  end
end
