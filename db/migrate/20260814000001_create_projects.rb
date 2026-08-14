class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.bigint :goal_amount_cents, null: false
      t.string :currency, limit: 3, null: false, default: "USD"
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :projects, :status
    add_check_constraint :projects, "goal_amount_cents > 0", name: "projects_goal_amount_positive"
    add_check_constraint :projects, "currency ~ '^[A-Z]{3}$'", name: "projects_currency_format"
    add_check_constraint :projects,
                         "status IN ('draft', 'active', 'completed')",
                         name: "projects_status_allowed"
  end
end
