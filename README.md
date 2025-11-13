## Librarian

Full-stack library management system composed of a Ruby on Rails API backend and a React + TypeScript frontend. The solution was built as the response to a technical exercise focusing on authentication, role-based authorization, catalog management, borrowing workflows, dashboards, automated testing, and containerised delivery.

### Informal User Story

> As Libby the librarian, I want a single place to register members, keep the catalogue up-to-date, and monitor outstanding borrowings so that our community library runs smoothly. Milo the member wants to sign up, browse books, borrow available copies, and track upcoming due dates without needing to call the front desk.

### Architecture Overview

- **Backend**: Rails 7.1 API-only app with JWT authentication, role-based gates, Postgres persistence, RSpec test suite, and seed data.
- **Frontend**: React 18 (Vite + TypeScript) SPA featuring responsive layout, auth-aware routing, CRUD forms for librarians, borrowing flows for members, and dashboards for both roles.
- **Containerisation**: Docker Compose orchestrates Postgres, the Ruby service, and the Vite dev server for a frictionless setup on Windows (or any Docker-capable host).

---

## Getting Started

### Prerequisites

- Docker Desktop (with Compose v2) **or**
- Ruby 3.2+, Node 20+, and PostgreSQL 15+ installed locally

### Quick Start with Docker (recommended)

```bash
# Build images and start Postgres, Rails API, and React frontend
docker compose up --build
```

- Backend API: http://localhost:3000  
- Frontend SPA: http://localhost:5173  

To stop services:

```bash
docker compose down
```

### Manual Setup (if you prefer running without Docker)

1. **Backend**
   ```bash
   cd backend
   bundle install
   # configure config/database.yml if needed
   bin/rails db:create db:migrate db:seed
   bin/rails server
   ```

2. **Frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

---

## Seeded Demo Accounts

After running `db:seed`, the following users are available:

- Librarian: `librarian@example.com` / `password123`
- Member: `member@example.com` / `password123`

Members can also sign up directly through the UI. Librarian accounts should be created via seeds or the Rails console.

---

## Backend Highlights

- JWT-based authentication with `Authorization: Bearer <token>` headers
- Role enforcement (`librarian`, `member`) for sensitive endpoints
- Book CRUD with search filters (title, author, genre)
- Borrowing lifecycle enforcing availability rules and 2-week due dates
- Dashboards tailored for librarians (metrics, overdue members) and members (borrowed + overdue books)
- REST API with consistent JSON responses and error handling

### Key Endpoints

| Verb | Path | Description | Auth |
|------|------|-------------|------|
| POST | `/signup` | Member registration | Public |
| POST | `/login` | Obtain JWT token | Public |
| DELETE | `/logout` | Client-side logout (placeholder) | Authenticated |
| GET | `/books` | List/search books | Authenticated |
| POST | `/books` | Create book | Librarian |
| PATCH | `/books/:id` | Update book | Librarian |
| DELETE | `/books/:id` | Remove book | Librarian |
| GET | `/borrowings` | List borrowings (scope by role) | Authenticated |
| POST | `/borrowings` | Borrow a book | Member |
| PATCH | `/borrowings/:id/return` | Mark as returned | Librarian |
| GET | `/dashboard` | Role-specific dashboard data | Authenticated |

> Detailed request/response samples can be inspected via the frontend or API tools (e.g. Postman).

### Running Tests

```bash
# Ensure Postgres is available (docker compose up -d postgres)
docker compose run --rm backend bash -lc "bundle install >/dev/null && bundle exec rspec"
```

---

## Frontend Highlights

- Responsive layout with role-aware navigation and protected routes
- Auth context stores user session (JWT + profile) in `localStorage`
- Catalog page with search filters, librarian management forms, and borrowing buttons
- Dedicated borrowings view (librarians can mark returns in-place)
- Dashboards summarise KPIs for librarians and due dates for members
- Type-safe codebase (strict TypeScript) and production build validation (`npm run build`)

### Frontend Development Scripts

```bash
cd frontend
npm install
npm run dev      # start Vite dev server on http://localhost:5173
npm run build    # compile production build (also used in CI)
```

> Configure the backend URL by copying `.env.example` to `.env` and setting `VITE_API_URL`.

---

## Additional Notes

- `docker-compose.yml` mounts volumes for hot reload (backend and frontend) and persists bundle/node_modules.
- Host authorization is relaxed in development/test to support Docker networking and Vite dev hosts.
- RSpec factories and request specs cover authentication, authorization, book lifecycle, borrowings, and dashboards.
- The React build uses shared CSS (`App.css`) for a clean yet lightweight design without external UI libraries.

---


