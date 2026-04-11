extends MeshInstance3D

const SCREEN_SIZE := Vector2(3.2, 1.8)
const VIEWPORT_SIZE := Vector2i(640, 360)
const STEP_SECONDS := 0.5
const MOVE_STEP := 0.17
const MIN_POSITION := 0.12
const MAX_POSITION := 0.88
const OBJECT_SIZE := Vector2(42.0, 42.0)
const OBJECT_Y := 78.0
const OBJECT_SMOOTHING := 4.5

var _viewport: SubViewport
var _sequence_label: Label
var _status_label: Label
var _instruction_label: Label
var _playfield: ColorRect
var _object_rect: ColorRect
var _program: Array[String] = []
var _running := false
var _step_index := 0
var _step_timer := 0.0
var _object_position := 0.5
var _target_position := 0.5
var _color_index := 0
var _palette := [
	Color8(80, 232, 255),
	Color8(255, 214, 64),
	Color8(255, 118, 118),
	Color8(163, 255, 106)
]


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	mesh = quad

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 2.6
	material.uv1_scale = Vector3(-1.0, 1.0, 1.0)
	material.uv1_offset = Vector3(1.0, 0.0, 0.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material

	_build_viewport()
	material.albedo_texture = _viewport.get_texture()
	material.emission_texture = _viewport.get_texture()
	reset_program()


func _process(delta: float) -> void:
	_object_position = move_toward(_object_position, _target_position, OBJECT_SMOOTHING * delta)
	_update_object_visual()

	if not _running:
		return

	_step_timer -= delta
	if _step_timer > 0.0:
		return

	if _step_index >= _program.size():
		_running = false
		_status_label.text = "STATUS: DONE"
		_instruction_label.text = "COMPLETE"
		return

	var instruction := _program[_step_index]
	_execute_instruction(instruction)
	_step_index += 1
	_step_timer = STEP_SECONDS
	_status_label.text = "STATUS: RUNNING"
	_instruction_label.text = "STEP %d: %s" % [_step_index, instruction]
	_update_sequence_label()


func set_program(program: Array[String]) -> void:
	_program = program.duplicate()
	if not _running:
		_step_index = 0
		_status_label.text = "STATUS: READY"
		_instruction_label.text = "PRESS RUN"
	_update_sequence_label()


func run_program(program: Array[String]) -> void:
	_program = program.duplicate()
	_running = not _program.is_empty()
	_step_index = 0
	_step_timer = 0.05
	_object_position = 0.5
	_target_position = 0.5
	_color_index = 0
	_update_object_visual()

	if _running:
		_status_label.text = "STATUS: RUNNING"
		_instruction_label.text = "BOOTING..."
	else:
		_status_label.text = "STATUS: EMPTY"
		_instruction_label.text = "ADD INSTRUCTIONS"

	_update_sequence_label()


func reset_program() -> void:
	_program.clear()
	_running = false
	_step_index = 0
	_step_timer = 0.0
	_object_position = 0.5
	_target_position = 0.5
	_color_index = 0
	_status_label.text = "STATUS: RESET"
	_instruction_label.text = "ADD INSTRUCTIONS"
	_update_sequence_label()
	_update_object_visual()


func _execute_instruction(instruction: String) -> void:
	match instruction:
		"MOVE_LEFT":
			_target_position = clamp(_target_position - MOVE_STEP, MIN_POSITION, MAX_POSITION)
		"MOVE_RIGHT":
			_target_position = clamp(_target_position + MOVE_STEP, MIN_POSITION, MAX_POSITION)
		"SET_COLOR":
			_color_index = (_color_index + 1) % _palette.size()
			_update_object_visual()
		"WAIT":
			pass


func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.size = VIEWPORT_SIZE
	add_child(_viewport)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(root)

	var background := ColorRect.new()
	background.color = Color(0.025, 0.03, 0.055, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var title := Label.new()
	title.text = "PHYSICAL VM"
	title.position = Vector2(20.0, 14.0)
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	_status_label = Label.new()
	_status_label.position = Vector2(420.0, 18.0)
	_status_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_status_label)

	_sequence_label = Label.new()
	_sequence_label.position = Vector2(20.0, 58.0)
	_sequence_label.size = Vector2(600.0, 74.0)
	_sequence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sequence_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_sequence_label)

	_instruction_label = Label.new()
	_instruction_label.position = Vector2(20.0, 128.0)
	_instruction_label.size = Vector2(420.0, 34.0)
	_instruction_label.add_theme_font_size_override("font_size", 24)
	root.add_child(_instruction_label)

	_playfield = ColorRect.new()
	_playfield.position = Vector2(60.0, 182.0)
	_playfield.size = Vector2(520.0, 128.0)
	_playfield.color = Color(0.055, 0.08, 0.13, 1.0)
	root.add_child(_playfield)

	var rail := ColorRect.new()
	rail.position = Vector2(0.0, 102.0)
	rail.size = Vector2(520.0, 8.0)
	rail.color = Color(0.2, 0.24, 0.32, 1.0)
	_playfield.add_child(rail)

	_object_rect = ColorRect.new()
	_object_rect.size = OBJECT_SIZE
	_object_rect.color = _palette[_color_index]
	_playfield.add_child(_object_rect)


func _update_sequence_label() -> void:
	if _program.is_empty():
		_sequence_label.text = "PROGRAM: [EMPTY]"
		return

	var segments: Array[String] = []
	for i in range(_program.size()):
		var prefix := ">"
		if not _running or i != _step_index:
			prefix = str(i + 1)
		segments.append("%s:%s" % [prefix, _program[i]])

	_sequence_label.text = "PROGRAM: %s" % "  |  ".join(segments)


func _update_object_visual() -> void:
	if _object_rect == null or _playfield == null:
		return

	_object_rect.color = _palette[_color_index]
	_object_rect.position = Vector2(
		lerpf(0.0, _playfield.size.x - OBJECT_SIZE.x, _object_position),
		OBJECT_Y
	)
