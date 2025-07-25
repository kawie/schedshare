# SchedShare

My new years resolution was to do more sports, and it's obviously more fun with friends. So I built this web application that allows me and my friends to share and sync our sports class schedules. Built using **Elixir** and **Phoenix LiveView**, it makes it easy to see who's doing what, and when you're going together.

![Three SchedShare screenshots: Onboarding/Schedule provider connection, the "Home Page" including activity feed, and the Calendar view](/assets/screenshots-small.png)

## Features

- Create an account and build your profile
- Send and receive friend requests
- "People you might know" suggestions for connecting with other users
- Connect your account to sync schedules from a big Berlin-based sports membership platform ;)
- Background synchronization every 15 minutes (production) or 1 minute (development)
- View your own schedule and friends' schedules (when approved as friends)
- Comprehensive calendar view, showing your bookings and friends' bookings
- View course information, venue details, teacher names, and timing
- Activity Feed: See recent bookings from friends
- Going Together: See which friends are attending the same classes

## Planned Features
- Passkey Authentication
- Invite System: Each user has a limited number of invite codes.
- Newsfeed & Web Push: Users receive notifications when friends book a class or leave a waitlist.
- Enhanced Notifications: Push notifications for schedule changes and friend activities.

## Tech Stack
- **Backend**: Elixir + Phoenix LiveView
- **Database**: SQLite (using `sqlite_ecto2` and `Ecto`)
- **Push Notifications**: WebPush API for real-time updates (planned)
- **Authentication**: Email/password with confirmation (WebAuthn planned)
- **Styling**: Tailwind CSS with dark mode support

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

### Configure environment variables
   Create a `.env` file in the project root:
   ```sh
   # API Configuration (for sports platform integration)
   API_BASE_URL=https://api.example.com
   API_CLIENT_ID=your_client_id
   API_CLIENT_SECRET=your_client_secret
   
   # External platform domain for deep linking
   EXTERNAL_DOMAIN=https://sports-platform.com
   
   # Schedule provider name (displayed in UI)
   SCHEDULE_PROVIDER_NAME="Your Sports Provider"
   
   # Development settings
   ENV=dev
   ```

### Start the application
   ```sh
   mix phx.server
   ```

Open your browser and navigate to `http://localhost:4000`

- **Run tests**: `mix test`
- **Format code**: `mix format`
- **Database reset**: `mix ecto.reset`


---

**SchedShare** is a work in progress. Contributions and feedback are welcome!

