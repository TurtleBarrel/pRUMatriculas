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

@export var parent_node:HSplitContainer
@export var schedule_node:MarginContainer
@export var course_list:MarginContainer

var caps_shown:bool = false
var creds_shown:bool = true
var rooms_shown:bool = true
var days_shown:bool = true
var times_shown:bool = true
var professors_shown:bool = true

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
var preview_sections:bool = true

var earliest:float = 0
var latest:float = 23 + 59.0/60.0
var selected_days:Array = [0,1,2,3,4,5,6]

var windowed:bool = false

func _ready() -> void:
	selected.course_selected.connect(add_selected)
	gs.schedule_window_toggled.connect(
		func(windowed):
			if gs.mobile_device == false:
				window_on_top_toggle.visible = windowed
			if windowed == false:
				window_on_top_toggle.button_pressed = false
	)
	pop_out_button.hide()
	gs.platform_detected.connect(func(is_mobile): pop_out_button.visible = is_mobile)
	options_tabs.hide()
	hide_disabled.button_pressed = true
	hide_conflicting.button_pressed = false
	toggle_options.button_pressed = true
	section_previews.button_pressed = true
	caps_button.button_pressed = false
	
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
func set_popout_display(popped_out):
	if popped_out == true:
		pop_out_button.icon = load("uid://fgt0bd733r21")
		pop_out_button.tooltip_text = 'Send back to main window'
		self.add_theme_constant_override('margin_top',0)
		self.add_theme_constant_override('margin_right',0)
		self.add_theme_constant_override('margin_bottom',0)
		if schedule_node.windowed == false:
			schedule_node.add_theme_constant_override('margin_right',10)
		
	else:
		pop_out_button.icon = load("uid://e4f8wj4uohht")
		pop_out_button.tooltip_text = 'Pop out to new window'
		self.add_theme_constant_override('margin_top',10)
		self.add_theme_constant_override('margin_right',10)
		self.add_theme_constant_override('margin_bottom',10)
		schedule_node.add_theme_constant_override('margin_right',0)
		if schedule_node.windowed == true:
			self.add_theme_constant_override('margin_left',25)
		
		
func _on_pop_out_button_toggled(toggled_on: bool) -> void:
	gs.selected_list_window_toggled.emit(toggled_on)
	window_on_top_toggle.visible = toggled_on
	set_popout_display(toggled_on)
	if toggled_on == true:
		to_window()
	else:
		close_window()
		window_on_top_toggle.set_pressed_no_signal(false)



func to_window() -> void:
	## Can only run in mobile version; button is hidden on PC.
	var window_closer = close_window
	var window = popups.create_popout_window(window_closer,Vector2i(roundi(self.custom_minimum_size.x),350))
	self.windowed = true
	self.add_theme_constant_override('margin_left',0)
	var scroller = ScrollContainer.new()
	scroller.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(scroller)
	self.reparent(scroller)


	window.popup_centered(Vector2i(roundi(self.size.x/1.25),roundi(self.size.y/1.25)))


func close_window() -> void:
	get_window().call_deferred('queue_free')
	self.window_on_top_toggle.visible = false
	self.window_on_top_toggle.button_pressed = false
	self.set_popout_display(false)
	self.windowed = false
	if gs.mobile_device == true:
		self.reparent(parent_node)
		self.pop_out_button.set_pressed_no_signal(false)
	else:
		## TODO Fix margins when changing window
		var sched_window = schedule_node.get_window()
		if self.get_window() == sched_window:
			get_tree().quit()
		else:
			## Move main_scene (selected list's scene) to the schedule window
			## Move schedule back to main_scene
			gs.main_scene_node.reparent(sched_window)
			gs.main_window = sched_window
			gs.reset_main_window_min_size()
			sched_window.close_requested.connect(close_window)
			files.connect_file_drop_signal(sched_window)
			
			schedule_node.reparent(schedule_node.parent_node)
			schedule_node.parent_node.show()
			schedule_node.window_on_top_toggle.visible = false
			schedule_node.window_on_top_toggle.button_pressed = false
			schedule_node.pop_out_button.set_pressed_no_signal(false)
			schedule_node.set_popout_display(false)
		
#endregion


func _on_window_on_top_toggle_toggled(toggled_on: bool) -> void:
	self.get_window().hide()
	self.get_window().always_on_top = toggled_on
	self.get_window().show()
