class AddCategoryToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :category, :int
    add_column :reports, :rule_ids, :bigint, array: true
  end
end
