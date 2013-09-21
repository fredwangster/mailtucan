class CreateSubscriptions < ActiveRecord::Migration
  def up
  	create_table :subscriptions do |t|
  		t.boolean :active
  		t.belongs_to :subscriber
  		t.belongs_to :newsletter
  	end
  end

  def down
  	drop_table :subscriptions
  end
end
