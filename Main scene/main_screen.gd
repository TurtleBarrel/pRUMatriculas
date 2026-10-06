extends Control

@onready var box_container: BoxContainer = %BoxContainer
@onready var schedule_scroller: ScrollContainer = %Schedule_scroller

@onready var course_list: MarginContainer = %course_list
@onready var selected_list: MarginContainer = %selected_list
@onready var graph_node: MarginContainer = %Schedule_node
@onready var course_list_resizer: HSplitContainer = %course_list_resizer
@onready var input_blocker: Control = %input_blocker

@onready var main_split_container: HSplitContainer = %sched_and_selected

func _ready() -> void:
	gs.main_scene_node = self
	gs.schedule_window_toggled.connect(sched_window_toggled)
	gs.course_list_toggled.connect(
		func(hid):
			course_list_resizer.dragging_enabled = !hid
	)
	
	gs.component_loaded.emit('main_screen')
	
	var main_split_handle = main_split_container.get_child(-1,true)
	main_split_handle.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
func sched_window_toggled(windowed):
	set_window_min_size(windowed)
	course_list.hide_list_button.button_pressed = true
	schedule_scroller.visible = !windowed


func set_window_min_size(selected_windowed):
	if selected_windowed == true:
		self.get_window().min_size.x = 800
