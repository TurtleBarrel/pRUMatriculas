extends PanelContainer

var code:String
var subject:String
var course_name:String
var credits:String
var list:MarginContainer
var pin_split:VSplitContainer
var pinned_container:VBoxContainer
var unpinned_container:VBoxContainer
var alph_order:int

var is_selected:bool
var is_pinned:bool

@onready var select_button: CheckBox = %Select
@onready var name_label: Label = %name
@onready var credits_label: Label = %credits
@onready var columns:Dictionary = {select_button.name.to_lower() : select_button, name_label.name.to_lower() : name_label, credits_label.name.to_lower() : credits_label}

@onready var remove_button: Button = %remove_course


func _ready() -> void:
	select_button.text = code
	select_button.tooltip_text = code+'\n'+course_name
	name_label.text = course_name
	credits_label.text = credits
	
	for column in columns.values():
		column.custom_minimum_size.x = list.columns_min_size_x[column.name.to_lower()]
	
	selected.course_deselected.connect(
		func(deselected_code):
			if deselected_code == self.code:
				select_button.set_pressed_no_signal(false)
	)
	list.names_toggled.connect(
		func(toggled_on):
			name_label.visible = toggled_on
	)
	
	for col in columns.values():
		col.resized.connect(func():list.column_resized.emit(col,self))

	list.column_resized.connect(
		func(resized_col,source):
			if source != self:
				var local_column = columns[resized_col.name.to_lower()]
				if resized_col.size.x > local_column.custom_minimum_size.x:
					local_column.custom_minimum_size.x = resized_col.size.x
					list.columns_min_size_x[resized_col.name.to_lower()] = resized_col.size.x
	)

func _on_select_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		selected.course_selected.emit(code, self)
		remove_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		selected.course_deselected.emit(code)
		remove_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	remove_button.disabled = toggled_on
	is_selected = toggled_on


func _on_pin_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		self.reparent(pinned_container)
		pinned_container.move_child(self,alph_order)
	else:
		self.reparent(unpinned_container)
		unpinned_container.move_child(self,alph_order)
	pin_split.update_vis()
	list.pins_changed.emit(toggled_on)
	is_pinned = toggled_on


func _on_remove_course_pressed() -> void:
	gs.added_course_codes.erase(code)
	gs.course_nodes_by_code.erase(code)
	gs.course_nodes_by_subject[subject].erase(code)
	if gs.course_nodes_by_subject[subject].is_empty() == true:
		gs.course_nodes_by_subject.erase(subject)
	gs.course_removed.emit(code,subject,self)
	files.save_loaded_courses()
	self.queue_free()
	
