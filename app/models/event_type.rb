class EventType < DomainModel
  belongs_to :content_model
  has_domain_file :image_id

  has_many :event_events, :dependent => :destroy

  validates_presence_of :name
  
  def self.default
    EventType.where(:name => 'Default').order('created_at').first || EventType.create(:name => 'Default')
  end
end
