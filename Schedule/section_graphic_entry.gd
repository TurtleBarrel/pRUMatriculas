extends PanelContainer

@onready var code_sec_label: Label = %code_sec
@onready var room_label: Label = %room
@onready var labels: VBoxContainer = %labels
@onready var deselect_margin: MarginContainer = %deselect_margin


var sect_block_container: Control
var section_list_entry_node: PanelContainer
var graph_node:MarginContainer

var code:String
var start:float
var end:float
var sec_num:String
var sec_dict:Dictionary
var block_index:int
#var section_color:Color


var first_load:bool = true

func _ready() -> void:
	sect_block_container.resized.connect(set_block)
	code_sec_label.text = code+' - '+sec_num
	room_label.text = sec_dict['rooms'][block_index]
	selected.start_end_hours_changed.connect(set_block)
	gs.weekends_toggled.connect(
		func(toggled_on):
			deselect_margin.visible = !toggled_on
	)
	
func set_block():
	set_block_pos()
	set_block_size()

func set_block_pos():
	var pos_percent:float = float(self.start - graph_node.start)/float(graph_node.end-graph_node.start)
	self.position.y = pos_percent*sect_block_container.size.y

func set_block_size():
	var block_duration:float = end-start
	var column_duration = graph_node.end - graph_node.start
	var size_percent:float = block_duration / column_duration

	self.size.y = size_percent * sect_block_container.size.y

func _on_deselect_pressed() -> void:
	section_list_entry_node.section_select.button_pressed = false
