require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires a unique email (case insensitive)" do
      create(:user, email: "Test@Example.com")
      user = build(:user, email: "test@example.com")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires a password" do
      user = build(:user, password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "downcases email before saving" do
      user = create(:user, email: "USER@Example.COM")
      expect(user.reload.email).to eq("user@example.com")
    end
  end

  describe "associations" do
    it "has many borrowings" do
      user = create(:user)
      create_list(:borrowing, 2, user:)
      expect(user.borrowings.count).to eq(2)
    end
  end

  describe "#overdue_borrowings" do
    it "returns borrowings that are overdue" do
      user = create(:user)
      on_time = create(:borrowing, user:)
      overdue = create(:borrowing, :overdue, user:)

      expect(user.overdue_borrowings).to contain_exactly(overdue)
      expect(user.overdue_borrowings).not_to include(on_time)
    end
  end
end
