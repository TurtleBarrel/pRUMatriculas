extends PanelContainer

@export_enum('Earliest', 'Latest') var mode = 'Earliest'
@export var selected_list:MarginContainer = null

@onready var hour_entry: LineEdit = %hour_entry
@onready var minute_entry: LineEdit = %minute_entry
@onready var entry_nodes_container: HBoxContainer = %Entry_nodes

@onready var am_button: Button = %am
@onready var pm_button: Button = %pm
@onready var toggle: CheckButton = %toggle


var num_string:String = '0123456789'

var old_hour_text:String = ''
var old_hour_col:int = 0
var old_minute_text:String = ''
var old_minute_col:int = 0

func _ready() -> void:
	toggle.text = mode
	toggle.button_pressed = false
	toggle.toggled.emit(false)
	if mode == 'Earliest':
		hour_entry.text = '12'
		minute_entry.text = '00'
		am_button.button_pressed = true
	elif mode == 'Latest':
		hour_entry.text = '11'
		minute_entry.text = '59'
		pm_button.button_pressed = true
	#if selected_list != null:
		#selected_list.filters_changed.connect(func(): prints(mode,'wowoa');print())

func _on_hour_entry_text_changed(new_text: String) -> void:
	fix_invalid('hour', new_text)
func _on_minute_entry_text_changed(new_text: String) -> void:
	fix_invalid('minute', new_text)

func fix_invalid(entry:String, new_text:String):
	var line_edit:LineEdit
	if entry == 'minute':
		line_edit = minute_entry
	elif entry == 'hour':
		line_edit = hour_entry
		
	var valid:bool = true
	for num:String in new_text:
		if num_string.contains(num) == false:
			valid = false
			break 
	
	if valid == false:
		if entry == 'minute':
			line_edit.text = old_minute_text
			line_edit.caret_column = old_minute_col
		elif entry == 'hour':
			line_edit.text = old_hour_text
			line_edit.caret_column = old_hour_col
	else:
		if entry == 'minute':
			old_minute_text = new_text
			old_minute_col = line_edit.caret_column
		elif entry == 'hour':
			old_hour_text = new_text
			old_hour_col = line_edit.caret_column

func _on_hour_entry_text_submitted(new_text: String) -> void:
	set_hour(new_text, true)
func _on_hour_entry_focus_exited() -> void:
	set_hour(hour_entry.text, false)
	set_filter_values()
	
func set_hour(time_text:String, unfocus:bool):
	if int(time_text) > 12 and int(time_text) < 24:
		hour_entry.text = str(int(time_text)-12)
		old_hour_text = str(int(time_text)-12)
		pm_button.button_pressed = true
	elif int(time_text) >= 24 or int(time_text) == 0:
		hour_entry.text = '12'
		old_hour_text = '12'
		am_button.button_pressed = true
		
	if unfocus == true:
		hour_entry.release_focus()
	

func _on_minute_entry_text_submitted(new_text: String) -> void:
	set_minute(new_text,true)
func _on_minute_entry_focus_exited() -> void:
	set_minute(minute_entry.text,false)
	set_filter_values()
	
func set_minute(time_text:String, unfocus:bool):
	if int(time_text) < 10 and time_text.length() < 2:
		minute_entry.text = '0'+str(time_text)
		old_minute_text = '0'+str(time_text)
	elif int(time_text) >= 60:
		minute_entry.text = '59'
		old_minute_text = '59'

	if unfocus == true:
		minute_entry.release_focus()
	
func set_filter_values():
	var time_num:float = int(hour_entry.text) + float(minute_entry.text)/60.0
	
	if floor(time_num) != 12:
		if pm_button.button_pressed == true:
			time_num += 12
	else:
		if am_button.button_pressed == true:
			time_num -= 12

	if selected_list != null:
		if mode == 'Earliest':
			selected_list.earliest = time_num
		elif mode == 'Latest':
			selected_list.latest = time_num
			
		selected_list.filters_changed.emit()
		
func _on_toggle_toggled(toggled_on: bool) -> void:
	hour_entry.editable = toggled_on
	hour_entry.selecting_enabled = toggled_on
	minute_entry.editable = toggled_on
	minute_entry.selecting_enabled = toggled_on
	
	
	am_button.disabled = !toggled_on
	pm_button.disabled = !toggled_on
	
	
	if mode == 'Earliest':
		selected_list.earliest_filtered = toggled_on
	elif mode == 'Latest':
		selected_list.latest_filtered = toggled_on
	selected_list.filters_changed.emit()
	
	if toggled_on == true:
		am_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		self.add_theme_stylebox_override('panel',load("uid://dm5c86g2m5qm2"))
		self.self_modulate = Color.WHITE
	else:
		am_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		pm_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		self.add_theme_stylebox_override('panel',load("uid://1otcojtmqd2n"))
		self.self_modulate = Color(0.6,0.6,0.6)


func _on_am_pressed() -> void:
	set_filter_values()
func _on_pm_pressed() -> void:
	set_filter_values()
