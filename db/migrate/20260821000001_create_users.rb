class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, null: false, default: "donor"

      t.timestamps
    end

    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
    add_index :users, :role
    add_check_constraint :users,
                         "role IN ('donor', 'project_manager', 'admin')",
                         name: "users_role_allowed"
  end
end
