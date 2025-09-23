module LeavesHelper
  def leaf_item_tag(leaf, **, &)
    tag.li class: "arrangement__item toc__leaf toc__leaf--#{leaf.leafable_name}",
      id: dom_id(leaf),
      data: {
        id: leaf.id,
        arrangement_target: "item"
      }, **, &
  end

  def leaf_nav_tag(leaf, **, &)
    tag.nav data: {
      controller: "reading-tracker",
      reading_tracker_book_id_value: leaf.book_id,
      reading_tracker_leaf_id_value: leaf.id
    }, **, &
  end

  def leafable_edit_form(leafable, **, &)
    form_with model: leafable, url: leafable_path(leafable.leaf), method: :put, format: :html,
    data: {
      controller: "autosave",
      action: "autosave#submit:prevent input@document->autosave#change house-md:change->autosave#change",
      autosave_clean_class: "clean",
      autosave_dirty_class: "dirty",
      autosave_saving_class: "saving"
    }, **, &
  end
end
