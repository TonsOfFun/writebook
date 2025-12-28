class CreateAgentToolCalls < ActiveRecord::Migration[8.2]
  def change
    create_table :agent_tool_calls do |t|
      # Parent context - every tool call belongs to an agent context
      t.references :agent_context, null: false, foreign_key: true, index: true

      # Tool identification
      t.string :tool_call_id       # UUID from the LLM's tool_call request
      t.string :name, null: false  # Tool name (e.g., "navigate", "extract_text")

      # Tool execution details
      t.json :arguments, default: {}  # Arguments passed to the tool
      t.json :result                  # Result returned from the tool

      # Execution status tracking
      t.string :status, default: "pending"  # pending, executing, completed, failed
      t.text :error_message                 # Error message if failed

      # Timing information
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :duration_ms

      # Position in execution sequence
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :agent_tool_calls, [:agent_context_id, :position]
    add_index :agent_tool_calls, :name
    add_index :agent_tool_calls, :tool_call_id
    add_index :agent_tool_calls, :status
  end
end
