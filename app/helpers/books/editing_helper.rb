module Books::EditingHelper
  def editing_mode_toggle_switch(leaf, checked:)
    target_url = checked ? leafable_slug_path(leaf) : edit_leafable_path(leaf)
    render "books/edit_mode", target_url: target_url, checked: checked
  end
end
