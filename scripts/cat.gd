extends CharacterBody3D

const MOVE_SPEED := 1.15
const GRAVITY := 14.0
const TURN_INTERVAL_MIN := 1.8
const TURN_INTERVAL_MAX := 4.6
const TURN_SMOOTHING := 6.0
const TARGET_MODEL_HEIGHT := 0.8
const WALK_ANIMATION_NAME := "GltfAnimation 0"
const FOOT_CLEARANCE := 0.1
const COLLISION_LOOKAHEAD := 0.35
const TURN_RETRY_COUNT := 4

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model_anchor: Node3D = $ModelAnchor

var _rng := RandomNumberGenerator.new()
var _heading := Vector3.FORWARD
var _turn_timer := 0.0
var _model_root: Node3D
var _visual_facing_offset := 0.0


func _ready() -> void:
	_rng.randomize()
	_choose_random_heading()
	_reset_turn_timer()
	_load_model()


func _physics_process(delta: float) -> void:
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_choose_random_heading()
		_reset_turn_timer()

	if _will_hit_obstacle():
		_pick_clear_heading()

	var desired_velocity := _heading * MOVE_SPEED
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_visual_rotation(delta)

	if is_on_wall():
		var wall_normal := Vector3.ZERO
		for index in range(get_slide_collision_count()):
			var collision := get_slide_collision(index)
			wall_normal += collision.get_normal()

		_turn_away_from(wall_normal)


func _load_model() -> void:
	var cat_scene := load("res://cat_walk.glb") as PackedScene
	if cat_scene == null:
		push_warning("Failed to load cat model")
		return

	var generated := cat_scene.instantiate() as Node3D
	if generated == null:
		push_warning("Failed to generate cat scene")
		return

	_model_root = generated
	_model_root.name = "Model"
	model_anchor.add_child(_model_root)
	_scale_model_to_target_height()
	_play_walk_animation()

func _scale_model_to_target_height() -> void:
	if _model_root == null:
		return

	var bounds := _compute_mesh_aabb(_model_root)
	if bounds.size.y <= 0.001:
		return

	var scale_factor := TARGET_MODEL_HEIGHT / bounds.size.y
	_model_root.scale = Vector3.ONE * scale_factor
	_model_root.position.y = -bounds.position.y * scale_factor + FOOT_CLEARANCE


func _compute_mesh_aabb(node: Node) -> AABB:
	var has_bounds := false
	var combined := AABB()

	if node is MeshInstance3D and node.mesh != null:
		combined = node.transform * node.mesh.get_aabb()
		has_bounds = true

	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _compute_mesh_aabb(child)
			if child_bounds.size != Vector3.ZERO:
				var transformed: AABB = child.transform * child_bounds
				if not has_bounds:
					combined = transformed
					has_bounds = true
				else:
					combined = combined.merge(transformed)

	if has_bounds:
		return combined

	return AABB()


func _play_walk_animation() -> void:
	if _model_root == null:
		return

	var player := _find_first_animation_player(_model_root)
	if player == null:
		return

	var animation_name := StringName(WALK_ANIMATION_NAME)
	if not player.has_animation(animation_name):
		var animation_list := player.get_animation_list()
		if animation_list.is_empty():
			return
		animation_name = animation_list[0]

	var animation := player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR

	player.play(animation_name)


func _find_first_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var found := _find_first_animation_player(child)
		if found != null:
			return found

	return null


func _update_visual_rotation(delta: float) -> void:
	if _heading.length_squared() <= 0.001:
		return

	var target_yaw := atan2(_heading.x, _heading.z) + _visual_facing_offset
	rotation.y = rotate_toward(rotation.y, target_yaw, TURN_SMOOTHING * delta)


func _choose_random_heading() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	_heading = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _reset_turn_timer() -> void:
	_turn_timer = _rng.randf_range(TURN_INTERVAL_MIN, TURN_INTERVAL_MAX)


func _will_hit_obstacle() -> bool:
	return test_move(global_transform, _heading * COLLISION_LOOKAHEAD)


func _pick_clear_heading() -> void:
	for _attempt in range(TURN_RETRY_COUNT):
		_choose_random_heading()
		if not _will_hit_obstacle():
			_reset_turn_timer()
			return

	_reset_turn_timer()


func _turn_away_from(wall_normal: Vector3) -> void:
	var horizontal_normal := Vector3(wall_normal.x, 0.0, wall_normal.z)
	if horizontal_normal.length_squared() <= 0.001:
		_pick_clear_heading()
	else:
		var base_angle := atan2(horizontal_normal.x, horizontal_normal.z)
		var offset := _rng.randf_range(-0.9, 0.9)
		var angle := base_angle + offset
		_heading = Vector3(sin(angle), 0.0, cos(angle)).normalized()
		if _will_hit_obstacle():
			_pick_clear_heading()

	_reset_turn_timer()
