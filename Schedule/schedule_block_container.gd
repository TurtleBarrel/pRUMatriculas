extends Control

var line_nodes:Array = []
var time_label_nodes:Array = []

func _ready() -> void:
	
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
	
	selected.start_end_hours_changed.connect(
		func():
			reset_columns()
	)
#
#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
		#reset_columns()

func reset_columns():
	for child in get_children():
		if child.get_meta('source') == false:
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
		
		var label_node = %time_label
		if i != 0 and i != entry_count-1:
			var label = label_node.duplicate()
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
	var line_node = $hour_line
	for i:int in entry_count:
		var line = line_node.duplicate()
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
