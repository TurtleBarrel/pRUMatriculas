extends PanelContainer

signal disabled_count_changed
signal enable_all


@onready var sec_container: VBoxContainer = %sections
@onready var foldable: FoldableContainer = $FoldableContainer
@onready var disabled_icon: Panel = %disabled_icon
@onready var disabled_label: Label = %disabled_count
@onready var pop_out_button: Button = %"Pop out"
@onready var window_on_top_button: Button = %window_on_top_toggle

@onready var section_scroller: ScrollContainer = %section_scroller


var code:String
var course_node:PanelContainer
var selected_list_node:MarginContainer
var pinned_sect_count:int = 0
var section_count:int = 0

var disabled_count:int = 0
var disabled_gray = Color(0.4, 0.4, 0.4, 1.0)
var disabled_red = Color(1.0, 0.245, 0.188, 1.0)

var window_node:Window
var windowed:bool = false

func _ready() -> void:
	disabled_count_changed.connect(updated_disabled_indicator)
	selected_list_node.search_changed.connect(update_filter)
	
	disabled_icon.modulate = disabled_gray
	foldable.title = code
	foldable.fold()
	add_sections()
	
	
func add_sections() -> void:
	var sec_entry_scene = load("uid://bhidlko7ua0mk")
	
	var course_sections = gs.course_info_by_code[code]['sections']
	for sec_num in course_sections.keys():
		section_count += 1
		var sec_entry = sec_entry_scene.instantiate()
		
		sec_entry.selected_list_node = selected_list_node
		sec_entry.selected_course_node = self
		sec_entry.code = code
		
		var sec_dict = course_sections[sec_num]
		sec_entry.sec_num = sec_num
		sec_entry.capacity = int(sec_dict['cap'])
		sec_entry.credits = int(sec_dict['creds'])
		var schedules:Array = []
		if sec_dict['async'] == false:
			for i in sec_dict['days'].size():
				var days:String = sec_dict['days'][i]
				var times:String = sec_dict['times'][i]
				var room:String = sec_dict['rooms'][i]
				
				var spaces = ''
				for space in 7 - days.length():
					spaces += ' '
				schedules.append(days + spaces + times)
				
				sec_entry.days.append(days)
				sec_entry.times.append(times)
				sec_entry.rooms.append(room)
				
			sec_entry.schedules = schedules
		
		sec_entry.professors = sec_dict['prof']
		sec_entry.sec_dict = sec_dict
		
		selected.available_section_nodes.get_or_add(code,{})
		selected.available_section_nodes[code].get_or_add(sec_num,sec_entry)
		sec_container.add_child(sec_entry)
	selected.selected_course_sections_added.emit(code)
	alphabetize_unpinned_sections()
	
func _on_remove_pressed() -> void:
	course_node.select_button.button_pressed = false

func updated_disabled_indicator(change) -> void:
	disabled_count += change
	if disabled_count == 0:
		disabled_icon.modulate = disabled_gray
	else:
		disabled_icon.modulate = disabled_red
	disabled_label.text = str(disabled_count)

func update_filter() -> void:
	var search_text_clean = selected_list_node.search_text.strip_edges().to_lower()
	if self.code.to_lower().contains(search_text_clean) or search_text_clean.is_empty():
		self.visible = true
	else:
		self.visible = false

func to_window() -> void:
	var window = Window.new()
	gs.main_scene_node.add_child(window)
	window_node = window
	window.visible = false
	window.force_native = true
	window.min_size = Vector2(600,150)
	window.close_requested.connect(
		func():
			pop_out_button.button_pressed = false
			pop_out_button.toggled.emit(false)
	)
	window.popup_centered(Vector2i(300,300))
	
	var vbox:VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override('separation',0)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col_titles:MarginContainer = selected_list_node.column_titles_margins.duplicate()
	col_titles.selected_list = selected_list_node
	col_titles.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	col_titles.add_theme_constant_override('margin_left', 14)
	vbox.add_child(col_titles)

	self.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	window.add_child(vbox)
	self.reparent(vbox)
	
	section_scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	windowed = true
	
func to_list() -> void:
	self.reparent(selected_list_node.entry_container)
	self.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section_scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	#section_scroller.custom_minimum_size.y = 0
	window_node.queue_free()
	windowed = false
	
func alphabetize_unpinned_sections() -> void:
	var section_nodes = sec_container.get_children()
	var unpinned_sec_nodes = section_nodes.filter(func(node): return (node.is_pinned == false))
	unpinned_sec_nodes.sort_custom(
		func(one, two):
			return one.sec_num.naturalnocasecmp_to(two.sec_num) < 0
	)
	for i in unpinned_sec_nodes.size():
		sec_container.move_child(unpinned_sec_nodes[i],i+pinned_sect_count)


func _on_pop_out_toggled(toggled_on: bool) -> void:
	window_on_top_button.visible = toggled_on
	
	if toggled_on == true:
		to_window()
		pop_out_button.icon = load("uid://fgt0bd733r21")
		pop_out_button.tooltip_text = 'Send back to main window'
	else:
		to_list()
		pop_out_button.icon = load("uid://e4f8wj4uohht")
		pop_out_button.tooltip_text = 'Pop out to new window'
		window_on_top_button.set_pressed_no_signal(false)

func _on_window_on_top_toggle_toggled(toggled_on: bool) -> void:
	get_window().hide()
	get_window().always_on_top = toggled_on
	get_window().show()
