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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191001203548) do

  create_table "club_categories", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "clubs", force: :cascade do |t|
    t.text    "name",             limit: 255
    t.string  "acronym",          limit: 8
    t.text    "location",         limit: 255
    t.text    "description",      limit: 65535
    t.text    "url",              limit: 255
    t.float   "lat",              limit: 53
    t.float   "lng",              limit: 53
    t.string  "country",          limit: 255
    t.text    "timezone",         limit: 255
    t.boolean "visible",                        default: false,     null: false
    t.string  "domain",           limit: 255
    t.string  "redirect_domain",  limit: 255
    t.integer "parent_id",        limit: 4
    t.integer "club_category_id", limit: 4
    t.string  "layout",           limit: 255,   default: "default", null: false
    t.text    "facebook_page_id", limit: 255
    t.boolean "use_map_urls",                   default: true,      null: false
    t.string  "juicer_feed_id",   limit: 255
  end

  add_index "clubs", ["club_category_id"], name: "club_category_id", using: :btree

  create_table "content_blocks", force: :cascade do |t|
    t.string  "key",     limit: 255
    t.text    "content", limit: 65535
    t.integer "order",   limit: 4,     default: 1
    t.integer "club_id", limit: 4
  end

  add_index "content_blocks", ["club_id"], name: "club_id", using: :btree
  add_index "content_blocks", ["key"], name: "key", using: :btree

  create_table "courses", force: :cascade do |t|
    t.integer "event_id",    limit: 4
    t.text    "name",        limit: 255
    t.integer "distance",    limit: 4
    t.integer "climb",       limit: 4
    t.text    "description", limit: 65535
    t.text    "map_url",     limit: 255
    t.boolean "is_score_o",                default: false, null: false
  end

  add_index "courses", ["event_id"], name: "event_id", using: :btree

  create_table "cross_app_sessions", force: :cascade do |t|
    t.integer  "user_id",              limit: 4,   null: false
    t.string   "cross_app_session_id", limit: 255, null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "cross_app_sessions", ["cross_app_session_id"], name: "index_cross_app_sessions_on_cross_app_session_id", unique: true, using: :btree
  add_index "cross_app_sessions", ["user_id"], name: "index_cross_app_sessions_on_user_id", using: :btree

  create_table "event_classifications", force: :cascade do |t|
    t.string "name",           limit: 50
    t.string "iof_3_0_name",   limit: 50
    t.string "iof_2_0_3_name", limit: 50
    t.string "description",    limit: 100
  end

  create_table "events", force: :cascade do |t|
    t.text     "name",                    limit: 255
    t.integer  "map_id",                  limit: 4
    t.integer  "series_id",               limit: 4
    t.datetime "date"
    t.float    "lat",                     limit: 53
    t.float    "lng",                     limit: 53
    t.boolean  "is_ranked",                             default: false, null: false
    t.text     "description",             limit: 65535
    t.boolean  "results_posted",                        default: false, null: false
    t.integer  "club_id",                 limit: 4
    t.string   "custom_url",              limit: 255
    t.integer  "event_classification_id", limit: 4
    t.datetime "finish_date"
    t.integer  "number_of_participants",  limit: 4
    t.string   "results_url",             limit: 255
    t.string   "registration_url",        limit: 255
    t.string   "routegadget_url",         limit: 255
    t.string   "facebook_url",            limit: 255
    t.string   "attackpoint_url",         limit: 255
    t.datetime "registration_deadline"
  end

  add_index "events", ["club_id"], name: "club_id", using: :btree
  add_index "events", ["date"], name: "index_events_on_date", using: :btree
  add_index "events", ["event_classification_id"], name: "event_classification_id", using: :btree
  add_index "events", ["finish_date"], name: "index_events_on_finish_date", using: :btree
  add_index "events", ["lat", "lng"], name: "index_events_on_lat_and_lng", using: :btree
  add_index "events", ["lat"], name: "index_events_on_lat", using: :btree
  add_index "events", ["lng"], name: "index_events_on_lng", using: :btree
  add_index "events", ["map_id"], name: "map_id", using: :btree
  add_index "events", ["results_posted", "results_url"], name: "index_events_on_results_posted_and_results_url", using: :btree
  add_index "events", ["series_id"], name: "series_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.text    "name",         limit: 255
    t.integer "access_level", limit: 4
    t.text    "description",  limit: 65535
    t.integer "club_id",      limit: 4
  end

  add_index "groups", ["club_id"], name: "club_id", using: :btree

  create_table "map_standards", force: :cascade do |t|
    t.text "name",        limit: 255
    t.text "description", limit: 65535
    t.text "color",       limit: 255
  end

  create_table "maps", force: :cascade do |t|
    t.text     "name",            limit: 255
    t.integer  "map_standard_id", limit: 4
    t.datetime "created"
    t.datetime "modified"
    t.integer  "scale",           limit: 4
    t.float    "lat",             limit: 53
    t.float    "lng",             limit: 53
    t.text     "repository_path", limit: 255
    t.integer  "club_id",         limit: 4
    t.string   "file_url",        limit: 255
    t.text     "notes",           limit: 65535
  end

  add_index "maps", ["club_id"], name: "club_id", using: :btree
  add_index "maps", ["map_standard_id"], name: "map_standard_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "user_id", limit: 4
    t.integer  "year",    limit: 4
    t.datetime "created"
    t.integer  "club_id", limit: 4
  end

  add_index "memberships", ["user_id"], name: "user_id", using: :btree

  create_table "official_classifications", force: :cascade do |t|
    t.string "name",        limit: 40,  default: "", null: false
    t.string "description", limit: 100
  end

  create_table "officials", force: :cascade do |t|
    t.integer  "user_id",                    limit: 4, null: false
    t.integer  "official_classification_id", limit: 4, null: false
    t.datetime "date"
  end

  add_index "officials", ["official_classification_id"], name: "official_classification_id", using: :btree
  add_index "officials", ["user_id"], name: "user_id", using: :btree

  create_table "organizers", force: :cascade do |t|
    t.integer "user_id",  limit: 4
    t.integer "event_id", limit: 4
    t.integer "role_id",  limit: 4
  end

  add_index "organizers", ["event_id"], name: "event_id", using: :btree
  add_index "organizers", ["role_id"], name: "role_id", using: :btree
  add_index "organizers", ["user_id"], name: "user_id", using: :btree

  create_table "pages", force: :cascade do |t|
    t.string  "name",    limit: 255
    t.string  "section", limit: 255
    t.text    "content", limit: 65535
    t.integer "club_id", limit: 4
  end

  add_index "pages", ["club_id"], name: "club_id", using: :btree

  create_table "privileges", force: :cascade do |t|
    t.integer "group_id", limit: 4
    t.integer "user_id",  limit: 4
  end

  add_index "privileges", ["group_id"], name: "group_id", using: :btree
  add_index "privileges", ["user_id"], name: "user_id", using: :btree

  create_table "resources", force: :cascade do |t|
    t.string   "caption",    limit: 255
    t.string   "key",        limit: 255
    t.integer  "club_id",    limit: 4
    t.string   "extension",  limit: 255
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "resources", ["club_id"], name: "club_id", using: :btree
  add_index "resources", ["key"], name: "key", using: :btree

  create_table "result_lists", force: :cascade do |t|
    t.text     "data",        limit: 16777215
    t.integer  "event_id",    limit: 4
    t.integer  "user_id",     limit: 4
    t.datetime "upload_time"
    t.boolean  "visible",                      default: false, null: false
    t.datetime "updated_at"
    t.string   "status",      limit: 255
  end

  add_index "result_lists", ["event_id"], name: "index_result_lists_on_event_id", using: :btree
  add_index "result_lists", ["upload_time"], name: "index_result_lists_on_upload_time", using: :btree
  add_index "result_lists", ["user_id"], name: "index_result_lists_on_user_id", using: :btree

  create_table "results", force: :cascade do |t|
    t.integer "user_id",            limit: 4
    t.integer "course_id",          limit: 4
    t.string  "status",             limit: 50,  default: "ok", null: false
    t.integer "registrant_id",      limit: 4
    t.integer "score_points",       limit: 4
    t.float   "time_seconds",       limit: 53
    t.string  "registrant_comment", limit: 255
    t.string  "official_comment",   limit: 255
  end

  add_index "results", ["course_id"], name: "course_id", using: :btree
  add_index "results", ["registrant_id"], name: "registrant_id", using: :btree
  add_index "results", ["user_id"], name: "user_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.text "name",        limit: 255
    t.text "description", limit: 65535
  end

  create_table "series", force: :cascade do |t|
    t.text    "acronym",     limit: 255
    t.text    "name",        limit: 255
    t.text    "color",       limit: 255
    t.text    "information", limit: 65535
    t.boolean "is_current",                default: true
    t.integer "club_id",     limit: 4
  end

  add_index "series", ["club_id"], name: "club_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "short_links", force: :cascade do |t|
    t.string "name",        limit: 255
    t.string "destination", limit: 255
  end

  add_index "short_links", ["name"], name: "index_short_links_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.integer  "club_id",                limit: 4
    t.text     "name",                   limit: 255
    t.string   "email",                  limit: 255
    t.text     "old_password",           limit: 255
    t.integer  "year_of_birth",          limit: 4
    t.integer  "si_number",              limit: 4
    t.text     "referred_from",          limit: 255
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.integer  "failed_attempts",        limit: 4,   default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.string   "google_id",              limit: 255
    t.string   "facebook_id",            limit: 255
    t.string   "gender",                 limit: 255
  end

  add_index "users", ["club_id"], name: "club_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "clubs", "club_categories", name: "clubs_ibfk_1", on_delete: :nullify
  add_foreign_key "content_blocks", "clubs", name: "content_blocks_ibfk_1", on_delete: :cascade
  add_foreign_key "courses", "events", name: "courses_ibfk_1", on_delete: :cascade
  add_foreign_key "events", "clubs", name: "events_ibfk_3"
  add_foreign_key "events", "event_classifications", name: "events_ibfk_4", on_delete: :nullify
  add_foreign_key "events", "maps", name: "events_ibfk_1", on_delete: :nullify
  add_foreign_key "events", "series", name: "events_ibfk_5", on_delete: :nullify
  add_foreign_key "groups", "clubs", name: "groups_ibfk_1", on_delete: :cascade
  add_foreign_key "maps", "clubs", name: "maps_ibfk_2"
  add_foreign_key "maps", "map_standards", name: "maps_ibfk_1", on_delete: :nullify
  add_foreign_key "memberships", "users", name: "memberships_ibfk_1", on_delete: :cascade
  add_foreign_key "organizers", "events", name: "organizers_ibfk_3", on_delete: :cascade
  add_foreign_key "organizers", "roles", name: "organizers_ibfk_2"
  add_foreign_key "organizers", "users", name: "organizers_ibfk_1", on_delete: :cascade
  add_foreign_key "pages", "clubs", name: "pages_ibfk_1", on_delete: :cascade
  add_foreign_key "privileges", "groups", name: "privileges_ibfk_1"
  add_foreign_key "privileges", "users", name: "privileges_ibfk_2"
  add_foreign_key "resources", "clubs", name: "resources_ibfk_1", on_delete: :cascade
  add_foreign_key "results", "courses", name: "results_ibfk_2", on_delete: :cascade
  add_foreign_key "results", "users", column: "registrant_id", name: "results_ibfk_3", on_delete: :nullify
  add_foreign_key "results", "users", name: "results_ibfk_1"
  add_foreign_key "series", "clubs", name: "series_ibfk_1"
  add_foreign_key "users", "clubs", name: "users_ibfk_1"
end
