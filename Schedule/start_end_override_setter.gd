extends PanelContainer
## Scene added as node to graphic schedule scene.
## Sets the maximum/minumum times displayed on the graphic.
## Toggles between manually setting the time, and setting it based on the selected sections

@export_enum('start','end') var mode = 'start' ## Whether the node is for the graph's start time or end time.
@export var counterpart:PanelContainer ## If start setter, override is the end setter, and viceversa

@onready var toggle_auto: Button = %toggle_auto
@onready var pretext: Label = %pretext
@onready var margin_setter: HBoxContainer = %Margin_setter
@onready var time_setter: HBoxContainer = %Time_setter
@onready var spin_box_margin: SpinBox = %SpinBox_margin
@onready var spin_box_override: SpinBox = %SpinBox_override
@onready var time_display_override: LineEdit = %time_display_override

var auto_active:bool = false ## Whether the setter is in manual or automatic mode
var initial_start:int = 6
var initial_end:int = 18

func _ready() -> void:
	## Signal emitted when the section_selected/deselected functions finish
	selected.section_selects_change_finished.connect(update_override_min_max)
	selected.section_selects_change_finished.connect(update_margin_min_max)
	gs.component_loads_finished.connect(
		## Setting spin_box_override value causes its value_changed ...
		## ... func to run. That func uses a reference to the ...
		## ... graph node, which must be loaded.
		func():
			if mode == 'start':
				pretext.text = 'Start time:'
				spin_box_override.set_value_no_signal(initial_start)
				call_deferred('_on_spin_box_override_value_changed',initial_start)
				spin_box_override.max_value = 23
			elif mode == 'end':
				pretext.text = 'End time:'
				spin_box_override.set_value_no_signal(initial_end)
				call_deferred('_on_spin_box_override_value_changed',initial_end)
				spin_box_override.min_value = 1

			call_deferred("update_override_min_max")
	)
	
	if toggle_auto.button_pressed == true:
		toggle_auto.text = 'Automatic'
	else:
		toggle_auto.text = 'Manual'

func update_override_min_max() -> void:
	## Runs when sections are selected/deselected. 
	## Assures override will never put a section out of bounds.
	if mode == 'start':
		## Sets max value based on whichever is earliest: Earliest selected section, or End override
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
	## Runs when sections are selected/deselected
	## Assures margins will never make graph go beyond 0-24
	var graph_node = gs.main_scene_node.graph_node
	if mode == 'start' and graph_node.start_override == false:
		spin_box_margin.max_value = selected.start_hour
	elif mode == 'end' and graph_node.end_override == false:
		spin_box_margin.max_value = 24 - selected.end_hour
		
func _on_spin_box_override_value_changed(value: float) -> void:
	## Sets the actual values used by the graph
	if value < spin_box_override.min_value or value > spin_box_override.max_value:
		## time_display_override can manually run this function with a value outside of ...
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
		
	
	set_override_text(value)
	spin_box_override.get_line_edit().release_focus()
	selected.start_end_hours_changed.emit()
	update_override_min_max()
	

func set_override_text(value) -> void:
	var suffix:String = 'am'
	var format_mod:int = 0 ## Accounts for the 12-hour format
	if value >= 12 and value < 24:
		suffix = 'pm'
	if value > 12:
		format_mod = -12
	elif value == 0:
		format_mod = 12
	
	var text = str(int(value+format_mod)) + suffix
	time_display_override.text = text
	time_display_override.old_text = text ## Used in time_display_override.gd to correct invalid inputs

func _on_spin_box_margin_value_changed(value: float) -> void:
	## Can only run when margin mode is active, so it doesn't check if it is
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

	
