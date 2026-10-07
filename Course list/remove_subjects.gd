extends Button

@onready var window:Window = %subjects_window
@onready var subject_template: PanelContainer = %subject_template
@onready var subjects_container: GridContainer = %Subjects_container
@onready var course_list_progress: ProgressBar = %course_list_progress
@onready var progress_container: Control = %progress_container


var selected_to_remove:Array = []
var active_subject_selectors:Dictionary = {}
var removing_finished:bool = true
var removal_count_initial:int = 0
var removal_count_live:int = 0

func _on_pressed() -> void:
	window.popup_centered()
	#gs.main_scene_node.input_blocker.modulate.a = 1
	gs.main_scene_node.input_blocker.show()
	gs.main_scene_node.input_blocker.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
func _process(_delta: float) -> void:
	if removing_finished == false:
		window.hide()
		var start_time =  Time.get_unix_time_from_system()
		for subject in selected_to_remove:
			for code in gs.course_nodes_by_subject[subject].keys():
				var current_time = Time.get_unix_time_from_system()
				if current_time - start_time < owner.max_frame_duration:
					var course_node = gs.course_nodes_by_subject[subject][code]
					if course_node.is_pinned == false and course_node.is_selected == false:
						gs.course_nodes_by_subject[subject][code]._on_remove_course_pressed()
						## The course node's function removes it from the dictionaries as well
					else:
						selected_to_remove.erase(subject)
					
				else:
					break
				removal_count_live -= 1
				course_list_progress.value = 1 - float(removal_count_live)/removal_count_initial
		if selected_to_remove.is_empty() == true:
			removing_finished = true
			removal_count_initial = 0
			progress_container.modulate = Color.TRANSPARENT
			progress_container.hide()
			close_window()
				
						
func _on_remove_pressed() -> void:
	for subject in selected_to_remove:
		removal_count_initial += gs.course_nodes_by_subject[subject].size()
	removal_count_live = removal_count_initial
	course_list_progress.value = 0
	progress_container.show()
	progress_container.modulate = Color.WHITE
	gs.main_scene_node.input_blocker.mouse_default_cursor_shape = Control.CURSOR_BUSY
	removing_finished = false
	
func _on_cancel_pressed() -> void:
	close_window()
	
func close_window() -> void:
	selected_to_remove.clear()
	for subject_selector in subjects_container.get_children():
		subject_selector.check_box.button_pressed = false
	gs.main_scene_node.input_blocker.mouse_default_cursor_shape = Control.CURSOR_BUSY
	gs.main_scene_node.input_blocker.modulate.a = 0
	gs.main_scene_node.input_blocker.hide()
	window.hide()

func alphabetize_entries() -> void:
	var entries:Array = subjects_container.get_children()
	entries.sort_custom(func(a,b): return a.subject.naturalnocasecmp_to(b.subject) < 1)
	for entry in entries:
		subjects_container.move_child(entry,-1)

func _ready() -> void:
	subject_template = subject_template.duplicate()
	%subject_template.queue_free()
	
	gs.courses_added.connect(
		func():
			for subject in gs.course_nodes_by_subject.keys():
				if active_subject_selectors.has(subject) == false:
					var subject_select = subject_template.duplicate()
					subject_select.subject = subject
					subject_select.subject_remover = self
					subject_select.show()
					subjects_container.add_child(subject_select)
					
					active_subject_selectors.get_or_add(subject,subject_select)
			alphabetize_entries()
					
	)
	gs.course_removed.connect(
		func(_course,subject,_node):
			## When the course's removal function is called, it removes its subject ...
			## ... from gs.course_nodes_by_subject if it's the last one in the subject
			if gs.course_nodes_by_subject.has(subject) == false:
				active_subject_selectors[subject].queue_free()
				active_subject_selectors.erase(subject)
				selected_to_remove.erase(subject)
	)
	
	
