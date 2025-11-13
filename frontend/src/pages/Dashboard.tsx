import { useEffect, useState } from "react";
import client from "../api/client";
import { useAuth } from "../contexts/AuthContext";

interface LibrarianDashboardData {
  total_books: number;
  total_borrowed_books: number;
  books_due_today: number;
  overdue_members: Array<{
    id: number;
    name: string;
    email: string;
    overdue_books: number;
  }>;
}

interface BorrowedBook {
  id: number;
  borrowed_at: string;
  due_at: string;
  returned_at: string | null;
  book: {
    id: number;
    title: string;
    author: string;
    genre: string;
    isbn: string;
  };
}

interface MemberDashboardData {
  borrowed_books: BorrowedBook[];
  overdue_books: BorrowedBook[];
}

export function DashboardPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [librarianData, setLibrarianData] = useState<LibrarianDashboardData | null>(null);
  const [memberData, setMemberData] = useState<MemberDashboardData | null>(null);

  useEffect(() => {
    const fetchDashboard = async () => {
      if (!user) return;

      setLoading(true);
      setError(null);

      try {
        const response = await client.get<LibrarianDashboardData | MemberDashboardData>("/dashboard");

        if (user.role === "librarian") {
          setLibrarianData(response.data as LibrarianDashboardData);
        } else {
          setMemberData(response.data as MemberDashboardData);
        }
      } catch (err) {
        console.error(err);
        setError("Failed to load dashboard data.");
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, [user]);

  if (loading) {
    return <p>Loading dashboard...</p>;
  }

  if (error) {
    return <p className="error-text">{error}</p>;
  }

  if (!user) {
    return null;
  }

  if (user.role === "librarian" && librarianData) {
    return (
      <section className="dashboard">
        <h2>Librarian overview</h2>
        <div className="dashboard-cards">
          <div className="stat-card">
            <h3>Total books</h3>
            <p>{librarianData.total_books}</p>
          </div>
          <div className="stat-card">
            <h3>Borrowed books</h3>
            <p>{librarianData.total_borrowed_books}</p>
          </div>
          <div className="stat-card">
            <h3>Books due today</h3>
            <p>{librarianData.books_due_today}</p>
          </div>
        </div>

        <section className="panel">
          <h3>Members with overdue books</h3>
          {librarianData.overdue_members.length === 0 ? (
            <p>No overdue members 🎉</p>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Overdue books</th>
                </tr>
              </thead>
              <tbody>
                {librarianData.overdue_members.map((member) => (
                  <tr key={member.id}>
                    <td>{member.name}</td>
                    <td>{member.email}</td>
                    <td>{member.overdue_books}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      </section>
    );
  }

  if (memberData) {
    return (
      <section className="dashboard">
        <h2>Your borrowed books</h2>
        <section className="panel">
          {memberData.borrowed_books.length === 0 ? (
            <p>You have not borrowed any books yet.</p>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Author</th>
                  <th>Borrowed at</th>
                  <th>Due at</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {memberData.borrowed_books.map((borrowing) => (
                  <tr key={borrowing.id}>
                    <td>{borrowing.book.title}</td>
                    <td>{borrowing.book.author}</td>
                    <td>{new Date(borrowing.borrowed_at).toLocaleDateString()}</td>
                    <td>{new Date(borrowing.due_at).toLocaleDateString()}</td>
                    <td>{borrowing.returned_at ? "Returned" : "Borrowed"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>

        <section className="panel">
          <h3>Overdue books</h3>
          {memberData.overdue_books.length === 0 ? (
            <p>You have no overdue books. Keep it up!</p>
          ) : (
            <ul className="list">
              {memberData.overdue_books.map((borrowing) => (
                <li key={borrowing.id}>
                  <strong>{borrowing.book.title}</strong> — overdue since{" "}
                  {new Date(borrowing.due_at).toLocaleDateString()}
                </li>
              ))}
            </ul>
          )}
        </section>
      </section>
    );
  }

  return null;
}

