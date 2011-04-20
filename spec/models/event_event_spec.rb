require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventEvent do
  it "should require a name and type" do
    @event = EventEvent.new
    @event.should have(1).error_on(:event_type_id)
    @event.should have(1).error_on(:name)
  end
  
  it "should require a valid start time" do
    @event = EventEvent.new :event_type_id => 1, :name => 'Test', :start_time => -10
    @event.should have(1).error_on(:start_time)
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

  describe "Event Times" do
    before(:each) do
      @event_type = EventType.create :name => 'Birthdays'
      @april_20th_2011 = Time.at 1303272000
    end
    
    it "should be able to set the event_at" do
      @event = @event_type.event_events.create :name => 'Testers', :event_on => @april_20th_2011, :start_time => 720
      @event.event_at.should == Time.at(1303272000 + (720 * 60))
    end
    
    it "should be able to set the start and end times" do
      @event = @event_type.event_events.create :name => 'Testers', :starts_at => 1303272000, :ends_at => (1303272000 + (720 * 60))
      @event.event_at.should == @april_20th_2011
      @event.event_on.should == @april_20th_2011
      @event.start_time.should == nil
      @event.duration.should == 1440
    end
  end
end
