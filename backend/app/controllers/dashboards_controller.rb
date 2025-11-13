class DashboardsController < ApplicationController
  def show
    if current_user.librarian?
      render json: librarian_dashboard, status: :ok
    else
      render json: member_dashboard, status: :ok
    end
  end

  private

  def librarian_dashboard
    overdue_members = User.member
                          .joins(:borrowings)
                          .merge(Borrowing.overdue)
                          .distinct

    {
      total_books: Book.count,
      total_borrowed_books: Borrowing.active.count,
      books_due_today: Borrowing.due_on(Date.current).count,
      overdue_members: overdue_members.map do |member|
        {
          id: member.id,
          name: member.name,
          email: member.email,
          overdue_books: member.borrowings.overdue.count
        }
      end
    }
  end

  def member_dashboard
    borrowings = current_user.borrowings.includes(:book)
    {
      borrowed_books: borrowings.map { |borrowing| borrowing_response(borrowing) },
      overdue_books: borrowings.overdue.map { |borrowing| borrowing_response(borrowing) }
    }
  end

  def borrowing_response(borrowing)
    borrowing.as_json(only: %i[id borrowed_at due_at returned_at]).merge(
      book: borrowing.book.slice(:id, :title, :author, :genre, :isbn)
    )
  end
end

