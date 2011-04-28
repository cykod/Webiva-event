class EventRepeat < DomainModel
  belongs_to :event_event
  
  validates_presence_of :event_event_id
  validates_presence_of :start_on
  validate :validate_start_on
  
  has_options :repeat_type, [['Daily', 'daily'], ['Weekly', 'weekly'], ['Biweekly', 'biweekly'], ['Monthly', 'monthly'], ['Yearly', 'yearly']], :validate => true

  before_create :set_last_generated_date

  def validate_start_on
    return unless self.event_event && self.start_on
    self.errors.add(:start_on, 'is invalid, must be greater than the event start') if self.start_on < self.event_event.event_on
  end

  def self.repeat_events
    end_time = (Time.now.at_midnight + 5.days).to_date
    self.where('start_on >= ? && last_generated_date <= ?', Time.now.at_midnight.to_date, end_time).all.each do |repeat|
      while repeat.last_generated_date <= end_time
        repeat.last_generated_date = repeat.next_start_on
        repeat.event_event.create_child_event repeat.last_generated_date
      end
      repeat.save
    end
  end
  
  def next_start_on
    from = self.last_generated_date

    case self.repeat_type
    when 'daily'
      from + 1.day
    when 'weekly'
      from + 1.week
    when 'monthly'
      from + 1.month
    when 'yearly'
      from + 1.year
    end
  end
  
  def set_last_generated_date
    self.last_generated_date = self.event_event.event_on
  end
end
