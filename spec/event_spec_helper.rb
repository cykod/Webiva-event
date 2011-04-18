
Factory.define :event_type do |d|
  d.sequence(:name) { |n| "Event Type #{n}" }
end

Factory.define :event_event do |d|
  d.sequence(:name) { |n| "Event #{n}" }
  d.association :event_type, :factory => :event_type
end
