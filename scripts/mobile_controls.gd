extends CanvasLayer

const MOVE_PAD_SIZE := 220.0
const MOVE_KNOB_SIZE := 84.0
const MOVE_RADIUS := 72.0
const LOOK_PAD_SIZE := 220.0
const LOOK_KNOB_SIZE := 84.0
const LOOK_RADIUS := 72.0
const ACTION_BUTTON_WIDTH := 136.0
const ACTION_BUTTON_HEIGHT := 58.0

var move_vector := Vector2.ZERO

var _look_vector := Vector2.ZERO
var _jump_requested := false
var _interact_requested := false
var _move_touch_id := -1
var _look_touch_id := -1
var _move_center := Vector2.ZERO
var _look_center := Vector2.ZERO

var _root: Control
var _move_zone: Control
var _move_knob: Control
var _look_zone: Control
var _look_knob: Control
var _jump_zone: Control
var _interact_zone: Control


func _ready() -> void:
	visible = _should_show_mobile_controls()
	if not visible:
		return

	layer = 10
	_build_ui()
	_update_move_knob(Vector2.ZERO)
	_update_look_knob(Vector2.ZERO)


func _should_show_mobile_controls() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS" or OS.has_feature("mobile")


func consume_look_delta() -> Vector2:
	return _look_vector


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
	move_base.color = Color(0.82, 0.9, 1.0, 0.24)
	move_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_zone.add_child(move_base)

	_move_knob = ColorRect.new()
	_move_knob.name = "MoveKnob"
	_move_knob.color = Color(0.9, 0.97, 1.0, 0.5)
	_move_knob.custom_minimum_size = Vector2(MOVE_KNOB_SIZE, MOVE_KNOB_SIZE)
	_move_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_zone.add_child(_move_knob)

	_look_zone = Control.new()
	_look_zone.name = "LookZone"
	_look_zone.anchor_left = 1.0
	_look_zone.anchor_top = 1.0
	_look_zone.anchor_right = 1.0
	_look_zone.anchor_bottom = 1.0
	_look_zone.offset_left = -(LOOK_PAD_SIZE + ACTION_BUTTON_WIDTH + 48.0)
	_look_zone.offset_top = -252.0
	_look_zone.offset_right = -(ACTION_BUTTON_WIDTH + 48.0)
	_look_zone.offset_bottom = -32.0
	_look_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_look_zone)

	var look_base := ColorRect.new()
	look_base.name = "LookBase"
	look_base.color = Color(0.82, 0.9, 1.0, 0.18)
	look_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	look_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look_zone.add_child(look_base)

	_look_knob = ColorRect.new()
	_look_knob.name = "LookKnob"
	_look_knob.color = Color(0.9, 0.97, 1.0, 0.42)
	_look_knob.custom_minimum_size = Vector2(LOOK_KNOB_SIZE, LOOK_KNOB_SIZE)
	_look_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look_zone.add_child(_look_knob)

	_interact_zone = _make_action_zone("InteractZone", "USE", 164.0)
	_root.add_child(_interact_zone)

	_jump_zone = _make_action_zone("JumpZone", "JUMP", 90.0)
	_root.add_child(_jump_zone)


func _make_action_zone(node_name: String, label_text: String, bottom_offset: float) -> Control:
	var zone := Control.new()
	zone.name = node_name
	zone.anchor_left = 1.0
	zone.anchor_top = 1.0
	zone.anchor_right = 1.0
	zone.anchor_bottom = 1.0
	zone.offset_left = -(ACTION_BUTTON_WIDTH + 28.0)
	zone.offset_top = -bottom_offset
	zone.offset_right = -28.0
	zone.offset_bottom = -(bottom_offset - ACTION_BUTTON_HEIGHT)
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.86, 0.94, 1.0, 0.28)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(background)

	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(label)

	return zone


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _jump_zone.get_global_rect().has_point(event.position):
			_queue_jump()
			return

		if _interact_zone.get_global_rect().has_point(event.position):
			_queue_interact()
			return

		if _move_touch_id == -1 and _move_zone.get_global_rect().has_point(event.position):
			_move_touch_id = event.index
			_move_center = _move_zone.get_global_rect().get_center()
			_update_move_from_position(event.position)
			return

		if _look_touch_id == -1 and _look_zone.get_global_rect().has_point(event.position):
			_look_touch_id = event.index
			_look_center = _look_zone.get_global_rect().get_center()
			_update_look_from_position(event.position)
			return

	if not event.pressed:
		if event.index == _move_touch_id:
			_move_touch_id = -1
			move_vector = Vector2.ZERO
			_update_move_knob(Vector2.ZERO)
		elif event.index == _look_touch_id:
			_look_touch_id = -1
			_look_vector = Vector2.ZERO
			_update_look_knob(Vector2.ZERO)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_touch_id:
		_update_move_from_position(event.position)
	elif event.index == _look_touch_id:
		_update_look_from_position(event.position)


func _update_move_from_position(position: Vector2) -> void:
	var offset := position - _move_center
	if offset.length() > MOVE_RADIUS:
		offset = offset.normalized() * MOVE_RADIUS

	move_vector = Vector2(offset.x / MOVE_RADIUS, offset.y / MOVE_RADIUS)
	if move_vector.length() > 1.0:
		move_vector = move_vector.normalized()

	_update_move_knob(offset)


func _update_move_knob(offset: Vector2) -> void:
	_move_knob.position = Vector2(
		MOVE_PAD_SIZE * 0.5 - MOVE_KNOB_SIZE * 0.5,
		MOVE_PAD_SIZE * 0.5 - MOVE_KNOB_SIZE * 0.5
	) + offset


func _update_look_from_position(position: Vector2) -> void:
	var offset := position - _look_center
	if offset.length() > LOOK_RADIUS:
		offset = offset.normalized() * LOOK_RADIUS

	_look_vector = Vector2(offset.x / LOOK_RADIUS, offset.y / LOOK_RADIUS)
	if _look_vector.length() > 1.0:
		_look_vector = _look_vector.normalized()

	_update_look_knob(offset)


func _update_look_knob(offset: Vector2) -> void:
	_look_knob.position = Vector2(
		LOOK_PAD_SIZE * 0.5 - LOOK_KNOB_SIZE * 0.5,
		LOOK_PAD_SIZE * 0.5 - LOOK_KNOB_SIZE * 0.5
	) + offset


func _queue_jump() -> void:
	_jump_requested = true


func _queue_interact() -> void:
	_interact_requested = true
