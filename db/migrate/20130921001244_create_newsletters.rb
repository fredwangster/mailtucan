class CreateNewsletters < ActiveRecord::Migration
  def up
  	create_table :newsletters do |t|
  		t.string :fb_id
  		t.belongs_to :page
  		t.belongs_to :template
  	end
  end

  def down
  	drop_table :newsletters
  end
end
