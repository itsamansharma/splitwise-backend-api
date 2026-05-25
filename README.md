# Splitwise Clone - Backend

This is the Ruby on Rails 8 API backend for the Splitwise Clone application. It handles authentication, group management, expense calculation, and settlement logic.

## Prerequisites
- **Ruby** (v3.x or higher recommended)
- **PostgreSQL** (running locally)
- **Bundler** (`gem install bundler`)

## Setup Instructions

1. **Install Dependencies:**
   From this `backend` directory, run:
   ```bash
   bundle install
   ```

2. **Database Setup:**
   Ensure PostgreSQL is running locally, then create and migrate the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

3. **Start the Server:**
   ```bash
   rails server
   ```
   *The API will be available at http://localhost:3000.*

## Architecture
This API securely authenticates requests via JWT and exposes endpoints for managing Users, Friends, Groups, Expenses, and Settlements. The calculation engine resolves and simplifies complex group debts automatically.
