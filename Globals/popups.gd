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
