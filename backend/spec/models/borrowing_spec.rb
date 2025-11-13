require 'rails_helper'

RSpec.describe Borrowing, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:borrowing)).to be_valid
    end

    it "requires due date after borrowed date" do
      borrowing = build(:borrowing, borrowed_at: Time.current, due_at: 1.day.ago)

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:due_at]).to include("must be after the borrowed date")
    end

    it "requires book availability" do
      book = create(:book, total_copies: 1)
      create(:borrowing, book:, user: create(:user))

      borrowing = build(:borrowing, book:, user: create(:user))

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:book]).to include("has no available copies to borrow")
    end

    it "prevents members from borrowing the same book twice concurrently" do
      user = create(:user)
      book = create(:book)
      create(:borrowing, user:, book:)

      borrowing = build(:borrowing, user:, book:)

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:base]).to include("already borrowed this book")
    end
  end

  describe ".active" do
    it "returns borrowings without a returned_at date" do
      active = create(:borrowing)
      returned = create(:borrowing, :returned)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(returned)
    end
  end

  describe ".overdue" do
    it "returns borrowings past due without return" do
      overdue = create(:borrowing, :overdue)
      on_time = create(:borrowing)

      expect(described_class.overdue).to include(overdue)
      expect(described_class.overdue).not_to include(on_time)
    end
  end

  describe "#mark_returned!" do
    it "updates returned_at timestamp" do
      borrowing = create(:borrowing)
      travel_to Time.zone.local(2025, 1, 1, 12, 0, 0) do
        borrowing.mark_returned!
      end

      expect(borrowing.returned_at).not_to be_nil
      expect(borrowing.returned_at).to be_within(1.second).of(Time.zone.local(2025, 1, 1, 12, 0, 0))
    end
  end
end
