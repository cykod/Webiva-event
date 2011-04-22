class EventBooking < DomainModel
  class NoSpaceException < Exception; end
  
  attr_accessor :email, :name

  belongs_to :event_event
  has_end_user :end_user_id, :name_column => :name

  validate :validate_user
  validates_presence_of :event_event_id
  validates_uniqueness_of :end_user_id, :scope => :event_event_id
  validate :validate_attendance

  before_save :set_end_user
  before_save :update_attendance
  
  named_scope :responded, where(:responded => true)
  named_scope :not_responded, where(:responded => false)
  named_scope :attending, where(:attending => true)
  named_scope :not_attending, where(:attending => false)

  def self.stats
    self.select('SUM(IF(responded=1 && attending=1,number, 0)) AS bookings, SUM(IF(responded=0,number, 0)) AS unconfirmed_bookings')
  end

  def name
    return @name if @name
    self.end_user.name if self.end_user
  end

  def email
    return @email if @email
    self.end_user.email if self.end_user
  end

  def validate_user
    user = EndUser.where(:email => @email).first unless @email.blank?
    self.end_user_id = user.id if user
    if self.end_user.nil?
      self.errors.add(:email, 'is missing') if @email.blank?
      self.errors.add(:name, 'is missing') if @name.blank?
    end
  end

  def set_end_user
    return if @email.blank?
    user = EndUser.push_target @email, :name => self.name
    user ? self.end_user_id = user.id : false
  end
  
  def validate_attendance
    self.errors.add(:number, 'is invalid, no guest allowed') unless self.number <= 1 || self.event_event.allow_guests
    self.errors.add(:number, 'is invalid, no space left') if (self.number - self.total_booked) > self.event_event.spaces_left
  end

  def update_attendance
    if self.responded
      if self.new_record?
        if self.attending
          self.total_booked = self.number
          raise NoSpaceException.new("No space left") unless self.event_event.remove_space(self.total_booked)
        end
      elsif self.attending
        amount = self.number - self.total_booked
        if amount > 0
          raise NoSpaceException.new("No space left") unless self.event_event.remove_space(amount)
        elsif amount < 0
          self.event_event.add_space(amount.abs)
        end
        self.total_booked = self.number
      else
        self.event_event.add_space(self.total_booked) if self.total_booked > 0
        self.total_booked = 0
      end
    end
  end
end
