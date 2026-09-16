extends HBoxContainer

@onready var cap_title: Label = %capacities
@onready var crd_title: Label = %credits
@onready var room_title: Label = %rooms
@onready var days_title: Label = %days
@onready var times_title: Label = %times
@onready var prof_title: Label = %professors


func _on_caps_toggled(toggled_on: bool) -> void:
	owner.column_toggled.emit('capacities',toggled_on)
	cap_title.visible = toggled_on
	owner.caps_shown = toggled_on

func _on_creds_toggled(toggled_on: bool) -> void:
	owner.column_toggled.emit('credits',toggled_on)
	crd_title.visible = toggled_on
	owner.creds_shown = toggled_on

func _on_rooms_toggled(toggled_on: bool) -> void:
	owner.column_toggled.emit('rooms',toggled_on)
	room_title.visible = toggled_on
	owner.rooms_shown = toggled_on

func _on_days_toggled(toggled_on: bool) -> void:
	owner.column_toggled.emit('days',toggled_on)
	owner.column_toggled.emit('times',toggled_on)
	days_title.visible = toggled_on
	times_title.visible = toggled_on
	owner.days_shown = toggled_on
	owner.times_shown = toggled_on

#func _on_times_toggled(toggled_on: bool) -> void:
	#owner.column_toggled.emit('times',toggled_on)
	
func _on_profs_toggled(toggled_on: bool) -> void:
	owner.column_toggled.emit('professors',toggled_on)
	prof_title.visible = toggled_on
	owner.professors_shown = toggled_on
