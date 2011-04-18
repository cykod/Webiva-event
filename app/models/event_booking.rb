class EventBooking < DomainModel
  attr_accessor :email

  belongs_to :event_event
  has_end_user :end_user_id

  validates_presence_of :event_event_id
  validate :validate_user
  
  before_save :set_end_user

  def name
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
    user = EndUser.push_target @email
    user ? self.end_user_id = user.id : false
  end
end
