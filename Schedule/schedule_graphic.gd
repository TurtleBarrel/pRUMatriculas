extends MarginContainer

signal columns_ready
signal column_scrolled(value,source)

@onready var weekday_node: PanelContainer = %weekday_node
@onready var columns:Array = [%Times, %Sunday, %Monday, %Tuesday, %Wednesday, %Thursday, %Friday, %Saturday]
@onready var sun_left_separator: VSeparator = %sun_left
@onready var sat_left_separator: VSeparator = %sat_left
@onready var weekend_toggle: CheckButton = %"Weekend toggle"
@onready var pop_out_button: Button = %Window_toggle
@onready var graphic_background: PanelContainer = %graphic_background
@onready var graph_options: PanelContainer = %Graph_options
@onready var table_node: PanelContainer = %Table
@onready var window_on_top_toggle: Button = %window_on_top_toggle
@onready var table_graphic_splitter: VSplitContainer = %table_grpahic_splitter

var start_override:bool = true
var end_override:bool = true
var start_margin:int = 1
var end_margin:int = 1
var start:int = 6
var end:int = 20

var parent_node
var win_node:Window

func _ready() -> void:
	weekend_toggle.button_pressed = false
	weekend_toggle.toggled.emit(false)
	window_on_top_toggle.hide()
	parent_node = get_parent()

	var table_graphic_handle = table_graphic_splitter.get_child(-1,true)
	table_graphic_handle.modulate = Color(0.5, 0.5, 0.5, 1.0)


	selected.selected_course_sections_added.connect(
		func(code):
			var section_nums_array = gs.course_info_by_code[code]['sections'].keys()
			for sec_num in section_nums_array:
				var sec_dict = gs.course_info_by_code[code]['sections'][sec_num]
				add_section_blocks(code, sec_dict, sec_num)
	)

	selected.overlap_updated.connect(warn_overlap)

func add_section_blocks(code, section_dict, sec_num) -> void:
	var day_groups_num:Array = section_dict['days_num']
	var times_num:Array = section_dict['times_num']
	var block_scene = load("uid://d3gvanju60gwk")
	if section_dict['async'] == false:
		#var section_color = Color(randf_range(0.35,0.6),randf_range(0.35,0.6),randf_range(0.35,0.6),0.75)
		for group in day_groups_num.size():
			for day in day_groups_num[group]:
				var sect_block_container = columns[day+1].sect_block_container
				var block = block_scene.instantiate()
				block.code = code
				block.graph_node = self
				block.sect_block_container = sect_block_container
				block.start = times_num[group]['start']
				block.end = times_num[group]['end']
				block.sec_dict = section_dict
				block.sec_num = sec_num
				block.block_index = group
				block.visible = false
				block.z_index = 1
				block.section_list_entry_node = selected.available_section_nodes[code][sec_num]
				selected.available_section_nodes[code][sec_num].graphic_block_nodes.append(block)
				
				sect_block_container.add_child(block)
				block.set_block()

func warn_overlap(overlapping) -> void:
	if overlapping == true:
		graphic_background.self_modulate = Color.RED
	else:
		graphic_background.self_modulate = Color.WHITE

func _on_toggle_options_toggled(toggled_on: bool) -> void:
	graph_options.visible = toggled_on

func _on_weekend_toggle_toggled(toggled_on: bool) -> void:
	gs.weekends_toggled.emit(toggled_on)
	columns[1].visible = toggled_on
	sun_left_separator.visible = toggled_on
	columns[7].visible = toggled_on
	sat_left_separator.visible = toggled_on

#region Window popout

func _on_window_toggle_toggled(toggled_on: bool) -> void:
	gs.schedule_window_toggled.emit(toggled_on)
	window_on_top_toggle.visible = toggled_on
	if toggled_on == true:
		to_window()
		pop_out_button.add_theme_icon_override('icon',load("uid://fgt0bd733r21"))
		pop_out_button.tooltip_text = 'Send back to main window'
		
	else:
		to_list(self.get_window())
		pop_out_button.add_theme_icon_override('icon',load("uid://e4f8wj4uohht"))
		pop_out_button.tooltip_text = 'Pop out to new window'
		window_on_top_toggle.set_pressed_no_signal(false)
		gs.reset_main_window_min_size()
		

func to_window() -> void:
	var window = Window.new()
	#gs.main_scene_node.add_child(window)
	GlobalScene.add_child(window)
	
	win_node = window
	window.visible = false
	window.force_native = true
	window.transient = false
	window.min_size.x = self.custom_minimum_size.x
	window.min_size.y = 350
	if gs.mobile_device == true:
		window.theme = load("uid://dawkytrj124w4")
	
	var scroller = ScrollContainer.new()
	scroller.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(scroller)
	
	window.close_requested.connect(func(): pop_out_button.button_pressed = false)
	window.popup_centered(Vector2i(roundi(self.size.x/1.1),roundi(self.size.y/1.25)))
	
	self.reparent(scroller)

	self.add_theme_constant_override('margin_left',0)
	self.add_theme_constant_override('margin_top',0)
	self.add_theme_constant_override('margin_right',0)
	self.add_theme_constant_override('margin_bottom',0)

func to_list(window_node) -> void:
	self.reparent(parent_node)
	parent_node.move_child(self,1)
	self.add_theme_constant_override('margin_left',25)
	self.add_theme_constant_override('margin_top',10)
	self.add_theme_constant_override('margin_right',0)
	self.add_theme_constant_override('margin_bottom',10)
	window_node.queue_free()

func _on_window_on_top_toggle_toggled(toggled_on: bool) -> void:
	self.get_window().visible = false
	self.get_window().always_on_top = toggled_on
	self.get_window().visible = true

#endregion


func _on_table_toggle_toggled(toggled_on: bool) -> void:
	table_node.visible = toggled_on
