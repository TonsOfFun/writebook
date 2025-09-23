module TurboStreamActionsHelper
  def scroll_into_view(id, animation: nil)
    turbo_stream_action_tag :scroll_into_view, target: id, animation: animation
  end
end

Turbo::Streams::TagBuilder.prepend TurboStreamActionsHelper
