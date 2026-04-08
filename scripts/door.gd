extends Node3D

const CLOSED_ANGLE := 0.0

var _player: Node3D
var _interaction_distance := 2.8
var _closed_angle := CLOSED_ANGLE
var _open_angle := deg_to_rad(-68.0)
var _animation_duration := 0.2
var _is_open := false
var _is_animating := false


func configure(player: Node3D, interaction_distance: float, open_angle: float, animation_duration: float) -> void:
	_player = player
	_interaction_distance = interaction_distance
	_open_angle = open_angle
	_animation_duration = animation_duration
	rotation.y = _closed_angle


func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if global_position.distance_to(_player.global_position) <= _interaction_distance:
			_toggle()


func _toggle() -> void:
	if _is_animating:
		return

	_is_open = not _is_open
	_is_animating = true

	var tween := create_tween()
	tween.tween_property(self, "rotation:y", _open_angle if _is_open else _closed_angle, _animation_duration)
	tween.finished.connect(_finish_toggle)


func _finish_toggle() -> void:
	_is_animating = false
