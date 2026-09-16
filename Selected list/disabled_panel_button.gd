extends PanelContainer

var hovering:bool = false

var default_color = Color(0.627, 0.627, 0.627, 1.0)
var hovered_color = Color.WHITE
func _ready() -> void:
	self.self_modulate = default_color

func _on_mouse_entered() -> void:
	hovering = true
	self.self_modulate = hovered_color
func _on_mouse_exited() -> void:
	hovering = false
	self.self_modulate=  default_color

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb") and hovering:
		owner.enable_all.emit()
