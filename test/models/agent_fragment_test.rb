require "test_helper"

class AgentFragmentTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "WritingAssistantAgent")
  end

  test "creates fragment with required attributes" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "This is the original text."
    )

    assert fragment.persisted?
    assert_equal "improve", fragment.action_type
    assert_equal "This is the original text.", fragment.original_content
    assert_equal "pending", fragment.status
  end

  test "computes content hash on create" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test content"
    )

    expected_hash = Digest::SHA256.hexdigest("Test content")
    assert_equal expected_hash, fragment.content_hash
  end

  test "creates fragment with polymorphic contextable" do
    page = pages(:welcome)

    fragment = AgentFragment.create!(
      agent_context: @context,
      contextable: page,
      action_type: "improve",
      original_content: "Test content"
    )

    assert_equal page, fragment.contextable
    assert_equal "Page", fragment.contextable_type
    assert_equal page.id, fragment.contextable_id
  end

  test "creates fragment with position offsets" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "selected text",
      start_offset: 100,
      end_offset: 113
    )

    assert_equal 100, fragment.start_offset
    assert_equal 113, fragment.end_offset
  end

  test "mark_generating! updates status" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test"
    )

    fragment.mark_generating!

    assert_equal "generating", fragment.status
  end

  test "mark_generated! updates status and content" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original"
    )

    fragment.mark_generated!("Improved content here")

    assert_equal "generated", fragment.status
    assert_equal "Improved content here", fragment.generated_content
  end

  test "mark_applied! updates status and content" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original",
      generated_content: "Generated"
    )

    fragment.mark_applied!

    assert_equal "applied", fragment.status
    assert_equal "Generated", fragment.applied_content
  end

  test "mark_applied! can use different content than generated" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original",
      generated_content: "Generated"
    )

    fragment.mark_applied!("User edited version")

    assert_equal "applied", fragment.status
    assert_equal "User edited version", fragment.applied_content
  end

  test "mark_discarded! updates status" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test"
    )

    fragment.mark_discarded!

    assert_equal "discarded", fragment.status
  end

  test "version_history returns chain of fragments" do
    parent = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original"
    )

    child = AgentFragment.create!(
      agent_context: @context,
      parent_fragment: parent,
      action_type: "improve",
      original_content: "Original"
    )

    grandchild = AgentFragment.create!(
      agent_context: @context,
      parent_fragment: child,
      action_type: "improve",
      original_content: "Original"
    )

    history = grandchild.version_history
    assert_equal 3, history.length
    assert_equal parent, history[0]
    assert_equal child, history[1]
    assert_equal grandchild, history[2]
  end

  test "has_references? returns true when references exist" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      detected_references: [
        { "url" => "https://example.com", "text" => "Example" }
      ]
    )

    assert fragment.has_references?
  end

  test "has_references? returns false when no references" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test"
    )

    assert_not fragment.has_references?
  end

  test "accepted_references returns only accepted refs" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      detected_references: [
        { "url" => "https://a.com", "text" => "A", "accepted" => true },
        { "url" => "https://b.com", "text" => "B", "accepted" => false },
        { "url" => "https://c.com", "text" => "C" }  # No accepted key defaults to true
      ]
    )

    accepted = fragment.accepted_references
    assert_equal 2, accepted.length
    assert_equal "https://a.com", accepted[0]["url"]
    assert_equal "https://c.com", accepted[1]["url"]
  end

  test "rejected_references returns only rejected refs" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      detected_references: [
        { "url" => "https://a.com", "text" => "A", "accepted" => true },
        { "url" => "https://b.com", "text" => "B", "accepted" => false }
      ]
    )

    rejected = fragment.rejected_references
    assert_equal 1, rejected.length
    assert_equal "https://b.com", rejected[0]["url"]
  end

  test "regenerate_with creates child fragment" do
    parent = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test content",
      start_offset: 10,
      end_offset: 22,
      detected_references: [{ "url" => "https://a.com" }]
    )

    child = parent.regenerate_with(
      new_references: [{ "url" => "https://b.com" }]
    )

    assert child.persisted?
    assert_equal parent, child.parent_fragment
    assert_equal parent.original_content, child.original_content
    assert_equal parent.start_offset, child.start_offset
    assert_equal parent.end_offset, child.end_offset
    assert_equal "pending", child.status
    assert_equal [{ "url" => "https://b.com" }], child.detected_references
  end

  test "action_label returns titleized action" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "expand",
      original_content: "Test"
    )

    assert_equal "Expand", fragment.action_label
  end

  test "original_preview truncates content" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "This is a very long piece of content that should be truncated"
    )

    preview = fragment.original_preview(length: 20)
    assert_equal "This is a very lo...", preview
  end

  test "was_modified_on_apply? returns true when content differs" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original",
      generated_content: "Generated",
      applied_content: "User modified"
    )

    assert fragment.was_modified_on_apply?
  end

  test "was_modified_on_apply? returns false when content matches" do
    fragment = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Original",
      generated_content: "Generated",
      applied_content: "Generated"
    )

    assert_not fragment.was_modified_on_apply?
  end

  test "recent scope orders by created_at desc" do
    old = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Old",
      created_at: 1.day.ago
    )

    new = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "New"
    )

    fragments = AgentFragment.recent
    assert_equal new, fragments.first
    assert_equal old, fragments.last
  end

  test "active scope excludes discarded" do
    active = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Active"
    )

    discarded = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Discarded",
      status: "discarded"
    )

    fragments = AgentFragment.active
    assert_includes fragments, active
    assert_not_includes fragments, discarded
  end

  test "with_generations scope includes only fragments with generated content" do
    with_gen = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      generated_content: "Generated"
    )

    without_gen = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test"
    )

    fragments = AgentFragment.with_generations
    assert_includes fragments, with_gen
    assert_not_includes fragments, without_gen
  end

  test "fragment_type enum works correctly" do
    selection = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      fragment_type: "selection"
    )

    full_doc = AgentFragment.create!(
      agent_context: @context,
      action_type: "improve",
      original_content: "Test",
      fragment_type: "full_document"
    )

    assert selection.fragment_type_selection?
    assert full_doc.fragment_type_full_document?
  end
end

class FragmentReferenceDetectorTest < ActiveSupport::TestCase
  test "detects standard markdown links" do
    content = "Check out [OpenAI](https://openai.com) for more info."
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal 1, refs.length
    assert_equal "OpenAI", refs[0][:text]
    assert_equal "https://openai.com", refs[0][:url]
    assert_equal :markdown, refs[0][:type]
  end

  test "detects multiple markdown links" do
    content = "See [Google](https://google.com) and [Bing](https://bing.com) for search."
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal 2, refs.length
    assert_equal "Google", refs[0][:text]
    assert_equal "Bing", refs[1][:text]
  end

  test "detects autolinks" do
    content = "Visit <https://example.com> for more."
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal 1, refs.length
    assert_equal "https://example.com", refs[0][:url]
    assert_nil refs[0][:text]
    assert_equal :autolink, refs[0][:type]
  end

  test "detects reference-style links" do
    content = <<~MARKDOWN
      Check [Ruby docs][ruby] for documentation.

      [ruby]: https://ruby-lang.org
    MARKDOWN

    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal 1, refs.length
    assert_equal "Ruby docs", refs[0][:text]
    assert_equal "https://ruby-lang.org", refs[0][:url]
    assert_equal :reference, refs[0][:type]
  end

  test "has_references? returns true when links exist" do
    content = "See [example](https://example.com)."
    detector = FragmentReferenceDetector.new(content)

    assert detector.has_references?
  end

  test "has_references? returns false when no links" do
    content = "Plain text without links."
    detector = FragmentReferenceDetector.new(content)

    assert_not detector.has_references?
  end

  test "reference_count returns correct count" do
    content = "[A](https://a.com) and [B](https://b.com) and [C](https://c.com)"
    detector = FragmentReferenceDetector.new(content)

    assert_equal 3, detector.reference_count
  end

  test "removes duplicate URLs" do
    content = "[First](https://example.com) and [Second](https://example.com)"
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal 1, refs.length
  end

  test "normalizes URLs by removing trailing punctuation" do
    content = "See [example](https://example.com,)."
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal "https://example.com", refs[0][:url]
  end

  test "all references default to accepted" do
    content = "[Link](https://example.com)"
    detector = FragmentReferenceDetector.new(content)

    refs = detector.detect_references
    assert_equal true, refs[0][:accepted]
  end

  test "handles empty content" do
    detector = FragmentReferenceDetector.new("")
    assert_equal [], detector.detect_references
    assert_not detector.has_references?
  end

  test "handles nil content" do
    detector = FragmentReferenceDetector.new(nil)
    assert_equal [], detector.detect_references
  end
end
