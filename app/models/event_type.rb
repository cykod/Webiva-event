class EventType < DomainModel
  include ModelExtension::HandlerExtension

  belongs_to :content_model
  has_domain_file :image_id

  has_many :event_events

  handler :handler, :event, :type
  
  validates_presence_of :name
  
end
