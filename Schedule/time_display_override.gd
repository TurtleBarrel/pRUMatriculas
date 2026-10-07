extends LineEdit

@onready var spin_box_override: SpinBox = %SpinBox_override

var allowed_chars:String = '1234567890apm'
var text_change_from_clear:bool = false
var old_text:String = ''

func _ready() -> void:
	owner.time_display_override = self
	spin_box_override.get_line_edit().hide()
	spin_box_override.get_line_edit().focus_mode = Control.FOCUS_NONE
	self.reparent(spin_box_override.get_line_edit().get_parent())



func _on_text_submitted(new_text: String) -> void:
	new_text = new_text.to_lower()
	var chars_valid:bool = true
	for char_ in new_text:
		if allowed_chars.contains(char_) == false:
			chars_valid = false
			self.text = old_text
			break
	
	var text_valid:bool = true
	if chars_valid == true and new_text.is_empty() == false:
		## Check that it doesn't start with a/p/m
		if new_text[0].is_valid_int() == false:
			text_valid = false
		## 24-hour format checks
		elif new_text.is_valid_int():
			## Check that if entering in 24h time, there's only 1 or 2 digits
			if new_text.length() > 2:
				text_valid = false
			## Check that time entered is between possible limits
			elif int(new_text) < 0 or int(new_text) > 24:
				text_valid = false
		## 12-hour format checks
		else:
			## Check min length for 12-hour entry (i.e. 9pm)
			if new_text.length() < 3:
				text_valid = false
			## 1-digit hour checks
			elif new_text.length() == 3:
				## Check suffix
				if new_text.substr(1,2) != 'am' and new_text.substr(1,2) != 'pm':
					text_valid = false
				## Check it's not 0pm
				elif new_text.substr(1,2) == 'pm' and int(new_text[0]) == 0:
					text_valid = false
			## 2-digit hour checks
			elif new_text.length() == 4:
				## Check suffix
				if new_text.substr(2,2) != 'am' and new_text.substr(2,2) != 'pm':
					text_valid = false
				## Check first to chars are ints
				elif new_text.substr(0,2).is_valid_int() == false:
					text_valid = false
				## Check it's within bounds
				elif int(new_text.substr(0,2)) < 0 or int(new_text.substr(0,2)) > 12:
					text_valid = false
				## Check it's not 00pm
				elif new_text.substr(2,2) == 'pm' and int(new_text.substr(0,2)) == 0:
					text_valid = false
	if chars_valid == true:
		if text_valid == true and new_text.is_empty() == false:
			var time_value:int
			var pm_mod:int = 0
			if new_text.contains('pm') and new_text.substr(0,2) != '12':
				pm_mod = 12
			if new_text == '12am':
				if owner.mode == 'start':
					time_value = 0
				elif owner.mode == 'end':
					time_value = 24
			elif new_text.length() < 3:
				time_value = int(new_text)
			elif new_text.length() == 3:
				time_value = int(new_text[0]) + pm_mod
			elif new_text.length() == 4:
				time_value = int(new_text.substr(0,2)) + pm_mod
			
			var graph_node = gs.main_scene_node.graph_node
			if owner.mode == 'start':
				if time_value >= graph_node.end:
					time_value = graph_node.end-1
			elif owner.mode == 'end':
				if time_value <= graph_node.start:
					time_value = graph_node.start+1
			spin_box_override.value = time_value
			spin_box_override.value_changed.emit(time_value)
			old_text = text
		else: 
			self.text = old_text
	self.release_focus()
