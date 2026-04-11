extends Node3D

const MAX_PROGRAM_LENGTH := 8
const ProgramStorage = preload("res://poc/scripts/poc_program_storage.gd")

@export var screen_path: NodePath

@onready var output_screen: Node = get_node_or_null(screen_path)
@onready var status_label: Label3D = $StatusLabel3D
@onready var file_label: Label3D = $FileLabel3D
@onready var path_label: Label3D = $PathLabel3D

var _program: Array[String] = []
var _saved_files: Array[String] = []
var _selected_file_index := 0


func _ready() -> void:
	for child in get_children():
		if child.has_method("set_station"):
			child.set_station(self)

	_refresh_saved_files()
	_refresh_status()
	_sync_screen_preview()
	path_label.text = ProgramStorage.global_program_dir()


func handle_button_press(action: String) -> void:
	match action:
		"RUN":
			if output_screen != null and output_screen.has_method("run_program"):
				output_screen.run_program(_program)
		"RESET":
			_program.clear()
			_sync_screen_preview()
		"SAVE":
			_handle_save()
		"LOAD":
			_handle_load()
		"NEXT_FILE":
			_cycle_selected_file(1)
		"PREV_FILE":
			_cycle_selected_file(-1)
		_:
			if _program.size() >= MAX_PROGRAM_LENGTH:
				status_label.text = "PROGRAM FULL"
				return
			_program.append(action)
			_sync_screen_preview()

	_refresh_status()


func _refresh_status() -> void:
	if _program.is_empty():
		status_label.text = "BUILD PROGRAM: E ON BUTTONS"
		return

	status_label.text = "QUEUE %d/%d" % [_program.size(), MAX_PROGRAM_LENGTH]


func _sync_screen_preview() -> void:
	if output_screen == null:
		return

	# Save/load reuses the same queue representation as normal button entry,
	# so the screen can be refreshed through the existing preview/reset API.
	if _program.is_empty():
		if output_screen.has_method("reset_program"):
			output_screen.reset_program()
		return

	if output_screen.has_method("set_program"):
		output_screen.set_program(_program)


func _refresh_saved_files() -> void:
	_saved_files = ProgramStorage.list_program_files()
	if _saved_files.is_empty():
		_selected_file_index = 0
		file_label.text = "FILES: NONE"
		return

	_selected_file_index = clamp(_selected_file_index, 0, _saved_files.size() - 1)
	file_label.text = "FILE: %s" % [_saved_files[_selected_file_index]]


func _cycle_selected_file(step: int) -> void:
	if _saved_files.is_empty():
		_refresh_saved_files()
		status_label.text = "NO SAVE FILES"
		return

	_selected_file_index = posmod(_selected_file_index + step, _saved_files.size())
	file_label.text = "FILE: %s" % [_saved_files[_selected_file_index]]
	status_label.text = "SELECTED %s" % [_saved_files[_selected_file_index]]


func _handle_save() -> void:
	if _program.is_empty():
		status_label.text = "NOTHING TO SAVE"
		return

	var result := ProgramStorage.save_program(_program)
	if not result.get("ok", false):
		status_label.text = result.get("error", "SAVE FAILED")
		return

	_refresh_saved_files()
	var file_name := String(result.get("file_name", ""))
	if file_name != "":
		_selected_file_index = _saved_files.find(file_name)
	_refresh_saved_files()
	status_label.text = "SAVED %s" % [file_name]


func _handle_load() -> void:
	_refresh_saved_files()
	if _saved_files.is_empty():
		status_label.text = "NO SAVE FILES"
		return

	var file_name := _saved_files[_selected_file_index]
	var result := ProgramStorage.load_program(file_name, MAX_PROGRAM_LENGTH)
	if not result.get("ok", false):
		status_label.text = result.get("error", "LOAD FAILED")
		return

	_program = result.get("program", []).duplicate()
	_sync_screen_preview()
	status_label.text = "LOADED %s" % [file_name]
	_refresh_status()
