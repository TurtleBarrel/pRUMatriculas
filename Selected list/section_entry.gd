extends PanelContainer

var sec_dict:Dictionary
var sec_num:String
var code:String
var capacity:int
var credits:int
var schedules:Array
var rooms:Array
var days:Array
var times:Array
var professors:Array

var selected_list_node:MarginContainer
var selected_course_node:PanelContainer
var graphic_block_nodes:Array = []

@onready var section_select: CheckBox = %section_select
@onready var capacity_label: Label = %capacity
@onready var credits_label: Label = %credits
@onready var rooms_label: Label = %rooms
@onready var days_label: Label = %days
@onready var times_label: Label = %times
@onready var async_label: Label = %async


@onready var professors_label: Label = %professors
@onready var columns_box: HBoxContainer = %Columns
@onready var disable_button: Button = %disable

var base_mod = Color.WHITE
var disabled_mod:Color = Color(0.462, 0.462, 0.462)
var overlapping_mod:Color = Color(0.804, 0.304, 0.274)
var pinned_mod:Color = Color(0.803, 0.81, 0.374, 1.0)
var pinned_overlap_mod:Color = Color(0.914, 0.495, 0.268, 1.0)

var is_selected:bool = false
var is_disabled:bool = false
var is_pinned:bool = false
var disabled_hidden:bool = false
var overlapping:bool = false
var section_hovered:bool = false



func _ready() -> void:
	selected_list_node.column_toggled.connect(toggle_column)
	selected_list_node.filters_changed.connect(update_vis_filters)
	selected_course_node.enable_all.connect(func():disable_button.button_pressed = false)
	selected.section_selects_change_finished.connect(
		func():
			check_overlap() 
			update_vis_filters()
			update_modulate()
	)
	selected.course_deselected.connect(on_course_deselected)

	## Sets data labels to empty to remove preview
	section_select.text = ''
	capacity_label.text = ''
	rooms_label.text = ''
	days_label.text = ''
	times_label.text = ''
	professors_label.text = ''
	
	## Sets data labels
	section_select.text = sec_num
	capacity_label.text = str(capacity)
	credits_label.text = str(credits)
	if sec_dict['async'] == false:
		for day in days:
			days_label.text += day+'\n'
		days_label.text = days_label.text.strip_edges()
		for time in times:
			times_label.text += time+'\n'
		times_label.text = times_label.text.strip_edges()
		for room in rooms:
			rooms_label.text += room+'\n'
		rooms_label.text = rooms_label.text.strip_edges()
	else:
		days_label.text = '---'
		times_label.text = '---'
		rooms_label.text = '---'
	
		
	for prof in professors:
		professors_label.text += prof+'\n'
	professors_label.text = professors_label.text.strip_edges()
	
	
	## Sets label visibility based on currently toggled-on columns
	capacity_label.visible = selected_list_node.caps_shown
	credits_label.visible = selected_list_node.creds_shown
	rooms_label.visible = selected_list_node.rooms_shown
	days_label.visible = selected_list_node.days_shown
	times_label.visible = selected_list_node.times_shown
	professors_label.visible = selected_list_node.professors_shown
	
	check_overlap()
	update_vis_filters()
	update_modulate()
	
func toggle_column(column, vis):
	match column:
		'capacities': capacity_label.visible = vis
		'credits': credits_label.visible = vis
		'rooms': rooms_label.visible = vis
		'days': days_label.visible = vis
		'times': times_label.visible = vis
		'professors': professors_label.visible = vis
		
func _on_disable_toggled(toggled_on: bool) -> void:
	is_disabled = toggled_on
	section_select.disabled = toggled_on
	
	if toggled_on: ## Deselect
		if is_selected == true:
			section_select.button_pressed = false
		else:
			for block in graphic_block_nodes:
				block.hide()
		section_select.mouse_default_cursor_shape = Control.CURSOR_ARROW
		selected_course_node.disabled_count_changed.emit(1)
		disable_button.tooltip_text = 'Enable section'
	else:
		section_select.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		selected_course_node.disabled_count_changed.emit(-1)
		disable_button.tooltip_text = 'Disable section'
	update_vis_filters()
	update_modulate()

func update_modulate() -> void:
	var darkener:float = 1
	if self.is_disabled:
		darkener = 0.6
	
	if overlapping == true and is_pinned == false:
		self.self_modulate = overlapping_mod*darkener
		
	elif overlapping == false and is_pinned == true:
		self.self_modulate = pinned_mod*darkener
	
	elif overlapping == true and is_pinned == true:
		self.self_modulate = pinned_overlap_mod*darkener

	else:
		if self.is_disabled: darkener = 0.5
		self.self_modulate = base_mod*darkener

func update_vis_filters() -> void:
	var disabled_vis:bool = self.is_disabled == false or selected_list_node.disabled_hidden == false
	var overlap_vis:bool = self.overlapping == false or selected_list_node.overlapping_hidden == false
	var time_vis:bool = true
	var day_vis:bool = true
	
	
	## ***_vis variables set to false if the section should not be visible
	if sec_dict['async'] == false:
		for time_block in sec_dict['times_num']:
			if time_block['start'] < selected_list_node.earliest and selected_list_node.earliest_filtered == true:
				time_vis = false
				break
			elif time_block['end'] > selected_list_node.latest and selected_list_node.latest_filtered == true:
				time_vis = false
				break
		for day_block in sec_dict['days_num']:
			for day in day_block:
				if selected_list_node.selected_days.has(int(day)) == false:
					day_vis = false
					break
			if day_vis == false:
				break

	if (not (disabled_vis and overlap_vis and time_vis and day_vis)) and self.is_selected == false:
		self.visible = false
	else:
		self.visible = true


func check_overlap() -> void:
	if sec_dict['async'] == false:
		overlapping = false
		var block_group_count:int = sec_dict['times_num'].size()
		for i in block_group_count:
			var day_group:Array = sec_dict['days_num'][i]
			for day in day_group:
				for active_time in selected.active_times[day]:
					var start:float = sec_dict['times_num'][i]['start']
					var end:float = sec_dict['times_num'][i]['end']
					var own_times:bool = (active_time['times_dict'] == sec_dict['times_num'][i] and active_time['code'] == self.code and active_time['sec_num'] == self.sec_num)
					var start_overlaps:bool = start >= active_time['times_dict']['start'] and start <= active_time['times_dict']['end']
					var end_overlaps:bool = end >= active_time['times_dict']['start'] and end <= active_time['times_dict']['end']
					
					#if own_times: print('SELF POSITIVE')
					if not own_times and (start_overlaps or end_overlaps):
						overlapping = true
						if self.is_selected == true:
							selected.overlap_present = true
							selected.overlap_updated.emit(true)
						break
				if overlapping: break
			if overlapping: break

func on_course_deselected(deselected_code) -> void:
	selected.section_deselected.emit(sec_dict)
	if deselected_code == self.code:
		for block in graphic_block_nodes:
			block.queue_free()

func _on_section_select_toggled(toggled_on: bool) -> void:
	is_selected = toggled_on
	
	for block:PanelContainer in graphic_block_nodes:
		block.visible = toggled_on
		if toggled_on == true:
			block.move_to_front()
	
	if toggled_on:
		selected.section_selected.emit(code, sec_dict, sec_num)
		modulate_blocks(false)
	else:
		selected.section_deselected.emit(sec_dict)

func _on_mouse_entered() -> void:
	section_hovered = true
	if self.is_selected == false and selected_list_node.preview_sections == true and is_disabled == false:
		var graph_node = gs.main_scene_node.graph_node
		var in_bounds:bool = true
		for block:PanelContainer in graphic_block_nodes:
			if block.start < graph_node.start or block.end > graph_node.end:
				in_bounds = false
		
		if in_bounds == true:
			for block:PanelContainer in graphic_block_nodes:
				block.visible = true
				block.move_to_front()
				modulate_blocks(true)

func _on_mouse_exited() -> void:
	section_hovered = false
	for block in graphic_block_nodes:
		if self.is_selected == false:
			block.visible = false

func modulate_blocks(preview:bool):
	var modulate_temp:Color
	var self_modulate_temp:Color
	
	if preview == true:
		modulate_temp = Color(1,1,1,0.5)
		self_modulate_temp = Color(0.486, 0.486, 0.486, 0.65)
	else:
		modulate_temp = Color.WHITE
		var r:float = randf_range(0,0.6)
		var g:float = randf_range(0.6-r,0.6-r/3)
		var b:float = randf_range(0.6-g,0.6)
		#prints(r,g,b)
		#print()
		#self_modulate_temp = Color(randf_range(0.35,0.6),randf_range(0.35,0.6),randf_range(0.35,0.6),0.75)
		self_modulate_temp = Color(r,g,b,0.75)

	for block in graphic_block_nodes:
		block.modulate = modulate_temp
		block.self_modulate = self_modulate_temp
	
func _on_pin_toggled(toggled_on: bool) -> void:
	is_pinned = toggled_on
	if toggled_on == true:
		selected_course_node.sec_container.move_child(self,selected_course_node.pinned_sect_count)
		selected_course_node.pinned_sect_count += 1
		
	else:
		selected_course_node.alphabetize_unpinned_sections()
		selected_course_node.pinned_sect_count -= 1
	update_modulate()
