  class CreateDb < ActiveRecord::Migration
   def change
  #  create_table "clubs", :force => true do |t|
  #    t.text    "name"
  #    t.string  "acronym",       :limit => 8
  #    t.text    "location"
  #    t.text    "description"
  #    t.text    "url"
  #    t.float   "lat"
  #    t.float   "lng"
  #    t.text    "timezone"
  #    t.integer "visible",       :limit => 4, :default => 0, :null => false
  #    t.text    "configuration"
  #  end
  # 
  #  add_index "clubs", ["id"], :unique => true
  # 
  #  create_table "content_blocks", :force => true do |t|
  #    t.string  "key"
  #    t.text    "content"
  #    t.integer "order",   :limit => 11, :default => 1
  #    t.integer "club_id", :limit => 11
  #  end
  # 
  #  add_index "content_blocks", ["id"], :unique => true
  #  add_index "content_blocks", ["key"], :name => "content_blocks_key"
  # 
  #  create_table "courses", :force => true do |t|
  #    t.integer "event_id",    :limit => 11
  #    t.text    "name"
  #    t.integer "distance",    :limit => 11
  #    t.integer "climb",       :limit => 11
  #    t.text    "description"
  #    t.text    "map_url"
  #  end
  # 
  #  add_index "courses", ["id"], :unique => true
  # 
  #  create_table "events", :force => true do |t|
  #    t.text     "name"
  #    t.integer  "group_id",       :limit => 11
  #    t.integer  "map_id",         :limit => 11
  #    t.integer  "series_id",      :limit => 11
  #    t.datetime "date"
  #    t.float    "lat"
  #    t.float    "lng"
  #    t.integer  "is_ranked",      :limit => 4
  #    t.text     "description"
  #    t.integer  "results_posted", :limit => 4,  :default => 0, :null => false
  #    t.integer  "is_major",       :limit => 1,  :default => 0
  #    t.integer  "club_id",        :limit => 11
  #  end
  # 
  #  add_index "events", ["id"], :unique => true
  # 
  #  create_table "groups", :force => true do |t|
  #    t.text    "name"
  #    t.integer "access_level", :limit => 11
  #    t.text    "description"
  #    t.integer "club_id",      :limit => 11
  #  end
  # 
  #  add_index "groups", ["id"], :unique => true
  # 
  #  create_table "map_standards", :force => true do |t|
  #    t.text "name"
  #    t.text "description"
  #  end
  # 
  #  add_index "map_standards", ["id"], :unique => true
  # 
  #  create_table "maps", :force => true do |t|
  #    t.text     "name"
  #    t.integer  "map_standard_id", :limit => 11
  #    t.datetime "created"
  #    t.datetime "modified"
  #    t.integer  "scale",           :limit => 11
  #    t.float    "lat"
  #    t.float    "lng"
  #    t.text     "repository_path"
  #    t.integer  "club_id",         :limit => 11
  #  end
  # 
  #  add_index "maps", ["id"], :unique => true
  # 
  #  Could not dump table "memberships" because of following StandardError
  #    Unknown type 'year(4)' for column 'year'
  # 
  #  create_table "organizers", :force => true do |t|
  #    t.integer "user_id",  :limit => 11
  #    t.integer "event_id", :limit => 11
  #    t.integer "role_id",  :limit => 11
  #  end
  # 
  #  add_index "organizers", ["id"], :unique => true
  # 
  #  create_table "pages", :force => true do |t|
  #    t.string  "name"
  #    t.string  "section"
  #    t.text    "content"
  #    t.integer "club_id", :limit => 11
  #  end
  # 
  #  add_index "pages", ["id"], :unique => true
  # 
  #  create_table "privileges", :force => true do |t|
  #    t.integer "group_id", :limit => 11
  #    t.integer "user_id",  :limit => 11
  #  end
  # 
  #  add_index "privileges", ["id"], :unique => true
  # 
  #  create_table "results", :force => true do |t|
  #    t.integer "user_id",         :limit => 11
  #    t.integer "course_id",       :limit => 11
  #    t.time    "time"
  #    t.integer "non_competitive", :limit => 4,  :default => 0, :null => false
  #    t.integer "points",          :limit => 11
  #    t.integer "needs_ride",      :limit => 4,  :default => 0, :null => false
  #    t.integer "offering_ride",   :limit => 4,  :default => 0, :null => false
  #  end
  # 
  #  add_index "results", ["id"], :unique => true
  # 
  #  create_table "roles", :force => true do |t|
  #    t.text    "name"
  #    t.text    "description"
  #    t.integer "club_id",     :limit => 11
  #  end
  # 
  #  add_index "roles", ["id"], :unique => true
  # 
  #  create_table "series", :force => true do |t|
  #    t.text    "acronym"
  #    t.text    "name"
  #    t.text    "description"
  #    t.text    "color"
  #    t.text    "information"
  #    t.integer "is_current",  :limit => 1,  :default => 1
  #    t.integer "club_id",     :limit => 11
  #  end
  # 
  #  add_index "series", ["id"], :unique => true
  # 
  #  create_table "tokens", :force => true do |t|
  #    t.datetime "created"
  #    t.datetime "modified"
  #    t.string   "token",    :limit => 32
  #    t.text     "data"
  #  end
  # 
  #  add_index "tokens", ["id"], :unique => true
  # 
  #  create_table "users", :force => true do |t|
  #    t.integer  "club_id",       :limit => 11
  #    t.text     "name"
  #    t.text     "username",                    :null => false
  #    t.text     "email"
  #    t.text     "password"
  #    t.integer  "year_of_birth", :limit => 11
  #    t.integer  "si_number",     :limit => 11
  #    t.datetime "last_login"
  #    t.datetime "last_news"
  #    t.datetime "time_created"
  #    t.text     "referred_from"
  #    t.integer  "old_id",        :limit => 11
  #  end
  # 
  #  add_index "users", ["id"], :unique => true
   end
  end
