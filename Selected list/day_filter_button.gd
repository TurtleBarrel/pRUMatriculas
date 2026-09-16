extends Button


func _ready() -> void:
	gs.weekends_toggled.connect(
		func(toggled_on):
			if get_meta("day_num") == 0 or get_meta("day_num") == 6:
				self.disabled = !toggled_on
				if toggled_on == true:
					self.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				else:
					self.mouse_default_cursor_shape = Control.CURSOR_ARROW
				
	)

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on == true: 
		owner.selected_days.append(self.get_meta('day_num'))
	else:
		owner.selected_days.erase(self.get_meta('day_num'))
	owner.filters_changed.emit()
