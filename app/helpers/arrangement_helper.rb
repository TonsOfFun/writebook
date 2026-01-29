module ArrangementHelper
  def arrangement_tag(report, **, &)
    tag.div data: {
      controller: "arrangement reading-progress",
      arrangement_cursor_class: "arrangement-cursor",
      arrangement_selected_class: "arrangement-selected",
      arrangement_placeholder_class: "arrangement-placeholder",
      arrangement_adding_mode_class: "arrangement--adding",
      arrangement_move_mode_class: "arrangement-move-mode",
      arrangement_url_value: report_chapters_moves_url(report),
      reading_progress_report_id_value: report.id,
      reading_progress_last_read_class: "toc__chapter--last-read"
    }, **, &
  end

  def arrangement_actions
    actions = {
      "click": "click",
      "dragstart": "dragStart",
      "dragover": "dragOver:prevent",
      "dragend": "dragEnd",
      "drop": "drop",
      "keydown.up": "moveBefore",
      "keydown.right": "moveAfter",
      "keydown.down": "moveAfter",
      "keydown.left": "moveBefore",
      "keydown.shift+up": "moveBefore",
      "keydown.shift+right": "moveAfter",
      "keydown.shift+down": "moveAfter",
      "keydown.shift+left": "moveBefore",
      "keydown.space": "toggleMoveMode",
      "keydown.enter": "applyMoveMode",
      "keydown.esc": "cancelMoveMode"
    }

    actions.map { |action, target| "#{action}->arrangement##{target}" }.join(" ")
  end
end
