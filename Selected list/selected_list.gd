extends MarginContainer

signal column_toggled(column, shown)
signal filters_changed
signal search_changed

@onready var entry_container: VBoxContainer = %selected
@onready var options_tabs: TabContainer = %Option_tabs
@onready var pop_out_button: Button = %pop_out_button
@onready var hide_disabled: CheckButton = %"Hide disabled"
@onready var hide_conflicting: CheckButton = %"Hide conflicting"
@onready var toggle_options: Button = %toggle_options
@onready var section_previews: CheckButton = %"Section previews"
@onready var caps_button: Button = %caps
@onready var column_titles: HBoxContainer = %column_titles
@onready var column_titles_margins: MarginContainer = %column_titles_margins
@onready var window_on_top_toggle: Button = %window_on_top_toggle


var caps_shown:bool = false
var creds_shown:bool = true
var rooms_shown:bool = true
var days_shown:bool = true
var times_shown:bool = true
var professors_shown:bool = true

var parent_node

## Set by columns
var sections_size:Vector2 = Vector2(0,0)
var capacities_size:Vector2 = Vector2(0,0)
var credits_size:Vector2 = Vector2(0,0)
var schedules_size:Vector2 = Vector2(0,0)
var professors_size:Vector2 = Vector2(0,0)

var dragging:bool = false
var offsets:PackedInt32Array

var search_text:String = ''
var disabled_hidden:bool = true
var overlapping_hidden:bool = false
var earliest_filtered:bool = false
var latest_filtered:bool = false

var earliest:float = 0
var latest:float = 23 + 59.0/60.0
var selected_days:Array = [0,1,2,3,4,5,6]

var preview_sections:bool = true

func _ready() -> void:
	selected.course_selected.connect(add_selected)
	gs.schedule_window_toggled.connect(
		func(windowed):
			if gs.mobile_device == false:
				window_on_top_toggle.visible = windowed
			
			if windowed == false:
				window_on_top_toggle.button_pressed = false
	)
	gs.mobile_detected.connect(pop_out_button.show)
	options_tabs.hide()
	hide_disabled.button_pressed = true
	hide_conflicting.button_pressed = false
	toggle_options.button_pressed = true
	section_previews.button_pressed = true
	caps_button.button_pressed = false
	

	
	parent_node = get_parent()
	gs.component_loaded.emit('selected_list')
	
func add_selected(code, course_node) -> void:
	var selected_course_entry = load("uid://1iosp7l2gf2g").instantiate()
	selected.selected_course_nodes.get_or_add(code,selected_course_entry)
	selected_course_entry.code = code
	selected_course_entry.course_node = course_node
	selected_course_entry.selected_list_node = self
	entry_container.add_child(selected_course_entry)

func _on_toggle_options_toggled(toggled_on: bool) -> void:
	options_tabs.visible = toggled_on

func _on_hide_disabled_toggled(toggled_on: bool) -> void:
	disabled_hidden = toggled_on
	filters_changed.emit()
func _on_hide_conflicting_toggled(toggled_on: bool) -> void:
	overlapping_hidden = toggled_on
	filters_changed.emit()
func _on_section_previews_toggled(toggled_on: bool) -> void:
	self.preview_sections = toggled_on



#region Window pop out
func _on_pop_out_button_toggled(toggled_on: bool) -> void:
	gs.selected_list_window_toggled.emit(toggled_on)
	window_on_top_toggle.visible = toggled_on
	if toggled_on == true:
		to_window()
		pop_out_button.icon = load("uid://fgt0bd733r21")
		pop_out_button.tooltip_text = 'Send back to main window'
	else:
		to_list(self.get_window())
		pop_out_button.icon = load("uid://e4f8wj4uohht")
		pop_out_button.tooltip_text = 'Pop out to new window'
		window_on_top_toggle.set_pressed_no_signal(false)

func to_window() -> void:
	var window = Window.new()
	GlobalScene.add_child(window)
	
	window.visible = false
	window.force_native = true
	window.min_size.y = 350
	window.min_size.x = self.custom_minimum_size.x
	if gs.mobile_device == true:
		window.theme = load("uid://dawkytrj124w4")
		
	var scroller = ScrollContainer.new()
	scroller.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(scroller)
	
	window.close_requested.connect(func(): pop_out_button.button_pressed = false)
	window.popup_centered(Vector2i(roundi(self.size.x/1.25),roundi(self.size.y/1.25)))
	
	self.reparent(scroller)

	self.add_theme_constant_override('margin_top',0)
	self.add_theme_constant_override('margin_right',0)
	self.add_theme_constant_override('margin_bottom',0)

func to_list(window_node) -> void:
	self.reparent(parent_node)
	self.add_theme_constant_override('margin_top',10)
	self.add_theme_constant_override('margin_right',0)
	self.add_theme_constant_override('margin_bottom',10)
	window_node.queue_free()
#endregion


func _on_window_on_top_toggle_toggled(toggled_on: bool) -> void:
	self.get_window().hide()
	self.get_window().always_on_top = toggled_on
	self.get_window().show()
