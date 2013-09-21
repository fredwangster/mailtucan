class CreateSubscribers < ActiveRecord::Migration
  def up
  	create_table :subscribers do |t|
  		t.string :subscriber_name
  		t.string :subscriber_email
  	end
  end

  def down
  	drop_table :subscribers
  end
end
