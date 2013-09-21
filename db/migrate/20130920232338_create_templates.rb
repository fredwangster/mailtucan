class CreateTemplates < ActiveRecord::Migration
  def up
  	create_table :templates do |t|
  		t.string :template_name
  		t.string :template_filename
  	end
  end

  def down
  	drop_table :templates
  end
end
