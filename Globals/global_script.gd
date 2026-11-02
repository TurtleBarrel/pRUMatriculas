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
signal course_removed(code,subject,course_entry)
signal data_title_set(title)
signal platform_detected(is_mobile)
var mobile_device:bool = false

var components_to_load:Array = ['courses_list','selected_list','main_scene']
var main_scene_node:Control

var course_info_by_code:Dictionary
var course_info_by_subject:Dictionary

var course_nodes_by_subject:Dictionary
var course_nodes_by_code:Dictionary
var added_course_codes:Array = []

var main_window:Window
var main_window_min_size:Vector2i = Vector2i(1200,500)

func _ready() -> void:
	component_loaded.connect(
		func(comp):
			components_to_load.erase(comp)
			if components_to_load.is_empty():
				component_loads_finished.emit()
				
				var is_mobile = OS.has_feature('android')
				platform_detected.emit(is_mobile)
				mobile_device = is_mobile
	)
	
	var screen_x = DisplayServer.screen_get_size().x
	var scale:float = 1.5 * screen_x/1920.0
	#prints(screen_x,' / ',1920,' = ', scale)
	if OS.has_feature('android'):
		get_tree().root.content_scale_factor = scale
		main_window = get_window()
	DisplayServer.window_set_min_size(Vector2i(1880,350))
	
func reset_main_window_min_size():
	main_window.min_size = main_window_min_size

func clear_courses() -> void:
	for course_code in selected.selected_course_nodes.keys():
		selected.course_deselected.emit(course_code)
	course_info_by_code.clear()
	course_info_by_subject.clear()

func set_component_margins(component:MarginContainer, mode:String):
	var margins:Dictionary
	match mode:
		'main_screen_solo':  margins = {'t':10,'r':10,'b':10,'l':25}
		## ^ On Mobile, when only component is un-windowed
		## On PC, given to selected_list when schedule_node is windowed
		'windowed':          margins = {'t':0, 'r':0, 'b':0, 'l':0 }
		## ^ On Mobile, when component is windowed
		## On PC, given to schedule_node when it is windowed
		'main_screen_left':  margins = {'t':10,'r':0, 'b':10,'l':25}
		## ^ On Mobile, given to left-side component when both are un-windowed
		## On PC, given to schedule_node when it is un-windowed
		'main_screen_right': margins = {'t':10,'r':10,'b':10,'l':0 }
		## ^ On Mobile, given to right-side component when both are un-windowed
		## On PC, given to selected_list when it is un-windowed
			
	component.add_theme_constant_override('margin_top',margins['t'])
	component.add_theme_constant_override('margin_right',margins['r'])
	component.add_theme_constant_override('margin_bottom',margins['b'])
	component.add_theme_constant_override('margin_left',margins['l'])
