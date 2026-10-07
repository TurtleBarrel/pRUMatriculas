extends Node

signal invalid_file_loaded

var data_file_path_file:String = "user://course_data_path.txt" ## File containing the file path to the data file
var active_courses_file:String = "user://active_courses.json" ## File containing an array of active course codes

func _ready() -> void:
	if FileAccess.file_exists(data_file_path_file) == false:
		FileAccess.open(data_file_path_file, FileAccess.WRITE)
	if FileAccess.file_exists(active_courses_file) == false:
		FileAccess.open(active_courses_file, FileAccess.WRITE)
	#print(OS.get_user_data_dir())
	#prints('data file path',FileAccess.open(data_file_path_file, FileAccess.READ))
	#prints('active courses file',FileAccess.open(active_courses_file, FileAccess.READ))

func save_data_file_path(path) -> void:
	if FileAccess.file_exists(data_file_path_file) == false:
		FileAccess.open(data_file_path_file, FileAccess.WRITE)
	#prints('Saving data_file_path_file',FileAccess.open(data_file_path_file, FileAccess.READ))
	var file_path_file = FileAccess.open(data_file_path_file, FileAccess.WRITE)
	file_path_file.store_string(path)
	file_path_file.close()

func get_data_file_path() -> String:
	if FileAccess.file_exists(data_file_path_file):
		var file_path:String = FileAccess.get_file_as_string(data_file_path_file)
		#prints('get file path:',file_path)
		return file_path
	else:
		return 'ERROR'

func save_loaded_courses() -> void:
	if FileAccess.file_exists(active_courses_file) == false:
		FileAccess.open(active_courses_file, FileAccess.WRITE)
	#prints('Saving active_courses_file',FileAccess.open(active_courses_file, FileAccess.READ))
	if FileAccess.file_exists(active_courses_file):
		var json_string = JSON.stringify(gs.added_course_codes)
		var courses_file = FileAccess.open(active_courses_file,FileAccess.WRITE)
		
		courses_file.store_string(json_string)
		courses_file.close()

func get_loaded_courses() -> Array:
	var array:Array = []
	if FileAccess.file_exists(active_courses_file):
		var file_contents = FileAccess.get_file_as_string(active_courses_file)
		var parsed_array = JSON.parse_string(file_contents)
		if parsed_array is Array:
			array = parsed_array
	return array
