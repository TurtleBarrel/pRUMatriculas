extends Button

func _ready() -> void:
	self.visible = converter.website_button_active

func _on_pressed() -> void:
	popups.website_popup.display_leaving_popup(converter.website_url)
