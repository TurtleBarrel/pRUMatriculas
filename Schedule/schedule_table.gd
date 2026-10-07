extends PanelContainer

@onready var section_label: Label = %Section
@onready var capacity_label: Label = %Capacity
@onready var credits_label: Label = %Credits
@onready var meetings_label: Label = %Meetings
@onready var professors_label: Label = %Professors
@onready var deselect_button: Button = %Deselect

@onready var sec_container: VBoxContainer = %sec_container
@onready var cap_container: VBoxContainer = %cap_container
@onready var cred_container: VBoxContainer = %cred_container
@onready var meet_container: VBoxContainer = %meet_container
@onready var prof_container: VBoxContainer = %prof_container
@onready var x_container: VBoxContainer = %x_container

@onready var sec_scroller: ScrollContainer = %sec_scroller
@onready var cap_scroller: ScrollContainer = %cap_scroller
@onready var cred_scroller: ScrollContainer = %cred_scroller
@onready var meet_scroller: ScrollContainer = %meet_scroller
@onready var prof_scroller: ScrollContainer = %prof_scroller
@onready var x_scroller: ScrollContainer = %x_scroller
@onready var scrollers:Array = [sec_scroller,cap_scroller,cred_scroller,meet_scroller,prof_scroller,x_scroller]

var section_entry_dicts:Array = []
## {'dict':sec_dict, 'nodes':[label1,label2,etc.],'code':course_code,'sec_num':sec_num}

signal scroll_changed(scroller,value)

func _ready() -> void:
	selected.section_selected.connect(add_section)
	selected.section_deselected.connect(remove_section)
	selected.overlap_updated.connect(update_overlaps)
	
	for scroller:ScrollContainer in scrollers:
		scroller.get_v_scroll_bar().value_changed.connect(func(value):emit_scroll(value,scroller))

	scroll_changed.connect(update_scrollers)

func emit_scroll(value, scroller:ScrollContainer):
	scroll_changed.emit(scroller,value)
func update_scrollers(source:ScrollContainer,value:float):
	for scroller:ScrollContainer in scrollers:
		if scroller != source:
			scroller.get_v_scroll_bar().value = value
			## Causes the value_changed signal to emit from every ...
			## ... other scroller, but doesn't cause a loop for ...
			## ... some reason, so it's fine

func add_section(code, sec_dict, sec_num) -> void:
	var dict = {'dict':sec_dict,'code':code,'sec_num':sec_num, 'nodes':[]}
	var sec_label:Label = section_label.duplicate()
	var cap_label:Label = capacity_label.duplicate()
	var creds_label:Label = credits_label.duplicate()
	var meets_label:Label = meetings_label.duplicate()
	var profs_label:Label = professors_label.duplicate()
	var x_button:Button = deselect_button.duplicate()
	
	var nodes:Array = [sec_label,cap_label,creds_label,meets_label,profs_label,x_button]
	dict['nodes'] = nodes
	
	for node in nodes:
		node.text = ''
		node.show()
	x_button.text = 'x'
	x_button.disabled = false
	x_button.modulate = Color.WHITE
	x_button.focus_mode = Control.FOCUS_ACCESSIBILITY
	x_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	x_button.tooltip_text = 'Deselect section'

	
	meets_label.resized.connect(
		func():
			for node in nodes:
				if node.custom_minimum_size.y < meets_label.size.y:
					node.custom_minimum_size.y = meets_label.size.y
			#if x_button.custom_maximum_size.y < meets_label.size.y:
			x_button.custom_maximum_size.y = meets_label.size.y
	)
	profs_label.resized.connect(
		func():
			for node in nodes:
				if node.custom_minimum_size.y < profs_label.size.y:
					node.custom_minimum_size.y = profs_label.size.y
	)
	
	sec_container.add_child(sec_label)
	cap_container.add_child(cap_label)
	cred_container.add_child(creds_label)
	meet_container.add_child(meets_label)
	prof_container.add_child(profs_label)
	x_container.add_child(x_button)
	
	sec_label.text = code+' - '+sec_num
	cap_label.text = sec_dict['cap']
	creds_label.text = sec_dict['creds']
	if sec_dict['async'] == false:
		for block in sec_dict['days'].size():
			meets_label.text  += sec_dict['rooms'][block]+'  |  '+sec_dict['days'][block]+'  |  '+sec_dict['times'][block]+'\n'
		meets_label.text = meets_label.text.strip_edges()
	for block in sec_dict['prof'].size():
		profs_label.text += sec_dict['prof'][block]+'\n'
	profs_label.text = profs_label.text.strip_edges()
	
	x_button.pressed.connect(
		func():
			var section_list_entry_node = selected.available_section_nodes[code][sec_num]
			section_list_entry_node.section_select.button_pressed = false
	)
	
	section_entry_dicts.append(dict)
	update_overlaps(true)
	
func remove_section(sec_dict) -> void:
	for sec in section_entry_dicts:
		if sec['dict'] == sec_dict:
			section_entry_dicts.erase(sec)

			for node in sec['nodes']:
				node.queue_free()
				section_entry_dicts.erase(sec)
			break

func update_overlaps(overlapping):
	if overlapping == true:
		for entry in section_entry_dicts:
			var selected_section_node = selected.available_section_nodes[entry['code']][entry['sec_num']]
			if selected_section_node.overlapping == true:
				for node in entry['nodes']:
					node.self_modulate = Color(1.0, 0.447, 0.379, 1.0)
	else:
		for entry in section_entry_dicts:
			for node in entry['nodes']:
				node.self_modulate = Color.WHITE
