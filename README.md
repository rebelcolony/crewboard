# CrewControl

A visual project management dashboard built for team managers who need an at-a-glance view of crew assignments across multiple projects. Designed for scenarios like offshore inspection management, where a project manager needs to know who is where and what state each project is in.

Projects are displayed as cards on a dashboard grid. Crew members appear as draggable avatar circles — drag them between projects or to/from the unassigned crew bar to reassign in real time.

## Tech Stack

- **Ruby on Rails 8** with Propshaft and Import Maps (no Node.js/bundler)
- **PostgreSQL**
- **Hotwire** — Turbo Drive, Turbo Frames, Turbo Streams + Stimulus
- **Custom CSS** — CSS custom properties for theming, no CSS framework
- **Authentication** — `has_secure_password` with session-based auth
- **Payments** — Stripe via the Pay gem (subscriptions, checkout, billing portal)
- **Deployment** — Kamal with staging and production destinations

## Features

### Dashboard & Crew Management
- **Visual dashboard** — responsive CSS grid of project cards showing name, location, status, progress bar, and assigned crew
- **Drag and drop** — drag crew avatars between projects or to/from the unassigned bar. Assignments update live via Turbo Streams (no page reload)
- **Project detail modal** — click a project card to see full details (description, dates, crew list) in an overlay
- **Dark/light theme** — dark mode by default, toggle in navbar, preference saved to localStorage
- **Projects CRUD** — create, edit, delete projects with name, location, description, status, progress, and date fields
- **Crew Members CRUD** — manage crew with name, role, email, phone, avatar upload (Active Storage)

### Multi-Tenancy
- **Account-based isolation** — all data (projects, crew, managers) scoped to an Account via `account_id` foreign keys
- **Tenantable concern** — shared `for_current_account` scope, no `default_scope` (admin can query across tenants)
- **Current.account** — set automatically from the logged-in manager's account during authentication
- **Registration flow** — new accounts create an Account + first Manager in a single transaction

### Stripe Subscription Plans
- **Pay gem integration** — Account model is billable via `pay_customer`
- **Pricing page** — public 3-tier pricing (Starter $29/mo, Pro $79/mo, Enterprise custom)
- **Stripe Checkout** — subscription creation via Stripe Checkout sessions
- **Billing portal** — manage subscriptions via Stripe's hosted billing portal
- **Webhook handling** — Pay gem auto-mounts webhook endpoint at `/pay/webhooks/stripe`

### Admin Backend
- **Separate `/admin` namespace** — dedicated layout with sidebar navigation
- **Role-based access** — `super_admin` boolean on Manager model, enforced by `AdminAuthentication` concern
- **Admin dashboard** — metrics cards showing total accounts, managers, projects, crew, and active subscriptions
- **Cross-tenant CRUD** — admin can view and manage all Accounts, Managers, Projects, Crew Members
- **Subscription management** — read-only view of all Pay::Subscription records

### Deployment Pipeline
- **Kamal destinations** — `staging` and `production` with separate server IPs, DB hosts, and environment config
- **Environment-specific credentials** — `rails credentials:edit --environment staging|production`
- **Deploy script** — `bin/deploy staging` or `bin/deploy production`

## Setup

```bash
git clone <repo-url>
cd crewboard
bundle install
rails db:create db:migrate db:seed
bin/rails server
```

Open `http://localhost:3000` and sign in:

- **Email:** `admin@crewboard.com`
- **Password:** `password123`

This account has `super_admin: true`, so the Admin link appears in the navbar.

### Running Tests

```bash
# Run full test suite
bin/rails test

# Run a specific test file
bin/rails test test/models/manager_test.rb

# Run a single test by line number
bin/rails test test/controllers/projects_controller_test.rb:26
```

### Prerequisites

- Ruby 3.2+
- PostgreSQL
- libvips (for Active Storage image processing)

### Stripe Configuration

Add your Stripe keys to Rails credentials:

```bash
rails credentials:edit
```

```yaml
stripe:
  publishable_key: pk_test_xxx
  secret_key: sk_test_xxx
  webhook_signing_secret: whsec_xxx
```

Set Stripe price IDs via environment variables:

```bash
export STRIPE_STARTER_PRICE_ID=price_xxx
export STRIPE_PRO_PRICE_ID=price_xxx
```

## Data Model

```
Account (tenant)
  has_many :managers, :projects, :crew_members
  pay_customer (Stripe billing via Pay gem)

Manager (login account)
  belongs_to :account
  has_secure_password
  has_many :sessions
  super_admin: boolean

Project
  belongs_to :account
  has_many :crew_members
  enum :status (not_started, in_progress, on_hold, completed)
  progress (0-100)

CrewMember
  belongs_to :account
  belongs_to :project (optional)
  has_one_attached :avatar
```

All tenant-scoped models include the `Tenantable` concern which provides `belongs_to :account` and `scope :for_current_account`.

## Key Files

```
app/
├── controllers/
│   ├── dashboard_controller.rb          # Main dashboard (account-scoped)
│   ├── projects_controller.rb           # CRUD (account-scoped)
│   ├── crew_members_controller.rb       # CRUD + drag-drop (account-scoped)
│   ├── sessions_controller.rb           # Login/logout
│   ├── registrations_controller.rb      # Account + Manager signup
│   ├── pricing_controller.rb            # Public pricing page
│   ├── checkouts_controller.rb          # Stripe Checkout sessions
│   ├── billings_controller.rb           # Stripe Billing Portal
│   ├── concerns/
│   │   ├── authentication.rb            # Session auth + Current.account
│   │   └── admin_authentication.rb      # Super admin gate
│   └── admin/
│       ├── base_controller.rb           # Admin layout + auth
│       ├── dashboard_controller.rb      # Metrics
│       ├── accounts_controller.rb       # CRUD
│       ├── managers_controller.rb       # CRUD
│       ├── projects_controller.rb       # Cross-tenant CRUD
│       ├── crew_members_controller.rb   # Cross-tenant CRUD
│       └── subscriptions_controller.rb  # Read-only
├── models/
│   ├── account.rb                       # Tenant + Pay billable
│   ├── manager.rb                       # Auth + Tenantable
│   ├── project.rb                       # Tenantable
│   ├── crew_member.rb                   # Tenantable
│   ├── current.rb                       # CurrentAttributes (session + account)
│   └── concerns/tenantable.rb           # Shared account scoping
├── javascript/controllers/
│   ├── draggable_controller.js          # Drag crew avatars
│   ├── drop_target_controller.js        # Drop on projects/unassigned
│   ├── modal_controller.js              # Project detail overlay
│   └── theme_controller.js              # Dark/light toggle
├── views/
│   ├── layouts/
│   │   ├── application.html.erb         # Main layout
│   │   ├── auth.html.erb                # Login/register layout
│   │   └── admin.html.erb               # Admin layout with sidebar
│   ├── dashboard/show.html.erb          # Dashboard grid
│   ├── registrations/new.html.erb       # Signup form
│   ├── pricing/show.html.erb            # 3-tier pricing cards
│   └── admin/                           # Admin views (dashboard, CRUD)
└── assets/stylesheets/
    └── application.css                  # All styles (CSS custom properties)
```

## Deployment

Kamal is configured with staging and production destinations:

```bash
# Deploy to staging
bin/deploy staging

# Deploy to production
bin/deploy production

# Or use kamal directly
kamal deploy -d staging
kamal deploy -d production

# Console access
kamal console -d production
```

Server IPs in `config/deploy.yml` are placeholders — replace with your actual servers before deploying.

Set `DATABASE_PASSWORD` as an environment variable before deploying:

```bash
export DATABASE_PASSWORD=your_db_password
bin/deploy production
```

## How Drag and Drop Works

1. Crew avatars use `draggable_controller.js` — sets `dataTransfer` with the crew member ID on drag start
2. Project cards and the unassigned bar use `drop_target_controller.js` — on drop, sends `PATCH /crew_members/:id` with the target `project_id` (or null for unassigned)
3. The controller responds with a Turbo Stream that replaces all project cards and the unassigned bar in place
4. No page reload — the dashboard updates instantly

## Seed Data

The seeds create an Aberdeen offshore inspection scenario:

- 1 account ("Aberdeen Offshore Inspections")
- 1 super admin manager
- 8 projects (platform inspections, pipeline surveys, decommissioning, wind farm)
- 25 crew members with realistic roles (Lead Inspector, NDT Technician, Rope Access Tech, ROV Pilot, etc.)
- Pre-assigned crew across projects with 5 left unassigned

## To Do

### Must-haves
- [x] Password reset / forgot password flow (mailer + token-based reset)
- [x] Profile page — allow managers to update their email and password
- [x] Account settings — edit company name, subdomain after registration

### Should-haves
- [x] Team invites — invite additional managers to an account via email
- [x] Transactional emails — welcome, payment receipt, invite, password reset mailers
- [x] Usage indicators on dashboard — "2 of 10 projects used" with upgrade prompt near limit

### Nice-to-haves
- [x] In-app plan upgrade/downgrade (not just via Stripe portal)
- [ ] Onboarding flow — guided first-project creation for new signups

## Future Enhancements

- Zoom in/out on dashboard (CSS `transform: scale()`)
- Free-position project cards (draggable on canvas)
- Real-time updates via Action Cable
- Per-seat pricing enforcement
- Subdomain-based tenant routing
- Mobile responsive drag (touch events)
