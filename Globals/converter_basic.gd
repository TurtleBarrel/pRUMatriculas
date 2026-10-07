extends Node

## Reads file containing all the information of every section of ...
## ... every course, and turns it into two dictionaries 
## Verifies that file is valid, and emits signal if not
## 

var file_filter_string:String = '*json'


func create_dicts(file_path:String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var sections_info_JSON = JSON.new()
	var error = sections_info_JSON.parse(json_text)
	var file_data = sections_info_JSON.data ## Null if parse failed
	
	var valid_JSON:bool = error == OK
	var valid_format:bool = (file_data is Dictionary) and (file_data.has('data')) and (file_data['data'] is Dictionary) and (file_data['data'].size() != 0)
	var course_sample = file_data['data'].values()[0]
	var valid_courses = course_sample is Dictionary and course_sample.has('subject') and course_sample.has('name') and course_sample.has('sections') and course_sample['sections'] is Dictionary and course_sample['sections'].size() != 0
	var sec_sample = course_sample['sections'].values()[0]
	var valid_sections = sec_sample is Dictionary and sec_sample.has('rooms') and sec_sample.has('days') and sec_sample.has('times') and sec_sample.has('creds') and sec_sample.has('prof') and sec_sample.has('cap') and sec_sample.has('async') and sec_sample.has('times_num') and sec_sample.has('days_num')
	
	if not valid_JSON or not valid_format or not valid_courses or not valid_sections: 
		## If file is not valid JSON or ...
		## ... file is valid JSON but not valid for the app
		prints('JSON valid:', valid_JSON)
		prints('JSON error:',sections_info_JSON.get_error_message())
		prints('JSON error line:',sections_info_JSON.get_error_line())
		prints('JSON Data format valid:',valid_format)
		prints('Course dicts format valid:',valid_courses)
		prints('Section dicts format valid:',valid_sections)
		
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

		#for code in formatted_courses.keys():
			#print(code, ':')
			#for sec in formatted_courses[code]['sections']:
				#print(sec,': ',formatted_courses[code]['sections'][sec])
			#print()
			
		gs.course_info_by_code = formatted_courses
		gs.info_loaded.emit()
