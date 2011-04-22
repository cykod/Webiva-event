class EventBooking < DomainModel
  attr_accessor :email, :name

  belongs_to :event_event
  has_end_user :end_user_id

  validates_presence_of :event_event_id
  validate :validate_user
  
  before_save :set_end_user
  after_save :update_event
  
  named_scope :responded, where(:responded => true)
  named_scope :not_responded, where(:responded => false)
  named_scope :attending, where(:attending => true)
  named_scope :not_attending, where(:attending => false)

  def self.stats
    self.select('SUM(IF(responded=1 && attending=1,number, 0)) AS bookings, SUM(IF(responded=0,1, 0)) AS unconfirmed_bookings')
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
    if @email.blank? && self.end_user.nil?
      self.errors.add(:end_user_id, 'is missing')
      self.errors.add(:email, 'is missing')
    end
  end

  def set_end_user
    return if @email.blank?
    user = EndUser.push_target @email, :name => self.name
    user ? self.end_user_id = user.id : false
  end
  
  def update_event
    self.event_event.update_attendance
  end
end
