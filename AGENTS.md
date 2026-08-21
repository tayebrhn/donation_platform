# AGENTS.md

## Project: Donation Platform

Build a small donation platform using **Ruby on Rails 7**. The application allows users to donate small amounts to school or charity projects using Stripe test payments and displays fundraising progress.

---

# 1. Development Environment

The project runs **natively on Windows**.

Do **NOT** introduce WSL, Docker, containers, or a Linux-specific development workflow unless explicitly requested.

### Environment

```text
Operating System: Windows 11
Architecture: x64
Ruby: 3.3.x
Rails: 7.1.x
Database: PostgreSQL
Frontend: Rails ERB + Hotwire/Turbo
Payments: Stripe Test Mode
Version Control: Git
AI Agent: OpenCode
Editor: VS Code
```

### Important

Use native Windows commands and paths when necessary.

Prefer Rails' standard commands:

```text
rails
rails server
rails test
rails db:migrate
rails db:seed
```

The project should remain compatible with a normal native Windows Rails development environment.

---

# 2. Existing Environment

Before changing anything, inspect the existing project.

Check:

```powershell
ruby --version
rails --version
bundle --version
psql --version
git --version
```

Also inspect:

```powershell
git status
git log --oneline -n 10
```

Do not reinstall or replace tools that are already correctly configured.

Do not upgrade Ruby, Rails, PostgreSQL, or other major dependencies without a concrete reason.

---

# 3. Database

Use **PostgreSQL**.

Do not replace PostgreSQL with SQLite.

Use Rails' PostgreSQL adapter and standard Active Record migrations.

The database should use:

```text
development
test
```

environments appropriately.

Use integer cents for monetary amounts.

Example:

```text
$10.50 = 1050 cents
```

Never use floating-point values for financial calculations.

---

# 4. Stripe

Use **Stripe Test Mode only**.

Never use real payment credentials or real transactions during development.

Expected environment variables:

```text
STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

Never commit actual Stripe secrets.

Use `.env.example` to document required variables if the project uses `.env`.

The Stripe webhook must verify its signature.

Never trust payment success based solely on browser/client-side behavior.

---

# 5. Git

Git is already part of the development workflow.

Maintain a clean and meaningful Git history.

Do not make one giant commit containing the entire application.

Make **incremental, focused commits** after each stable milestone.

Before every commit:

```powershell
git status
git diff
```

Run the relevant tests/checks.

Then stage only the files belonging to that change:

```powershell
git add <specific-files>
```

Create a descriptive commit:

```powershell
git commit -m "feat: add donation model"
```

After committing:

```powershell
git status
git log -1 --oneline
```

Do not squash or rewrite previous commits unless explicitly instructed.

Avoid meaningless commit messages such as:

```text
update
changes
fix
stuff
final
wip
```

Prefer conventional commit messages:

```text
chore: initialize Rails application
feat: add project model
feat: add donation model
feat: add fundraising progress calculation
feat: add project pages
feat: add donation form
feat: integrate Stripe PaymentIntent
feat: add Stripe webhook handling
test: add donation payment tests
fix: prevent duplicate webhook processing
style: improve donation platform UI
docs: document Stripe setup
```

---

# 6. Development Principles

Follow standard Rails conventions.

Prefer:

* MVC architecture
* Active Record
* RESTful routes
* Rails validations
* Rails associations
* Rails migrations
* ERB views
* Hotwire/Turbo where useful
* Server-side validation
* Small focused methods
* Clear naming
* Database constraints

Avoid unnecessary architecture.

Do not introduce:

* React
* Vue
* Angular
* Docker
* WSL
* Kubernetes
* microservices
* repositories
* excessive service objects
* unnecessary APIs

unless there is a concrete requirement.

This is intended to be a **small Rails application**, not an over-engineered system.

---

# 7. Project Requirements

The application must provide:

## Projects

A project represents a school or charity fundraising campaign.

Fields:

```text
title
description
goal_amount_cents
currency
status
created_at
updated_at
```

Possible statuses:

```text
draft
active
completed
```

## Donations

Fields:

```text
project_id
donor_name
donor_email
amount_cents
currency
stripe_payment_intent_id
status
created_at
updated_at
```

Possible statuses:

```text
pending
succeeded
failed
```

Associations:

```ruby
Project has_many :donations
Donation belongs_to :project
```

---

# 8. Fundraising Progress

Projects must provide calculations for:

```text
amount_raised
remaining_amount
progress_percentage
```

Example:

```text
Goal:   $10,000
Raised: $4,250

Progress: 42.5%
```

Progress must never exceed:

```text
100%
```

If donations exceed the goal, display 100%.

---

# 9. Public Application Flow

The application should support:

```text
Home
  ↓
Projects
  ↓
Project Details
  ↓
Donate
  ↓
Donation Form
  ↓
Stripe Payment
  ↓
Payment Result
```

A project page should show:

```text
Project title
Description
Amount raised
Fundraising goal
Remaining amount
Progress percentage
Progress bar
Donate button
```

---

# 10. Stripe Payment Flow

Use Stripe PaymentIntents.

The server must:

1. Validate the donation.
2. Create a pending Donation.
3. Create a Stripe PaymentIntent.
4. Associate the PaymentIntent with the Donation.
5. Allow Stripe to process the payment.
6. Process Stripe's webhook.
7. Mark the Donation as succeeded or failed.

Do not mark a donation as successful merely because the user reaches a success page.

Stripe's server-side confirmation/webhook flow is authoritative.

---

# 11. Webhooks

Create:

```text
POST /webhooks/stripe
```

Handle at minimum:

```text
payment_intent.succeeded
payment_intent.payment_failed
```

Verify Stripe webhook signatures.

Webhook processing must be idempotent.

A webhook may be delivered more than once. Duplicate events must not create duplicate successful donations or otherwise corrupt application state.

---

# 12. Security

Always validate important values server-side.

Never trust client-provided:

```text
amount
project_id
donation status
Stripe payment status
Stripe PaymentIntent ID
```

Use:

* Strong parameters
* Rails CSRF protection
* Model validations
* Database constraints
* Stripe webhook signature verification
* Secure secret management

Never store raw credit-card information.

---

# 13. Testing

Use the project's existing testing framework.

If no framework has been selected, use Rails' default test framework unless there is a strong reason to introduce RSpec.

Test:

### Models

* Valid projects
* Invalid projects
* Valid donations
* Invalid donations
* Associations
* Amount calculations
* Progress calculations
* Progress capped at 100%

### Donation Flow

* Valid donation
* Invalid amount
* Invalid email
* Missing project
* Stripe API failure
* Successful payment
* Failed payment

### Webhooks

* Valid Stripe signature
* Invalid Stripe signature
* Successful PaymentIntent
* Failed PaymentIntent
* Duplicate webhook/event processing

Mock Stripe API calls in automated tests.

Never make real Stripe API calls as part of the normal test suite.

---

# 14. Implementation Phases

Implement the project incrementally.

## Phase 1 — Project Setup

* Inspect existing Rails application.
* Verify development environment.
* Configure PostgreSQL.
* Establish baseline tests.
* Establish Git baseline.

Commit:

```text
chore: initialize Rails donation platform
```

## Phase 2 — Database and Models

Implement:

* Project
* Donation
* Migrations
* Associations
* Validations
* Fundraising calculations

Commit separately.

## Phase 3 — Public UI

Implement:

* Project listing
* Project details
* Progress bar
* Donation form

Commit separately.

## Phase 4 — Stripe Integration

Implement:

* Stripe configuration
* PaymentIntent creation
* Stripe payment UI
* Pending donation handling

Commit separately.

## Phase 5 — Stripe Webhooks

Implement:

* Webhook endpoint
* Signature verification
* Successful payments
* Failed payments
* Idempotency

Commit separately.

## Phase 6 — Error Handling

Implement and test:

* Validation errors
* Stripe errors
* Missing records
* Failed payments
* Cancelled payments
* Invalid webhooks

Commit separately.

## Phase 7 — Automated Tests

Complete the test suite.

Commit separately.

## Phase 8 — Documentation and Polish

Implement:

* README
* `.env.example`
* Stripe local development instructions
* UI improvements
* Final cleanup

Commit separately.

---

# 15. Phase Gate

**Do not automatically continue from one phase to the next.**

After completing a phase:

1. Run the relevant tests.
2. Inspect the changes.
3. Review `git diff`.
4. Create the focused Git commit.
5. Verify `git status`.
6. Report what was completed.
7. Stop.

Wait for the user to explicitly request the next phase.

Do not implement future phases while waiting.

---

# 16. Agent Behavior

Before modifying code:

```text
1. Inspect the repository.
2. Inspect existing Git history.
3. Inspect relevant Rails files.
4. Understand the current implementation.
5. Determine the smallest appropriate change.
```

Do not blindly overwrite existing code.

When encountering an error:

```text
1. Read the complete error.
2. Identify the root cause.
3. Inspect relevant code/configuration.
4. Make the smallest appropriate fix.
5. Re-run the failing command/test.
6. Verify that the fix did not break existing functionality.
```

Do not hide errors by disabling tests, removing validations, or weakening security.

If a requirement is ambiguous and the decision could materially affect architecture, security, payments, or data integrity, stop and ask for clarification rather than making a risky assumption.

---

# 17. Completion Requirements

The application is complete only when:

```text
[ ] Rails application runs successfully
[ ] PostgreSQL works
[ ] Projects can be created/displayed
[ ] Fundraising progress works
[ ] Donations can be submitted
[ ] Stripe Test Mode works
[ ] PaymentIntent integration works
[ ] Stripe webhook works
[ ] Duplicate webhook handling works
[ ] Failed payments are handled
[ ] Automated tests pass
[ ] No secrets are committed
[ ] README is complete
[ ] Git history contains meaningful incremental commits
[ ] Working tree is clean
```

Before declaring the project complete, run the appropriate Rails test suite and verify:

```powershell
git status
```

The final working tree should be clean unless there is an explicitly documented reason for uncommitted changes.
