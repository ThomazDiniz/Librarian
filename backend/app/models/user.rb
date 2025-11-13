class User < ApplicationRecord
  has_secure_password

  enum role: { member: 0, librarian: 1 }

  has_many :borrowings, dependent: :destroy
  has_many :borrowed_books, through: :borrowings, source: :book

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  def overdue_borrowings
    borrowings.overdue
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
