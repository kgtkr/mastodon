class CreateAccountStrikes < ActiveRecord::Migration[6.1]
  def change
    create_table :account_strikes do |t|
      t.belongs_to :account, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :report, null: true, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :account_strikes, [:account_id, :report_id], unique: true, where: 'report_id is not null'
  end
end
