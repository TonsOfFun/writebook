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

ActiveRecord::Schema[8.2].define(version: 2026_01_29_214504) do
  create_table "accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.integer "report_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["report_id"], name: "index_accesses_on_report_id"
    t.index ["user_id", "report_id"], name: "index_accesses_on_user_id_and_report_id", unique: true
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

  create_table "agent_fragments", force: :cascade do |t|
    t.string "action_type"
    t.integer "agent_context_id", null: false
    t.text "applied_content"
    t.string "content_hash"
    t.integer "contextable_id"
    t.string "contextable_type"
    t.datetime "created_at", null: false
    t.json "detected_references"
    t.integer "end_offset"
    t.string "fragment_type"
    t.text "generated_content"
    t.json "metadata"
    t.text "original_content"
    t.integer "parent_fragment_id"
    t.integer "start_offset"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["agent_context_id"], name: "index_agent_fragments_on_agent_context_id"
    t.index ["content_hash"], name: "index_agent_fragments_on_content_hash"
    t.index ["contextable_type", "contextable_id"], name: "index_agent_fragments_on_contextable"
    t.index ["contextable_type", "contextable_id"], name: "index_agent_fragments_on_contextable_type_and_contextable_id"
    t.index ["parent_fragment_id"], name: "index_agent_fragments_on_parent_fragment_id"
    t.index ["status"], name: "index_agent_fragments_on_status"
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

  create_table "agent_references", force: :cascade do |t|
    t.integer "agent_context_id", null: false
    t.integer "agent_tool_call_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "domain"
    t.text "error_message"
    t.text "extracted_content"
    t.string "favicon_url"
    t.json "metadata", default: {}
    t.text "og_description"
    t.string "og_image"
    t.string "og_site_name"
    t.string "og_title"
    t.string "og_type"
    t.integer "position", default: 0
    t.string "status", default: "pending"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["agent_context_id", "position"], name: "index_agent_references_on_agent_context_id_and_position"
    t.index ["agent_context_id"], name: "index_agent_references_on_agent_context_id"
    t.index ["agent_tool_call_id"], name: "index_agent_references_on_agent_tool_call_id"
    t.index ["domain"], name: "index_agent_references_on_domain"
    t.index ["url"], name: "index_agent_references_on_url"
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

  create_table "chapters", force: :cascade do |t|
    t.integer "chapterable_id", null: false
    t.string "chapterable_type", null: false
    t.datetime "created_at", null: false
    t.float "position_score", null: false
    t.integer "report_id", null: false
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["chapterable_type", "chapterable_id"], name: "index_leafs_on_leafable"
    t.index ["report_id"], name: "index_chapters_on_report_id"
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
    t.integer "chapter_id", null: false
    t.integer "chapterable_id", null: false
    t.string "chapterable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_edits_on_chapter_id"
    t.index ["chapterable_type", "chapterable_id"], name: "index_edits_on_leafable"
  end

  create_table "findings", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "evidence"
    t.json "metadata", default: {}
    t.text "recommendation"
    t.string "severity", default: "medium", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_findings_on_category"
    t.index ["severity"], name: "index_findings_on_severity"
    t.index ["status"], name: "index_findings_on_status"
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

  create_table "reports", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", null: false
    t.boolean "everyone_access", default: true, null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.string "subtitle"
    t.string "theme", default: "blue", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_reports_on_published"
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

  create_table "source_tags", force: :cascade do |t|
    t.string "context"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.integer "position", default: 0
    t.integer "source_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_source_tags_on_source_id"
    t.index ["taggable_type", "taggable_id", "source_id"], name: "index_source_tags_uniqueness", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_source_tags_on_taggable"
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "extracted_content"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.datetime "processed_at"
    t.text "processing_error"
    t.string "processing_status", default: "pending"
    t.text "raw_content"
    t.integer "report_id", null: false
    t.string "source_type", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["processing_status"], name: "index_sources_on_processing_status"
    t.index ["report_id"], name: "index_sources_on_report_id"
    t.index ["source_type"], name: "index_sources_on_source_type"
  end

  create_table "suggestions", force: :cascade do |t|
    t.boolean "ai_generated", default: false
    t.integer "author_id"
    t.text "comment"
    t.string "content_hash"
    t.datetime "created_at", null: false
    t.integer "end_offset"
    t.text "original_text"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.integer "start_offset"
    t.string "status", default: "pending", null: false
    t.integer "suggestable_id", null: false
    t.string "suggestable_type", null: false
    t.text "suggested_text"
    t.string "suggestion_type", default: "edit", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_generated"], name: "index_suggestions_on_ai_generated"
    t.index ["author_id"], name: "index_suggestions_on_author_id"
    t.index ["resolved_by_id"], name: "index_suggestions_on_resolved_by_id"
    t.index ["status"], name: "index_suggestions_on_status"
    t.index ["suggestable_type", "suggestable_id"], name: "index_suggestions_on_suggestable"
    t.index ["suggestion_type"], name: "index_suggestions_on_suggestion_type"
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

  add_foreign_key "accesses", "reports"
  add_foreign_key "accesses", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_fragments", "agent_contexts"
  add_foreign_key "agent_fragments", "agent_fragments", column: "parent_fragment_id"
  add_foreign_key "agent_generations", "agent_contexts"
  add_foreign_key "agent_generations", "agent_messages", column: "response_message_id"
  add_foreign_key "agent_messages", "agent_contexts"
  add_foreign_key "agent_references", "agent_contexts"
  add_foreign_key "agent_references", "agent_tool_calls"
  add_foreign_key "agent_tool_calls", "agent_contexts"
  add_foreign_key "chapters", "reports"
  add_foreign_key "edits", "chapters"
  add_foreign_key "sessions", "users"
  add_foreign_key "source_tags", "sources"
  add_foreign_key "sources", "reports"
  add_foreign_key "suggestions", "users", column: "author_id"
  add_foreign_key "suggestions", "users", column: "resolved_by_id"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "chapter_search_index", "fts5", ["title", "content", "tokenize='porter'"]
end
