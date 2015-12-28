class RemoveSuppliersFromCkeditorAssets < ActiveRecord::Migration
  if table_exists?(:ckeditor_assets)
    def change
      remove_column :ckeditor_assets, :supplier_id, :integer
      remove_index :ckeditor_assets, :supplier_id if index_exists?(:ckeditor_assets, :supplier_id)
    end
  end
end
