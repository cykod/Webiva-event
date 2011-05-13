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
  before_validation :set_permalink

  validates_presence_of :event_type_id
  validates_presence_of :permalink
  validates_presence_of :name
  validates_presence_of :event_on
  validates_numericality_of :start_time, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :duration, :greater_than_or_equal_to => 0
  validates_uniqueness_of :permalink
  validate :validate_event_times
  validate :validate_custom_content

  after_save :update_custom_content
  after_save :update_spaces

  named_scope :published, where(:published => true)
  named_scope :directory, where(:directory => true) # wether or not to display the event in the list paragraph

  def self.for_owner(owner,include_others=false)
    owner_type,owner_id = case owner
    when DomainModel
      [ owner.class.to_s, owner.id ]
    when Array
      [ owner[0].to_s, owner[1] ] 
    else
      return self
    end

    if include_others
      self.where("((owner_type = ? and owner_id = ?) OR owner_type is NULL)",owner_type,owner_id)
    else
      self.where(:owner_type => owner_type, :owner_id => owner_id)
    end
  end

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

  def all_day_event?
    self.start_time.nil?
  end

  def set_defaults
    if self.parent
      self.event_type_id ||= self.parent.event_type_id
      self.published ||= self.parent.published
      self.owner_type ||= self.parent.owner_type
      self.owner_id ||= self.parent.owner_id
    end

    self.published ||= false
    self.duration ||= 0
    self.permalink = DomainModel.generate_hash if self.permalink.blank?
    self.type_handler = self.event_type.type_handler if self.event_type
    true
  end
  
  def generate_permalink
    return self.permalink unless self.permalink.blank? && self.event_on && self.name
    base_url = self.event_on.strftime("%Y-%m-%d") + '-' + SiteNode.generate_node_path(self.name)
    test_url = base_url
    cnt = 2
    while(EventEvent.where(:permalink => test_url).first) do
      test_url = "#{base_url}-#{cnt}"
      cnt += 1
    end
    test_url
  end

  def set_permalink
    self.permalink = self.generate_permalink
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
    elsif self.all_day_event?
      self.duration = 1440
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
    data = {
      :event_id => self.id,
      :title => self.published ? self.name : "* #{self.name}",
      :start => self.event_at,
      :allDay => self.start_time ? false : true,
      :end => self.ends_at,
      :parent_id => self.parent_id
    }
    data[:url] = opts[:event_node].link(self.permalink) if opts[:event_node]
    data
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
    if self.ends_at
      (self.ends_at.to_i - self.ends_at.at_midnight.to_i) / 60
    else
      self.start_time
    end
  end
  
  def ends_time=(minutes)
    @ends_time = minutes.to_i
  end
  
  def ended?
    return false unless self.ends_at
    time = self.ends_at
    time += 1.day if self.all_day_event?
    time <= Time.now
  end

  def started?
    self.event_at && self.event_at > Time.now
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

  def get_field(fld)
    return self[fld] unless self[fld].blank?
    self.parent.send(fld) if self.parent
  end

  %w(name description address address_2 city state zip lon lat image_id).each do |fld|
    self.send(:define_method, fld) do
      get_field fld
    end
  end
  
  def attendance
    @attendance ||= self.event_bookings.includes(:end_user).order('responded DESC, attending DESC').all
  end


  def event_month
    @event_month ||= self.event_at.at_beginning_of_month
  end
  
  def can_book?
    self.spaces_left > 0
  end

  def add_space(quantity)
    quantity = quantity.to_i
    affected_rows = self.connection.update "UPDATE event_events SET spaces_left = spaces_left + #{quantity}, bookings = bookings - #{quantity} WHERE id = #{self.id}"
    return false unless affected_rows == 1
    self.spaces_left += quantity
    self.bookings -= quantity
    true
  end

  def remove_space(quantity)
    quantity = quantity.to_i
    affected_rows = self.connection.update "UPDATE event_events SET spaces_left = spaces_left - #{quantity}, bookings = bookings + #{quantity} WHERE id = #{self.id} AND (spaces_left - #{quantity}) >= 0"
    return false unless affected_rows == 1
    self.spaces_left -= quantity
    self.bookings += quantity
    true
  end
  
  def total_allowed=(amount)
    amount = amount.to_i
    @total_allowed_changed = amount - self[:total_allowed].to_i
    self[:total_allowed] = amount
  end
  
  def update_spaces
    return if @total_allowed_changed.to_i == 0
    self.connection.update "UPDATE event_events SET spaces_left = spaces_left + #{@total_allowed_changed} WHERE id = #{self.id}"
  end
  
  def location
    [self.address, self.address_2, "#{self.city}, #{self.state} #{self.zip}"].reject(&:blank?).map(&:strip).compact.join(', ')
  end
end
