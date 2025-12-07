class ApplicationAgent < ActiveAgent::Base
  include SolidAgent

  layout "agent"

  generate_with :ollama, model: "gpt-oss:20b"

  # Handle exceptions during streaming to prevent crashes
  def handle_exception(exception)
    Rails.logger.error "[Agent] Exception: #{exception.message}"
    Rails.logger.error exception.backtrace&.join("\n") if exception.backtrace
  end

  # Class method version in case framework expects it
  def self.handle_exception(exception)
    Rails.logger.error "[Agent] Class Exception: #{exception.message}"
    Rails.logger.error exception.backtrace&.join("\n") if exception.backtrace
  end
end

