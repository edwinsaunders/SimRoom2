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
const WALL_TEXTURE_GLB_PATH := "res://the_backrooms_wallpaper_texture.glb"
const FLOOR_COLOR_PATH := "res://backrooms/carpet/carpet_color.png"
const FLOOR_NORMAL_PATH := "res://backrooms/carpet/carpet_normal.png"
const FLOOR_ROUGHNESS_PATH := "res://backrooms/carpet/carpet_rough.png"
const CEILING_COLOR_PATH := "res://backrooms/ceiling_tiles/ceiling_tiles_color.png"
const CEILING_NORMAL_PATH := "res://backrooms/ceiling_tiles/ceiling_tiles_normal.png"
const CEILING_ROUGHNESS_PATH := "res://backrooms/ceiling_tiles/ceiling_tiles_rough.png"
const WALL_TILE_WIDTH := 2.0
const WALL_TILE_HEIGHT := 2.0
const FLOOR_TILE_SIZE := 2.4
const CEILING_TILE_SIZE := 1.6

@onready var music: AudioStreamPlayer = $Music
@onready var player: CharacterBody3D = $Player
@onready var wall_screen: MeshInstance3D = $Screen
@onready var room_a: Node3D = $RoomA
@onready var upper_room: Node3D = $UpperRoom
@onready var staircase_up: Node3D = $StaircaseUp
@onready var room_b: Node3D = $RoomB
@onready var doorway_opening: Node3D = $DoorwayOpening
@onready var door: Node3D = $Door
@onready var prototype_doorway: Node3D = $PrototypeDoorway
@onready var prototype_door: Node3D = $PrototypeDoor
@onready var prototype_annex: Node3D = $PrototypeAnnex
@onready var video_screen: Node3D = $VideoScreen
@onready var program_station: Node3D = $ProgramStation

var _door_material: StandardMaterial3D
var _wall_material: Material
var _floor_material: Material
var _ceiling_material: Material
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
	_apply_backrooms_wall_material()
	_apply_backrooms_floor_and_ceiling_materials()
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


func _apply_backrooms_wall_material() -> void:
	_wall_material = _load_wall_material_from_glb()
	if _wall_material == null:
		return

	for root in [room_a, upper_room, staircase_up, room_b, doorway_opening, prototype_doorway, prototype_annex]:
		_apply_wall_material_recursive(root)


func _load_wall_material_from_glb() -> Material:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(WALL_TEXTURE_GLB_PATH, state)
	if error != OK:
		push_warning("Failed to load wall texture GLB: %s" % WALL_TEXTURE_GLB_PATH)
		return null

	var generated := document.generate_scene(state)
	if generated == null:
		push_warning("Failed to generate wall texture scene from GLB")
		return null

	var source_material := _find_first_material(generated)
	generated.free()
	if source_material == null:
		push_warning("No wall material found in GLB")
		return null

	return source_material.duplicate(true)


func _apply_backrooms_floor_and_ceiling_materials() -> void:
	_floor_material = _build_surface_material(FLOOR_COLOR_PATH, FLOOR_NORMAL_PATH, FLOOR_ROUGHNESS_PATH)
	_ceiling_material = _build_surface_material(CEILING_COLOR_PATH, CEILING_NORMAL_PATH, CEILING_ROUGHNESS_PATH)

	for root in [room_a, upper_room, staircase_up, room_b, prototype_annex]:
		_apply_surface_material_recursive(root)


func _build_surface_material(color_path: String, normal_path: String, roughness_path: String) -> Material:
	var color_texture := _load_runtime_texture(color_path)
	var normal_texture := _load_runtime_texture(normal_path)
	var roughness_texture := _load_runtime_texture(roughness_path)
	if color_texture == null:
		push_warning("Missing surface texture: %s" % color_path)
		return null

	var material := StandardMaterial3D.new()
	material.albedo_texture = color_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.roughness = 1.0
	material.roughness_texture = roughness_texture
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = normal_texture != null
	material.normal_texture = normal_texture
	material.cull_mode = BaseMaterial3D.CULL_BACK
	return material


func _load_runtime_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null

	return ImageTexture.create_from_image(image)


func _find_first_material(node: Node) -> Material:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override != null:
			return mesh_instance.material_override
		if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			var surface_material := mesh_instance.mesh.surface_get_material(0)
			if surface_material != null:
				return surface_material

	for child in node.get_children():
		var found := _find_first_material(child)
		if found != null:
			return found

	return null


func _apply_wall_material_recursive(node: Node) -> void:
	if node is MeshInstance3D and _is_wall_mesh(node):
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = _make_tiled_wall_material(mesh_instance)

	for child in node.get_children():
		_apply_wall_material_recursive(child)


func _apply_surface_material_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if _is_floor_mesh(mesh_instance) and _floor_material != null:
			mesh_instance.material_override = _make_tiled_plane_material(mesh_instance, _floor_material, FLOOR_TILE_SIZE)
		elif _is_ceiling_mesh(mesh_instance) and _ceiling_material != null:
			mesh_instance.material_override = _make_tiled_plane_material(mesh_instance, _ceiling_material, CEILING_TILE_SIZE)

	for child in node.get_children():
		_apply_surface_material_recursive(child)


func _is_wall_mesh(node: MeshInstance3D) -> bool:
	var parent := node.get_parent()
	if parent == null:
		return false

	var parent_name := String(parent.name)
	return parent_name.contains("Wall") or parent_name == "DoorHeader"


func _make_tiled_wall_material(mesh_instance: MeshInstance3D) -> Material:
	var material := _wall_material.duplicate(true)
	if material is BaseMaterial3D and mesh_instance.mesh is BoxMesh:
		var base_material := material as BaseMaterial3D
		var box_mesh := mesh_instance.mesh as BoxMesh
		var horizontal_span: float = maxf(box_mesh.size.x, box_mesh.size.z)
		var vertical_span: float = box_mesh.size.y

		base_material.uv1_scale = Vector3(
			maxf(1.0, horizontal_span / WALL_TILE_WIDTH),
			maxf(1.0, vertical_span / WALL_TILE_HEIGHT),
			1.0
		)

	return material


func _make_tiled_plane_material(mesh_instance: MeshInstance3D, source_material: Material, tile_size: float) -> Material:
	var material := source_material.duplicate(true)
	if material is BaseMaterial3D and mesh_instance.mesh is BoxMesh:
		var base_material := material as BaseMaterial3D
		var box_mesh := mesh_instance.mesh as BoxMesh
		base_material.uv1_scale = Vector3(
			maxf(1.0, box_mesh.size.x / tile_size),
			maxf(1.0, box_mesh.size.z / tile_size),
			1.0
		)

	return material


func _is_floor_mesh(node: MeshInstance3D) -> bool:
	var parent := node.get_parent()
	return parent != null and String(parent.name) == "Floor"


func _is_ceiling_mesh(node: MeshInstance3D) -> bool:
	var parent := node.get_parent()
	return parent != null and String(parent.name) == "Ceiling"
