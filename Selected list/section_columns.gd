extends HBoxContainer

var dragging:bool = false

#var offsets:PackedInt32Array = self.split_offsets

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
	
	#owner.offsets = self.split_offsets
	#
	#owner.sections_size = section_label.size
	#owner.capacities_size = capacity_label.size
	#owner.credits_size = credits_label.size
	#owner.schedules_size = schedule_label.size
	#owner.professors_size = professor_label.size
	#

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#if dragging:
		#offsets = split_offsets
		#owner.offsets = split_offsets
		#
		#owner.sections_size = section_label.size
		#owner.capacities_size = capacity_label.size
		#owner.credits_size = credits_label.size
		#owner.schedules_size = schedule_label.size
		#owner.professors_size = professor_label.size
	#
	
#
#func _on_drag_started() -> void:
	#dragging = true
	#owner.dragging = true
#func _on_drag_ended() -> void:
	#dragging = false
	#owner.dragging = false
