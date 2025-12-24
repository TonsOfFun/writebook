source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", github: "rails/rails"

# Drivers
gem "sqlite3", "~> 2.2"
gem "redis", ">= 4.0.1"

# Deployment
gem "puma", ">= 5.0"

# Jobs
gem "solid_queue"
gem "mission_control-jobs"

# Front-end
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Other
gem "jbuilder"
gem "redcarpet", "~> 3.6"
gem "rouge", "~> 4.5"
gem "bcrypt", "~> 3.1.7"
gem "image_processing", "~> 1.13"
gem "rqrcode"
gem "thruster"
gem "useragent", github: "basecamp/useragent"
gem "front_matter_parser"

group :development, :test do
  gem "debug"
  gem "faker", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "selenium-webdriver"
end

gem "reactionview", "~> 0.1.2"

# AI Integration
gem "activeagent", "~> 1.0.1"
gem "solid_agent", "~> 0.1.1"
gem "openai"
gem "ruby-anthropic"  # For Anthropic/Claude support
gem "pdf-reader"  # For PDF analysis
gem "capybara"  # Browser automation for research agent
gem "cuprite"  # Headless Chrome driver for web browsing
