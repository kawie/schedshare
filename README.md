# SchedShare

SchedShare is a web application that allows users to share and sync their sports class schedules with friends. Built using **Elixir** and **Phoenix LiveView**, it provides real-time updates and push notifications for an interactive experience.

## Planned Features
- **Passkey Authentication**: Users log in with **passkeys** and require an **invite code** to create an account.
- **Invite System**: Each user has a limited number of invite codes (default: 3).
- **Follow & Approve Requests**: Users can follow each other, but all follows require manual approval.
- **Sports Schedule Sync**: Users can link their account from a **big Berlin-based sports membership platform** to fetch schedules automatically.
- **Newsfeed & Web Push**: Users receive notifications when friends book a class or leave a waitlist.
- **Profile & My Schedule Pages**: View your own and friends' schedules, approve follow requests, and manage settings.
- **Deep Linking to External Platform**: No separate event pages; links redirect to the sports platform with an obfuscated base URL.
- **No Class Browsing or Management**: Users cannot browse, book, or cancel classes through SchedShare.

## Tech Stack
- **Backend**: Elixir + Phoenix LiveView
- **Database**: SQLite (using `sqlite_ecto2` and `Ecto`)
- **Hosting**: Fly.io (with potential LiteFS for SQLite replication)
- **Push Notifications**: WebPush API for real-time updates
- **Authentication**: WebAuthn for passkey-based login
- **Data Storage**: SQLite (or in-memory storage via ETS if needed)

## Installation
### Prerequisites
- Elixir & Erlang installed ([Install Guide](https://elixir-lang.org/install.html))
- Phoenix installed:  
  ```sh
  mix archive.install hex phx_new
  ```

### Clone & Setup Project
```sh
git clone https://github.com/yourusername/schedshare.git
cd schedshare
mix deps.get
```

### Configure Database
SchedShare uses **SQLite** by default. To set up the database:
```sh
mix ecto.create
mix ecto.migrate
```

### Run the Application
```sh
mix phx.server
```
Access the app at: `http://localhost:4000`

### Environment Variables
Create a `.env` file in the project root with the following variables:

```sh
# API Configuration
API_BASE_URL=https://api.example.com  # Base URL for the sports platform API
API_CLIENT_ID=your_client_id          # Client ID for API authentication
API_CLIENT_SECRET=your_client_secret  # Client secret for API authentication

# Development Mode
ENV=dev  # Set to 'dev' for development, 'test' for testing, or 'prod' for production
```

## Deployment (Fly.io)
To deploy to Fly.io:
1. Install Fly CLI:  
   ```sh
   curl -L https://fly.io/install.sh | sh
   ```
2. Authenticate & Deploy:  
   ```sh
   flyctl auth login
   flyctl launch
   ```

---
**SchedShare** is a work in progress. Contributions and feedback are welcome!

