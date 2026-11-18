# Append-only consent log: what was agreed, which version, when, and if withdrawn.
class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string   :purpose, null: false
      t.string   :version, null: false
      t.datetime :granted_at, null: false
      t.datetime :withdrawn_at
      t.timestamps
    end
    add_index :consents, [ :user_id, :purpose ]
  end
end
