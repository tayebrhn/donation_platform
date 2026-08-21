# Common Ground Donation Platform

Common Ground is a small Rails 7 donation platform for school and community fundraising campaigns. Visitors can browse active projects, submit a donation, complete a Stripe PaymentIntent in test mode, and see fundraising progress after Stripe confirms the payment through a signed webhook.

## Requirements

- Ruby 3.3.x
- Rails 7.1.x and Bundler
- PostgreSQL 14 or newer, running locally
- A Stripe test-mode account
- Stripe CLI for local webhook forwarding

The application uses Rails ERB, Hotwire, PostgreSQL, and Stripe test mode. It does not use Docker, WSL, or a separate JavaScript application.

## Setup

Open PowerShell in the project directory and install the bundle:

```powershell
bundle install
```

Create the PostgreSQL databases and run migrations:

```powershell
$env:POSTGRES_USER = "postgres"
$env:POSTGRES_PASSWORD = "your-local-postgres-password"
bin\rails db:prepare
```

Use `.env.example` as the list of required variables. This application does not load `.env` files automatically; set the Stripe test credentials in PowerShell before starting Rails:

```powershell
$env:STRIPE_SECRET_KEY = "sk_test_..."
$env:STRIPE_PUBLISHABLE_KEY = "pk_test_..."
$env:STRIPE_WEBHOOK_SECRET = "whsec_..."
```

Load the demo campaigns:

```powershell
bin\rails db:seed
```

To bootstrap the first administrator, set `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and optionally `ADMIN_NAME` before running the seed command. The password is used only when creating a new administrator:

```powershell
$env:ADMIN_NAME = "Platform Administrator"
$env:ADMIN_EMAIL = "admin@example.com"
$env:ADMIN_PASSWORD = "use-a-unique-secure-password"
bin\rails db:seed
```

New public registrations always receive the `donor` role. Administrators can promote users to `project_manager` or `admin` from the Users screen.

## User Roles

- `donor`: manage a profile, view donations made while signed in, and continue to use the public donation flow.
- `project_manager`: use the campaign workspace to create projects and manage only assigned projects.
- `admin`: manage every project, assign project managers, and change other users' roles.

Public registration cannot request a privileged role. An administrator cannot demote their own account through the UI, reducing the risk of accidental administrative lockout. Guest donations remain supported and are not retroactively linked to accounts by email address.

Start Rails:

```powershell
bin\rails server
```

Visit <http://localhost:3000>.

## Stripe Test Payments

Use only Stripe test-mode keys. The initializer rejects live secret and publishable keys. Common Ground never receives or stores raw card details; Stripe.js collects them in the browser.

The server creates a pending Donation and PaymentIntent. A donation becomes `succeeded` or `failed` only after the signed webhook is verified. Returning to the browser or reaching the result page does not mark a pending donation as paid.

To forward Stripe events to the local webhook endpoint, authenticate the Stripe CLI and run:

```powershell
stripe login
stripe listen --forward-to localhost:3000/webhooks/stripe
```

The CLI prints a webhook signing secret beginning with `whsec_`. Set that value as `STRIPE_WEBHOOK_SECRET` and restart Rails. Keep the CLI running while testing payments.

For a basic test payment, use Stripe's test card `4242 4242 4242 4242`, any future expiry date, any three-digit CVC, and any postal code. Do not use real card details.

## Database Configuration

`config/database.yml` reads these environment variables:

- `POSTGRES_USER` (default: `postgres`)
- `POSTGRES_PASSWORD`
- `POSTGRES_HOST` (default: `localhost`)
- `POSTGRES_PORT` (default: `5432`)

The development and test databases are `donation_platform_development` and `donation_platform_test`.

## Tests and Checks

Run the full test suite with the PostgreSQL password available in the environment:

```powershell
$env:POSTGRES_PASSWORD = "your-local-postgres-password"
bin\rails test
```

The suite mocks Stripe API calls and does not make real payment requests. Additional checks:

```powershell
bundle exec rubocop
bundle exec brakeman --no-pager
```

The test suite runs with one worker because Stripe configuration and client stubs are process-global during tests.

## Project Structure

- `app/models`: Project, Donation, and webhook event models
- `app/controllers`: public project and donation flow plus the Stripe webhook endpoint
- `app/views`: server-rendered ERB pages
- `app/javascript/controllers`: Stripe Payment Element integration
- `db/seeds.rb`: idempotent local demo campaigns
- `test`: model, controller, webhook, and integration coverage

## Security Notes

- Never commit `.env`, Stripe keys, PostgreSQL passwords, or `config/master.key`.
- Use Stripe test keys only during local development.
- The webhook endpoint verifies Stripe signatures and handles duplicate event delivery idempotently.
- Monetary values are stored as integer cents; no floating-point financial calculations are used.
