extends MarginContainer

var selected_list:MarginContainer = null

func _ready() -> void:
	if selected_list != null:
		selected_list.column_toggled.connect(toggle_column)

func toggle_column(column, shown):
	for col_label:Label in get_child(0).get_children():
		if col_label.name == column:
			col_label.visible = shown
