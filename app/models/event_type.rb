class EventType < DomainModel
  belongs_to :content_model
  belongs_to :content_publication
  belongs_to :relational_field, :class_name => 'ContentModelField'
  has_domain_file :image_id

  has_many :event_events, :dependent => :destroy

  before_validation :set_relational_field

  validates_presence_of :name
  validate :validate_content_model
  validate :validate_handler

  def self.default
    EventType.where(:name => 'Default').order('created_at').first || EventType.create(:name => 'Default')
  end
  
  def build_event(opts={})
    event = self.event_events.new opts
    event.type_handler = self.type_handler unless self.type_handler.blank?
    event
  end
  
  def set_relational_field
    if self.content_model.nil?
      self.content_model_id = nil
      self.relational_field_id = nil
    elsif self.relational_field.nil? || self.relational_field.content_model_id != self.content_model_id
      self.relational_field_id = nil
      fld = self.content_model.content_model_fields.where(:field_type => 'belongs_to').all.detect { |fld| fld.relation_class_name == 'Other' }
      self.relational_field_id = fld.id if fld
    end
  end
  
  def validate_content_model
    if self.content_model && self.relational_field_id.nil?
      self.errors.add(:content_model_id, "is invalid, missing belongs_to relation")
      self.errors.add(:relational_field_id, "is invalid")
    end
  end
  
  def validate_handler
    return if self.type_handler.blank?
    self.errors.add(:type_handler, 'is invalid') unless self.get_handler_info(:event, :type, self.type_handler)
  end
end
