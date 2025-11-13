class BooksController < ApplicationController
  before_action :require_librarian!, only: %i[create update destroy]
  before_action :set_book, only: %i[show update destroy]

  def index
    books = Book.all
    books = books.search(params[:q]) if params[:q].present?
    books = books.by_title(params[:title]) if params[:title].present?
    books = books.by_author(params[:author]) if params[:author].present?
    books = books.by_genre(params[:genre]) if params[:genre].present?

    render json: books.map { |book| book_response(book) }, status: :ok
  end

  def show
    render json: book_response(@book), status: :ok
  end

  def create
    book = Book.new(book_params)

    if book.save
      render json: book_response(book), status: :created
    else
      render json: { errors: book.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @book.update(book_params)
      render json: book_response(@book), status: :ok
    else
      render json: { errors: @book.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @book.borrowings.active.exists?
      render json: { errors: ["Cannot delete book with active borrowings"] }, status: :unprocessable_content
      return
    end

    @book.destroy
    head :no_content
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :genre, :isbn, :total_copies, :description)
  end

  def book_response(book)
    book.as_json(only: %i[id title author genre isbn total_copies description updated_at created_at]).merge(
      available_copies: book.available_copies
    )
  end
end

