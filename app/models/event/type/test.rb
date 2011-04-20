class Event::Type::Test < HashModel
  def self.event_type_handler_info
    {
      :name => 'Test Hanlder for Events'
    }
  end

  attributes :name => nil, :description => nil
  
  validates_presence_of :name
  
  options_form(
               fld(:name, :text_field, :required => true),
               fld(:description, :text_area, :rows => 2)
               )
end
