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

ActiveRecord::Schema[8.2].define(version: 2025_12_28_123555) do
  create_table "accesses", force: :cascade do |t|
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["book_id"], name: "index_accesses_on_book_id"
    t.index ["user_id", "book_id"], name: "index_accesses_on_user_id_and_book_id", unique: true
    t.index ["user_id"], name: "index_accesses_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "custom_styles"
    t.string "join_code", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "action_text_markdowns", force: :cascade do |t|
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_action_text_markdowns_on_record"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.string "slug"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["slug"], name: "index_active_storage_attachments_on_slug", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_contexts", force: :cascade do |t|
    t.string "action_name"
    t.string "agent_name", null: false
    t.integer "contextable_id"
    t.string "contextable_type"
    t.datetime "created_at", null: false
    t.text "instructions"
    t.json "options", default: {}
    t.string "status", default: "pending"
    t.string "trace_id"
    t.datetime "updated_at", null: false
    t.index ["contextable_type", "contextable_id"], name: "index_agent_contexts_on_contextable"
    t.index ["trace_id"], name: "index_agent_contexts_on_trace_id"
  end

  create_table "agent_generations", force: :cascade do |t|
    t.integer "agent_context_id", null: false
    t.integer "cached_tokens"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "finish_reason"
    t.integer "input_tokens", default: 0
    t.string "model"
    t.integer "output_tokens", default: 0
    t.json "provider_details", default: {}
    t.string "provider_id"
    t.json "raw_request"
    t.json "raw_response"
    t.integer "reasoning_tokens"
    t.integer "response_message_id"
    t.string "status", default: "completed"
    t.integer "total_tokens", default: 0
    t.datetime "updated_at", null: false
    t.index ["agent_context_id"], name: "index_agent_generations_on_agent_context_id"
    t.index ["response_message_id"], name: "index_agent_generations_on_response_message_id"
  end

  create_table "agent_messages", force: :cascade do |t|
    t.integer "agent_context_id", null: false
    t.text "content"
    t.json "content_parts", default: []
    t.datetime "created_at", null: false
    t.string "function_name"
    t.string "name"
    t.integer "position", default: 0
    t.string "role", null: false
    t.string "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["agent_context_id", "position"], name: "index_agent_messages_on_agent_context_id_and_position"
    t.index ["agent_context_id"], name: "index_agent_messages_on_agent_context_id"
  end

  create_table "agent_tool_calls", force: :cascade do |t|
    t.integer "agent_context_id", null: false
    t.json "arguments", default: {}
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "name", null: false
    t.integer "position", default: 0
    t.json "result"
    t.datetime "started_at"
    t.string "status", default: "pending"
    t.string "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["agent_context_id", "position"], name: "index_agent_tool_calls_on_agent_context_id_and_position"
    t.index ["agent_context_id"], name: "index_agent_tool_calls_on_agent_context_id"
    t.index ["name"], name: "index_agent_tool_calls_on_name"
    t.index ["status"], name: "index_agent_tool_calls_on_status"
    t.index ["tool_call_id"], name: "index_agent_tool_calls_on_tool_call_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", null: false
    t.boolean "everyone_access", default: true, null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.string "subtitle"
    t.string "theme", default: "blue", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_books_on_published"
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_type"
    t.integer "page_count", default: 0
    t.json "page_images", default: {}
    t.json "page_text", default: {}
    t.text "processing_error"
    t.string "processing_status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["document_type"], name: "index_documents_on_document_type"
    t.index ["processing_status"], name: "index_documents_on_processing_status"
  end

  create_table "edits", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "leaf_id", null: false
    t.integer "leafable_id", null: false
    t.string "leafable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["leaf_id"], name: "index_edits_on_leaf_id"
    t.index ["leafable_type", "leafable_id"], name: "index_edits_on_leafable"
  end

  create_table "leaves", force: :cascade do |t|
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "leafable_id", null: false
    t.string "leafable_type", null: false
    t.float "position_score", null: false
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_leaves_on_book_id"
    t.index ["leafable_type", "leafable_id"], name: "index_leafs_on_leafable"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pictures", force: :cascade do |t|
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sections", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "theme"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "accesses", "books"
  add_foreign_key "accesses", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_generations", "agent_contexts"
  add_foreign_key "agent_generations", "agent_messages", column: "response_message_id"
  add_foreign_key "agent_messages", "agent_contexts"
  add_foreign_key "agent_tool_calls", "agent_contexts"
  add_foreign_key "edits", "leaves"
  add_foreign_key "leaves", "books"
  add_foreign_key "sessions", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "leaf_search_index", "fts5", ["title", "content", "tokenize='porter'"]
end
