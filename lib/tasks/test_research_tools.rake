namespace :agent do
  desc "Test research agent tool loading and Ollama request format"
  task test_research_tools: :environment do
    puts "=" * 60
    puts "Testing Research Assistant Agent Tool Configuration"
    puts "=" * 60

    # Create an instance of the agent to test tool loading
    agent = ResearchAssistantAgent.new

    puts "\n1. Testing tool schema loading..."
    puts "-" * 40

    tool_names = %w[web_search read_webpage fetch_top_pages]
    tools = []

    tool_names.each do |tool_name|
      begin
        # Load each tool template
        json_content = agent.render_to_string(
          template: "research_assistant_agent/tools/#{tool_name}",
          formats: [:json],
          layout: false
        )

        tool_schema = JSON.parse(json_content, symbolize_names: true)
        tools << tool_schema

        puts "\n✓ #{tool_name}.json.erb loaded successfully:"
        puts JSON.pretty_generate(tool_schema)
      rescue => e
        puts "\n✗ #{tool_name} failed: #{e.message}"
      end
    end

    puts "\n" + "=" * 60
    puts "2. Full tools array that would be sent to Ollama:"
    puts "-" * 40
    puts JSON.pretty_generate(tools)

    puts "\n" + "=" * 60
    puts "3. Checking Ollama API format requirements..."
    puts "-" * 40

    # Ollama expects tools in a specific format
    # Let's check if our format matches
    valid_format = tools.all? do |tool|
      tool[:type] == "function" &&
      tool[:function].is_a?(Hash) &&
      tool[:function][:name].present? &&
      tool[:function][:parameters].is_a?(Hash)
    end

    if valid_format
      puts "✓ Tool schemas match expected Ollama function format"
    else
      puts "✗ Tool schemas may not match Ollama format"
    end

    puts "\n" + "=" * 60
    puts "4. Testing actual Ollama API connection..."
    puts "-" * 40

    # Test a simple Ollama request with tools
    begin
      require 'net/http'
      require 'json'

      ollama_url = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
      uri = URI("#{ollama_url}/api/chat")

      request_body = {
        model: "gpt-oss:20b",
        messages: [
          { role: "system", content: "You are a research assistant. Use the provided tools." },
          { role: "user", content: "Search the web for 'test query'" }
        ],
        tools: tools,
        stream: false
      }

      puts "Sending test request to: #{uri}"
      puts "\nRequest body (truncated):"
      puts JSON.pretty_generate(request_body)[0..500] + "..."

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(request_body)

      response = http.request(request)

      puts "\nResponse status: #{response.code}"

      if response.code == "200"
        result = JSON.parse(response.body)
        puts "\nOllama response:"
        puts JSON.pretty_generate(result)

        if result.dig("message", "tool_calls")
          puts "\n✓ SUCCESS: Model returned tool calls!"
          puts "Tool calls: #{result['message']['tool_calls']}"
        else
          puts "\n⚠ Model responded but did NOT use tools:"
          puts "Content: #{result.dig('message', 'content')&.slice(0, 200)}..."
        end
      else
        puts "\n✗ Error response: #{response.body}"
      end

    rescue Errno::ECONNREFUSED
      puts "✗ Cannot connect to Ollama at #{ollama_url}"
      puts "  Make sure Ollama is running: ollama serve"
    rescue => e
      puts "✗ Error: #{e.class} - #{e.message}"
    end

    puts "\n" + "=" * 60
    puts "Test complete!"
    puts "=" * 60
  end
end
