require "rails_helper"

RSpec.describe "Dashboard API", type: :request do
  describe "GET /dashboard for librarian" do
    it "returns library metrics" do
      librarian = create(:user, :librarian)
      member = create(:user)
      book1 = create(:book)
      book2 = create(:book)
      create(:borrowing, user: member, book: book1)
      create(:borrowing, :overdue, user: member, book: book2)

      get "/dashboard", headers: auth_headers(librarian)

      expect(response).to have_http_status(:ok)
      body = parsed_response
      expect(body["total_books"]).to eq(Book.count)
      expect(body["total_borrowed_books"]).to eq(Borrowing.active.count)
      emails = body["overdue_members"].map { |entry| entry["email"] }
      expect(emails).to include(member.email)
    end
  end

  describe "GET /dashboard for member" do
    it "returns borrowed and overdue books" do
      member = create(:user)
      borrowed = create(:borrowing, user: member)
      overdue = create(:borrowing, :overdue, user: member)

      get "/dashboard", headers: auth_headers(member)

      expect(response).to have_http_status(:ok)
      body = parsed_response
      expect(body["borrowed_books"].map { |b| b["id"] }).to include(borrowed.id, overdue.id)
      expect(body["overdue_books"].map { |b| b["id"] }).to include(overdue.id)
    end
  end
end

