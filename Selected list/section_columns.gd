extends HBoxContainer

var dragging:bool = false

@onready var section_label: Label = $section_label
@onready var capacity_label: Label = $capacity_label
@onready var credits_label: Label = $credits_label
@onready var schedule_label: Label = $schedule_label
@onready var professor_label: Label = $professor_label

func toggle_column(column, vis):
	if column == 'capacities':
		capacity_label.visible = vis
	elif column == 'credits':
		credits_label.visible = vis
	elif column == 'schedules':
		schedule_label.visible = vis
	elif column == 'professors':
		professor_label.visible = vis


func _ready() -> void:
	owner.column_toggled.connect(toggle_column)
	
