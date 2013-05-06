# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130503230210) do

  create_table "club_categories", :force => true do |t|
    t.string "name"
  end

  create_table "clubs", :force => true do |t|
    t.text    "name",             :limit => 255
    t.string  "acronym",          :limit => 8
    t.text    "location",         :limit => 255
    t.text    "description"
    t.text    "url",              :limit => 255
    t.float   "lat"
    t.float   "lng"
    t.string  "country"
    t.text    "timezone",         :limit => 255
    t.boolean "visible",                         :default => false,     :null => false
    t.string  "domain"
    t.integer "parent_id"
    t.integer "club_category_id"
    t.string  "layout",                          :default => "default", :null => false
    t.text    "facebook_page_id", :limit => 255
  end

  add_index "clubs", ["club_category_id"], :name => "club_category_id"

  create_table "configuration", :force => true do |t|
    t.string  "key"
    t.string  "value"
    t.integer "club_id"
  end

  add_index "configuration", ["club_id"], :name => "club_id"

  create_table "content_blocks", :force => true do |t|
    t.string  "key"
    t.text    "content"
    t.integer "order",   :default => 1
    t.integer "club_id"
  end

  add_index "content_blocks", ["club_id"], :name => "club_id"
  add_index "content_blocks", ["key"], :name => "key"

  create_table "courses", :force => true do |t|
    t.integer "event_id"
    t.text    "name",        :limit => 255
    t.integer "distance"
    t.integer "climb"
    t.text    "description"
    t.text    "map_url",     :limit => 255
    t.boolean "is_score_o",                 :default => false, :null => false
  end

  add_index "courses", ["event_id"], :name => "event_id"

  create_table "cross_app_sessions", :force => true do |t|
    t.integer  "user_id",              :null => false
    t.string   "cross_app_session_id", :null => false
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "cross_app_sessions", ["cross_app_session_id"], :name => "index_cross_app_sessions_on_cross_app_session_id", :unique => true
  add_index "cross_app_sessions", ["user_id"], :name => "index_cross_app_sessions_on_user_id", :unique => true

  create_table "event_classifications", :force => true do |t|
    t.string "name",           :limit => 50
    t.string "iof_3_0_name",   :limit => 50
    t.string "iof_2_0_3_name", :limit => 50
    t.string "description",    :limit => 100
  end

  create_table "events", :force => true do |t|
    t.text     "name",                    :limit => 255
    t.integer  "map_id"
    t.integer  "series_id"
    t.datetime "date"
    t.float    "lat"
    t.float    "lng"
    t.boolean  "is_ranked",                              :default => false, :null => false
    t.text     "description"
    t.boolean  "results_posted",                         :default => false, :null => false
    t.integer  "club_id"
    t.string   "custom_url"
    t.integer  "event_classification_id"
    t.datetime "finish_date"
    t.integer  "number_of_participants"
  end

  add_index "events", ["club_id"], :name => "club_id"
  add_index "events", ["event_classification_id"], :name => "event_classification_id"
  add_index "events", ["map_id"], :name => "map_id"
  add_index "events", ["series_id"], :name => "series_id"

  create_table "groups", :force => true do |t|
    t.text    "name",         :limit => 255
    t.integer "access_level"
    t.text    "description"
    t.integer "club_id"
  end

  add_index "groups", ["club_id"], :name => "club_id"

  create_table "map_standards", :force => true do |t|
    t.text "name",        :limit => 255
    t.text "description"
  end

  create_table "maps", :force => true do |t|
    t.text     "name",            :limit => 255
    t.integer  "map_standard_id"
    t.datetime "created"
    t.datetime "modified"
    t.integer  "scale"
    t.float    "lat"
    t.float    "lng"
    t.text     "repository_path", :limit => 255
    t.integer  "club_id"
  end

  add_index "maps", ["club_id"], :name => "club_id"
  add_index "maps", ["map_standard_id"], :name => "map_standard_id"

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "year"
    t.datetime "created"
    t.integer  "club_id"
  end

  add_index "memberships", ["user_id"], :name => "user_id"

  create_table "official_classifications", :force => true do |t|
    t.string "name",        :limit => 40,  :default => "", :null => false
    t.string "description", :limit => 100
  end

  create_table "officials", :force => true do |t|
    t.integer  "user_id",                    :null => false
    t.integer  "official_classification_id", :null => false
    t.datetime "date"
  end

  add_index "officials", ["official_classification_id"], :name => "official_classification_id"
  add_index "officials", ["user_id"], :name => "user_id"

  create_table "organizers", :force => true do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.integer "role_id"
  end

  add_index "organizers", ["event_id"], :name => "event_id"
  add_index "organizers", ["role_id"], :name => "role_id"
  add_index "organizers", ["user_id"], :name => "user_id"

  create_table "pages", :force => true do |t|
    t.string  "name"
    t.string  "section"
    t.text    "content"
    t.integer "club_id"
  end

  add_index "pages", ["club_id"], :name => "club_id"

  create_table "privileges", :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "privileges", ["group_id"], :name => "group_id"
  add_index "privileges", ["user_id"], :name => "user_id"

  create_table "resources", :force => true do |t|
    t.string  "caption"
    t.string  "url"
    t.string  "key"
    t.integer "club_id"
    t.integer "course_id"
    t.integer "map_id"
    t.string  "thumbnail_50_url"
    t.string  "thumbnail_100_url"
    t.string  "thumbnail_500_url"
    t.string  "thumbnail_1000_url"
    t.string  "thumbnail_1300_url"
    t.string  "thumbnail_2600_url"
  end

  add_index "resources", ["club_id"], :name => "club_id"
  add_index "resources", ["course_id"], :name => "course_id"
  add_index "resources", ["key"], :name => "key"
  add_index "resources", ["map_id"], :name => "map_id"

  create_table "results", :force => true do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.integer "points"
    t.boolean "needs_ride",                  :default => false, :null => false
    t.boolean "offering_ride",               :default => false, :null => false
    t.string  "status",        :limit => 50, :default => "ok",  :null => false
    t.integer "registrant_id"
    t.integer "score_points"
    t.float   "time_seconds"
  end

  add_index "results", ["course_id"], :name => "course_id"
  add_index "results", ["registrant_id"], :name => "registrant_id"
  add_index "results", ["user_id"], :name => "user_id"

  create_table "roles", :force => true do |t|
    t.text "name",        :limit => 255
    t.text "description"
  end

  create_table "schema", :force => true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "series", :force => true do |t|
    t.text    "acronym",     :limit => 255
    t.text    "name",        :limit => 255
    t.text    "description"
    t.text    "color",       :limit => 255
    t.text    "information"
    t.boolean "is_current",                 :default => true
    t.integer "club_id"
  end

  add_index "series", ["club_id"], :name => "club_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tokens", :force => true do |t|
    t.datetime "created"
    t.datetime "modified"
    t.string   "token",    :limit => 32
    t.text     "data"
  end

  create_table "users", :force => true do |t|
    t.integer  "club_id"
    t.text     "name",                   :limit => 255
    t.text     "username",               :limit => 255,                 :null => false
    t.string   "email"
    t.text     "old_password",           :limit => 255
    t.integer  "year_of_birth"
    t.integer  "si_number"
    t.text     "referred_from",          :limit => 255
    t.datetime "last_login"
    t.datetime "time_created"
    t.string   "encrypted_password",                    :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "provider"
    t.string   "uid"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
  end

  add_index "users", ["club_id"], :name => "club_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
