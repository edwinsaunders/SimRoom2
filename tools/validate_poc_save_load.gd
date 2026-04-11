extends SceneTree

const ProgramStorage = preload("res://poc/scripts/poc_program_storage.gd")


func _initialize() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Failed to load main scene")
		quit(1)
		return

	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var annex := world.get_node_or_null("PrototypeAnnex")
	var station := annex.get_node_or_null("PocStation")
	var screen := annex.get_node_or_null("PocScreen")
	if annex == null or station == null or screen == null:
		push_error("Prototype annex objects missing")
		quit(1)
		return

	_clear_program_dir()
	print("Program dir: %s" % ProgramStorage.global_program_dir())

	station.handle_button_press("MOVE_RIGHT")
	station.handle_button_press("SET_COLOR")
	station.handle_button_press("WAIT")
	station.handle_button_press("SAVE")

	var files := ProgramStorage.list_program_files()
	if files.size() != 1:
		push_error("Expected exactly one saved file")
		quit(1)
		return

	var file_name := files[0]
	var full_path := ProjectSettings.globalize_path("%s/%s" % [ProgramStorage.PROGRAM_DIR, file_name])
	print("Saved file: %s" % full_path)

	var saved_text := FileAccess.get_file_as_string("%s/%s" % [ProgramStorage.PROGRAM_DIR, file_name])
	if "MOVE_RIGHT" not in saved_text or "SET_COLOR" not in saved_text:
		push_error("Saved file contents are incorrect")
		quit(1)
		return

	station.handle_button_press("RESET")
	station.handle_button_press("LOAD")
	if screen._program.size() != 3:
		push_error("Loaded program did not repopulate screen state")
		quit(1)
		return

	station.handle_button_press("RUN")
	screen._process(0.6)
	screen._process(0.6)
	if screen._target_position <= 0.5 or screen._color_index != 1:
		push_error("Loaded program did not execute correctly")
		quit(1)
		return

	var malformed_path := "%s/bad_file%s" % [ProgramStorage.PROGRAM_DIR, ProgramStorage.PROGRAM_EXTENSION]
	var malformed := FileAccess.open(malformed_path, FileAccess.WRITE)
	malformed.store_string("JUMP NOW\n")
	malformed = null

	var malformed_result := ProgramStorage.load_program("bad_file%s" % ProgramStorage.PROGRAM_EXTENSION, 8)
	if malformed_result.get("ok", false):
		push_error("Malformed file should not parse")
		quit(1)
		return

	print("Malformed file result: %s" % malformed_result.get("error", "UNKNOWN"))
	print("POC save/load validation passed")
	quit()


func _clear_program_dir() -> void:
	ProgramStorage.ensure_program_dir()
	var files := ProgramStorage.list_program_files()
	for file_name in files:
		DirAccess.remove_absolute("%s/%s" % [ProgramStorage.PROGRAM_DIR, file_name])
	DirAccess.remove_absolute("%s/bad_file%s" % [ProgramStorage.PROGRAM_DIR, ProgramStorage.PROGRAM_EXTENSION])
