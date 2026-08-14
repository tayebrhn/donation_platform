# Rails 7 Donation Platform — AI Agent Implementation Prompt

You are an experienced Ruby on Rails 7 engineer. Build a small, production-quality **Donation Platform** for a school or charity project.

## 1. Project Goal

Create a web application where:

* A project/organization can define a fundraising goal.
* Visitors can view the project and its fundraising progress.
* Visitors can make small donations.
* Donations are processed through **Stripe in test mode**.
* The project page displays a progress bar showing:

  * Current amount raised.
  * Fundraising goal.
  * Percentage completed.
* Donors do not need to create an account.

Keep the MVP simple. Do not implement unnecessary features such as subscriptions, complex user roles, social login, or an admin dashboard unless they are required for the core functionality.

## 2. Technology Stack

Use:

* Ruby on Rails 7
* Ruby 3.x
* PostgreSQL
* Stripe API / Stripe Ruby SDK
* Hotwire/Turbo where useful
* ERB views
* Importmap or the default Rails 7 JavaScript setup
* Bootstrap or simple custom CSS for styling
* Rails credentials or environment variables for Stripe secrets
* RSpec or Rails/Minitest for testing

Prefer standard Rails conventions over unnecessary abstractions.

## 3. Core Domain Model

Create a `Project` model.

Suggested fields:

```text
Project
- title
- description
- goal_amount_cents
- currency
- status
- created_at
- updated_at
```

Create a `Donation` model.

Suggested fields:

```text
Donation
- project_id
- donor_name
- donor_email
- amount_cents
- currency
- stripe_payment_intent_id
- status
- created_at
- updated_at
```

Use integer cents for monetary values rather than floating-point numbers.

Example:

```text
$10.50 → 1050 cents
```

Add appropriate validations and database indexes.

Possible donation statuses:

```text
pending
succeeded
failed
```

Project statuses can be:

```text
draft
active
completed
```

## 4. Database Requirements

Create Rails migrations for the models.

Add:

* Foreign key from donations to projects.
* Index on `donations.project_id`.
* Unique index on `donations.stripe_payment_intent_id` where appropriate.
* Appropriate `NOT NULL` constraints.
* Reasonable default values.

Use Rails associations:

```ruby
Project has_many :donations
Donation belongs_to :project
```

Add model methods such as:

```ruby
Project#amount_raised
Project#progress_percentage
Project#remaining_amount
```

The progress percentage must never exceed 100%.

For example:

```text
Goal: $10,000
Raised: $4,250

Progress: 42.5%
```

If donations exceed the goal, display 100% rather than something greater than 100%.

## 5. Public Pages

Implement:

```text
GET /
GET /projects/:id
GET /projects/:project_id/donations/new
POST /projects/:project_id/donations
GET /donations/:id/success
GET /donations/:id/cancel
```

The home page should show active fundraising projects.

The project page should display:

* Project title
* Description
* Goal
* Amount raised
* Remaining amount
* Progress percentage
* Visual progress bar
* Donation button

Example:

```text
Help Build a New School Library

$4,250 raised of $10,000

[████████████░░░░░░░░] 42.5%

$5,750 remaining

[ Donate Now ]
```

## 6. Donation Flow

Implement the following flow:

```text
Project Page
     ↓
Donate
     ↓
Donation Form
     ↓
Enter name, email and amount
     ↓
Create pending Donation
     ↓
Create Stripe PaymentIntent
     ↓
Stripe payment
     ↓
Payment succeeds
     ↓
Mark Donation as succeeded
     ↓
Show success page
```

Do not mark a donation as successful merely because the user reaches the success page.

The application's donation status must be based on the Stripe payment result/webhook.

## 7. Stripe Integration

Use Stripe's test environment.

Store credentials using environment variables or Rails credentials.

Example configuration:

```text
STRIPE_PUBLISHABLE_KEY
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
```

Never hard-code Stripe secret keys.

Implement Stripe PaymentIntent creation.

The amount sent to Stripe must come from the server-side validated donation amount.

Never trust a client-provided amount when creating a Stripe payment.

Use Stripe test cards for development.

Do not use real payments.

## 8. Stripe Webhook

Implement a webhook endpoint such as:

```text
POST /webhooks/stripe
```

Handle at least:

```text
payment_intent.succeeded
payment_intent.payment_failed
```

Verify the Stripe webhook signature.

Do not blindly trust webhook request data.

When:

```text
payment_intent.succeeded
```

is received:

* Find the corresponding Donation.
* Verify the PaymentIntent ID.
* Mark the donation as `succeeded`.
* Prevent duplicate processing.

The webhook handling must be idempotent.

## 9. Security

Follow Rails security best practices.

Implement:

* Strong parameters.
* CSRF protection where appropriate.
* Server-side donation amount validation.
* Email validation.
* Minimum donation amount.
* Maximum donation amount.
* Stripe webhook signature verification.
* No exposure of secret Stripe keys.
* Protection against duplicate payment records.
* Proper authorization of project/donation relationships.

Do not allow users to modify:

```text
amount_cents
project_id
status
stripe_payment_intent_id
```

through unsafe parameters after the payment process begins.

## 10. Donation Amount Validation

For the MVP, enforce reasonable limits.

For example:

```text
minimum: $1
maximum: $10,000
```

The exact values should be configurable.

Reject:

* zero
* negative values
* invalid decimals
* excessively large donations

Convert the validated amount to cents on the server.

## 11. UI

Create a clean, responsive interface.

Prioritize:

* Simple navigation.
* Project cards.
* Project fundraising page.
* Donation form.
* Progress bar.
* Stripe payment UI.
* Success page.
* Cancel/failure page.

Do not over-engineer the frontend.

Use Rails views and Hotwire where appropriate rather than creating a separate React application.

## 12. Error Handling

Handle:

* Invalid donation amounts.
* Invalid email addresses.
* Stripe API errors.
* Failed payments.
* Cancelled payments.
* Missing projects.
* Missing donations.
* Invalid Stripe webhook signatures.
* Duplicate webhook events.

Show useful user-facing error messages without exposing internal exceptions or Stripe secrets.

Log useful server-side diagnostic information.

## 13. Routes

Use RESTful Rails routes where possible.

Example:

```ruby
resources :projects, only: [:index, :show] do
  resources :donations, only: [:new, :create]
end

resources :donations, only: [] do
  member do
    get :success
    get :cancel
  end
end

post "/webhooks/stripe", to: "webhooks/stripe#create"
```

Adjust the routing if a cleaner Rails convention is preferable.

## 14. Testing

Write tests for:

### Models

Test:

* Project validations.
* Donation validations.
* Project/donation associations.
* Amount calculations.
* Progress calculation.
* Progress never exceeding 100%.

### Controllers

Test:

* Project listing.
* Project details.
* Donation creation.
* Invalid donation submission.
* Missing project.
* Success page.
* Cancel page.
* Webhook endpoint.

### Stripe

Mock Stripe API calls.

Do not make real Stripe API calls during the test suite.

Test:

* Successful PaymentIntent creation.
* Stripe API failure.
* Successful webhook.
* Failed-payment webhook.
* Invalid webhook signature.
* Duplicate webhook event.

## 15. Seed Data

Create useful development seed data.

For example:

```text
Project:
Title: Build a School Library
Goal: $10,000
Status: active
```

Create several example donations so the progress bar can be demonstrated.

Make sure running:

```bash
bin/rails db:seed
```

creates usable demo data.

## 16. README

Create a complete README containing:

* Project description.
* Requirements.
* Installation.
* Database setup.
* Environment variables.
* Stripe test configuration.
* How to run the Rails server.
* How to run tests.
* How to test Stripe webhooks locally.
* Example Stripe test card.
* Project structure.
* Donation/payment flow.

Example commands:

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/dev
```

If Stripe CLI is used, document the webhook forwarding command.

## 17. Code Quality

Follow Rails conventions.

Prefer:

```text
skinny controllers
rich models/services where appropriate
RESTful routes
database constraints
clear naming
small methods
```

Do not introduce service objects, repositories, serializers, or additional architecture unless there is a concrete reason.

Use RuboCop if appropriate.

Avoid duplicated business logic.

Keep monetary calculations deterministic and integer-based.

## 18. Implementation Process

Work incrementally.

### Phase 1 — Rails Setup

Create/configure the Rails 7 application and database.

### Phase 2 — Models

Implement:

```text
Project
Donation
```

with migrations, associations, validations, and calculations.

### Phase 3 — Public UI

Implement:

```text
Projects#index
Projects#show
Donations#new
```

and the fundraising progress UI.

### Phase 4 — Stripe

Implement PaymentIntent creation and the payment UI using Stripe test mode.

### Phase 5 — Webhooks

Implement and verify Stripe webhooks.

### Phase 6 — Error Handling

Handle payment failures, validation errors, missing records, and webhook failures.

### Phase 7 — Tests

Add comprehensive automated tests.

### Phase 8 — Documentation

Finish the README and setup instructions.

## 19. Important Constraints

Do not:

* Use real Stripe payments.
* Store raw credit-card information.
* Store Stripe secret keys in source control.
* Trust payment status from the browser.
* Trust donation amounts from the client.
* Mark donations as successful without Stripe confirmation.
* Build authentication unless necessary.
* Build subscriptions.
* Build recurring donations.
* Build a complicated admin system.
* Build a separate frontend application.

The goal is a **small but properly engineered Rails 7 donation platform** demonstrating:

* Rails MVC.
* PostgreSQL.
* Active Record.
* RESTful routing.
* Form handling.
* Payment integration.
* Stripe PaymentIntents.
* Webhooks.
* Secure server-side validation.
* Testing.
* Clean UI.

## 20. Deliverables

At the end, provide:

1. Complete Rails application.
2. Database migrations.
3. Models.
4. Controllers.
5. Views.
6. Stripe integration.
7. Stripe webhook handling.
8. Routes.
9. Tests.
10. Seed data.
11. README.
12. `.env.example` if environment variables are used.
13. Any required Stripe setup instructions.

Before finishing, run:

```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails test
```

or the appropriate RSpec command if RSpec is selected.

Fix all errors found during implementation.

Finally, provide a concise summary of:

* What was implemented.
* Important architectural decisions.
* How Stripe payments work.
* How to run the application.
* How to test a donation locally.
* Any remaining limitations.
## 21. Incremental Git Commits

Use Git throughout the implementation. **Do not wait until the entire project is finished to make one large commit.**

Make small, logical commits after completing each stable milestone.

Use conventional, descriptive commit messages such as:

```text
chore: initialize Rails 7 application
feat: add project and donation models
feat: add fundraising progress calculation
feat: add public project pages
feat: add donation form
feat: integrate Stripe PaymentIntents
feat: add Stripe webhook handling
feat: add donation success and failure flows
test: add project and donation model tests
test: add Stripe payment and webhook tests
style: improve donation platform UI
docs: add setup and Stripe testing instructions
```

### Commit Rules

Before each commit:

1. Check the current Git status:

```bash
git status
```

2. Review the changes:

```bash
git diff
```

3. Run the relevant tests.

4. Make sure unrelated files or changes are not included.

5. Stage only the intended files:

```bash
git add <specific-files>
```

6. Create a focused commit:

```bash
git commit -m "feat: add project and donation models"
```

7. Verify the commit:

```bash
git status
git log -1 --oneline
```

### Commit Granularity

Prefer commits representing a single coherent change.

For example, do **not** create:

```text
feat: build entire donation platform
```

with dozens of unrelated changes.

Instead, use a progression similar to:

```text
chore: initialize Rails 7 application
feat: configure PostgreSQL database
feat: add project and donation models
feat: add project fundraising calculations
feat: add project listing page
feat: add project donation page
feat: add donation creation flow
feat: integrate Stripe PaymentIntents
feat: add Stripe webhook processing
test: add donation payment tests
test: add Stripe webhook tests
style: improve donation platform UI
docs: document local Stripe setup
```

### Important

Do not create meaningless commits such as:

```text
update
changes
fix stuff
final
misc
wip
```

Keep commits independently understandable and preferably buildable/testable.

If a bug is discovered during implementation, fix it in a separate focused commit when practical, for example:

```text
fix: prevent duplicate Stripe webhook processing
fix: cap fundraising progress at 100 percent
fix: validate donation amount server side
```

Do not rewrite, squash, or delete previous commits unless explicitly instructed.

At the end, show the final commit history with:

```bash
git log --oneline --decorate -n 20
```

The implementation should therefore leave behind a clear Git history that demonstrates the project's development progression rather than a single large final commit.
