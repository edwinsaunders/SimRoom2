extends CanvasLayer

const MOVE_PAD_SIZE := 220.0
const MOVE_KNOB_SIZE := 84.0
const MOVE_RADIUS := 72.0
const LOOK_ZONE_COLOR := Color(1, 1, 1, 0.035)

var move_vector := Vector2.ZERO

var _look_delta := Vector2.ZERO
var _jump_requested := false
var _interact_requested := false
var _move_touch_id := -1
var _look_touch_id := -1
var _move_center := Vector2.ZERO

var _root: Control
var _move_zone: Control
var _move_knob: Control
var _look_zone: Control


func _ready() -> void:
	visible = OS.has_feature("android") or OS.has_feature("ios")
	if not visible:
		return

	layer = 10
	_build_ui()
	_update_move_knob(Vector2.ZERO)


func consume_look_delta() -> Vector2:
	var delta := _look_delta
	_look_delta = Vector2.ZERO
	return delta


func consume_jump_requested() -> bool:
	var requested := _jump_requested
	_jump_requested = false
	return requested


func consume_interact_requested() -> bool:
	var requested := _interact_requested
	_interact_requested = false
	return requested


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_move_zone = Control.new()
	_move_zone.name = "MoveZone"
	_move_zone.anchor_left = 0.0
	_move_zone.anchor_top = 1.0
	_move_zone.anchor_right = 0.0
	_move_zone.anchor_bottom = 1.0
	_move_zone.offset_left = 28.0
	_move_zone.offset_top = -252.0
	_move_zone.offset_right = 28.0 + MOVE_PAD_SIZE
	_move_zone.offset_bottom = -32.0
	_move_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_move_zone)

	var move_base := ColorRect.new()
	move_base.name = "MoveBase"
	move_base.color = Color(0.82, 0.9, 1.0, 0.14)
	move_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_zone.add_child(move_base)

	_move_knob = ColorRect.new()
	_move_knob.name = "MoveKnob"
	_move_knob.color = Color(0.9, 0.97, 1.0, 0.34)
	_move_knob.custom_minimum_size = Vector2(MOVE_KNOB_SIZE, MOVE_KNOB_SIZE)
	_move_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_zone.add_child(_move_knob)

	_look_zone = ColorRect.new()
	_look_zone.name = "LookZone"
	_look_zone.anchor_left = 0.5
	_look_zone.anchor_top = 0.0
	_look_zone.anchor_right = 1.0
	_look_zone.anchor_bottom = 1.0
	_look_zone.offset_left = 0.0
	_look_zone.offset_top = 0.0
	_look_zone.offset_right = 0.0
	_look_zone.offset_bottom = 0.0
	_look_zone.color = LOOK_ZONE_COLOR
	_look_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_look_zone)

	var interact_button := _make_action_button("Use", 164.0)
	interact_button.pressed.connect(_queue_interact)
	_root.add_child(interact_button)

	var jump_button := _make_action_button("Jump", 76.0)
	jump_button.pressed.connect(_queue_jump)
	_root.add_child(jump_button)


func _make_action_button(label: String, bottom_offset: float) -> Button:
	var button := Button.new()
	button.text = label
	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = -164.0
	button.offset_top = -bottom_offset
	button.offset_right = -28.0
	button.offset_bottom = -(bottom_offset - 56.0)
	button.modulate = Color(1, 1, 1, 0.62)
	return button


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _move_touch_id == -1 and _move_zone.get_global_rect().has_point(event.position):
			_move_touch_id = event.index
			_move_center = _move_zone.get_global_rect().get_center()
			_update_move_from_position(event.position)
			return

		if _look_touch_id == -1 and _look_zone.get_global_rect().has_point(event.position):
			_look_touch_id = event.index
			return

	if not event.pressed:
		if event.index == _move_touch_id:
			_move_touch_id = -1
			move_vector = Vector2.ZERO
			_update_move_knob(Vector2.ZERO)
		elif event.index == _look_touch_id:
			_look_touch_id = -1


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_touch_id:
		_update_move_from_position(event.position)
	elif event.index == _look_touch_id:
		_look_delta += event.relative


func _update_move_from_position(position: Vector2) -> void:
	var offset := position - _move_center
	if offset.length() > MOVE_RADIUS:
		offset = offset.normalized() * MOVE_RADIUS

	move_vector = Vector2(offset.x / MOVE_RADIUS, -offset.y / MOVE_RADIUS)
	if move_vector.length() > 1.0:
		move_vector = move_vector.normalized()

	_update_move_knob(offset)


func _update_move_knob(offset: Vector2) -> void:
	_move_knob.position = Vector2(
		MOVE_PAD_SIZE * 0.5 - MOVE_KNOB_SIZE * 0.5,
		MOVE_PAD_SIZE * 0.5 - MOVE_KNOB_SIZE * 0.5
	) + offset


func _queue_jump() -> void:
	_jump_requested = true


func _queue_interact() -> void:
	_interact_requested = true
