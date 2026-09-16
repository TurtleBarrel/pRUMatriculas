extends LineEdit

@onready var entries: VBoxContainer = %Entries_unpinned



func _on_text_changed(new_text: String) -> void:
	for entry in entries.get_children():
		if entry.code.to_lower().contains(new_text.strip_edges().to_lower()) == true or new_text.strip_edges().is_empty():
			entry.show()
		else:
			entry.hide() 

	
