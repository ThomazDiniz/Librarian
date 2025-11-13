## Librarian – Presentation Outline

### 1. Opening (1 minute)
- Brief intro, reiterate informal user story:
  - Libby (librarian) needs to manage catalogue & overdue tracking efficiently.
  - Milo (member) wants easy sign-up, browsing, borrowing, reminders.
- State tech stack: Rails 7 API + PostgreSQL + JWT auth, React/Vite/TypeScript SPA, Docker Compose for local orchestration.

### 2. Architecture Overview (2 minutes)
- **Backend**
  - API-only Rails app, organized with PORO service (`JwtService`), controllers focused on HTTP layer, models encapsulate domain rules.
  - Authentication flow: `/login` and `/signup` issuing JWT, `ApplicationController` handles auth/authorization.
  - Role-based authorization via `require_librarian!`.
  - Entities: `User`, `Book`, `Borrowing` with validations and scopes (`active`, `overdue`, `search`).
- **Frontend**
  - React with context-based auth store, react-router protected routes.
  - Axios API client that injects JWT from localStorage.
  - Pages split by domain responsibility: Dashboard, Books, Borrowings, Auth screens.
- **Infrastructure**
  - `docker-compose.yml` spins up Postgres, Rails API, Vite dev server.
  - Seed data for demo accounts and catalogue; tests run via Docker as well.

### 3. Demo Flow (5–6 minutes)
1. **Authentication**
   - Show signup as new member, then logout & login as seeded librarian.
2. **Librarian Dashboard**
   - Highlight metrics (total books, borrowed, due today, overdue members).
3. **Book Management**
   - Create/edit/delete book as librarian.
   - Demonstrate search/filtering.
4. **Borrowing Lifecycle**
   - Switch to member account.
   - Borrow a book, observe availability change on Books page.
   - View member dashboard (borrowed + overdue lists).
5. **Borrowing Return**
   - Login as librarian, mark borrowing as returned, show status updates.
6. (Optional) point out REST endpoints via browser devtools / curl if asked.

### 4. Testing & Quality (2 minutes)
- Backend: 39 passing RSpec examples (models + request specs).
  - Mention change to use `:unprocessable_content` to align with Rack 3.
- Frontend: TypeScript strict build (`npm run build`) used to catch type issues.
- Manual verification via browser, zero console warnings targeted.

### 5. Clean Architecture Considerations (2 minutes)
- Separation of concerns: controllers thin, models encapsulate rules, service for JWT.
- CORS + auth middleware centralized.
- Frontend uses hooks/context to isolate state management from views.
- Docker for environment parity; `.env` example for frontend configuration.

### 6. Potential Enhancements (1 minute)
- Pagination & sorting on listings.
- Toast notifications / better error surfacing in UI.
- Tests for frontend (React Testing Library) if time allowed.
- Background jobs for overdue reminders, audit trail.

### 7. Code Review Readiness
- Be prepared to explain:
  - Why validations live in models (single source of truth).
  - How scopes power dashboard queries (`Borrowing.due_on`, `.overdue`).
  - Reasoning for JWT service abstraction & auth context on frontend.
  - Docker choices (volume mounting for live reload).

### 8. Wrap-up
- Reiterate project goals achieved.
- Invite questions on design trade-offs, testing approach, AI-assisted productivity (describe prompt strategy, verification steps).

