class EventRepeat < DomainModel
  belongs_to :event_event
  
  validates_presence_of :event_event_id
  validates_presence_of :start_on

  has_options :repeat_type, [['Daily', 'daily'], ['Weekly', 'weekly'], ['Biweekly', 'biweekly'], ['Monthly', 'monthly'], ['Yearly', 'yearly']], :validate => true

end
