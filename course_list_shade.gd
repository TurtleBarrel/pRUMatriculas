extends HBoxContainer

func _ready() -> void:
	gs.course_list_toggled.connect(func(hid): self.visible = !hid)
