class EventEvent < DomainModel
  attr_accessor :starts_at, :ends_at, :ends_on, :ends_time

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
  before_validation :set_event_at

  validates_presence_of :event_type_id
  validates_presence_of :permalink
  validates_presence_of :name
  validates_numericality_of :start_time, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :duration, :greater_than_or_equal_to => 0
  validates_uniqueness_of :permalink
  validate :validate_event_times
  validate :validate_custom_content

  after_save :update_custom_content
  
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

  def self.calculate_duration_options
    options = []
    period = 15
    (1..(360/period - 1)).each do |idx|
      minutes = (idx * period) % 60
      hour = (idx * period) / 60
      options << [sprintf("%02d:%02d hours/mins", hour, minutes), idx * period]
    end
    
    
    (6..23).each do |idx|
      options << ["#{idx} hours", idx*60]
    end
    options << ["1 day", 1440]
    (2..6).each do |idx|
      options << ["#{idx} days", idx*1440]
    end
    options << ["1 week", 10080]
    (2..4).each do |idx|
      options << ["#{idx} weeks", idx*10080]
    end
    options
  end
  
  @@duration_options = self.calculate_duration_options
  has_options :duration, @@duration_options

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

  def all_day_event?
    self.start_time.nil?
  end

  def set_defaults
    self.published ||= false
    self.duration ||= 0
    self.event_type_id ||= self.parent.event_type_id if self.parent
    self.permalink = DomainModel.generate_hash if self.permalink.blank?
    self.type_handler = self.event_type.type_handler if self.event_type
    true
  end
  
  def set_event_at
    if @ends_on && @ends_time
      @ends_at = @ends_on + @ends_time.to_i.minutes
      if self.all_day_event?
        @ends_at = @ends_at.at_beginning_of_day
        @ends_at += 1.day unless @starts_at
      end
    end

    if @starts_at
      if self.all_day_event? # all day event
        @starts_at = @starts_at.at_beginning_of_day
        @ends_at = (@ends_at || (@starts_at + self.duration.to_i.minutes)).at_beginning_of_day + 1.day
      end

      self.event_at = @starts_at
      @starts_at = nil
      self.event_on = self.event_at
      self.start_time = (self.event_at.to_i - self.event_at.at_midnight.to_i) / 60 if self.start_time
    else
      self.event_at = self.event_on + self.start_time.to_i.minutes if self.event_on
    end
    
    if @ends_at
      self.duration = (@ends_at.to_i - self.event_at.to_i) / 60
      @ends_at = nil
    end
  end
  
  def starts_at=(time)
    @starts_at = begin
                   case time
                   when Integer
                     Time.at(time)
                   when String
                     Time.parse(time)
                   when Time
                     time
                   end
                 end
  end

  def ends_at=(time)
    @ends_at = begin
                 case time
                 when Integer
                   Time.at(time)
                 when String
                   Time.parse(time)
                 when Time
                   time
                 end
               end
  end

  def ends_at
    return @ends_at if @ends_at
    return nil unless self.event_at
    if self.start_time
      self.event_at + self.duration.to_i.minutes
    else
      # all day event
      self.event_at + self.duration.to_i.minutes - 1.day
    end
  end
  
  def as_json(opts={})
    {
      :event_id => self.id,
      :title => self.name,
      :start => self.event_at,
      :allDay => self.start_time ? false : true,
      :end => self.ends_at,
      :parent_id => self.parent_id
    }
  end
  
  def move(days, minutes, all_day)
    @starts_at = self.event_at + days.days + minutes.minutes
    if self.all_day_event? && all_day == false && self.duration == 1440
      @ends_at = @starts_at + 2.hours
    else
      @ends_at = self.ends_at + days.days + minutes.minutes
    end
    self.start_time = all_day ? nil : 0
    self.save
  end
  
  def resize(days, minutes)
    @ends_at = self.ends_at + days.days + minutes.minutes
    @ends_at += 1.day if self.all_day_event?
    self.save
  end
  
  def ends_on
    self.ends_at
  end
  
  def ends_on=(time)
    @ends_on = begin
                 case time
                 when Integer
                   Time.at(time).at_beginning_of_day
                 when String
                   Time.parse(time).at_beginning_of_day
                 when Time
                   time.at_beginning_of_day
                 end
               end
  end

  def ends_time
    (self.ends_at.to_i - self.ends_at.at_midnight.to_i) / 60
  end
  
  def ends_time=(minutes)
    @ends_time = minutes.to_i
  end
  
  def validate_event_times
    if self.duration.to_i < 0 || (self.ends_at && self.event_at && self.event_at > self.ends_at)
      self.errors.add(:event_on, 'is invalid')
      self.errors.add(:start_time, 'is invalid')
      self.errors.add(:ends_on, 'is invalid')
      self.errors.add(:ends_time, 'is invalid')
      self.errors.add(:ends_at, 'is invalid')
    end
  end
  
  def content_model
    self.event_type.content_model if self.event_type
  end

  def relational_field
    self.event_type.relational_field if self.event_type
  end
  
  def content_data
    return nil unless self.content_model && self.relational_field
    return @content_data if @content_data
    @content_data = self.content_model.content_model.where(self.relational_field.field => self.id).first unless self.new_record?
    @content_data ||= self.content_model.content_model.new self.relational_field.field => self.id
  end
  
  def content_data=(hsh)
    self.content_data.attributes = hsh if self.content_data
  end

  def validate_custom_content
    if self.content_data
      self.errors.add(:content_data, 'is invalid') unless self.content_data.valid?
    end
  end
  
  def update_custom_content
    self.content_data.save if self.content_data
  end
  
  def type_handler
    return self[:type_handler] if self[:type_handler]
    self[:type_handler] = self.event_type.type_handler if self.event_type
    self[:type_handler]
  end
end
