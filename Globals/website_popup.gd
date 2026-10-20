extends PanelContainer

@onready var link_label: Label = %link_label
@onready var popups_container: PanelContainer = %popup_shade
var active_url:String

func display_leaving_popup(url) -> void:
	link_label.text = url
	active_url = url
	popups_container.show()
	self.show()


func _on_cancel_pressed() -> void:
	popups_container.hide()

func _on_ok_pressed() -> void:
	popups_container.hide()
	OS.shell_open(active_url)
