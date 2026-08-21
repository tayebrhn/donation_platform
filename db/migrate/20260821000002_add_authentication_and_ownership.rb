class AddAuthenticationAndOwnership < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
    end

    add_index :users, :reset_password_token, unique: true
    add_reference :donations, :user, foreign_key: true
    add_reference :projects, :project_manager, foreign_key: { to_table: :users }
  end
end
