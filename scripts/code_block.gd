extends Node3D

const INTERACTION_GROUP := "world_interactables"

enum BlockState {
	WORLD,
	HELD,
	PLACED,
}

var _player: Node3D
var _block_kind := ""
var _display_text := ""
var _editable := false
var _block_color := Color(0.35, 0.75, 1.0, 1.0)
var _interaction_distance := 2.2
var _state := BlockState.WORLD
var _spawn_parent: Node
var _spawn_position := Vector3.ZERO
var _spawn_rotation := Vector3.ZERO

@onready var _collision: CollisionShape3D = $Body/CollisionShape3D
@onready var _mesh_instance: MeshInstance3D = $Body/MeshInstance3D
@onready var _top_label: Label3D = $TopLabel
@onready var _front_label: Label3D = $FrontLabel


func configure(
	player: Node3D,
	block_kind: String,
	display_text: String,
	editable: bool,
	block_color: Color,
	interaction_distance: float,
) -> void:
	_player = player
	_block_kind = block_kind
	_display_text = display_text
	_editable = editable
	_block_color = block_color
	_interaction_distance = interaction_distance
	if is_node_ready():
		_apply_visual_state()


func _ready() -> void:
	add_to_group(INTERACTION_GROUP)
	_spawn_parent = get_parent()
	_spawn_position = position
	_spawn_rotation = rotation
	_apply_visual_state()


func get_block_kind() -> String:
	return _block_kind


func get_block_text() -> String:
	return _display_text


func can_edit_text() -> bool:
	return _editable and _state != BlockState.PLACED


func set_block_text(value: String) -> void:
	_display_text = value.strip_edges()
	if _display_text == "":
		_display_text = "TEXT"
	_refresh_labels()


func get_display_name() -> String:
	return _display_text


func can_interact(player: Node3D) -> bool:
	return _state == BlockState.WORLD and player != null and global_position.distance_to(player.global_position) <= _interaction_distance


func try_interact(player: Node3D) -> bool:
	if not can_interact(player):
		return false

	if player != null and player.has_method("hold_code_block"):
		return player.hold_code_block(self)

	return false


func pick_up(hold_anchor: Node3D) -> void:
	_state = BlockState.HELD
	_set_collision_enabled(false)
	reparent(hold_anchor)
	position = Vector3(0.38, -0.28, -1.15)
	rotation_degrees = Vector3(12.0, -18.0, 0.0)


func attach_to_slot(slot_anchor: Node3D) -> void:
	_state = BlockState.PLACED
	_set_collision_enabled(false)
	reparent(slot_anchor)
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func return_to_spawn() -> void:
	_state = BlockState.WORLD
	_set_collision_enabled(true)
	if _spawn_parent != null:
		reparent(_spawn_parent)
	position = _spawn_position
	rotation = _spawn_rotation


func _set_collision_enabled(enabled: bool) -> void:
	if _collision != null:
		_collision.disabled = not enabled


func _apply_visual_state() -> void:
	if _mesh_instance != null and _mesh_instance.material_override != null:
		var material := _mesh_instance.material_override.duplicate() as StandardMaterial3D
		material.albedo_color = _block_color
		_mesh_instance.material_override = material
	_refresh_labels()


func _refresh_labels() -> void:
	var label_text := _display_text.substr(0, 16)
	if _top_label != null:
		_top_label.text = label_text
	if _front_label != null:
		_front_label.text = label_text
