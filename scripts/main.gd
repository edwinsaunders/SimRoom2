extends Node3D

const DOOR_WIDTH := 2.2
const DOOR_INTERACTION_DISTANCE := 2.8
const DOOR_OPEN_ANGLE := deg_to_rad(-68.0)
const DOOR_ANIMATION_DURATION := 0.2
const SCREEN_SIZE := Vector2(3.2, 1.8)
const VIDEO_AUDIO_MIN_DISTANCE := 1.8
const VIDEO_AUDIO_MAX_DISTANCE := 14.0
const VIDEO_AUDIO_MIN_VOLUME_DB := -28.0
const VIDEO_AUDIO_MAX_VOLUME_DB := -4.0
const VIDEO_AUDIO_SMOOTHING_SPEED := 8.0
const PROGRAM_INTERACTION_DISTANCE := 2.4

@onready var music: AudioStreamPlayer = $Music
@onready var player: CharacterBody3D = $Player
@onready var wall_screen: MeshInstance3D = $Screen
@onready var door: Node3D = $Door
@onready var prototype_door: Node3D = $PrototypeDoor
@onready var video_screen: Node3D = $VideoScreen
@onready var program_station: Node3D = $ProgramStation

var _door_material: StandardMaterial3D
var _quit_requested := false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	music.stop()
	music.stream = null

	_configure_scene()
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


func _configure_scene() -> void:
	door.configure(player, DOOR_INTERACTION_DISTANCE, DOOR_OPEN_ANGLE, DOOR_ANIMATION_DURATION)
	prototype_door.configure(player, DOOR_INTERACTION_DISTANCE, DOOR_OPEN_ANGLE, DOOR_ANIMATION_DURATION)
	video_screen.configure(
		player,
		"res://output.ogv",
		SCREEN_SIZE,
		VIDEO_AUDIO_MIN_DISTANCE,
		VIDEO_AUDIO_MAX_DISTANCE,
		VIDEO_AUDIO_MIN_VOLUME_DB,
		VIDEO_AUDIO_MAX_VOLUME_DB,
		VIDEO_AUDIO_SMOOTHING_SPEED
	)
	program_station.configure(player, wall_screen, PROGRAM_INTERACTION_DISTANCE)
