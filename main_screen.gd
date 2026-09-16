extends Control

@onready var box_container: BoxContainer = %BoxContainer
@onready var schedule_scroller: ScrollContainer = %Schedule_scroller

@onready var course_list: MarginContainer = %course_list
@onready var selected_list: MarginContainer = %selected_list
@onready var graph_node: MarginContainer = %Schedule_node
@onready var course_list_resizer: HSplitContainer = %course_list_resizer
@onready var input_blocker: Control = %input_blocker


func _ready() -> void:
	gs.main_scene_node = self
	gs.schedule_window_toggled.connect(sched_window_toggled)
	gs.course_list_toggled.connect(
		func(hid):
			course_list_resizer.dragging_enabled = !hid
	)
	
	graph_node.parent_node =  schedule_scroller
	selected_list.parent_node = box_container
	
	gs.component_loaded.emit('main_screen')
	
func sched_window_toggled(windowed):
	set_window_min_size(windowed)
	course_list.hide_list_button.button_pressed = true
	schedule_scroller.visible = !windowed
	if windowed == true:
		selected_list.add_theme_constant_override('margin_left',25)
	else:
		selected_list.add_theme_constant_override('margin_left',10)
	

func set_window_min_size(selected_windowed):
	if selected_windowed == true:
		self.get_window().min_size.x = 800
	else:
		self.get_window().min_size.x = 1780
	self.get_window().min_size.y = 350
