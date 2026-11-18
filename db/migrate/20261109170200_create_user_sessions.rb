# Server-side record of each signed-in browser, so sessions can be listed and revoked.
class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string   :token_digest, null: false          # SHA-256 of the random token kept in the cookie session
      t.string   :user_agent, limit: 255
      t.string   :ip_hash, limit: 64                 # keyed hash, not the raw IP
      t.datetime :last_seen_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :user_sessions, :token_digest, unique: true
    add_index :user_sessions, [ :user_id, :revoked_at ]
  end
end
