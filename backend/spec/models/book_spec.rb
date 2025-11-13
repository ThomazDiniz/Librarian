require 'rails_helper'

RSpec.describe Book, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:book)).to be_valid
    end

    it "requires unique ISBN" do
      create(:book, isbn: "12345")
      book = build(:book, isbn: "12345")

      expect(book).not_to be_valid
      expect(book.errors[:isbn]).to include("has already been taken")
    end

    it "requires unique title and author combination" do
      create(:book, title: "The Book", author: "John Doe", isbn: "9781111111111")
      book = build(:book, title: "The Book", author: "John Doe", isbn: "9782222222222")

      expect(book).not_to be_valid
      expect(book.errors[:title]).to include("and author combination already exists")
    end

    it "allows same title with different author" do
      create(:book, title: "The Book", author: "John Doe", isbn: "9781111111111")
      book = build(:book, title: "The Book", author: "Jane Smith", isbn: "9782222222222")

      expect(book).to be_valid
    end

    it "does not allow negative total copies" do
      book = build(:book, total_copies: -1)

      expect(book).not_to be_valid
      expect(book.errors[:total_copies]).to include("must be greater than or equal to 0")
    end
  end

  describe "#available_copies" do
    it "returns total copies minus active borrowings" do
      book = create(:book, total_copies: 3)
      create(:borrowing, book:)
      create(:borrowing, :overdue, book:)

      expect(book.available_copies).to eq(1)
    end
  end

  describe ".search" do
    it "filters books by query across title, author, and genre" do
      matching = create(:book, title: "Ruby 101", author: "Jane Doe", genre: "Programming")
      non_matching = create(:book, title: "Cooking Basics", author: "Chef Anne", genre: "Cooking")

      results = described_class.search("ruby")

      expect(results).to include(matching)
      expect(results).not_to include(non_matching)
    end
  end
end
