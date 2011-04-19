class EventEvent < DomainModel
  include ModelExtension::HandlerExtension

  belongs_to :event_type
  belongs_to :owner, :polymorphic => true
  has_end_user :end_user_id
  
  has_many :event_bookings, :dependent => :destroy
  has_many :event_repeats, :dependent => :delete_all
  
  handler :handler, :event, :type
  
  before_validation_on_create :set_defaults
  
  validates_presence_of :event_type_id
  validates_presence_of :name
  validates_presence_of :permalink
  
  validates_uniqueness_of :permalink

  def set_defaults
    self.permalink ||= DomainModel.generate_hash
  end
end
