require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventRepeat do
  it "should require an event and user" do
    @repeat = EventRepeat.new
    @repeat.should have(1).error_on(:event_event_id)
    @repeat.should have(1).error_on(:start_on)
    @repeat.should have(1).error_on(:repeat_type)
  end
  
  describe "EventEvent" do
    before(:each) do
      @event = Factory.create :event_event
    end

    it "should be able to create an event repeat" do
      expect {
        @repeat = @event.event_repeats.create :repeat_type => 'daily', :start_on => Time.now
      }.to change{ EventRepeat.count }
    end
  end
end
