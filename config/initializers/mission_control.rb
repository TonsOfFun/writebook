# Mission Control - Jobs configuration
Rails.application.config.to_prepare do
  MissionControl::Jobs.base_controller_class = "ApplicationController"

  # Disable HTTP Basic auth in development
  if Rails.env.development?
    MissionControl::Jobs.http_basic_auth_enabled = false
  end
end
