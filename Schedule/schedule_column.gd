extends PanelContainer

@onready var label: Label = %Label
@onready var sect_block_container: Control = %time_column

@export var day:String = ''
@export var is_time_column:bool = false
@export var graph_node:MarginContainer

func _ready() -> void:
	label.text = day
	if is_time_column:
		label.custom_minimum_size.x = 80
