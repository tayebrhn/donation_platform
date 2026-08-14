class CreateDonations < ActiveRecord::Migration[7.1]
  def change
    create_table :donations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :donor_name, null: false
      t.string :donor_email, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, limit: 3, null: false, default: "USD"
      t.string :stripe_payment_intent_id
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :donations,
              :stripe_payment_intent_id,
              unique: true,
              where: "stripe_payment_intent_id IS NOT NULL"
    add_check_constraint :donations,
                         "amount_cents BETWEEN 100 AND 1000000",
                         name: "donations_amount_allowed"
    add_check_constraint :donations, "currency ~ '^[A-Z]{3}$'", name: "donations_currency_format"
    add_check_constraint :donations,
                         "status IN ('pending', 'succeeded', 'failed')",
                         name: "donations_status_allowed"
  end
end
