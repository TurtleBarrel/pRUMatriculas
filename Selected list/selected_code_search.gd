extends LineEdit


func _on_text_changed(new_text: String) -> void:
	owner.search_text = new_text
	owner.search_changed.emit()
