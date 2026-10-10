# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_09_201859) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "milestones", force: :cascade do |t|
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on", null: false
    t.integer "kind", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.bigint "research_project_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["research_project_id", "due_on"], name: "index_milestones_on_research_project_id_and_due_on"
    t.index ["research_project_id"], name: "index_milestones_on_research_project_id"
  end

  create_table "progress_notes", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "research_project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_progress_notes_on_author_id"
    t.index ["research_project_id"], name: "index_progress_notes_on_research_project_id"
  end

  create_table "research_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on"
    t.integer "kind", default: 0, null: false
    t.date "starts_on"
    t.bigint "student_id", null: false
    t.bigint "supervisor_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_research_projects_on_student_id"
    t.index ["supervisor_id"], name: "index_research_projects_on_supervisor_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "full_name"
    t.bigint "manager_id"
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "milestones", "research_projects"
  add_foreign_key "progress_notes", "research_projects"
  add_foreign_key "progress_notes", "users", column: "author_id"
  add_foreign_key "research_projects", "users", column: "student_id"
  add_foreign_key "research_projects", "users", column: "supervisor_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "users", column: "manager_id"
end
