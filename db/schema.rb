# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_28_204633) do

  create_table "club_categories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "clubs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.string "acronym", limit: 8
    t.text "location", size: :tiny
    t.text "description", size: :medium
    t.text "url", size: :tiny
    t.float "lat", limit: 53
    t.float "lng", limit: 53
    t.string "country"
    t.text "timezone", size: :tiny
    t.boolean "visible", default: false, null: false
    t.string "domain"
    t.string "redirect_domain"
    t.integer "parent_id"
    t.integer "club_category_id"
    t.string "layout", default: "default", null: false
    t.text "facebook_page_id", size: :tiny
    t.boolean "use_map_urls", default: true, null: false
    t.string "juicer_feed_id"
    t.index ["club_category_id"], name: "club_category_id"
  end

  create_table "content_blocks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "key"
    t.text "content", size: :medium
    t.integer "order", default: 1
    t.integer "club_id"
    t.index ["club_id"], name: "club_id"
    t.index ["key"], name: "key"
  end

  create_table "courses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "event_id"
    t.text "name", size: :tiny
    t.integer "distance"
    t.integer "climb"
    t.text "description", size: :medium
    t.text "map_url", size: :tiny
    t.boolean "is_score_o", default: false, null: false
    t.index ["event_id"], name: "event_id"
  end

  create_table "cross_app_sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "cross_app_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cross_app_session_id"], name: "index_cross_app_sessions_on_cross_app_session_id", unique: true
    t.index ["user_id"], name: "index_cross_app_sessions_on_user_id"
  end

  create_table "event_classifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 50
    t.string "iof_3_0_name", limit: 50
    t.string "iof_2_0_3_name", limit: 50
    t.text "description", size: :medium
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.integer "map_id"
    t.integer "series_id"
    t.datetime "date"
    t.float "lat", limit: 53
    t.float "lng", limit: 53
    t.boolean "is_ranked", default: false, null: false
    t.text "description", size: :medium
    t.boolean "results_posted", default: false, null: false
    t.integer "club_id"
    t.string "custom_url"
    t.integer "event_classification_id"
    t.datetime "finish_date"
    t.integer "number_of_participants"
    t.string "results_url"
    t.string "registration_url"
    t.string "routegadget_url"
    t.string "facebook_url"
    t.string "attackpoint_url"
    t.datetime "registration_deadline"
    t.index ["club_id"], name: "club_id"
    t.index ["date"], name: "index_events_on_date"
    t.index ["event_classification_id"], name: "event_classification_id"
    t.index ["finish_date"], name: "index_events_on_finish_date"
    t.index ["lat", "lng"], name: "index_events_on_lat_and_lng"
    t.index ["lat"], name: "index_events_on_lat"
    t.index ["lng"], name: "index_events_on_lng"
    t.index ["map_id"], name: "map_id"
    t.index ["results_posted", "results_url"], name: "index_events_on_results_posted_and_results_url"
    t.index ["series_id"], name: "series_id"
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.integer "access_level"
    t.text "description", size: :medium
    t.integer "club_id"
    t.index ["club_id"], name: "club_id"
  end

  create_table "map_standards", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.text "description", size: :medium
    t.text "color", size: :tiny
  end

  create_table "maps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.integer "map_standard_id"
    t.datetime "created"
    t.datetime "modified"
    t.integer "scale"
    t.float "lat", limit: 53
    t.float "lng", limit: 53
    t.text "repository_path", size: :tiny
    t.integer "club_id"
    t.string "file_url"
    t.text "notes", size: :medium
    t.index ["club_id"], name: "club_id"
    t.index ["map_standard_id"], name: "map_standard_id"
  end

  create_table "memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "year"
    t.datetime "created"
    t.integer "club_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "official_classifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 40, default: "", null: false
    t.string "description", limit: 100
  end

  create_table "officials", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "official_classification_id", null: false
    t.datetime "date"
    t.index ["official_classification_id"], name: "official_classification_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "organizers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.integer "role_id"
    t.index ["event_id"], name: "event_id"
    t.index ["role_id"], name: "role_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "section"
    t.text "content", size: :medium
    t.integer "club_id"
    t.index ["club_id"], name: "club_id"
  end

  create_table "privileges", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.index ["group_id"], name: "group_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "resources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "caption"
    t.string "key"
    t.integer "club_id"
    t.string "extension"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["club_id"], name: "club_id"
    t.index ["key"], name: "key"
  end

  create_table "result_lists", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "data", size: :medium
    t.integer "event_id"
    t.integer "user_id"
    t.datetime "upload_time"
    t.boolean "visible", default: false, null: false
    t.datetime "updated_at"
    t.string "status"
    t.index ["event_id"], name: "index_result_lists_on_event_id"
    t.index ["upload_time"], name: "index_result_lists_on_upload_time"
    t.index ["user_id"], name: "index_result_lists_on_user_id"
  end

  create_table "results", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.string "status", limit: 50, default: "ok", null: false
    t.integer "registrant_id"
    t.integer "score_points"
    t.float "time_seconds", limit: 53
    t.string "registrant_comment"
    t.string "official_comment"
    t.index ["course_id"], name: "course_id"
    t.index ["registrant_id"], name: "registrant_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", size: :tiny
    t.text "description", size: :medium
  end

  create_table "series", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "acronym", size: :tiny
    t.text "name", size: :tiny
    t.text "color", size: :tiny
    t.text "information", size: :medium
    t.boolean "is_current", default: true
    t.integer "club_id"
    t.index ["club_id"], name: "club_id"
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "short_links", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "destination"
    t.index ["name"], name: "index_short_links_on_name", unique: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "club_id"
    t.text "name", size: :tiny
    t.string "email"
    t.text "old_password", size: :tiny
    t.integer "year_of_birth"
    t.integer "si_number"
    t.text "referred_from", size: :tiny
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "google_id"
    t.string "facebook_id"
    t.string "gender"
    t.index ["club_id"], name: "club_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

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
