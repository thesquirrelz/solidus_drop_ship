class Spree::Supplier < Spree::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  attr_accessor :password, :password_confirmation

  belongs_to :address, class_name: 'Spree::Address'
  accepts_nested_attributes_for :address

  has_many :products, through: :variants
  has_many :shipments, through: :stock_locations
  has_many :stock_locations
  has_many :supplier_variants
  has_many :users, class_name: Spree.user_class.to_s
  has_many :variants, through: :supplier_variants

  validates :commission_flat_rate, presence: true
  validates :commission_percentage, presence: true
  validates :email, presence: true, email: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :url, format: { with: URI::regexp(%w(http https)), allow_blank: true }

  after_create :assign_user
  after_create :create_stock_location
  after_create :send_welcome, if: -> { SpreeDropShip::Config[:send_supplier_email] }
  before_create :set_commission
  before_validation :check_url

  scope :active, -> { where(active: true) }

  def deleted?
    deleted_at.present?
  end

  def user_ids_string
    user_ids.join(',')
  end

  def user_ids_string=(s)
    self.user_ids = s.to_s.split(',').map(&:strip)
  end

  def stock_locations_with_available_stock_items(variant)
    stock_locations.select { |sl| sl.available?(variant) }
  end

  protected

  def assign_user
    if self.users.empty? && user = Spree.user_class.find_by_email(self.email)
      self.users << user
      self.save
    end
  end

  def check_url
    self.url = "http://#{self.url}" unless self.url.blank? || self.url =~ URI::regexp(%w(http https))
  end

  def create_stock_location
    if self.stock_locations.empty?
      location = self.stock_locations.build(active: true, country_id: self.address.try(:country_id), name: self.name, state_id: self.address.try(:state_id))
      location.save validate: false
    end
  end

  def send_welcome
    begin
      Spree::SupplierMailer.welcome(self.id).deliver_later!
      # Specs raise error for not being able to set default_url_options[:host]
    rescue => ex
      Rails.logger.error ex.message
      Rails.logger.error ex.backtrace.join("\n")
      return true
    end
  end

  def set_commission
    self.commission_flat_rate = SpreeDropShip::Config[:default_commission_flat_rate] unless changes.has_key?(:commission_flat_rate)
    self.commission_percentage = SpreeDropShip::Config[:default_commission_percentage] unless changes.has_key?(:commission_percentage)
  end
end
