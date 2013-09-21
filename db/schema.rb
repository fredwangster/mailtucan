# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130921001244) do

  create_table "newsletters", force: true do |t|
    t.string  "fb_id"
    t.integer "page_id"
    t.integer "template_id"
  end

  create_table "pages", force: true do |t|
    t.string   "fb_id"
    t.text     "fb_data"
    t.datetime "send_last"
    t.datetime "send_next"
    t.string   "url"
  end

  create_table "subscribers", force: true do |t|
    t.string "subscriber_name"
    t.string "subscriber_email"
  end

  create_table "subscriptions", force: true do |t|
    t.boolean "active"
    t.integer "subscriber_id"
    t.integer "newsletter_id"
  end

  create_table "templates", force: true do |t|
    t.string "template_name"
    t.string "template_filename"
  end

end
