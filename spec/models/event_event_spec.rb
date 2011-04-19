require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventEvent do
  it "should require a name and type" do
    @event = EventEvent.new
    @event.valid?
    @event.should have(1).error_on(:event_type_id)
    @event.should have(1).error_on(:name)
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
  
  describe "Event" do
    before(:each) do
      @event = Factory.create :event_event
    end
    
    it "should be able to create child events" do
      expect {
        @child_event = @event.children.create
      }.to change{ EventEvent.count }
      @event.name.should == @child_event.name
      @event.description.should == @child_event.description
    end
  end
end
