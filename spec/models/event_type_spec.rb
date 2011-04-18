require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventType do
  it "should require a name" do
    @event_type = EventType.new
    @event_type.should have(1).error_on(:name)
  end
  
  it "should be able to create an event type" do
    expect {
      @event_type = EventType.create :name => 'Birthdays'
    }.to change{ EventType.count }
  end
end
