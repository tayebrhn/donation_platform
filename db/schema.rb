# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_08_21_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "donations", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "donor_name", null: false
    t.string "donor_email", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "stripe_payment_intent_id"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_donations_on_project_id"
    t.index ["stripe_payment_intent_id"], name: "index_donations_on_stripe_payment_intent_id", unique: true, where: "(stripe_payment_intent_id IS NOT NULL)"
    t.check_constraint "amount_cents >= 100 AND amount_cents <= 1000000", name: "donations_amount_allowed"
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "donations_currency_format"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'succeeded'::character varying::text, 'failed'::character varying::text])", name: "donations_status_allowed"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.bigint "goal_amount_cents", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_projects_on_status"
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "projects_currency_format"
    t.check_constraint "goal_amount_cents > 0", name: "projects_goal_amount_positive"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'active'::character varying::text, 'completed'::character varying::text])", name: "projects_status_allowed"
  end

  create_table "stripe_webhook_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_stripe_webhook_events_on_event_type"
    t.index ["stripe_event_id"], name: "index_stripe_webhook_events_on_stripe_event_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", default: "donor", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.check_constraint "role::text = ANY (ARRAY['donor'::character varying, 'project_manager'::character varying, 'admin'::character varying]::text[])", name: "users_role_allowed"
  end

  add_foreign_key "donations", "projects"
end
