import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import client from "../api/client";
import { useAuth } from "../contexts/AuthContext";

interface Book {
  id: number;
  title: string;
  author: string;
  genre: string;
  isbn: string;
  total_copies: number;
  description: string | null;
  available_copies: number;
}

const emptyForm: Omit<Book, "id" | "available_copies"> = {
  title: "",
  author: "",
  genre: "",
  isbn: "",
  total_copies: 1,
  description: "",
};

export function BooksPage() {
  const { user } = useAuth();
  const isLibrarian = user?.role === "librarian";
  const isMember = user?.role === "member";

  const [books, setBooks] = useState<Book[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [search, setSearch] = useState({ q: "", genre: "" });
  const [formData, setFormData] = useState(emptyForm);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const hasSearchFilters = useMemo(
    () => Boolean(search.q.trim() || search.genre.trim()),
    [search],
  );

  const fetchBooks = async (params?: Record<string, string>) => {
    setLoading(true);
    setError(null);

    try {
      const response = await client.get<Book[]>("/books", { params });
      setBooks(response.data);
    } catch (err) {
      console.error(err);
      setError("Unable to load books. Please try again later.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBooks();
  }, []);

  const resetForm = () => {
    setFormData(emptyForm);
    setEditingId(null);
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!isLibrarian) return;

    setSubmitting(true);
    setMessage(null);
    setError(null);

    try {
      if (editingId) {
        await client.patch(`/books/${editingId}`, { book: formData });
        setMessage("Book updated");
      } else {
        await client.post("/books", { book: formData });
        setMessage("Book created");
      }

      await fetchBooks(hasSearchFilters ? search : undefined);
      resetForm();
    } catch (err: any) {
      console.error(err);
      if (err.response?.data?.errors) {
        setError(err.response.data.errors.join(", "));
      } else {
        setError("Unable to save book. Check the details and try again.");
      }
    } finally {
      setSubmitting(false);
    }
  };

  const startEditing = (book: Book) => {
    setEditingId(book.id);
    setFormData({
      title: book.title,
      author: book.author,
      genre: book.genre,
      isbn: book.isbn,
      total_copies: book.total_copies,
      description: book.description ?? "",
    });
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleDelete = async (id: number) => {
    if (!isLibrarian) return;
    const confirmation = window.confirm("Are you sure you want to delete this book?");
    if (!confirmation) return;

    try {
      await client.delete(`/books/${id}`);
      setMessage("Book removed");
      await fetchBooks(hasSearchFilters ? search : undefined);
    } catch (err: any) {
      console.error(err);
      if (err.response?.data?.errors) {
        setError(err.response.data.errors.join(", "));
      } else {
        setError("Unable to delete book.");
      }
    }
  };

  const handleBorrow = async (bookId: number) => {
    if (!isMember) return;

    try {
      await client.post("/borrowings", { borrowing: { book_id: bookId } });
      setMessage("Book borrowed successfully!");
      await fetchBooks(hasSearchFilters ? search : undefined);
    } catch (err) {
      console.error(err);
      setError("Unable to borrow this book. It might be unavailable.");
    }
  };

  const handleReturnSearch = async (event: FormEvent) => {
    event.preventDefault();
    await fetchBooks(search);
  };

  return (
    <section className="books-page">
      <header className="page-header">
        <h2>Library catalog</h2>
        <p>Search the collection and manage availability.</p>
      </header>

      <form className="search-form" onSubmit={handleReturnSearch}>
        <input
          type="search"
          placeholder="Search by title, author, or genre"
          value={search.q}
          onChange={(event) => setSearch((prev) => ({ ...prev, q: event.target.value }))}
        />
        <input
          type="text"
          placeholder="Filter by genre"
          value={search.genre}
          onChange={(event) => setSearch((prev) => ({ ...prev, genre: event.target.value }))}
        />
        <button type="submit">Apply filters</button>
        <button
          type="button"
          onClick={() => {
            setSearch({ q: "", genre: "" });
            fetchBooks();
          }}
          className="secondary"
        >
          Clear
        </button>
      </form>

      {isLibrarian && (
        <form className="book-form" onSubmit={handleSubmit}>
          <h3>{editingId ? "Edit book" : "Add a new book"}</h3>
          <div className="form-grid">
            <label>
              Title
              <input
                type="text"
                value={formData.title}
                onChange={(event) => setFormData((prev) => ({ ...prev, title: event.target.value }))}
                required
              />
            </label>
            <label>
              Author
              <input
                type="text"
                value={formData.author}
                onChange={(event) => setFormData((prev) => ({ ...prev, author: event.target.value }))}
                required
              />
            </label>
            <label>
              Genre
              <input
                type="text"
                value={formData.genre}
                onChange={(event) => setFormData((prev) => ({ ...prev, genre: event.target.value }))}
                required
              />
            </label>
            <label>
              ISBN
              <input
                type="text"
                value={formData.isbn}
                onChange={(event) => setFormData((prev) => ({ ...prev, isbn: event.target.value }))}
                required
              />
            </label>
            <label>
              Total copies
              <input
                type="number"
                min={0}
                value={formData.total_copies}
                onChange={(event) =>
                  setFormData((prev) => ({ ...prev, total_copies: Number(event.target.value) }))
                }
                required
              />
            </label>
            <label className="full-width">
              Description
              <textarea
                value={formData.description ?? ""}
                onChange={(event) =>
                  setFormData((prev) => ({ ...prev, description: event.target.value }))
                }
                rows={3}
              />
            </label>
          </div>
          <div className="form-actions">
            <button type="submit" disabled={submitting}>
              {submitting ? "Saving..." : editingId ? "Update book" : "Add book"}
            </button>
            {editingId && (
              <button type="button" className="secondary" onClick={resetForm}>
                Cancel
              </button>
            )}
          </div>
        </form>
      )}

      {message && <p className="success-text">{message}</p>}
      {error && <p className="error-text">{error}</p>}

      {loading ? (
        <p>Loading books...</p>
      ) : books.length === 0 ? (
        <p>No books found.</p>
      ) : (
        <div className="book-grid">
          {books.map((book) => (
            <article key={book.id} className="book-card">
              <div className="book-card-header">
                <h3>{book.title}</h3>
                <span className={`badge ${book.available_copies > 0 ? "success" : "warning"}`}>
                  {book.available_copies} / {book.total_copies} available
                </span>
              </div>
              <p className="book-meta">
                {book.author} • {book.genre}
              </p>
              <p className="book-isbn">ISBN: {book.isbn}</p>
              {book.description && <p className="book-description">{book.description}</p>}

              <div className="book-actions">
                {isMember && (
                  <button
                    type="button"
                    disabled={book.available_copies === 0}
                    onClick={() => handleBorrow(book.id)}
                  >
                    Borrow
                  </button>
                )}

                {isLibrarian && (
                  <>
                    <button type="button" onClick={() => startEditing(book)}>
                      Edit
                    </button>
                    <button type="button" className="danger" onClick={() => handleDelete(book.id)}>
                      Delete
                    </button>
                  </>
                )}
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}

