extends Node

## Reads file containing all the information of every section of ...
## ... every course, and turns it into two dictionaries 
## Verifies that file is valid, and emits signal if not
## 

var file_filter_string:String = '*json'


func create_dicts(file_path:String) -> void:
	#var start_time = Time.get_unix_time_from_system()
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var sections_info_JSON = JSON.new()
	var error = sections_info_JSON.parse(json_text)
	var file_data = sections_info_JSON.data ## Null if parse failed
	if error != OK or file_data is Dictionary == false or file_data.has('data') == false: 
		## If file is not valid JSON or ...
		## ... file is valid JSON but not valid for the app
		print('err: ',sections_info_JSON.get_error_message())
		print('err line: ',sections_info_JSON.get_error_line())
		files.invalid_file_loaded.emit()
	else:
		## If file is valid
		gs.clear_courses()
		files.save_data_file_path(file_path)
		var formatted_courses = file_data['data']
		if file_data.has('title') and file_data['title'] is String:
			gs.data_title_set.emit(file_data['title'])
		else:
			gs.data_title_set.emit('')
		
		## Creates dictionary to search course data by subject
		for code:String in formatted_courses.keys():
			var subject = formatted_courses[code]['subject'] ## Subject code string
			gs.course_info_by_subject.get_or_add(subject,{})
			gs.course_info_by_subject[subject].get_or_add(code,formatted_courses[code])

		#for code in dict_dict.keys():
			#print(code, ':')
			#for sec in dict_dict[code]['sections']:
				#print(sec,': ',dict_dict[code]['sections'][sec])
			#print()
			
		gs.course_info_by_code = formatted_courses
		gs.info_loaded.emit()
