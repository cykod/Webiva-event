require File.expand_path("../../../../../../spec/spec_helper", __FILE__)
require File.expand_path("../../event_spec_helper", __FILE__)

describe EventBooking do
  it "should require an event and user" do
    @booking = EventBooking.new
    @booking.should have(1).error_on(:end_user_id)
    @booking.should have(1).error_on(:event_event_id)
    @booking.should have(1).error_on(:email)
  end
  
  describe "EventEvent" do
    before(:each) do
      @event = Factory.create :event_event
    end

    it "should be able to create an event booking" do
      expect {
        @booking = @event.event_bookings.create :email => 'fake@test.dev'
      }.to change{ EventBooking.count }
      @booking.end_user.should_not be_nil
      @booking.end_user.email.should == 'fake@test.dev'
    end

    it "should be able to create an event booking" do
      @user = EndUser.push_target 'fake@test.dev'
      expect {
        @booking = @event.event_bookings.create :end_user_id => @user.id
      }.to change{ EventBooking.count }
      @booking.end_user.should_not be_nil
      @booking.end_user.email.should == 'fake@test.dev'
    end
  end
end
