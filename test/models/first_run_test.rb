require "test_helper"

class FirstRunTest < ActiveSupport::TestCase
  setup do
    Book.destroy_all
    User.destroy_all
    Account.destroy_all
  end

  test "creating makes first user an administrator" do
    user = create_first_run_user
    assert user.administrator?
  end

  test "creates an account" do
    assert_changes -> { Account.count }, +1 do
      create_first_run_user
    end
  end

  test "creates a demo book" do
    assert_changes -> { Book.count }, to: 1 do
      create_first_run_user
    end

    book = Book.first

    assert book.editable?(user: User.first)
    assert book.cover.attached?
    assert book.leaves.any?
  end

  private
    def create_first_run_user
      FirstRun.create!({ name: "User", email_address: "user@example.com", password: "secret123456" })
    end
end
