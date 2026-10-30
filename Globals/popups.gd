extends Node

@onready var update_popup: PanelContainer = %update_popup
@onready var website_popup: PanelContainer = %website_popup
@onready var popups_container: PanelContainer = %popup_shade

func _ready() -> void:
	popups_container.hide()
	gs.component_loads_finished.connect(
		func():
			get_parent().call_deferred("move_child",self,-1)
	)

func create_popout_window(close_func,min_size = Vector2i.ZERO) -> Window:
	var window = Window.new()
	window.visible = false
	window.min_size = min_size
	window.force_native = true
	window.close_requested.connect(close_func)
	
	if gs.mobile_device == true:
		window.theme = load("uid://dawkytrj124w4")
	
	self.add_child(window)
	
	return window
