extends RefCounted

const PROGRAM_DIR := "user://programs"
const PROGRAM_EXTENSION := ".pocprog"
const VALID_INSTRUCTIONS := {
	"MOVE_LEFT": true,
	"MOVE_RIGHT": true,
	"WAIT": true,
	"SET_COLOR": true
}


static func ensure_program_dir() -> int:
	return DirAccess.make_dir_recursive_absolute(PROGRAM_DIR)


static func global_program_dir() -> String:
	return ProjectSettings.globalize_path(PROGRAM_DIR)


static func list_program_files() -> Array[String]:
	var result: Array[String] = []
	var error := ensure_program_dir()
	if error != OK and error != ERR_ALREADY_EXISTS:
		return result

	var dir := DirAccess.open(PROGRAM_DIR)
	if dir == null:
		return result

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if dir.current_is_dir():
			continue
		if entry.get_extension() == PROGRAM_EXTENSION.trim_prefix("."):
			result.append(entry)
	dir.list_dir_end()

	result.sort()
	return result


static func next_auto_filename() -> String:
	var files := list_program_files()
	var next_index := 1
	for file_name in files:
		if file_name.begins_with("program_") and file_name.ends_with(PROGRAM_EXTENSION):
			var number_text := file_name.trim_prefix("program_").trim_suffix(PROGRAM_EXTENSION)
			if number_text.is_valid_int():
				next_index = max(next_index, int(number_text) + 1)

	return "program_%03d%s" % [next_index, PROGRAM_EXTENSION]


static func serialize_program(program: Array[String]) -> String:
	var lines: Array[String] = []
	for instruction in program:
		lines.append(instruction)
	return "\n".join(lines) + ("\n" if not lines.is_empty() else "")


static func parse_program_text(text: String, max_length: int) -> Dictionary:
	var program: Array[String] = []
	var lines := text.split("\n", false)
	for line_index in range(lines.size()):
		var raw_line := lines[line_index].strip_edges()
		if raw_line == "" or raw_line.begins_with("#"):
			continue

		# The file format is intentionally permissive after the opcode so the
		# fake language can grow later without rewriting the basic loader.
		var opcode := raw_line.split(" ", false, 1)[0].strip_edges().to_upper()
		if not VALID_INSTRUCTIONS.has(opcode):
			return {
				"ok": false,
				"error": "INVALID OPCODE ON LINE %d" % [line_index + 1]
			}

		if program.size() >= max_length:
			return {
				"ok": false,
				"error": "PROGRAM TOO LONG"
			}

		program.append(opcode)

	return {
		"ok": true,
		"program": program
	}


static func save_program(program: Array[String]) -> Dictionary:
	var error := ensure_program_dir()
	if error != OK and error != ERR_ALREADY_EXISTS:
		return {
			"ok": false,
			"error": "FAILED TO CREATE PROGRAM DIR"
		}

	var file_name := next_auto_filename()
	var path := "%s/%s" % [PROGRAM_DIR, file_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"error": "FAILED TO OPEN SAVE FILE"
		}

	file.store_string(serialize_program(program))
	return {
		"ok": true,
		"file_name": file_name,
		"path": path,
		"global_path": ProjectSettings.globalize_path(path)
	}


static func load_program(file_name: String, max_length: int) -> Dictionary:
	if file_name == "":
		return {
			"ok": false,
			"error": "NO FILE SELECTED"
		}

	var path := "%s/%s" % [PROGRAM_DIR, file_name]
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"error": "FILE NOT FOUND"
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"error": "FAILED TO OPEN FILE"
		}

	var parsed := parse_program_text(file.get_as_text(), max_length)
	if not parsed.get("ok", false):
		return parsed

	parsed["file_name"] = file_name
	parsed["path"] = path
	parsed["global_path"] = ProjectSettings.globalize_path(path)
	return parsed
