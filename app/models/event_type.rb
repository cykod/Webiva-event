class EventType < DomainModel

  belongs_to :content_model
  has_domain_file :image_id

  has_many :event_events

  validates_presence_of :name
  
end
