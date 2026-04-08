extends Node3D

const VIEWPORT_SIZE := Vector2i(1280, 720)

var _player: Node3D
var _video_path := ""
var _screen_size := Vector2(3.2, 1.8)
var _min_distance := 1.8
var _max_distance := 14.0
var _min_volume_db := -28.0
var _max_volume_db := -4.0
var _smoothing_speed := 8.0
var _current_volume_db := _min_volume_db
var _video_player: VideoStreamPlayer
var _media_started := false


func configure(
	player: Node3D,
	video_path: String,
	screen_size: Vector2,
	min_distance: float,
	max_distance: float,
	min_volume_db: float,
	max_volume_db: float,
	smoothing_speed: float,
) -> void:
	_player = player
	_video_path = video_path
	_screen_size = screen_size
	_min_distance = min_distance
	_max_distance = max_distance
	_min_volume_db = min_volume_db
	_max_volume_db = max_volume_db
	_smoothing_speed = smoothing_speed
	_current_volume_db = _min_volume_db


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.name = "VideoViewport"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = VIEWPORT_SIZE
	add_child(viewport)

	var video_player := VideoStreamPlayer.new()
	video_player.name = "VideoPlayer"
	video_player.size = Vector2(VIEWPORT_SIZE)
	video_player.expand = true
	video_player.autoplay = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.stream = load(_video_path)
	video_player.volume_db = _current_volume_db
	video_player.finished.connect(_restart_video)
	viewport.add_child(video_player)
	_video_player = video_player

	var quad := MeshInstance3D.new()
	quad.name = "ScreenSurface"
	var mesh := QuadMesh.new()
	mesh.size = _screen_size
	quad.mesh = mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.emission_enabled = true
	material.emission_texture = viewport.get_texture()
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 1.4
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material_override = material
	add_child(quad)

	_start_media.call_deferred()


func _restart_video() -> void:
	if _video_player != null and not DisplayServer.get_name().contains("headless"):
		_video_player.play()


func _process(delta: float) -> void:
	if not _media_started and not DisplayServer.get_name().contains("headless"):
		_start_media()

	if _player == null or _video_player == null:
		return

	var distance: float = global_position.distance_to(_player.global_position)
	var clamped_distance: float = clamp(distance, _min_distance, _max_distance)
	var normalized_distance: float = (clamped_distance - _min_distance) / max(_max_distance - _min_distance, 0.001)
	var attenuation: float = 1.0 / (1.0 + normalized_distance * normalized_distance * 3.0)
	var target_volume_db: float = lerp(_min_volume_db, _max_volume_db, attenuation)
	var blend: float = clamp(delta * _smoothing_speed, 0.0, 1.0)
	_current_volume_db = lerp(_current_volume_db, target_volume_db, blend)
	_video_player.volume_db = clamp(_current_volume_db, _min_volume_db, _max_volume_db)


func _start_media() -> void:
	if _media_started or DisplayServer.get_name().contains("headless"):
		return

	_media_started = true
	if _video_player != null:
		_video_player.play()
