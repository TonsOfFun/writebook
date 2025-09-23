require "test_helper"

class Book::AccessableTest < ActiveSupport::TestCase
  test "update_access always grants read access to everyone when everyone_access is set" do
    book = Book.create!(title: "My new book")
    book.update_access(editors: [], readers: [])

    assert book.everyone_access?

    User.all.each do |user|
      assert book.accessable?(user: user)
      assert_not book.editable?(user: user) unless user.administrator?
    end
  end

  test "update_access updates existing access" do
    book = Book.create!(title: "My new book", everyone_access: false)

    book.update_access(editors: [ users(:kevin).id ], readers: [])
    assert book.editable?(user: users(:kevin))

    book.update_access(editors: [], readers: [ users(:kevin).id ])
    assert book.accessable?(user: users(:kevin))
    assert_not book.editable?(user: users(:kevin))
  end

  test "update_access removes stale accesses" do
    book = Book.create!(title: "My new book", everyone_access: false)

    book.update_access(editors: [ users(:kevin).id ], readers: [ users(:jz).id ])
    assert_equal 2, book.accesses.size

    book.update_access(editors: [ users(:kevin).id ], readers: [])
    assert_equal 1, book.accesses.size
  end
end
