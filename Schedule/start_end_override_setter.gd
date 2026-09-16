extends PanelContainer

signal override_change_finished(value)

@export_enum('start','end') var mode = 'start'
@export var counterpart:PanelContainer ## If start setter, the end setter, and viceversa

@onready var toggle_auto: Button = %toggle_auto
@onready var pretext: Label = %pretext
@onready var margin_setter: HBoxContainer = %Margin_setter
@onready var time_setter: HBoxContainer = %Time_setter
@onready var spin_box_margin: SpinBox = %SpinBox_margin
@onready var spin_box_override: SpinBox = %SpinBox_override
@onready var time_display_override: LineEdit = %time_display_override

var auto_active:bool = false
var initial_start:int = 6
var initial_end:int = 20

func _ready() -> void:
	selected.section_selected.connect(section_select_override_update)
	
	override_change_finished.connect(set_override_text)
	gs.override_changed.connect(update_override_min_max)
	selected.section_selects_change_finished.connect(update_override_min_max)
	selected.section_selects_change_finished.connect(update_margin_min_max)
	

	if mode == 'start':
		pretext.text = 'Start time:'
		spin_box_override.set_value_no_signal(initial_start)
		set_override_text(initial_start)
		spin_box_override.max_value = 23
		gs.call_deferred('emit_signal','override_changed')
	elif mode == 'end':
		pretext.text = 'End time:'
		spin_box_override.set_value_no_signal(initial_end)
		set_override_text(initial_end)
		spin_box_override.min_value = 1
		gs.call_deferred('emit_signal','override_changed')
	
	if toggle_auto.button_pressed == true:
		toggle_auto.text = 'Automatic'
	else:
		toggle_auto.text = 'Manual'

func update_override_min_max() -> void:
	if mode == 'start':
		if selected.start_hour <= counterpart.spin_box_override.value and selected.selected_section_dicts.is_empty() == false:
			spin_box_override.max_value = selected.start_hour-1
		else:
			spin_box_override.max_value = counterpart.spin_box_override.value-1
	elif mode == 'end':
		if selected.end_hour >= counterpart.spin_box_override.value and selected.selected_section_dicts.is_empty() == false:
			spin_box_override.min_value = selected.end_hour + 1
		else:
			spin_box_override.min_value = counterpart.spin_box_override.value+1

func update_margin_min_max() -> void:
	var graph_node = gs.main_scene_node.graph_node
	if mode == 'start' and graph_node.start_override == false:
		spin_box_margin.max_value = selected.start_hour
	elif mode == 'end' and graph_node.end_override == false:
		spin_box_margin.max_value = 24 - selected.end_hour
		

func section_select_override_update(_code,sec_dict,_sec_num) -> void:
	## Runs when a section is selected, changes override if it puts section out of bounds
	if sec_dict['async'] == false:
		var starts:Array = sec_dict['times_num'].map(func(times): return times['start'])
		var ends:Array = sec_dict['times_num'].map(func(times): return times['end'])
		var graph_node = gs.main_scene_node.graph_node
		
		var new_value:int

		var new_sec_in_bounds:bool = true
		if self.mode == 'start' and graph_node.start_override == true:
			new_value = 24
			for new_start in starts:
				if new_start < graph_node.start:
					new_sec_in_bounds = false
					if new_start < new_value:
						new_value = floori(new_start)-1
		elif self.mode == 'end' and graph_node.end_override == true:
			new_value = 0
			for new_end in ends:
				if new_end > graph_node.end:
					new_sec_in_bounds = false
					if new_end > new_value:
						new_value = ceili(new_end)+1
						
		if new_sec_in_bounds == false:
			spin_box_override.value = new_value
		
	
func _on_spin_box_override_value_changed(value: float) -> void:
	## TODO On section selected, check if it goes beyond override
	## TODO Let time_display be focusable on click. Add parser ...
	## ... function: read am/pm and 24 hour time.......
	
	if value < spin_box_override.min_value or value > spin_box_override.max_value:
		## time_display_override can manually emit this signal with a value outside of ...
		## the min/max range. This fixes the value if it happens
		if mode == 'start':
			value = spin_box_override.max_value
		elif mode == 'end':
			value = spin_box_override.min_value
	
	var graph_node = gs.main_scene_node.graph_node
	if mode == 'start':
		graph_node.start = value
	elif mode == 'end':
		graph_node.end = value
	
	override_change_finished.emit(value)
	spin_box_override.get_line_edit().release_focus()
	
	selected.start_end_hours_changed.emit()
	gs.override_changed.emit()
	

func set_override_text(value) -> void:
	var suffix:String = 'am'
	var pm_mod:int = 0
	if value >= 12 and value < 24:
		suffix = 'pm'
	if value > 12:
		pm_mod = -12
	elif value == 0:
		pm_mod = 12
	
	var text = str(int(value+pm_mod)) + suffix
	time_display_override.text = text
	time_display_override.old_text = text

func _on_spin_box_margin_value_changed(value: float) -> void:
	## TODO Check if margins make time go beyond 0/24
	var graph_node = gs.main_scene_node.graph_node
	if mode == 'start':
		graph_node.start_margin = value
		graph_node.start = selected.start_hour - graph_node.start_margin
	elif mode == 'end':
		graph_node.end_margin = value
		graph_node.end = selected.end_hour + graph_node.end_margin
	selected.start_end_hours_changed.emit()
	spin_box_margin.get_line_edit().release_focus()


func _on_toggle_auto_toggled(auto_on: bool) -> void:
	var graph_node = gs.main_scene_node.graph_node
	
	auto_active = auto_on
	if mode == 'start':
		graph_node.start_override = !auto_on
	elif mode == 'end':
		graph_node.end_override = !auto_on

	if auto_on:
		toggle_auto.text = 'Automatic'
		margin_setter.visible = true
		time_setter.visible = false
		if mode == 'start':
			graph_node.start = selected.start_hour - graph_node.start_margin
		elif mode == 'end':
			graph_node.end = selected.end_hour + graph_node.end_margin
		update_margin_min_max()
	else:
		toggle_auto.text = 'Manual'
		time_setter.visible = true
		margin_setter.visible = false
		if mode == 'start':
			graph_node.start = spin_box_override.value
		elif mode == 'end':
			graph_node.end = spin_box_override.value
		update_override_min_max()
		
	selected.start_end_hours_changed.emit()

	
