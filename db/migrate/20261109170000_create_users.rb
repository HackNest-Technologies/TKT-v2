class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext"

    create_table :users do |t|
      # Identity
      t.citext   :email,              null: false
      t.string   :encrypted_password, null: false, default: ""
      t.citext   :handle                                   # chosen after sign-up
      t.integer  :birth_year                               # 16+ policy; nothing else about age is stored
      t.datetime :terms_accepted_at
      t.datetime :sensitive_data_consent_at                # consent to processing religious-affiliation data

      # Devise: recoverable, rememberable, confirmable, lockable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.citext   :unconfirmed_email
      t.integer  :failed_attempts, null: false, default: 0
      t.string   :unlock_token
      t.datetime :locked_at

      # Lifecycle
      t.datetime :deletion_requested_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :handle, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true
    add_index :users, :deletion_requested_at, where: "deletion_requested_at IS NOT NULL"

    add_check_constraint :users, "handle IS NULL OR handle ~ '^[A-Za-z0-9_]{3,20}$'", name: "users_handle_format"
    add_check_constraint :users, "birth_year IS NULL OR birth_year BETWEEN 1900 AND 2100", name: "users_birth_year_range"
  end
end
