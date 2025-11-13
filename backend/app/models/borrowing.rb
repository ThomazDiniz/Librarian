class Borrowing < ApplicationRecord
  belongs_to :user
  belongs_to :book

  scope :active, -> { where(returned_at: nil) }
  scope :overdue, -> { active.where("due_at < ?", Time.current) }
  scope :due_on, ->(date) { active.where(due_at: date.beginning_of_day..date.end_of_day) }

  validates :borrowed_at, :due_at, presence: true
  validate :due_after_borrowed
  validate :book_must_have_available_copies, on: :create
  validate :unique_active_borrowing_for_user, on: :create

  def mark_returned!
    update!(returned_at: Time.current)
  end

  private

  def due_after_borrowed
    return if borrowed_at.blank? || due_at.blank?

    errors.add(:due_at, "must be after the borrowed date") if due_at <= borrowed_at
  end

  def book_must_have_available_copies
    return if book.blank?
    return if book.available?

    errors.add(:book, "has no available copies to borrow")
  end

  def unique_active_borrowing_for_user
    return if user.blank? || book.blank?

    if user.borrowings.active.where(book_id:).exists?
      errors.add(:base, "already borrowed this book")
    end
  end
end
