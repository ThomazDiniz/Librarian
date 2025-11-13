import { useEffect, useState } from "react";
import client from "../api/client";
import { useAuth } from "../contexts/AuthContext";

interface Borrowing {
  id: number;
  borrowed_at: string;
  due_at: string;
  returned_at: string | null;
  user: {
    id: number;
    name: string;
    email: string;
    role: "member" | "librarian";
  };
  book: {
    id: number;
    title: string;
    author: string;
    genre: string;
    isbn: string;
  };
}

export function BorrowingsPage() {
  const { user } = useAuth();
  const isLibrarian = user?.role === "librarian";
  const [borrowings, setBorrowings] = useState<Borrowing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadBorrowings = async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await client.get<Borrowing[]>("/borrowings");
      setBorrowings(response.data);
    } catch (err) {
      console.error(err);
      setError("Unable to load borrowings.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBorrowings();
  }, []);

  const handleReturn = async (borrowingId: number) => {
    if (!isLibrarian) return;

    try {
      await client.patch(`/borrowings/${borrowingId}/return`);
      setMessage("Borrowing marked as returned.");
      await loadBorrowings();
    } catch (err) {
      console.error(err);
      setError("Unable to mark as returned.");
    }
  };

  return (
    <section>
      <header className="page-header">
        <h2>Borrowings</h2>
        <p>Track borrowed books and due dates.</p>
      </header>

      {message && <p className="success-text">{message}</p>}
      {error && <p className="error-text">{error}</p>}

      {loading ? (
        <p>Loading borrowings...</p>
      ) : borrowings.length === 0 ? (
        <p>No borrowings found.</p>
      ) : (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Book</th>
                <th>Borrower</th>
                <th>Borrowed</th>
                <th>Due</th>
                <th>Status</th>
                {isLibrarian && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {borrowings.map((borrowing) => {
                const isReturned = Boolean(borrowing.returned_at);
                const isOverdue =
                  !isReturned && new Date(borrowing.due_at).getTime() < Date.now();

                return (
                  <tr key={borrowing.id}>
                    <td>
                      <strong>{borrowing.book.title}</strong>
                      <br />
                      <span className="muted">{borrowing.book.author}</span>
                    </td>
                    <td>
                      {borrowing.user.name}
                      <br />
                      <span className="muted">{borrowing.user.email}</span>
                    </td>
                    <td>{new Date(borrowing.borrowed_at).toLocaleDateString()}</td>
                    <td>{new Date(borrowing.due_at).toLocaleDateString()}</td>
                    <td>
                      {isReturned ? (
                        <span className="badge success">Returned</span>
                      ) : isOverdue ? (
                        <span className="badge danger">Overdue</span>
                      ) : (
                        <span className="badge info">Borrowed</span>
                      )}
                    </td>
                    {isLibrarian && (
                      <td>
                        <button
                          type="button"
                          className="secondary"
                          onClick={() => handleReturn(borrowing.id)}
                          disabled={isReturned}
                        >
                          Mark returned
                        </button>
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

