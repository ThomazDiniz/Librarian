# Librarian

Full-stack library management system composed of a Ruby on Rails API backend and a React + TypeScript frontend. The solution was built as the response to a technical exercise focusing on authentication, role-based authorization, catalog management, borrowing workflows, dashboards, automated testing, and containerised delivery.

# Library Management System - Development Presentation

## Introduction

This document outlines the development process, architectural decisions, and thought process behind building a full-stack library management system. The project was developed as a technical exercise demonstrating proficiency in Ruby on Rails backend development, React frontend development, testing practices, and containerization.

## Project Overview

The Library Management System is a complete solution for managing a community library, serving two distinct user personas:

- **Libby the Librarian**: Needs to manage the catalog, track borrowings, monitor overdue books, and maintain member records efficiently.
- **Milo the Member**: Wants to browse books, borrow available copies, track due dates, and manage their reading history without friction.

## Development Approach

### Initial Planning

When I first read the requirements, I broke them down into clear components:

1. **Authentication & Authorization**: Two roles (Librarian and Member) with different permissions
2. **Book Management**: CRUD operations with search capabilities
3. **Borrowing System**: Track borrowings, enforce availability rules, manage due dates
4. **Dashboards**: Role-specific views showing relevant metrics
5. **API Design**: RESTful endpoints with proper status codes
6. **Testing**: Comprehensive test coverage with RSpec
7. **Frontend Integration**: Responsive, user-friendly interface

I started by sketching out the data model relationships: Users have many Borrowings, Books have many Borrowings, and Borrowings belong to both Users and Books. This helped me understand the domain before writing any code.

### Technology Stack Selection

**Backend:**
- **Rails 7.1 API mode**: Chose API-only mode since we're building a JSON API, avoiding unnecessary view layer overhead
- **PostgreSQL**: Robust relational database with excellent support for complex queries needed for dashboards
- **JWT Authentication**: Stateless authentication perfect for API-first architecture
- **RSpec**: Industry-standard testing framework for Rails, enabling TDD approach

**Frontend:**
- **React 18 with TypeScript**: Type safety and modern React patterns
- **Vite**: Fast development experience and optimized builds
- **React Router**: Client-side routing with protected routes
- **Axios**: HTTP client with interceptors for automatic JWT injection

**Infrastructure:**
- **Docker Compose**: Ensures consistent environment across different machines, especially important for Windows development

### Development Process

#### Phase 1: Backend Foundation

I began by setting up the Rails API project structure. The first step was creating the core models:

1. **User Model**: Started with basic fields (name, email, password_digest, role). Used Rails enums for roles to keep it simple and type-safe. Added `has_secure_password` for bcrypt encryption.

2. **Book Model**: Included all required fields (title, author, genre, ISBN, total_copies, description). Early on, I realized we needed to track available copies dynamically, so I added the `available_copies` method that calculates total minus active borrowings.

3. **Borrowing Model**: This was the most complex model. I needed to track:
   - When a book was borrowed (`borrowed_at`)
   - When it's due (`due_at` - automatically set to 2 weeks from borrowing)
   - When it was returned (`returned_at`)

I added validations to ensure:
- Books can't be borrowed if no copies are available
- Users can't borrow the same book multiple times concurrently
- Due date must be after borrowed date

The `unique_active_borrowing_for_user` validation uses a database index to prevent duplicate active borrowings efficiently.

#### Phase 2: Authentication System

I implemented JWT-based authentication because:
- Stateless: No need for server-side session storage
- Scalable: Works well with multiple API instances
- Secure: Tokens can expire and be validated without database lookups

Created a `JwtService` PORO (Plain Old Ruby Object) to encapsulate JWT encoding/decoding logic. This keeps the authentication logic separate from controllers and makes it testable.

The `ApplicationController` handles authentication via a `before_action` that:
1. Extracts the Bearer token from the Authorization header
2. Decodes and validates the token
3. Loads the current user
4. Handles errors gracefully with appropriate HTTP status codes

#### Phase 3: Authorization & Business Rules

Role-based authorization was implemented using `before_action` callbacks:

- `require_librarian!`: Protects book CRUD operations and borrowing returns
- Member-only operations: Borrowing creation is restricted to members only

I also added business rule validations:
- **Book deletion protection**: Can't delete books with active borrowings (prevents data integrity issues)
- **Title + Author uniqueness**: Prevents duplicate book entries while allowing same title by different authors
- **ISBN uniqueness**: Standard library practice

#### Phase 4: API Endpoints

Designed RESTful endpoints following Rails conventions:

```
POST   /signup          - Public member registration
POST   /login           - Public authentication
GET    /books           - List/search books (authenticated)
POST   /books           - Create book (librarian only)
PATCH  /books/:id       - Update book (librarian only)
DELETE /books/:id       - Delete book (librarian only)
GET    /borrowings      - List borrowings (role-scoped)
POST   /borrowings      - Borrow a book (member only)
PATCH  /borrowings/:id/return - Mark as returned (librarian only)
GET    /dashboard       - Role-specific dashboard data
```

Each endpoint returns appropriate HTTP status codes:
- `200 OK`: Successful GET/PATCH
- `201 Created`: Successful POST
- `204 No Content`: Successful DELETE
- `401 Unauthorized`: Missing/invalid token
- `403 Forbidden`: Insufficient permissions
- `422 Unprocessable Content`: Validation errors (updated from deprecated `:unprocessable_entity` for Rack 3 compatibility)

#### Phase 5: Dashboard Implementation

The dashboard was interesting because it needed to serve different data based on user role:

**Librarian Dashboard:**
- Total books in catalog
- Total currently borrowed books
- Books due today
- List of members with overdue books (with count)

I used ActiveRecord scopes and joins to efficiently query this data:
- `Borrowing.active`: Returns borrowings without `returned_at`
- `Borrowing.overdue`: Active borrowings past their due date
- `Borrowing.due_on(date)`: Active borrowings due on a specific date

**Member Dashboard:**
- All their borrowings (with book details)
- Overdue books specifically highlighted

#### Phase 6: Testing Strategy

I followed a TDD approach where possible, writing tests that guided the implementation:

1. **Model Tests**: Validated business rules, validations, and scopes
2. **Request Tests**: Covered authentication, authorization, and API behavior
3. **Edge Cases**: Tested scenarios like:
   - Trying to borrow unavailable books
   - Duplicate borrowings
   - Deleting books with active borrowings
   - Creating duplicate books

The test suite grew to 46 examples covering:
- User authentication and role management
- Book CRUD operations with validations
- Borrowing lifecycle (create, return, overdue tracking)
- Dashboard data accuracy
- Authorization boundaries

I used FactoryBot for test data generation and RSpec's `travel_to` helper to test time-sensitive logic (like due date calculations).

#### Phase 7: Frontend Development

The frontend was built with a focus on:
- **User Experience**: Clean, intuitive interface
- **Type Safety**: TypeScript prevents runtime errors
- **State Management**: React Context for authentication state
- **Error Handling**: Clear error messages from API responses

**Key Components:**
- `AuthContext`: Manages user session, login/logout, token storage
- `ProtectedRoute`: Wraps routes requiring authentication
- `AppLayout`: Main navigation and layout wrapper
- Pages: Login, Signup, Dashboard, Books, Borrowings

The Books page was particularly complex because it needed to:
- Display searchable/filterable book list
- Show librarian-only CRUD forms
- Allow members to borrow books
- Display availability in real-time

I implemented optimistic UI updates where possible, but also added proper error handling to show validation messages from the backend.

#### Phase 8: Docker & Deployment Setup

Docker Compose was essential for:
- Consistent development environment
- Easy onboarding (just `docker compose up`)
- Isolated services (Postgres, Rails, Vite)

I configured:
- Volume mounts for live code reloading
- Environment variables for configuration
- Automatic database setup and seeding
- Proper service dependencies

### Challenges & Solutions

1. **CORS Configuration**: Initially had issues with frontend-backend communication. Solved by configuring Rack::CORS to allow requests from the frontend URL.

2. **Host Authorization**: Rails 7's host authorization blocked requests. Fixed by allowing localhost in development/test environments.

3. **Docker Volume Permissions**: Windows file permissions caused issues with node_modules. Solved by adding `.dockerignore` to exclude node_modules from build context.

4. **PID File Conflicts**: Rails server PID files persisted between container restarts. Fixed by adding cleanup in the startup command.

5. **TypeScript Strict Mode**: Had to fix type imports to use `type` keyword for type-only imports when `verbatimModuleSyntax` is enabled.

### Code Quality & Best Practices

**Backend:**
- Thin controllers: Business logic in models, controllers handle HTTP concerns
- Service objects: JWT logic extracted to `JwtService`
- Scopes: Reusable query logic (active, overdue, due_on)
- Validations: Data integrity enforced at model level
- Error handling: Consistent error responses with appropriate status codes

**Frontend:**
- Component composition: Reusable components
- Type safety: TypeScript interfaces for API responses
- Error boundaries: Graceful error handling
- Responsive design: Works on different screen sizes

**Testing:**
- High coverage: 46 test examples covering critical paths
- Fast execution: Tests run in ~16 seconds
- Clear test names: Descriptive test descriptions
- Factory usage: Consistent test data generation

### AI-Assisted Development

During development, I used GitHub Copilot as a coding assistant. It was particularly helpful for:
- Generating boilerplate code (migrations, controller actions)
- Suggesting test cases based on requirements
- Providing TypeScript type definitions
- Offering Rails conventions and best practices

However, I made all architectural decisions, wrote the business logic, designed the API structure, and verified all code through testing. Copilot accelerated the development process but didn't replace critical thinking or understanding of the codebase.

### Conclusion

This project demonstrates a full-stack development approach with:
- Clean architecture and separation of concerns
- Comprehensive test coverage
- User-focused design
- Production-ready code quality
- Modern development practices

The system is ready for deployment and can be extended with additional features as needed. All requirements from the technical exercise have been met and tested.

---

## Quick Start

```bash
# Start all services
docker compose up --build

# Access the application
# Frontend: http://localhost:5173
# Backend API: http://localhost:3000

# Run tests
docker compose run --rm backend bundle exec rspec
```

## Demo Credentials

- **Librarian**: `librarian@example.com` / `password123`
- **Member**: `member@example.com` / `password123`

---

*Developed with attention to code quality, user experience, and maintainability.*

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


