require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventEvent do
  it "should require a name and type" do
    @event = EventEvent.new
    @event.should have(1).error_on(:event_type_id)
    @event.should have(1).error_on(:name)
    @event.should have(1).error_on(:event_on)
  end
  
  it "should require a valid start time" do
    @event = EventEvent.new :event_type_id => 1, :name => 'Test', :start_time => -10
    @event.should have(1).error_on(:start_time)
  end

  describe "EventType" do
    before(:each) do
      @event_type = Factory.create :event_type
    end

    it "should be able to create an event type" do
      expect {
        @event = @event_type.event_events.create :name => 'Testers', :event_on => Time.now
      }.to change{ EventEvent.count }
    end
  end
  
  describe "Event" do
    before(:each) do
      @event = Factory.create :event_event
    end
    
    it "should be able to create child events" do
      expect {
        @child_event = @event.children.create :event_on => Time.now
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
    
    it "should be able to set the start and end times for all day event" do
      @event = @event_type.event_events.create :name => 'Testers', :starts_at => 1303272000, :ends_at => (1303272000 + (720 * 60))
      @event = EventEvent.find @event.id
      @event.event_at.should == @april_20th_2011
      @event.event_on.should == @april_20th_2011.to_date
      @event.start_time.should be_nil
      @event.duration.should == 1440
      @event.ends_at.should == @april_20th_2011
    end

    it "should be able to set the start and end times for all day event" do
      @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => nil, :ends_on => '04/20/2011', :ends_time => 720
      @event = EventEvent.find @event.id
      @event.event_at.should == @april_20th_2011
      @event.event_on.should == @april_20th_2011.to_date
      @event.start_time.should be_nil
      @event.duration.should == 1440
      @event.ends_at.should == @april_20th_2011
    end

    it "should be able to set the start and end times" do
      @event = @event_type.event_events.create :name => 'Testers', :starts_at => 1303272000, :ends_at => (1303272000 + (720 * 60)), :start_time => 0
      @event = EventEvent.find @event.id
      @event.event_at.should == @april_20th_2011
      @event.event_on.should == @april_20th_2011.to_date
      @event.start_time.should == 0
      @event.duration.should == 720
    end
    
    it "should be able to set the start and end times" do
      @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => 0, :ends_on => '04/20/2011', :ends_time => 720
      @event = EventEvent.find @event.id
      @event.event_at.should == @april_20th_2011
      @event.event_on.should == @april_20th_2011.to_date
      @event.start_time.should == 0
      @event.duration.should == 720
      @event.ends_at.should == (@april_20th_2011 + 720.minutes)
    end
    
    describe "Move Events" do
      it "should be able to move an event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => 0, :ends_on => '04/20/2011', :ends_time => 720
        @event = EventEvent.find @event.id
        @event.move -1, 60, false
        @event = EventEvent.find @event.id
        @start_time = @april_20th_2011 - 1.day + 60.minutes
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should == 60
        @event.duration.should == 720
        @event.ends_at.should == (@start_time + 720.minutes)
      end
      
      it "should be able to move an event to an all day event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => 0, :ends_on => '04/20/2011', :ends_time => 720
        @event.all_day_event?.should be_false
        @event = EventEvent.find @event.id
        @event.move -1, 0, true
        @event = EventEvent.find @event.id
        @event.all_day_event?.should be_true
        @start_time = @april_20th_2011 - 1.day
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should be_nil
        @event.duration.should == 1440
        @event.ends_at.should == @start_time
      end

      it "should be able to move an all day event to a time event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => nil, :ends_on => '04/20/2011', :ends_time => 720
        @event.all_day_event?.should be_true
        @event = EventEvent.find @event.id
        @event.move -1, 60, false
        @event = EventEvent.find @event.id
        @event.all_day_event?.should be_false
        @start_time = @april_20th_2011 - 1.day + 60.minutes
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should == 60
        @event.duration.should == 120
        @event.ends_at.should == (@start_time + 120.minutes)
      end
      
      it "should be able to move an all day event to a time event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => nil, :ends_on => '04/22/2011', :ends_time => 0
        @event.all_day_event?.should be_true
        @event.duration.should == 4320
        @event = EventEvent.find @event.id
        @event.move -1, 60, false
        @event = EventEvent.find @event.id
        @event.all_day_event?.should be_false
        @start_time = @april_20th_2011 - 1.day + 60.minutes
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should == 60
        @event.duration.should == 2880
        @event.ends_at.should == (@start_time + 2.days)
      end
    end

    describe "Resize Events" do
      it "should be able to resize an all day event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => nil, :ends_on => '04/22/2011', :ends_time => 0
        @event.all_day_event?.should be_true
        @event.duration.should == 4320
        @event = EventEvent.find @event.id
        @event.resize 4, 0
        @event = EventEvent.find @event.id
        @event.all_day_event?.should be_true
        @start_time = @april_20th_2011
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should == nil
        @event.duration.should == 1440 * 7
        @event.ends_at.should == (@start_time + 6.days)
      end

      it "should be able to resize an all day event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => nil, :ends_on => '04/22/2011', :ends_time => 0
        @event.all_day_event?.should be_true
        @event.duration.should == 4320
        @event = EventEvent.find @event.id
        @event.resize -2, 0
        @event = EventEvent.find @event.id
        @event.all_day_event?.should be_true
        @start_time = @april_20th_2011
        @event.event_at.should == @start_time
        @event.event_on.should == @start_time.to_date
        @event.start_time.should == nil
        @event.duration.should == 1440
        @event.ends_at.should == @start_time
      end
      
      it "should be able to resize an event" do
        @event = @event_type.event_events.create :name => 'Testers', :event_on => '04/20/2011', :start_time => 0, :ends_on => '04/20/2011', :ends_time => 720
        @event.all_day_event?.should be_false
        @event.duration.should == 720
        @event = EventEvent.find @event.id
        @event.resize 1, 30
        @event = EventEvent.find @event.id
        @event.event_at.should == @april_20th_2011
        @event.event_on.should == @april_20th_2011.to_date
        @event.start_time.should == 0
        @event.duration.should == 2190
        @event.ends_at.should == (@april_20th_2011 + 2190.minutes)
      end
    end
  end
end
