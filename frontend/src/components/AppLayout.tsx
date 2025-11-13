import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";

export function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="app-layout">
      <header className="app-header">
        <div>
          <h1>Librarian</h1>
          {user && (
            <p className="user-meta">
              Signed in as <strong>{user.name}</strong> ({user.role})
            </p>
          )}
        </div>
        <nav>
          <NavLink to="/dashboard">Dashboard</NavLink>
          <NavLink to="/books">Books</NavLink>
          <NavLink to="/borrowings">Borrowings</NavLink>
          <button type="button" onClick={handleLogout} className="logout-btn">
            Logout
          </button>
        </nav>
      </header>
      <main className="app-content">
        <Outlet />
      </main>
    </div>
  );
}

