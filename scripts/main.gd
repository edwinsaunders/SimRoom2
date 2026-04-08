extends Node3D

const ROOM_WIDTH := 12.0
const ROOM_DEPTH := 12.0
const ROOM_HEIGHT := 4.0
const WALL_THICKNESS := 0.2
const DOOR_WIDTH := 2.2
const DOOR_HEIGHT := 2.8
const DOOR_THICKNESS := 0.08
const DOOR_INTERACTION_DISTANCE := 2.8
const DOOR_OPEN_ANGLE := deg_to_rad(-68.0)
const DOOR_ANIMATION_DURATION := 0.2
const SECOND_ROOM_OFFSET := Vector3(ROOM_WIDTH, 0, 0)
const SCREEN_SIZE := Vector2(3.2, 1.8)
const VIDEO_AUDIO_MIN_DISTANCE := 1.8
const VIDEO_AUDIO_MAX_DISTANCE := 14.0
const VIDEO_AUDIO_MIN_VOLUME_DB := -28.0
const VIDEO_AUDIO_MAX_VOLUME_DB := -4.0
const VIDEO_AUDIO_SMOOTHING_SPEED := 8.0
const DoorScript = preload("res://scripts/door.gd")
const VideoScreenScript = preload("res://scripts/video_screen.gd")

@onready var music: AudioStreamPlayer = $Music
@onready var player: CharacterBody3D = $Player

var _wall_material: StandardMaterial3D
var _floor_material: StandardMaterial3D
var _ceiling_material: StandardMaterial3D
var _bezel_material: StandardMaterial3D
var _door_material: StandardMaterial3D
var _quit_requested := false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	music.stop()
	music.stream = null

	_build_materials()
	_build_room()
	_build_screen_frame()
	_build_video_screen()
	print("SimRoom ready")


func request_quit() -> void:
	if _quit_requested:
		return

	_quit_requested = true
	music.stop()
	music.stream = null

	if player != null and player.has_method("prepare_for_quit"):
		player.prepare_for_quit()

	_finish_quit.call_deferred()


func _finish_quit() -> void:
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()


func _exit_tree() -> void:
	music.stop()
	music.stream = null


func _build_materials() -> void:
	_wall_material = StandardMaterial3D.new()
	_wall_material.albedo_color = Color(0.15, 0.16, 0.19)
	_wall_material.roughness = 0.96

	_floor_material = StandardMaterial3D.new()
	_floor_material.albedo_color = Color(0.08, 0.085, 0.1)
	_floor_material.roughness = 0.92

	_ceiling_material = StandardMaterial3D.new()
	_ceiling_material.albedo_color = Color(0.11, 0.12, 0.145)
	_ceiling_material.roughness = 0.98

	_bezel_material = StandardMaterial3D.new()
	_bezel_material.albedo_color = Color(0.02, 0.02, 0.025)
	_bezel_material.metallic = 0.2
	_bezel_material.roughness = 0.35

	_door_material = StandardMaterial3D.new()
	_door_material.albedo_color = Color(0.34, 0.24, 0.16)
	_door_material.roughness = 0.7


func _build_room() -> void:
	_build_room_shell("RoomA", Vector3.ZERO, true, false)
	_build_room_shell("RoomB", SECOND_ROOM_OFFSET, false, true)
	_build_shared_doorway(ROOM_WIDTH * 0.5)
	_build_door_leaf(ROOM_WIDTH * 0.5)


func _build_room_shell(prefix: String, center: Vector3, build_west_wall: bool, build_east_wall: bool) -> void:
	_add_box("%sFloor" % prefix, center, Vector3(ROOM_WIDTH, WALL_THICKNESS, ROOM_DEPTH), _floor_material)
	_add_box("%sCeiling" % prefix, center + Vector3(0, ROOM_HEIGHT, 0), Vector3(ROOM_WIDTH, WALL_THICKNESS, ROOM_DEPTH), _ceiling_material)
	_add_box("%sNorthWall" % prefix, center + Vector3(0, ROOM_HEIGHT * 0.5, -ROOM_DEPTH * 0.5), Vector3(ROOM_WIDTH, ROOM_HEIGHT, WALL_THICKNESS), _wall_material)
	_add_box("%sSouthWall" % prefix, center + Vector3(0, ROOM_HEIGHT * 0.5, ROOM_DEPTH * 0.5), Vector3(ROOM_WIDTH, ROOM_HEIGHT, WALL_THICKNESS), _wall_material)

	if build_west_wall:
		_add_box("%sWestWall" % prefix, center + Vector3(-ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH), _wall_material)

	if build_east_wall:
		_add_box("%sEastWall" % prefix, center + Vector3(ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH), _wall_material)


func _build_shared_doorway(wall_x: float) -> void:
	var side_wall_depth := (ROOM_DEPTH - DOOR_WIDTH) * 0.5
	var side_wall_z := DOOR_WIDTH * 0.5 + side_wall_depth * 0.5
	var header_height := ROOM_HEIGHT - DOOR_HEIGHT

	_add_box("SharedWallNorth", Vector3(wall_x, ROOM_HEIGHT * 0.5, -side_wall_z), Vector3(WALL_THICKNESS, ROOM_HEIGHT, side_wall_depth), _wall_material)
	_add_box("SharedWallSouth", Vector3(wall_x, ROOM_HEIGHT * 0.5, side_wall_z), Vector3(WALL_THICKNESS, ROOM_HEIGHT, side_wall_depth), _wall_material)
	_add_box("DoorHeader", Vector3(wall_x, DOOR_HEIGHT + header_height * 0.5, 0), Vector3(WALL_THICKNESS, header_height, DOOR_WIDTH), _wall_material)


func _build_door_leaf(wall_x: float) -> void:
	var door := Node3D.new()
	door.name = "Door"
	door.script = DoorScript
	door.position = Vector3(wall_x, 0, -DOOR_WIDTH * 0.5)
	add_child(door)

	var leaf := StaticBody3D.new()
	leaf.name = "Leaf"
	door.add_child(leaf)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(DOOR_THICKNESS, DOOR_HEIGHT - 0.15, DOOR_WIDTH)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	collision.position = Vector3(DOOR_THICKNESS * 0.5, mesh.size.y * 0.5, mesh.size.z * 0.5)
	leaf.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _door_material
	mesh_instance.position = collision.position
	leaf.add_child(mesh_instance)

	door.configure(player, DOOR_INTERACTION_DISTANCE, DOOR_OPEN_ANGLE, DOOR_ANIMATION_DURATION)


func _build_screen_frame() -> void:
	var frame := MeshInstance3D.new()
	frame.name = "ScreenFrame"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.5, 2.1, 0.08)
	frame.mesh = mesh
	frame.material_override = _bezel_material
	frame.position = Vector3(0, 2.05, -5.93)
	add_child(frame)


func _build_video_screen() -> void:
	var screen := Node3D.new()
	screen.name = "VideoScreen"
	screen.script = VideoScreenScript
	screen.position = SECOND_ROOM_OFFSET + Vector3(0, 2.05, -5.87)
	screen.configure(
		player,
		"res://output.ogv",
		SCREEN_SIZE,
		VIDEO_AUDIO_MIN_DISTANCE,
		VIDEO_AUDIO_MAX_DISTANCE,
		VIDEO_AUDIO_MIN_VOLUME_DB,
		VIDEO_AUDIO_MAX_VOLUME_DB,
		VIDEO_AUDIO_SMOOTHING_SPEED
	)
	add_child(screen)

	var frame := MeshInstance3D.new()
	frame.name = "VideoScreenFrame"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.5, 2.1, 0.08)
	frame.mesh = mesh
	frame.material_override = _bezel_material
	frame.position = SECOND_ROOM_OFFSET + Vector3(0, 2.05, -5.93)
	add_child(frame)


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
