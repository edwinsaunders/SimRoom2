extends CharacterBody3D

const MOVE_SPEED := 4.8
const RUN_MULTIPLIER := 1.75
const CROUCH_SPEED_MULTIPLIER := 0.55
const JUMP_VELOCITY := 5.2
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0025
const MIN_PITCH := deg_to_rad(-85.0)
const MAX_PITCH := deg_to_rad(85.0)
const INTERACTION_GROUP := "world_interactables"
const CROUCH_CAMERA_OFFSET := -0.65
const CROUCH_CAPSULE_HEIGHT := 0.9
const CROUCH_TRANSITION_SPEED := 10.0
const AudioLibrary = preload("res://scripts/audio_library.gd")

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var land_sfx: AudioStreamPlayer = $LandSfx

var _pitch := 0.0
var _mobile_controls: CanvasLayer
var _audio_listener: AudioListener3D
var _held_code_block: Node3D
var _block_hold_anchor: Node3D
var _text_edit_layer: CanvasLayer
var _text_edit_panel: PanelContainer
var _text_edit_field: LineEdit
var _editing_block: Node3D
var _is_editing_text := false
var _standing_camera_height := 0.0
var _standing_capsule_height := 0.0


func _ready() -> void:
	jump_sfx.stream = AudioLibrary.create_jump_stream()
	land_sfx.stream = AudioLibrary.create_land_stream()
	_standing_camera_height = camera.position.y
	if collision_shape.shape is CapsuleShape3D:
		_standing_capsule_height = collision_shape.shape.height
	_mobile_controls = get_parent().get_node_or_null("MobileControls")
	_ensure_audio_listener()
	_ensure_block_hold_anchor()
	_ensure_text_edit_ui()
	if _using_mobile_controls():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _is_editing_text:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_text_edit()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _using_mobile_controls():
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pitch = clamp(_pitch - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
		camera.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _using_mobile_controls():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not _using_mobile_controls():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_try_edit_text_block()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_try_interact()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q and event.ctrl_pressed:
		var root := get_parent()
		if root != null and root.has_method("request_quit"):
			root.request_quit()
		else:
			get_tree().quit()


func _physics_process(delta: float) -> void:
	if _is_editing_text:
		_update_crouch_state(false, delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity = Vector3.ZERO
		move_and_slide()
		return

	var was_on_floor := is_on_floor()
	var previous_vertical_velocity := velocity.y
	var input_vector := Vector2.ZERO
	var jump_requested := Input.is_physical_key_pressed(KEY_SPACE)
	var crouch_requested := Input.is_physical_key_pressed(KEY_CTRL)

	_apply_mobile_look()

	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0

	if _using_mobile_controls():
		input_vector += _mobile_controls.move_vector
		jump_requested = jump_requested or _mobile_controls.consume_jump_requested()
		if _mobile_controls.consume_interact_requested():
			_try_interact()

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		direction = global_transform.basis * direction
		direction.y = 0.0
		direction = direction.normalized()

	var speed := MOVE_SPEED
	if Input.is_physical_key_pressed(KEY_SHIFT):
		speed *= RUN_MULTIPLIER
	if crouch_requested:
		speed *= CROUCH_SPEED_MULTIPLIER

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif jump_requested:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_crouch_state(crouch_requested, delta)

	if not was_on_floor and is_on_floor() and previous_vertical_velocity < -2.5:
		land_sfx.play()


func prepare_for_quit() -> void:
	jump_sfx.stop()
	jump_sfx.stream = null
	land_sfx.stop()
	land_sfx.stream = null


func _exit_tree() -> void:
	prepare_for_quit()


func _apply_mobile_look() -> void:
	if not _using_mobile_controls():
		return

	var look_delta: Vector2 = _mobile_controls.consume_look_delta()
	if look_delta == Vector2.ZERO:
		return

	rotate_y(-look_delta.x * MOUSE_SENSITIVITY)
	_pitch = clamp(_pitch - look_delta.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
	camera.rotation.x = _pitch


func _update_crouch_state(crouch_requested: bool, delta: float) -> void:
	var target_camera_height := _standing_camera_height
	if crouch_requested:
		target_camera_height += CROUCH_CAMERA_OFFSET

	camera.position.y = move_toward(camera.position.y, target_camera_height, CROUCH_TRANSITION_SPEED * delta)

	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return

	var target_capsule_height := _standing_capsule_height
	if crouch_requested:
		target_capsule_height = CROUCH_CAPSULE_HEIGHT

	capsule.height = move_toward(capsule.height, target_capsule_height, CROUCH_TRANSITION_SPEED * delta)
	collision_shape.position.y = capsule.radius + capsule.height * 0.5


func hold_code_block(block: Node3D) -> bool:
	if block == null:
		return false

	if _held_code_block != null and _held_code_block != block:
		return false

	_held_code_block = block
	if _held_code_block.has_method("pick_up"):
		_held_code_block.pick_up(_block_hold_anchor)
	return true


func peek_held_code_block() -> Node3D:
	return _held_code_block


func consume_held_code_block() -> Node3D:
	var block := _held_code_block
	_held_code_block = null
	return block


func _try_edit_text_block() -> void:
	var target_block := _held_code_block
	if target_block == null or not target_block.has_method("can_edit_text") or not target_block.can_edit_text():
		target_block = _find_nearest_editable_block()

	if target_block == null:
		return

	_open_text_edit(target_block)


func _try_interact() -> void:
	var nearest_interactable: Node3D = null
	var nearest_distance := INF

	for interactable in get_tree().get_nodes_in_group(INTERACTION_GROUP):
		if interactable.has_method("can_interact") and interactable.can_interact(self):
			var distance: float = global_position.distance_to(interactable.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_interactable = interactable

	if nearest_interactable != null and nearest_interactable.has_method("try_interact"):
		nearest_interactable.try_interact(self)


func _using_mobile_controls() -> bool:
	return _mobile_controls != null and _mobile_controls.visible


func _ensure_audio_listener() -> void:
	_audio_listener = camera.get_node_or_null("AudioListener3D")
	if _audio_listener == null:
		_audio_listener = AudioListener3D.new()
		_audio_listener.name = "AudioListener3D"
		camera.add_child(_audio_listener)

	_audio_listener.make_current()


func _ensure_block_hold_anchor() -> void:
	_block_hold_anchor = camera.get_node_or_null("BlockHoldAnchor")
	if _block_hold_anchor == null:
		_block_hold_anchor = Node3D.new()
		_block_hold_anchor.name = "BlockHoldAnchor"
		_block_hold_anchor.position = Vector3.ZERO
		camera.add_child(_block_hold_anchor)


func _ensure_text_edit_ui() -> void:
	_text_edit_layer = CanvasLayer.new()
	_text_edit_layer.name = "TextEditLayer"
	_text_edit_layer.layer = 20
	_text_edit_layer.visible = false
	add_child(_text_edit_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_edit_layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	_text_edit_panel = PanelContainer.new()
	_text_edit_panel.custom_minimum_size = Vector2(520.0, 120.0)
	_text_edit_panel.anchor_left = 0.5
	_text_edit_panel.anchor_top = 0.5
	_text_edit_panel.anchor_right = 0.5
	_text_edit_panel.anchor_bottom = 0.5
	_text_edit_panel.offset_left = -260.0
	_text_edit_panel.offset_top = -60.0
	_text_edit_panel.offset_right = 260.0
	_text_edit_panel.offset_bottom = 60.0
	root.add_child(_text_edit_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_text_edit_panel.add_child(margin)

	var layout := VBoxContainer.new()
	margin.add_child(layout)

	var hint := Label.new()
	hint.text = "EDIT TEXT BLOCK  ENTER: SAVE  ESC: CANCEL"
	layout.add_child(hint)

	_text_edit_field = LineEdit.new()
	_text_edit_field.placeholder_text = "Type program output text"
	_text_edit_field.text_submitted.connect(_submit_text_edit)
	layout.add_child(_text_edit_field)


func _open_text_edit(block: Node3D) -> void:
	_editing_block = block
	_is_editing_text = true
	_text_edit_layer.visible = true
	if _editing_block != null and _editing_block.has_method("get_block_text"):
		_text_edit_field.text = _editing_block.get_block_text()
	else:
		_text_edit_field.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_text_edit_field.grab_focus()
	_text_edit_field.select_all()


func _submit_text_edit(_submitted_text: String) -> void:
	if _editing_block != null and _editing_block.has_method("set_block_text"):
		_editing_block.set_block_text(_text_edit_field.text)
	_close_text_edit()


func _close_text_edit() -> void:
	_editing_block = null
	_is_editing_text = false
	_text_edit_layer.visible = false
	_text_edit_field.release_focus()
	if not _using_mobile_controls():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _find_nearest_editable_block() -> Node3D:
	var nearest_block: Node3D = null
	var nearest_distance := INF

	for interactable in get_tree().get_nodes_in_group(INTERACTION_GROUP):
		if interactable.has_method("can_edit_text") and interactable.can_edit_text():
			if interactable.has_method("can_interact") and not interactable.can_interact(self):
				continue
			var distance: float = global_position.distance_to(interactable.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_block = interactable

	return nearest_block
