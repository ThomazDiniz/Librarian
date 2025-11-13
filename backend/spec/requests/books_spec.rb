require "rails_helper"

RSpec.describe "Books API", type: :request do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user) }

  describe "GET /books" do
    before do
      create(:book, title: "Eloquent Ruby", author: "Russ Olsen", genre: "Programming")
      create(:book, title: "The Hobbit", author: "J.R.R. Tolkien", genre: "Fantasy")
    end

    it "returns all books for authenticated users" do
      get "/books", headers: auth_headers(member)

      expect(response).to have_http_status(:ok)
      titles = parsed_response.map { |book| book["title"] }
      expect(titles).to include("Eloquent Ruby", "The Hobbit")
    end

    it "filters books by search query" do
      get "/books", params: { q: "ruby" }, headers: auth_headers(member)

      expect(response).to have_http_status(:ok)
      titles = parsed_response.map { |book| book["title"] }
      expect(titles).to include("Eloquent Ruby")
      expect(titles).not_to include("The Hobbit")
    end
  end

  describe "POST /books" do
    let(:book_params) do
      {
        book: {
          title: "New Book",
          author: "Author Name",
          genre: "Genre",
          isbn: "9781234567890",
          total_copies: 3
        }
      }
    end

    it "allows librarians to create books" do
      expect do
        post "/books", params: book_params, headers: auth_headers(librarian), as: :json
      end.to change(Book, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "forbids members from creating books" do
      post "/books", params: book_params, headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /books/:id" do
    let!(:book) { create(:book, title: "Original Title") }

    it "updates a book for librarians" do
      patch "/books/#{book.id}", params: { book: { title: "Updated Title" } }, headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:ok)
      expect(book.reload.title).to eq("Updated Title")
    end

    it "forbids members from updating books" do
      patch "/books/#{book.id}", params: { book: { title: "Updated Title" } }, headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /books/:id" do
    let!(:book) { create(:book) }

    it "allows librarians to delete books" do
      expect do
        delete "/books/#{book.id}", headers: auth_headers(librarian), as: :json
      end.to change(Book, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "forbids members from deleting books" do
      delete "/books/#{book.id}", headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "prevents deleting book with active borrowings" do
      borrowing = create(:borrowing, book:)
      expect(borrowing.returned_at).to be_nil

      delete "/books/#{book.id}", headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Cannot delete book with active borrowings")
      expect(Book.exists?(book.id)).to be true
    end
  end

  describe "POST /books validations" do
    it "prevents creating book with duplicate title and author" do
      existing_book = create(:book, title: "The Book", author: "John Doe", isbn: "9781111111111")

      book_params = {
        book: {
          title: "The Book",
          author: "John Doe",
          genre: "Fiction",
          isbn: "9782222222222",
          total_copies: 1
        }
      }

      post "/books", params: book_params, headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Title and author combination already exists")
    end

    it "prevents creating book with duplicate ISBN" do
      existing_book = create(:book, isbn: "9781234567890")

      book_params = {
        book: {
          title: "Different Title",
          author: "Different Author",
          genre: "Fiction",
          isbn: "9781234567890",
          total_copies: 1
        }
      }

      post "/books", params: book_params, headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Isbn has already been taken")
    end
  end
end

