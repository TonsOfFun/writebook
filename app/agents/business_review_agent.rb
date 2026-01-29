class BusinessReviewAgent < ApplicationAgent
  has_context

  generate_with :openai,
    model: "gpt-4o",
    stream: true,
    instructions: <<~INSTRUCTIONS
      You are a business-focused reviewer helping improve technology diligence reports.
      Your role is to ensure reports are:
      - Clear and understandable by non-technical stakeholders
      - Actionable with concrete recommendations
      - Properly scoped with appropriate severity assessments
      - Complete and comprehensive
      - Well-organized and professionally written

      You provide suggestions like a collaborative editor - offering specific changes
      that authors can accept, reject, or discuss.
    INSTRUCTIONS

  on_stream :broadcast_chunk
  on_stream_close :broadcast_complete

  # Review content and generate suggestions
  def review_content
    @content = params[:content]
    @content_type = params[:content_type] || "page"
    @focus = params[:focus] || "clarity"
    @suggestable = params[:suggestable]

    create_context(
      contextable: @suggestable,
      input_params: {
        action: "review_content",
        content_type: @content_type,
        focus: @focus,
        content_length: @content.length
      }
    )

    prompt
  end

  # Review a finding for business appropriateness
  def review_finding
    @finding = params[:finding]
    @content_type = "finding"

    create_context(
      contextable: @finding,
      input_params: {
        action: "review_finding",
        severity: @finding.severity,
        category: @finding.category,
        status: @finding.status
      }
    )

    prompt
  end

  # Suggest improvements to executive summary
  def review_summary
    @report = params[:report]
    @summary = params[:summary]

    create_context(
      contextable: @report,
      input_params: {
        action: "review_summary",
        summary_length: @summary&.length || 0
      }
    )

    prompt
  end

  # Review overall report structure
  def review_structure
    @report = params[:report]
    @chapters = @report.chapters.active.positioned
    @findings_count = @report.chapters.active.joins("INNER JOIN findings ON findings.id = chapters.chapterable_id AND chapters.chapterable_type = 'Finding'").count

    create_context(
      contextable: @report,
      input_params: {
        action: "review_structure",
        chapter_count: @chapters.count,
        findings_count: @findings_count
      }
    )

    prompt
  end

  private

  def broadcast_chunk(chunk)
    return unless chunk.message
    return unless params[:stream_id]

    @accumulated_content ||= ""
    @accumulated_content = chunk.message[:content] if chunk.message[:content].present?

    ActionCable.server.broadcast(params[:stream_id], { content: chunk.message[:content] })
  end

  def broadcast_complete(chunk)
    return unless params[:stream_id]

    # Parse accumulated content for suggestions if applicable
    suggestions = parse_suggestions_from_response

    ActionCable.server.broadcast(params[:stream_id], {
      done: true,
      suggestions_count: suggestions.count
    })
  end

  def parse_suggestions_from_response
    return [] unless @accumulated_content.present?
    return [] unless @suggestable.present?

    suggestions = []

    # Try to parse structured suggestions from the response
    # Look for markdown-style suggestion blocks
    @accumulated_content.scan(/\*\*Suggestion\*\*:\s*(.+?)\n\*\*Original\*\*:\s*(.+?)\n\*\*Suggested\*\*:\s*(.+?)(?=\n\n|\z)/m).each do |match|
      comment, original, suggested = match
      suggestions << @suggestable.create_suggestion(
        type: "edit",
        original_text: original.strip,
        suggested_text: suggested.strip,
        comment: comment.strip,
        ai_generated: true
      )
    end

    suggestions
  rescue => e
    Rails.logger.warn "[BusinessReviewAgent] Failed to parse suggestions: #{e.message}"
    []
  end
end
