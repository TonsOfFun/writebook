module ChaptersHelper
  def chapter_item_tag(chapter, **, &)
    tag.li class: "arrangement__item toc__chapter toc__chapter--#{chapter.chapterable_name}",
      id: dom_id(chapter),
      data: {
        id: chapter.id,
        arrangement_target: "item"
      }, **, &
  end

  def chapter_nav_tag(chapter, **, &)
    tag.nav data: {
      controller: "reading-tracker",
      reading_tracker_report_id_value: chapter.report_id,
      reading_tracker_chapter_id_value: chapter.id
    }, **, &
  end

  def chapterable_edit_form(chapterable, **, &)
    form_with model: chapterable, url: chapterable_path(chapterable.chapter), method: :put, format: :html,
    data: {
      controller: "autosave",
      action: "autosave#submit:prevent input@document->autosave#change house-md:change->autosave#change",
      autosave_clean_class: "clean",
      autosave_dirty_class: "dirty",
      autosave_saving_class: "saving"
    }, **, &
  end
end
