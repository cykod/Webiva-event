class EventEvent < DomainModel
  include ModelExtension::HandlerExtension

  belongs_to :parent, :class_name => 'EventEvent', :foreign_key => :parent_id
  has_many :children, :class_name => 'EventEvent', :foreign_key => :parent_id, :order => 'event_at', :dependent => :destroy

  belongs_to :event_type
  belongs_to :owner, :polymorphic => true
  has_end_user :end_user_id
  
  has_many :event_bookings, :dependent => :destroy
  has_many :event_repeats, :dependent => :delete_all
  
  handler :handler, :event, :type
  
  before_validation_on_create :set_defaults
  
  validates_presence_of :event_type_id
  validates_presence_of :permalink
  validates_presence_of :name

  validates_uniqueness_of :permalink

  before_save :set_event_at

  def self.calculate_start_time_options
    options = [['All day', nil]]
    period = 15
    (0..(1440/period - 1)).each do |idx|
      minutes = idx * period
      hour = minutes / 60
      meridiem = 'am'
      if hour >= 12
        meridiem = 'pm'
        hour -= 12 if hour > 12
      elsif hour == 0
        hour = 12
      end
      m = minutes % 60
      options << [sprintf("%02d:%02d %s", hour, m, meridiem), minutes]
    end
    options
  end

  @@start_time_options = self.calculate_start_time_options
  has_options :start_time, @@start_time_options

  def name
    return self[:name] if self[:name]
    self.parent.name if self.parent
  end

  def name=(name)
    self[:name] = name.blank? ? nil : name
  end

  def description
    return self[:description] if self[:description]
    self.parent.description if self.parent
  end

  def description=(description)
    self[:description] = description.blank? ? nil : description
  end

  def set_defaults
    self.event_type_id ||= self.parent.event_type_id if self.parent
    self.permalink = DomainModel.generate_hash if self.permalink.blank?
  end
  
  def set_event_at
    self.event_at = self.event_on + self.start_time.to_i.minutes if self.event_on
  end
end
