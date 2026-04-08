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


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	jump_sfx.stream = AudioLibrary.create_jump_stream()
	land_sfx.stream = AudioLibrary.create_land_stream()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pitch = clamp(_pitch - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
		camera.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
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

	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0

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
	elif Input.is_physical_key_pressed(KEY_SPACE):
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
