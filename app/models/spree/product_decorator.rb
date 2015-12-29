Spree::Product.class_eval do
  has_many :suppliers, through: :master

  def add_supplier!(supplier_or_id)
    supplier = supplier_or_id.is_a?(Spree::Supplier) ? supplier_or_id : Spree::Supplier.find(supplier_or_id)
    populate_for_supplier! supplier if supplier
  end

  def add_suppliers!(supplier_ids)
    Spree::Supplier.where(id: supplier_ids).each do |supplier|
      populate_for_supplier! supplier
    end
  end

  def supplier?
    suppliers.present?
  end

  private

  def populate_for_supplier!(supplier)
    variants_including_master.each do |variant|
      unless variant.suppliers.pluck(:id).include?(supplier.id)
        variant.suppliers << supplier
        supplier.stock_locations.each { |location| location.propagate_variant(variant) unless location.stock_items.pluck(:variant_id).include?(variant.id) }
      end
    end
  end
end
