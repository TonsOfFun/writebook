require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user does not prevent very long passwords" do
    users(:david).update(password: "secret" * 50)
    assert users(:david).valid?
  end

  test "new users get access to everyone books" do
    everyone_book = Book.create!(title: "My new book", everyone_access: true)
    other_book = Book.create!(title: "My secret book", everyone_access: false)

    bob = User.create!(email_address: "bob@example.com", name: "Bob", password: "secret123456")

    assert everyone_book.accessable?(user: bob)
    assert_not everyone_book.editable?(user: bob)

    assert_not other_book.accessable?(user: bob)
  end
end
