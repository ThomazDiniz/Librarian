class BorrowingsController < ApplicationController
  before_action :set_borrowing, only: %i[show return_book]
  before_action :require_librarian!, only: :return_book

  def index
    borrowings = if current_user.librarian?
                   Borrowing.includes(:book, :user).order(borrowed_at: :desc)
                 else
                   current_user.borrowings.includes(:book).order(borrowed_at: :desc)
                 end

    render json: borrowings.map { |borrowing| borrowing_response(borrowing) }, status: :ok
  end

  def show
    authorize_member_access!
    return if performed?

    render json: borrowing_response(@borrowing), status: :ok
  end

  def create
    return render json: { errors: ["Only members can borrow books"] }, status: :forbidden unless current_user.member?

    book = Book.find(borrowing_params[:book_id])
    borrowing = current_user.borrowings.new(
      book:,
      borrowed_at: Time.current,
      due_at: 2.weeks.from_now
    )

    if borrowing.save
      render json: borrowing_response(borrowing), status: :created
    else
      render json: { errors: borrowing.errors.full_messages }, status: :unprocessable_content
    end
  end

  def return_book
    if @borrowing.returned_at.present?
      render json: { errors: ["Borrowing already marked as returned"] }, status: :unprocessable_content
    else
      @borrowing.mark_returned!
      render json: borrowing_response(@borrowing), status: :ok
    end
  end

  private

  def set_borrowing
    @borrowing = Borrowing.find(params[:id])
  end

  def borrowing_params
    params.require(:borrowing).permit(:book_id)
  end

  def borrowing_response(borrowing)
    borrowing.as_json(only: %i[id borrowed_at due_at returned_at created_at updated_at]).merge(
      user: borrowing.user.slice(:id, :name, :email, :role),
      book: borrowing.book.slice(:id, :title, :author, :genre, :isbn)
    )
  end

  def authorize_member_access!
    return if current_user.librarian?
    return if current_user.member? && @borrowing.user_id == current_user.id

    render json: { errors: ["Forbidden"] }, status: :forbidden
  end
end

