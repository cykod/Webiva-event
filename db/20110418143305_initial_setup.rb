class InitialSetup < ActiveRecord::Migration
  def self.up
    create_table :event_types, :force => true do |t|
      t.string :name
      t.text :description
      t.integer :image_id
      t.integer :content_model_id
      t.integer :relational_field_id
      t.integer :content_publication_id
      t.string :type_handler
      t.timestamps
    end
    
    create_table :event_events, :force => true do |t|
      t.integer :event_type_id
      t.integer :parent_id

      # This would be the social unit
      t.string :owner_type
      t.integer :owner_id

      t.integer :end_user_id

      t.string :name
      t.text :description
      t.string :permalink

      t.string :address
      t.string :address_2
      t.string :city
      t.string :state
      t.string :zip
      
      t.decimal  :lon, :precision => 11, :scale => 6
      t.decimal  :lat, :precision => 11, :scale => 6
      
      t.integer :image_id
      
      t.date :event_on
      t.integer :start_time
      t.datetime :event_at
      
      t.integer :duration
      
      t.integer :total_allowed
      t.integer :spaces_left, :default => 0
      t.integer :bookings, :default => 0
      t.integer :unconfirmed_bookings, :default => 0
      t.datetime :last_unconfirmed_check

      t.boolean :notify_organizer, :default => true
      t.boolean :directory, :default => true
      t.boolean :allow_guests, :default => false
      t.boolean :published, :default => false
      
      t.string :type_handler
      t.text :data

      t.timestamps
    end
    
    create_table :event_bookings do |t|
      t.integer :event_event_id
      t.integer :end_user_id

      t.boolean :responded, :default => false
      t.boolean :attending, :default => false
      t.integer :total_booked, :default => 0
      t.integer :number, :default => 1
      
      t.timestamps
    end

    create_table :event_repeats, :force => true do |t|
      t.integer :event_event_id
      t.string :repeat_type
      t.integer :start_time
      t.date   :start_on
      t.date   :last_generated_date
    end
  end

  def self.down
    drop_table :event_types
    drop_table :event_events
    drop_table :event_bookings
    drop_table :event_repeats
  end
end
