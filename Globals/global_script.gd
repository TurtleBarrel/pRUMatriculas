extends Node

signal info_loaded
signal courses_added
signal component_loaded
signal component_loads_finished
signal selected_list_window_toggled
signal schedule_window_toggled
signal section_block_scrolled
signal course_list_toggled
signal weekends_toggled(toggled_on)
signal override_changed()
signal course_removed(code,subject,course_entry)
signal data_title_set(title)

var components_to_load:Array = ['courses_list','selected_list','main_screen']
var main_scene_node:Control

var course_info_by_code:Dictionary
var course_info_by_subject:Dictionary

var course_nodes_by_subject:Dictionary
var course_nodes_by_code:Dictionary
var added_course_codes:Array = []

var main_winow:Window
var main_window_min_size:Vector2i = Vector2i(1880,350)

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"): ## HACK
		#get_tree().root.content_scale_factor = 2
		#print(DisplayServer.window_get_min_size())
		#print(DisplayServer.window_get_size())
		#print()

func _ready() -> void:
	component_loaded.connect(
		func(comp):
			components_to_load.erase(comp)
			if components_to_load.is_empty():
				component_loads_finished.emit()
			
	)
	main_winow = get_window()
	DisplayServer.window_set_min_size(Vector2i(1880,350))

func reset_main_window_min_size():
	main_winow.min_size = main_window_min_size

func clear_courses() -> void:
	for course_code in selected.selected_course_nodes.keys():
		selected.course_deselected.emit(course_code)
	course_info_by_code.clear()
	course_info_by_subject.clear()
