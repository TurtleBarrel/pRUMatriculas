extends PanelContainer

@onready var popups_container: PanelContainer = %popup_shade
@onready var website_popup: PanelContainer = %website_popup

@onready var version: Label = %version
@onready var changelog: Label = %Changelog

func _ready() -> void:
	gs.component_loads_finished.connect(check_for_update)

func check_for_update() -> void:
	var http_request = HTTPRequest.new()
	http_request.request_completed.connect(
		func(_result, _response_code, _headers, body):
			var JSON_result = JSON.parse_string(body.get_string_from_utf8())
			if JSON_result != null and JSON_result is Dictionary and JSON_result.has_all(['name','body']):
				var current_version = ProjectSettings.get_setting("application/config/version")
				var latest_version = JSON_result['name']
				if current_version != latest_version:
					set_update_popup(JSON_result)
			http_request.queue_free()
	)
	self.add_child(http_request)
	http_request.request(converter.release_url)

func set_update_popup(release_dict:Dictionary) -> void:
	changelog.text = release_dict['body']
	version.text = release_dict['name']
	popups_container.show()
	self.show()

func _on_dismiss_update_pressed() -> void:
	popups_container.hide()

func _on_website_pressed() -> void:
	website_popup.display_leaving_popup(converter.website_url)
