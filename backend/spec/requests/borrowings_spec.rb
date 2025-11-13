require "rails_helper"

RSpec.describe "Borrowings API", type: :request do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user) }
  let(:book) { create(:book, total_copies: 2) }

  describe "GET /borrowings" do
    it "returns member's borrowings" do
      own_borrowing = create(:borrowing, user: member)
      create(:borrowing, user: create(:user)) # other borrowing

      get "/borrowings", headers: auth_headers(member)

      expect(response).to have_http_status(:ok)
      expect(parsed_response.length).to eq(1)
      expect(parsed_response.first["id"]).to eq(own_borrowing.id)
    end

    it "returns all borrowings for librarians" do
      borrowings = create_list(:borrowing, 3)

      get "/borrowings", headers: auth_headers(librarian)

      expect(response).to have_http_status(:ok)
      returned_ids = parsed_response.map { |borrowing| borrowing["id"] }
      expect(returned_ids).to include(*borrowings.map(&:id))
    end
  end

  describe "POST /borrowings" do
    it "allows members to borrow an available book" do
      expect do
        post "/borrowings", params: { borrowing: { book_id: book.id } }, headers: auth_headers(member), as: :json
      end.to change(Borrowing, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(parsed_response["book"]["id"]).to eq(book.id)
    end

    it "prevents borrowing when no copies are available" do
      unavailable_book = create(:book, total_copies: 1)
      create(:borrowing, book: unavailable_book)

      post "/borrowings", params: { borrowing: { book_id: unavailable_book.id } }, headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Book has no available copies to borrow")
    end

    it "forbids librarians from borrowing books" do
      post "/borrowings", params: { borrowing: { book_id: book.id } }, headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "prevents member from borrowing the same book multiple times" do
      create(:borrowing, user: member, book:)

      post "/borrowings", params: { borrowing: { book_id: book.id } }, headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("already borrowed this book")
    end

    it "tracks borrowing date and sets due date to 2 weeks from borrowing" do
      travel_to Time.zone.local(2025, 1, 15, 10, 0, 0) do
        post "/borrowings", params: { borrowing: { book_id: book.id } }, headers: auth_headers(member), as: :json

        expect(response).to have_http_status(:created)
        borrowing = Borrowing.find(parsed_response["id"])

        expect(borrowing.borrowed_at).to be_within(1.second).of(Time.zone.local(2025, 1, 15, 10, 0, 0))
        expect(borrowing.due_at).to be_within(1.second).of(Time.zone.local(2025, 1, 29, 10, 0, 0))
        expect(borrowing.due_at - borrowing.borrowed_at).to be_within(1.second).of(14.days)
      end
    end
  end

  describe "PATCH /borrowings/:id/return" do
    let!(:borrowing) { create(:borrowing, book:, user: member) }

    it "allows librarian to mark borrowing as returned" do
      patch "/borrowings/#{borrowing.id}/return", headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:ok)
      expect(borrowing.reload.returned_at).not_to be_nil
    end

    it "prevents marking as returned twice" do
      patch "/borrowings/#{borrowing.id}/return", headers: auth_headers(librarian), as: :json
      patch "/borrowings/#{borrowing.id}/return", headers: auth_headers(librarian), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Borrowing already marked as returned")
    end
  end
end

