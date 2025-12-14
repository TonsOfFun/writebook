require "capybara"
require "capybara/cuprite"

class ResearchAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o",
    stream: true

  include HasTools
  include StreamsToolUpdates

  class_attribute :browser_session, default: nil

  # Enable context persistence for tracking research sessions
  has_context

  # Declare tools - auto-discovers from app/views/research_assistant_agent/tools/*.json.erb
  has_tools :navigate, :click, :fill_form, :extract_text, :extract_main_content, :extract_links, :page_info, :go_back

  # Custom tool descriptions for UI feedback during execution
  tool_description :navigate, ->(args) { "Visiting #{args[:url] || 'page'}..." }
  tool_description :click, ->(args) { args[:text] ? "Clicking '#{args[:text]}'..." : "Clicking element..." }
  tool_description :fill_form, ->(args) { "Filling in #{args[:field] || 'form field'}..." }
  tool_description :extract_text, "Reading page content..."
  tool_description :extract_main_content, "Extracting main content..."
  tool_description :extract_links, "Finding links on page..."
  tool_description :page_info, "Analyzing page structure..."
  tool_description :go_back, "Going back to previous page..."

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  def research
    @topic = params[:topic]
    @context = params[:context]
    @full_content = params[:full_content]
    @depth = params[:depth] || "standard"

    # Create context with input parameters for audit trail
    # The after_prompt callback from SolidAgent will persist the rendered template
    create_context(
      contextable: params[:contextable],
      input_params: {
        topic: @topic,
        depth: @depth,
        has_full_content: @full_content.present?
      }.compact
    )

    prompt(tools: tools, tool_choice: "auto")
  end

  # Tool method: Navigate to a URL
  def navigate(url:)
    Rails.logger.info "[ResearchAgent] Tool called: navigate(#{url})"
    setup_browser_if_needed

    self.class.browser_session.visit(url)
    {
      success: true,
      current_url: self.class.browser_session.current_url,
      title: self.class.browser_session.title
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Navigate error: #{e.message}"
    { success: false, error: e.message }
  end

  # Tool method: Click on an element
  def click(selector: nil, text: nil)
    Rails.logger.info "[ResearchAgent] Tool called: click(selector=#{selector}, text=#{text})"
    setup_browser_if_needed

    if text
      self.class.browser_session.click_on(text)
    elsif selector
      self.class.browser_session.find(selector).click
    else
      return { success: false, error: "Must provide either selector or text" }
    end

    {
      success: true,
      current_url: self.class.browser_session.current_url,
      title: self.class.browser_session.title
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Click error: #{e.message}"
    { success: false, error: e.message }
  end

  # Tool method: Fill in a form field
  def fill_form(field:, value:)
    Rails.logger.info "[ResearchAgent] Tool called: fill_form(#{field}, #{value})"
    setup_browser_if_needed

    self.class.browser_session.fill_in(field, with: value)
    { success: true }
  rescue => e
    Rails.logger.error "[ResearchAgent] Fill form error: #{e.message}"
    { success: false, error: e.message }
  end

  # Tool method: Extract text from the page
  def extract_text(selector: "body")
    Rails.logger.info "[ResearchAgent] Tool called: extract_text(#{selector})"
    setup_browser_if_needed

    element = self.class.browser_session.find(selector)
    text = element.text.gsub(/\s+/, " ").strip

    # Limit content length
    text = text[0..6000] if text.length > 6000

    {
      success: true,
      text: text,
      current_url: self.class.browser_session.current_url
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Extract text error: #{e.message}"
    { success: false, error: e.message, text: "" }
  end

  # Tool method: Extract main content from a page (smart content detection)
  def extract_main_content
    Rails.logger.info "[ResearchAgent] Tool called: extract_main_content"
    setup_browser_if_needed

    content_selectors = [
      "#mw-content-text",  # Wikipedia
      "main",
      "article",
      "[role='main']",
      ".content",
      "#content",
      ".article-body",
      ".post-content"
    ]

    text = nil
    selector_used = nil

    content_selectors.each do |selector|
      if self.class.browser_session.has_css?(selector, wait: 0)
        element = self.class.browser_session.find(selector)
        text = element.text.gsub(/\s+/, " ").strip
        selector_used = selector
        break if text.present?
      end
    end

    text ||= self.class.browser_session.find("body").text.gsub(/\s+/, " ").strip
    text = text[0..6000] if text.length > 6000

    {
      success: true,
      content: text,
      selector_used: selector_used,
      current_url: self.class.browser_session.current_url,
      title: self.class.browser_session.title
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Extract main content error: #{e.message}"
    { success: false, error: e.message, content: "" }
  end

  # Tool method: Extract all links from the page
  def extract_links(selector: "body", limit: 10)
    Rails.logger.info "[ResearchAgent] Tool called: extract_links(#{selector}, limit=#{limit})"
    setup_browser_if_needed

    links = []
    within_element = (selector == "body") ? self.class.browser_session : self.class.browser_session.find(selector)

    within_element.all("a", visible: true).first(limit).each do |link|
      href = link["href"]
      next if href.nil? || href.empty? || href.start_with?("#") || href.start_with?("javascript:")

      links << {
        text: link.text.strip,
        href: href,
        title: link["title"]
      }
    end

    {
      success: true,
      links: links,
      current_url: self.class.browser_session.current_url
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Extract links error: #{e.message}"
    { success: false, error: e.message, links: [] }
  end

  # Tool method: Get current page info
  def page_info
    Rails.logger.info "[ResearchAgent] Tool called: page_info"
    setup_browser_if_needed

    has_elements = {}
    %w[form input button a img].each do |tag|
      has_elements[tag] = self.class.browser_session.has_css?(tag, wait: 0)
    end

    {
      success: true,
      current_url: self.class.browser_session.current_url,
      title: self.class.browser_session.title,
      has_elements: has_elements
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Page info error: #{e.message}"
    { success: false, error: e.message }
  end

  # Tool method: Go back to previous page
  def go_back
    Rails.logger.info "[ResearchAgent] Tool called: go_back"
    setup_browser_if_needed

    self.class.browser_session.go_back
    sleep 0.5

    {
      success: true,
      current_url: self.class.browser_session.current_url,
      title: self.class.browser_session.title
    }
  rescue => e
    Rails.logger.error "[ResearchAgent] Go back error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def setup_browser_if_needed
    return if self.class.browser_session

    # Configure Cuprite driver if not already configured
    unless Capybara.drivers[:cuprite_research]
      Capybara.register_driver :cuprite_research do |app|
        Capybara::Cuprite::Driver.new(
          app,
          window_size: [ 1920, 1080 ],
          browser_options: {
            "no-sandbox": nil,
            "disable-gpu": nil,
            "disable-dev-shm-usage": nil
          },
          inspector: false,
          headless: true,
          timeout: 30
        )
      end
    end

    # Create a shared session for this agent class
    self.class.browser_session = Capybara::Session.new(:cuprite_research)
  end

  def broadcast_chunk(chunk)
    return unless chunk.delta
    return unless params[:stream_id]

    Rails.logger.info "[ResearchAgent] Broadcasting chunk to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { content: chunk.delta })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    Rails.logger.info "[ResearchAgent] Broadcasting completion to stream_id: #{params[:stream_id]}"
    ActionCable.server.broadcast(params[:stream_id], { done: true })
  end
end
