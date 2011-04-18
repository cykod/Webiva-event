require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventEvent do
  it "should require a name and type" do
    @event = EventEvent.new
    @event.should have(1).error_on(:name)
    @event.should have(1).error_on(:event_type_id)
  end
  
  describe "EventType" do
    before(:each) do
      @event_type = EventType.create :name => 'Birthdays'
    end

    it "should be able to create an event type" do
      expect {
        @event = @event_type.event_events.create :name => 'Testers'
      }.to change{ EventEvent.count }
    end
  end
end
