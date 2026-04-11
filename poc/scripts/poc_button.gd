extends Node3D

const INTERACTION_GROUP := "world_interactables"

@export var button_action := "MOVE_RIGHT"
@export var button_label := "MOVE RIGHT"
@export var interaction_distance := 2.6
@export var base_color := Color(0.22, 0.24, 0.32, 1.0)

@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance: MeshInstance3D = $StaticBody3D/MeshInstance3D

var _station: Node3D


func _ready() -> void:
	add_to_group(INTERACTION_GROUP)
	label_3d.text = button_label

	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = 0.78
	material.metallic = 0.08
	mesh_instance.material_override = material


func set_station(station: Node3D) -> void:
	_station = station


func can_interact(player: Node3D) -> bool:
	return player != null and global_position.distance_to(player.global_position) <= interaction_distance


func try_interact(player: Node3D) -> bool:
	if not can_interact(player):
		return false
	if _station == null or not _station.has_method("handle_button_press"):
		return false

	_station.handle_button_press(button_action)
	return true
