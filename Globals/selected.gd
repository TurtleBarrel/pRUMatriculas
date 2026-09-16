extends Node

signal course_selected(code, course_node)
signal course_deselected(code)
signal section_selected(code, sec_dict, sec_num)
signal section_deselected(sec_dict)
signal section_selects_change_finished
signal overlap_updated(overlapping)
signal selected_course_sections_added
signal start_end_hours_changed

var selected_course_dicts:Array = []
var selected_course_nodes:Dictionary = {}
var available_section_nodes:Dictionary = {}
## ^ {code:{secnum:entry,secnum:entry}, code:{secnum:entry,secnum:entry}}
var selected_section_dicts:Array = []
var active_times:Array = [[],[],[],[],[],[],[]]
## ^ 0 is sunday, 1 is monday, ... , 6 is saturday
var overlap_present:bool = false

var start_hour:int = 6 ## Earliest start time for selected sections
var end_hour:int  = 20 ##  Latest end time for selected sections


func _ready() -> void:
	section_selected.connect(on_section_selected)
	section_deselected.connect(on_section_deselected)
	course_selected.connect(on_course_selected)
	course_deselected.connect(on_course_deselected)
	
	
### Dict level 1:	{code:{course}, code:{course} ...}
	### {course}:		{name:"name", sections:{sections}}
	### {sections}:		{secnum1:{data}, secnum2:{data} ...}
	### {data}:			{async:bool, times_num:[{'start':start,'end':end},...], days_num:[[],[]]}

func on_course_selected(code, _course_node) -> void:
	selected_course_dicts.append(gs.course_info_by_code[code])
	
func on_course_deselected(code) -> void:
	if selected_course_nodes[code].windowed == true:
		selected_course_nodes[code].window_node.queue_free()
	selected_course_nodes[code].queue_free()
	
	available_section_nodes.erase(code)
	selected_course_dicts.erase(gs.course_info_by_code[code])
	selected_course_nodes.erase(code)
	for dict in gs.course_info_by_code[code]['sections'].values():
		selected_section_dicts.erase(dict)


func on_section_selected(code, dict, sec_num):
	if dict['async'] == false:
		
		var start_end_changed:bool = false
		var block_group_count = dict['times_num'].size()
		for i in block_group_count:
			## Set day/times for overlap checks
			var days = dict['days_num'][i]
			for day in days:
				active_times[day].append({'times_dict':dict['times_num'][i], 'sec_dict':dict, 'code':code, 'sec_num':sec_num})
		
			## Check for start/end hours
			
			var times = dict['times_num'][i]
			var graph_node = gs.main_scene_node.graph_node
			
			if floori(times['start']) < start_hour or selected_section_dicts.size() == 0:
				start_hour = floori(times['start'])
				if graph_node.start_override == false:
					graph_node.start = floori(times['start']) - graph_node.start_margin
				start_end_changed = true
					
			if ceili(times['end']) > end_hour or selected_section_dicts.size() == 0:
				end_hour = ceili(times['end'])
				if graph_node.end_override == false:
					graph_node.end = ceili(times['end']) + graph_node.end_margin
				start_end_changed = true
					
		if start_end_changed == true:
			start_end_hours_changed.emit()
		
	selected_section_dicts.append(dict)
	section_selects_change_finished.emit()

func on_section_deselected(dict):
	if dict['async'] == false:
		var start_end_changed:bool = false
		## Set day/times for overlap checks
		var block_group_count = dict['times_num'].size()
		for i in block_group_count:
			for day in dict['days_num'][i]:
				var day_sec_dicts = active_times[day].map(func(d): return d['sec_dict'])
				if day_sec_dicts.has(dict):
					active_times[day].pop_at(day_sec_dicts.find(dict))
			
			## Check for start/end hours
			var times = dict['times_num'][i]
			if floori(times['start']) == start_hour or ceili(times['end']) == end_hour:
				start_hour = 24
				end_hour = 0
				if selected_section_dicts.size() == 1:
					start_hour = 6
					end_hour = 18
					start_end_changed = true
				else:
					var graph_node = gs.main_scene_node.graph_node
					for sec_dict:Dictionary in selected_section_dicts:
						if sec_dict['async'] == false:
							for i2 in sec_dict['times_num'].size():
								var sec_start = floori(sec_dict['times_num'][i2]['start'])
								var sec_end = ceili(sec_dict['times_num'][i2]['end'])
								if sec_dict != dict:
									if sec_start < start_hour:
										start_hour = sec_start
										if graph_node.start_override == false:
											graph_node.start = start_hour - graph_node.start_margin
										start_end_changed = true
									if sec_end > end_hour:
										end_hour = sec_end
										if graph_node.end_override == false:
											graph_node.end = end_hour + graph_node.end_margin
										start_end_changed = true
		if start_end_changed == true:
			start_end_hours_changed.emit()

		overlap_present = false
		overlap_updated.emit(false)
	selected_section_dicts.erase(dict)
	section_selects_change_finished.emit()
