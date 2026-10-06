extends Control

@onready var time_label:Label = %time_label.duplicate()
@onready var hour_line: Panel = %hour_line.duplicate()


var line_nodes:Array = []
var time_label_nodes:Array = []

func _ready() -> void:
	%hour_line.queue_free()
	%time_label.queue_free()
	
	owner.ready.connect(
		func():
			set_lines()
			if owner.is_time_column == true:
				set_time_labels()
	)
	self.resized.connect(
		func():
			update_lines()
			if owner.is_time_column == true:
				update_time_labels()
	)
	
	selected.start_end_hours_changed.connect(reset_columns)

func reset_columns():
	for child in get_children():
		## Children include the section graphic entries.
		## graph_element only holds the hour lines and labels
		if child.is_in_group('graph_element'):
			child.queue_free()
	
	line_nodes.clear()
	time_label_nodes.clear()
	
	set_lines()
	update_lines()
	if owner.is_time_column == true:
		set_time_labels()
		update_time_labels()


func set_time_labels():
	var graph_node = owner.graph_node
	
	var start = graph_node.start
	var end = graph_node.end
	
	var entry_count:int = end-start+1
	var time:int = start
	for i in entry_count:
		var suffix:String = 'am'
		var modifier:int = 0
		if time >= 12:
			suffix = 'pm'
		if time > 12:
			modifier = -12
	
		if i != 0 and i != entry_count-1:
			var label = time_label.duplicate()
			label.set_meta('source', false)
			label.text = str(time+modifier)+':'+'00'+suffix
			label.visible = true
			time_label_nodes.append(label)
			self.add_child(label)
		time += 1

func update_time_labels():
	var label_count = time_label_nodes.size()
	for i in label_count:
		time_label_nodes[i].position.y = self.size.y * ((i+1)/float(label_count+1)) - time_label_nodes[i].size.y/2

func set_lines():
	var graph_node = owner.graph_node

	var start = graph_node.start
	var end = graph_node.end
	
	var entry_count:int = (end-start)*2+1
	for i:int in entry_count:
		var line = hour_line.duplicate()
		line.set_meta('source',false)
		line.size.x = self.size.x
		line.size.y = 2
		line.visible = true
		if i%2 != 0:
			line.modulate.a = 0.25
		line_nodes.append(line)
		self.add_child(line)
		
func update_lines():
	var line_count = line_nodes.size()
	for i in line_count:
		line_nodes[i].position.y = self.size.y * (i/float(line_count-1))
		line_nodes[i].size.x = self.size.x
