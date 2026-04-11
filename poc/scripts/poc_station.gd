extends Node3D

const MAX_PROGRAM_LENGTH := 8

@export var screen_path: NodePath

@onready var output_screen: Node = get_node_or_null(screen_path)
@onready var status_label: Label3D = $StatusLabel3D

var _program: Array[String] = []


func _ready() -> void:
	for child in get_children():
		if child.has_method("set_station"):
			child.set_station(self)

	_refresh_status()
	if output_screen != null and output_screen.has_method("reset_program"):
		output_screen.reset_program()


func handle_button_press(action: String) -> void:
	match action:
		"RUN":
			if output_screen != null and output_screen.has_method("run_program"):
				output_screen.run_program(_program)
		"RESET":
			_program.clear()
			if output_screen != null and output_screen.has_method("reset_program"):
				output_screen.reset_program()
		_:
			if _program.size() >= MAX_PROGRAM_LENGTH:
				status_label.text = "PROGRAM FULL"
				return
			_program.append(action)
			if output_screen != null and output_screen.has_method("set_program"):
				output_screen.set_program(_program)

	_refresh_status()


func _refresh_status() -> void:
	if _program.is_empty():
		status_label.text = "BUILD PROGRAM: E ON BUTTONS"
		return

	status_label.text = "QUEUE %d/%d" % [_program.size(), MAX_PROGRAM_LENGTH]
