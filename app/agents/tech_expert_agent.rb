class TechExpertAgent < ApplicationAgent
  has_context

  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: <<~INSTRUCTIONS
      You are a senior technology diligence expert helping assess technology companies and products.
      You analyze source materials (documents, code, architecture diagrams, etc.) to identify:
      - Security vulnerabilities and risks
      - Performance issues and bottlenecks
      - Architectural concerns and technical debt
      - Code quality issues
      - Compliance gaps
      - Opportunities for improvement

      Always cite your sources when making observations. Be thorough but concise.
      Focus on actionable findings with clear severity assessments.
    INSTRUCTIONS

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  # Analyze sources and generate findings
  def analyze_sources
    @report = params[:report]
    @focus_areas = params[:focus_areas] || []
    @sources = @report.sources.processed.limit(10)
    @source_context = build_source_context

    create_context(
      contextable: @report,
      input_params: {
        action: "analyze_sources",
        focus_areas: @focus_areas,
        source_count: @sources.count
      }
    )

    prompt
  end

  # Generate a finding draft based on a topic and sources
  def draft_finding
    @report = params[:report]
    @topic = params[:topic]
    @category = params[:category] || "other"
    @sources = params[:source_ids].present? ?
      @report.sources.where(id: params[:source_ids]) :
      @report.sources.processed.limit(5)
    @source_context = build_source_context

    create_context(
      contextable: @report,
      input_params: {
        action: "draft_finding",
        topic: @topic,
        category: @category,
        source_count: @sources.count
      }
    )

    prompt
  end

  # Review and enhance an existing finding
  def enhance_finding
    @finding = params[:finding]
    @report = @finding.report
    @sources = @report.sources.processed.limit(5)
    @source_context = build_source_context

    create_context(
      contextable: @finding,
      input_params: {
        action: "enhance_finding",
        finding_id: @finding.id,
        severity: @finding.severity,
        category: @finding.category
      }
    )

    prompt
  end

  # Suggest sources that might be relevant to content
  def suggest_sources
    @report = params[:report]
    @content = params[:content]
    @sources = @report.sources.processed
    @source_summaries = @sources.map do |s|
      { id: s.id, name: s.display_name, type: s.source_type, summary: s.summary&.truncate(200) }
    end

    create_context(
      contextable: @report,
      input_params: {
        action: "suggest_sources",
        content_length: @content.length,
        available_sources: @source_summaries.count
      }
    )

    prompt
  end

  private

  def build_source_context
    return "" if @sources.blank?

    @sources.map do |source|
      content = source.context_for_ai&.truncate(5000)
      next unless content.present?

      <<~SOURCE
        ## Source: #{source.display_name} (ID: #{source.id})
        Type: #{source.source_type.upcase}
        #{source.url.present? ? "URL: #{source.url}" : ""}

        Content:
        #{content}

        ---
      SOURCE
    end.compact.join("\n")
  end

  def broadcast_chunk(chunk)
    return unless chunk.message
    return unless params[:stream_id]

    @accumulated_content ||= ""
    @accumulated_content = chunk.message[:content] if chunk.message[:content].present?

    ActionCable.server.broadcast(params[:stream_id], { content: chunk.message[:content] })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    ActionCable.server.broadcast(params[:stream_id], {
      done: true,
      sources_used: @sources&.pluck(:id)
    })
  end
end
