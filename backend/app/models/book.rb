class Book < ApplicationRecord
  has_many :borrowings, dependent: :destroy
  has_many :borrowers, through: :borrowings, source: :user

  validates :title, :author, :genre, :isbn, presence: true
  validates :isbn, uniqueness: true
  validates :total_copies, numericality: { greater_than_or_equal_to: 0 }
  validates :title, uniqueness: { scope: :author, message: "and author combination already exists" }

  scope :search, lambda { |query|
    return all if query.blank?

    pattern = "%#{query.downcase}%"
    where("LOWER(title) LIKE :pattern OR LOWER(author) LIKE :pattern OR LOWER(genre) LIKE :pattern", pattern:)
  }

  scope :by_title, ->(title) { where("LOWER(title) LIKE ?", "%#{title.downcase}%") if title.present? }
  scope :by_author, ->(author) { where("LOWER(author) LIKE ?", "%#{author.downcase}%") if author.present? }
  scope :by_genre, ->(genre) { where("LOWER(genre) LIKE ?", "%#{genre.downcase}%") if genre.present? }

  def available_copies
    total_copies - borrowings.active.count
  end

  def available?
    available_copies.positive?
  end
end
