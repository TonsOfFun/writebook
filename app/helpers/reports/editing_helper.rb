module Reports::EditingHelper
  def editing_mode_toggle_switch(chapter, checked:)
    target_url = checked ? chapterable_slug_path(chapter) : edit_chapterable_path(chapter)
    render "reports/edit_mode", target_url: target_url, checked: checked
  end
end
