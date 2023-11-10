extends Node

const VERSION = 0
const PERSIST_PATH = 'user://'
const FILENAME_PREFIX = 'Default'

var progress_data : Dictionary = {}
var battle_data : Dictionary = {}

static func list_contents(path:String):
	var contents : Array = []
	var directory = DirAccess.open(path)
	if directory == null:
		var err = DirAccess.get_open_error()
		if err:
			print("Error code %d opening directory: %s" % [err, path])
			return
	directory.list_dir_begin()
		
	while true:
		var filename = directory.get_next()
		if filename == "":
			break
		if filename.begins_with("."):
			continue
		if directory.current_is_dir():
			contents.append(filename + "/")
		else:
			contents.append(filename)
	directory.list_dir_end()
	return contents

func get_local_path():
	return "%sv%d/" % [PERSIST_PATH, VERSION]

func make_local_directory():
	var local_path : String = get_local_path()
	var dir_access = DirAccess.open(local_path)
	if dir_access == null:
		var err = DirAccess.make_dir_absolute(local_path)
		if err:
			print("Error code %d making directory: %s" % [err, local_path])
			err = OS.execute("CMD.exe", ["/C", "mkdir %s" % local_path])
			if err:
				print("Error code %d OS executing mkdir: %s" % [err, local_path])

func _get_default_file_path():
	var regex = RegEx.new()
	var directory_path : String = get_local_path()
	var contents : Array = list_contents(directory_path)
	var match_string : String = FILENAME_PREFIX + \
	"\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}\\.json"
	regex.compile(match_string)
	for content in contents:
		var regex_match = regex.search(content)
		if regex_match:
			return (directory_path + content)
	return ''

func _get_datetime_string():
	var date : Dictionary = Time.get_datetime_dict_from_system()
	return "%4d-%02d-%02d_%02d-%02d-%02d" % [date['year'], date['month'], date['day'], date['hour'], date['minute'], date['second']]

func _new_file(filename_prefix : String):
	make_local_directory()
	var directory_path : String = get_local_path()
	var date_string : String = _get_datetime_string()
	var file_path : String = "%s%s%s.json" % [directory_path, filename_prefix, date_string]
	var file_handler = FileAccess.open(file_path, FileAccess.WRITE)
	if file_handler == null:
		var err = FileAccess.get_open_error()
		if err:
			print("Error code %d opening file for writing: %s" % [err, file_path])
	return file_handler

func _new_default_file():
	return _new_file(FILENAME_PREFIX)

func _open_default_file():
	var file_handler
	var existing_file_path = _get_default_file_path()
	if existing_file_path:
		file_handler = FileAccess.open(existing_file_path, FileAccess.READ)
	if file_handler == null:
		var err = FileAccess.get_open_error()
		if err:
			print("Error code %d opening file for writing: %s" % [err, existing_file_path])
	return file_handler

func save_data(data : Dictionary):
	var file_handler : FileAccess = _new_default_file()
	file_handler.store_line(JSON.stringify(data))
	file_handler.close()

func _load_or_start_default():
	var file_handler : FileAccess = _open_default_file()
	var saved_dict : Dictionary
	if file_handler.is_open():
		var contents : String = file_handler.get_line()
		if contents != '':
			saved_dict = JSON.parse_string(contents)
		else:
			saved_dict = {}
		file_handler.close()
	else:
		saved_dict = {}
	return saved_dict
