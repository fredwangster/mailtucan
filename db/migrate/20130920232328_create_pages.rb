class CreatePages < ActiveRecord::Migration
  def up
  	create_table :pages do |t|
  		t.string :fb_id
  		t.text :fb_data
  		t.datetime :send_last
  		t.datetime :send_next
  		t.string :url
  	end
  end

  def down
  end
end
