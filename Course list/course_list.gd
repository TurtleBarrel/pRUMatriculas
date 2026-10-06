extends MarginContainer

signal names_toggled(toggled_on)
signal column_resized(column,source)
signal scroll_changed
signal pins_changed(added:bool)

@onready var entries_unpinned: VBoxContainer = %Entries_unpinned
@onready var entries_pinned: VBoxContainer = %Entries_pinned
@onready var pin_split: VSplitContainer = %Pin_split
@onready var hide_list_button: Button = %"Hide list"
@onready var list_panel: PanelContainer = %list
@onready var course_list_progress: ProgressBar = %course_list_progress
@onready var progress_container: Control = %progress_container
@onready var title_label: Label = %title_label

@onready var add_subject: LineEdit = %add_subject
@onready var add_course: LineEdit = %add_course
@onready var search_bar: LineEdit = %search
@onready var remove_subjects: Button = %remove_subjects
@onready var adders_container: HBoxContainer = %adders
@onready var file_select_button: Button = %file_select_button
@onready var subjects_container: GridContainer = %Subjects_container


@onready var scroller_titles_pinned: ScrollContainer = %Column_titles_scroller_pinned
@onready var scroller_titles_unpinned: ScrollContainer = %Column_titles_scroller_unpinned
@onready var scroller_pinned: ScrollContainer = %Scroller_pinned
@onready var scroller_unpinned: ScrollContainer = %Scroller_unpinned
@onready var scrollers:Array = [scroller_titles_pinned,scroller_titles_unpinned,scroller_pinned,scroller_unpinned]

@onready var code_title_pinned: Label = %Code_title_pinned
@onready var creds_title_pinned: Label = %Creds_title_pinned
@onready var name_title_pinned: Label = %Name_title_pinned
@onready var titles_pinned:Dictionary = {'code':code_title_pinned,'credits':creds_title_pinned,'name':name_title_pinned}
@onready var code_title_unpinned: Label = %Code_title_unpinned
@onready var creds_title_unpinned: Label = %Creds_title_unpinned
@onready var name_title_unpinned: Label = %Name_title_unpinned
@onready var titles_unpinned:Dictionary = {'code':code_title_unpinned,'credits':creds_title_unpinned,'name':name_title_unpinned}

@onready var course_entry_scene = load('uid://y5c3dqwhaowv')

var courses_to_add:Dictionary
var adding_finished:bool = true
var course_count_initial:int = 0
var course_count_buffer:int = 0
var max_frame_duration:float = 0.02
var names_on:bool = true

var columns_min_size_x:Dictionary = {'select':0.0,'credits':0.0,'name':0.0}

func _ready() -> void:
	adders_container.hide()
	progress_container.modulate.a = 0
	progress_container.show()
	
	gs.component_loads_finished.connect(
		func():
			## Needs main_scene to be loaded (signal info_loaded affects input_blocker in this script) 
			var file_path = files.get_data_file_path()
			if file_path.is_absolute_path() and FileAccess.file_exists(file_path):
				load_file(file_path, false)
	)
	
	gs.info_loaded.connect(
		func():
			pulse_file_select(Color(0.0, 0.892, 0.309, 0.66))
			adders_container.show()
			var subject = gs.course_info_by_subject.keys().pick_random()
			var course = gs.course_info_by_subject[subject].keys().pick_random()
			add_subject.placeholder_text = 'Add subject (Ex. %s)' % subject
			add_course.placeholder_text = 'Add course (Ex. %s)' % course
			reset_list()
			
			var added_course_codes:Array = files.get_loaded_courses()
			var added_course_dicts:Dictionary = {}
			for code in added_course_codes:
				if gs.course_info_by_code.has(code):
					added_course_dicts.get_or_add(code,gs.course_info_by_code[code])
			add_courses(added_course_dicts)
	)
	
	files.invalid_file_loaded.connect(
		func():
			pulse_file_select(Color(1.0, 0.22, 0.165, 0.722))
	)
	
	
	column_resized.connect(
		func(resized_column, _source):
			var local_column_pinned:Label = titles_pinned[resized_column.get_meta('col_name')]
			var local_column_unpinned:Label = titles_unpinned[resized_column.get_meta('col_name')]
			if resized_column.size.x > local_column_pinned.custom_minimum_size.x:
				local_column_pinned.custom_minimum_size.x = resized_column.size.x
			if resized_column.size.x > local_column_unpinned.custom_minimum_size.x:
				local_column_unpinned.custom_minimum_size.x = resized_column.size.x
	)		
	
	for scroller:ScrollContainer in scrollers:
		var scroll_bar:HScrollBar = scroller.get_h_scroll_bar()
		scroll_bar.value_changed.connect(func(_value):scroll_changed.emit(scroll_bar.ratio,scroller))

	scroll_changed.connect(
		func(ratio,scroll_source):
			for scroller:ScrollContainer in scrollers:
				if scroll_source != scroller:
					scroller.get_h_scroll_bar().ratio = ratio
	)
	
	gs.component_loaded.emit('courses_list')

	gs.data_title_set.connect(
		func(title:String):
			if title.is_empty() == false:
				title_label.text = title
	)

	
func _process(_delta: float) -> void:
	if adding_finished == false:
		var start_time:float = Time.get_unix_time_from_system()
		course_count_buffer = courses_to_add.size()

		for code in courses_to_add.keys():
			var current_time = Time.get_unix_time_from_system()
			if current_time - start_time < max_frame_duration:
				if gs.added_course_codes.has(code) == false:
					gs.added_course_codes.append(code)

					var entry = course_entry_scene.instantiate()
					var subject = courses_to_add[code]['subject']
					
					entry.code = code
					entry.subject = courses_to_add[code]['subject']
					entry.course_name = courses_to_add[code]['name']
					
					var creds:Array = courses_to_add[code]['sections'].values().map(func(sec):return sec['creds'])
					var creds_const:bool = creds.all(func(cred): return cred==creds[0])
					if creds_const == true:
						entry.credits = creds[0]
					else:
						entry.credits = '#'
					entry.list = self
					entry.pinned_container = entries_pinned
					entry.unpinned_container = entries_unpinned
					entry.pin_split = pin_split
					entries_unpinned.add_child(entry)
					gs.course_nodes_by_subject.get_or_add(subject,{})
					gs.course_nodes_by_subject[subject].get_or_add(code,entry)
					gs.course_nodes_by_code.get_or_add(code,entry)

			else: 
				break
					
			courses_to_add.erase(code)
		
		if courses_to_add.is_empty() == true:
			finish_course_add()


		course_list_progress.value = 1-(courses_to_add.size()/float(course_count_initial))

func alphabetize_unpinned_courses() -> void:
	### Sets entries in alphabetical order
	## BUG Crashes??
	var entry_nodes = entries_unpinned.get_children()
	entry_nodes.sort_custom(
		func(one, two):
			return one.code.naturalnocasecmp_to(two.code) < 0
	)
	for i in entry_nodes.size():
		var entry:PanelContainer = entry_nodes[i]
		entry.alph_order = i
		entries_unpinned.move_child(entry,i)
	gs.courses_added.emit()
	

func add_courses(course_dicts_dupe) -> void:
	gs.main_scene_node.input_blocker.show()
	courses_to_add = course_dicts_dupe
	progress_container.modulate.a = 1
	progress_container.show()
	course_count_initial = courses_to_add.size()
	adding_finished = false
	
func finish_course_add() -> void:
	progress_container.modulate.a = 0
	if title_label.text.is_empty() == false:
		title_label.show()
	course_list_progress.value = 0
	adding_finished = true
	gs.main_scene_node.input_blocker.hide()
	gs.courses_added.emit()
	search_bar.text_changed.emit(search_bar.text)
	names_toggled.emit(names_on)
	alphabetize_unpinned_courses()
	files.save_loaded_courses()


func _on_hide_list_toggled(toggled_on: bool) -> void:
	list_panel.visible = !toggled_on
	gs.course_list_toggled.emit(toggled_on)
	if toggled_on:
		hide_list_button.icon = load("uid://dlft584snvvbk")
		self.add_theme_constant_override('margin_left',0)
	else:
		hide_list_button.icon = load("uid://cv5s6b5d2fc4u")
		self.add_theme_constant_override('margin_left',10)


func _on_display_names_toggle_toggled(toggled_on: bool) -> void:
	names_toggled.emit(toggled_on)
	names_on = toggled_on
	name_title_pinned.visible = toggled_on
	name_title_unpinned.visible = toggled_on

func _on_file_select_button_pressed() -> void:
	var file_dialogue:FileDialog = FileDialog.new()
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.use_native_dialog = true
	var last_loaded_path:String = files.get_data_file_path()
	if last_loaded_path != 'ERROR':
		file_dialogue.current_dir = last_loaded_path.get_base_dir()
	else:
		file_dialogue.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	file_dialogue.add_filter(converter.file_filter_string, 'Data')
	self.add_child(file_dialogue)
	file_dialogue.popup_centered()
	
	file_dialogue.file_selected.connect(load_file)
func load_file(path, clear_loaded_courses:bool = true):
	if clear_loaded_courses == true:
		gs.added_course_codes.clear()
		files.save_loaded_courses()
	converter.create_dicts(path)

func reset_list():
	for course_entry in entries_pinned.get_children():
		course_entry.queue_free()
	for course_entry in entries_unpinned.get_children():
		course_entry.queue_free()
	gs.course_nodes_by_code.clear()
	gs.course_nodes_by_subject.clear()
	for child in subjects_container.get_children():
		child.queue_free()
	

	
func pulse_file_select(color:Color) -> void:
	var panel = StyleBoxFlat.new()
	panel.bg_color = color

	var transparent_color:Color = color
	transparent_color.a = 0
	
	panel.border_color = color
	panel.corner_radius_bottom_left = 5
	panel.corner_radius_bottom_right = 5
	panel.corner_radius_top_left = 5
	panel.corner_radius_top_right = 5
	
	panel.expand_margin_bottom = 2
	panel.expand_margin_left = 2
	panel.expand_margin_top = 2
	panel.expand_margin_right = 2

	file_select_button.add_theme_stylebox_override("disabled",panel)
	file_select_button.disabled = true
	## TODO Add to other panels too
	var tween = get_tree().create_tween()
	tween.tween_property(panel,'bg_color',transparent_color,0.75)
	tween.finished.connect(
		func():
			file_select_button.remove_theme_stylebox_override("disabled")
			file_select_button.disabled = false
	)

func _on_add_subject_text_submitted(subject: String) -> void:
	add_subject.clear()
	var flash_color:Color
	if gs.course_info_by_subject.has(subject.to_upper()):
		flash_color = Color(0.493, 1.0, 0.552, 1.0)
		var courses_dict_by_code:Dictionary = gs.course_info_by_subject[subject.to_upper()]
		courses_to_add = courses_dict_by_code.duplicate()
		add_courses(courses_dict_by_code.duplicate())
	else:
		flash_color = Color(1.0, 0.329, 0.263, 1.0)

	var panel:StyleBox = add_subject.get_theme_stylebox("normal").duplicate()
	var default_color = panel.border_color
	panel.border_color = flash_color
	
	add_subject.add_theme_stylebox_override("normal", panel)
	var tween = get_tree().create_tween()
	tween.tween_property(panel,'border_color',default_color,0.75)
	tween.finished.connect(add_subject.remove_theme_stylebox_override.bind("normal"))


func _on_add_course_text_submitted(code: String) -> void:
	add_course.clear()
	var flash_color:Color
	if gs.course_info_by_code.has(code.to_upper()):
		flash_color = Color(0.493, 1.0, 0.552, 1.0)
		var course_dicts:Dictionary = {code.to_upper():gs.course_info_by_code[code.to_upper()].duplicate()}
		add_courses(course_dicts.duplicate())
	else:
		flash_color = Color(1.0, 0.329, 0.263, 1.0)

	var panel:StyleBox = add_course.get_theme_stylebox("normal").duplicate()
	var default_color = panel.border_color
	panel.border_color = flash_color
	
	add_course.add_theme_stylebox_override("normal", panel)
	var tween = get_tree().create_tween()
	tween.tween_property(panel,'border_color',default_color,0.75)
	tween.finished.connect(add_course.remove_theme_stylebox_override.bind("normal"))
		
