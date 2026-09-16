extends PanelContainer

@onready var check_box:CheckBox = self.get_child(0)

var subject_remover:Button
var subject:String

func _ready() -> void:
	check_box.text = subject
	
	check_box.toggled.connect(
		func(toggled_on):
			if toggled_on == true:
				subject_remover.selected_to_remove.append(subject)
			else:
				subject_remover.selected_to_remove.erase(subject)
	)
