puts "Seeding users..."
librarian = User.find_or_initialize_by(email: "librarian@example.com")
librarian.update!(
  name: "Libby Page",
  password: "password123",
  password_confirmation: "password123",
  role: :librarian
)

member = User.find_or_initialize_by(email: "member@example.com")
member.update!(
  name: "Milo Reader",
  password: "password123",
  password_confirmation: "password123",
  role: :member
)

puts "Seeding books..."
books_data = [
  { title: "The Pragmatic Programmer", author: "Andrew Hunt", genre: "Technology", isbn: "9780201616224", total_copies: 3 },
  { title: "Clean Code", author: "Robert C. Martin", genre: "Technology", isbn: "9780132350884", total_copies: 5 },
  { title: "Sapiens", author: "Yuval Noah Harari", genre: "History", isbn: "9780062316097", total_copies: 4 },
  { title: "Educated", author: "Tara Westover", genre: "Memoir", isbn: "9780399590504", total_copies: 2 },
  { title: "1984", author: "George Orwell", genre: "Fiction", isbn: "9780451524935", total_copies: 6 }
]

books = books_data.map do |book_attrs|
  Book.find_or_create_by!(isbn: book_attrs[:isbn]) do |book|
    book.assign_attributes(book_attrs)
  end
end

puts "Creating sample borrowings..."
Borrowing.find_or_create_by!(user: member, book: books.first, returned_at: nil) do |borrowing|
  borrowing.borrowed_at = 10.days.ago
  borrowing.due_at = borrowing.borrowed_at + 14.days
end

Borrowing.find_or_create_by!(user: member, book: books.second, returned_at: nil) do |borrowing|
  borrowing.borrowed_at = 20.days.ago
  borrowing.due_at = borrowing.borrowed_at + 14.days
end

puts "Seeding complete."
