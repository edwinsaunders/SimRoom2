extends CharacterBody3D

const MOVE_SPEED := 4.8
const RUN_MULTIPLIER := 1.75
const JUMP_VELOCITY := 5.2
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0025
const MIN_PITCH := deg_to_rad(-85.0)
const MAX_PITCH := deg_to_rad(85.0)
const AudioLibrary = preload("res://scripts/audio_library.gd")

@onready var camera: Camera3D = $Camera3D
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var land_sfx: AudioStreamPlayer = $LandSfx

var _pitch := 0.0
var _mobile_controls: CanvasLayer
var _audio_listener: AudioListener3D


func _ready() -> void:
	jump_sfx.stream = AudioLibrary.create_jump_stream()
	land_sfx.stream = AudioLibrary.create_land_stream()
	_mobile_controls = get_parent().get_node_or_null("MobileControls")
	_ensure_audio_listener()
	if _using_mobile_controls():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
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
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q and event.ctrl_pressed:
		var root := get_parent()
		if root != null and root.has_method("request_quit"):
			root.request_quit()
		else:
			get_tree().quit()


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var previous_vertical_velocity := velocity.y
	var input_vector := Vector2.ZERO
	var jump_requested := Input.is_physical_key_pressed(KEY_SPACE)

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
			_try_mobile_interact()

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		direction = global_transform.basis * direction
		direction.y = 0.0
		direction = direction.normalized()

	var speed := MOVE_SPEED
	if Input.is_physical_key_pressed(KEY_SHIFT):
		speed *= RUN_MULTIPLIER

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


func _try_mobile_interact() -> void:
	var nearest_door: Node3D = null
	var nearest_distance := INF

	for door in get_tree().get_nodes_in_group("doors"):
		if door.has_method("can_interact") and door.can_interact(self):
			var distance: float = global_position.distance_to(door.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_door = door

	if nearest_door != null and nearest_door.has_method("try_interact"):
		nearest_door.try_interact(self)


func _using_mobile_controls() -> bool:
	return _mobile_controls != null and _mobile_controls.visible


func _ensure_audio_listener() -> void:
	_audio_listener = camera.get_node_or_null("AudioListener3D")
	if _audio_listener == null:
		_audio_listener = AudioListener3D.new()
		_audio_listener.name = "AudioListener3D"
		camera.add_child(_audio_listener)

	_audio_listener.make_current()
