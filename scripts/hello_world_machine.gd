extends Node3D

const INTERACTION_GROUP := "world_interactables"
const MAX_SLOTS := 10

var _player: Node3D
var _screen: Node
var _interaction_distance := 2.6
var _program_blocks: Array[Node3D] = []
var _slot_anchors: Array[Node3D] = []


func configure(player: Node3D, screen: Node, interaction_distance: float) -> void:
	_player = player
	_screen = screen
	_interaction_distance = interaction_distance


func _ready() -> void:
	add_to_group(INTERACTION_GROUP)
	for i in range(MAX_SLOTS):
		var slot_anchor := get_node_or_null("SlotAnchor%d" % i)
		if slot_anchor != null:
			_slot_anchors.append(slot_anchor)


func can_interact(player: Node3D) -> bool:
	return player != null and global_position.distance_to(player.global_position) <= _interaction_distance


func try_interact(player: Node3D) -> bool:
	if not can_interact(player):
		return false

	var held_block: Node3D = null
	if player != null and player.has_method("peek_held_code_block"):
		held_block = player.peek_held_code_block()

	if held_block != null:
		return _insert_block(player, held_block)

	return _run_program()


func _insert_block(player: Node3D, held_block: Node3D) -> bool:
	if _program_blocks.size() >= MAX_SLOTS:
		_show_failure("PROGRAM ERROR")
		return false

	var block_from_player: Node3D = held_block
	if player != null and player.has_method("consume_held_code_block"):
		block_from_player = player.consume_held_code_block()

	_program_blocks.append(block_from_player)
	if _screen != null and _screen.has_method("clear_program_message"):
		_screen.clear_program_message()
	if block_from_player != null and block_from_player.has_method("attach_to_slot"):
		block_from_player.attach_to_slot(_slot_anchors[_program_blocks.size() - 1])
	return true


func _run_program() -> bool:
	if _program_blocks.is_empty():
		_show_failure("PROGRAM ERROR")
		return false

	var output := _evaluate_program()
	if output != "":
		if _screen != null and _screen.has_method("show_program_message"):
			_screen.show_program_message(output, true)
	else:
		_show_failure("PROGRAM ERROR")

	_reset_program_blocks()
	return true


func _evaluate_program() -> String:
	if _program_blocks.size() != 2:
		return ""

	var first_block: Node3D = _program_blocks[0]
	var second_block: Node3D = _program_blocks[1]
	if first_block == null or second_block == null:
		return ""
	if not first_block.has_method("get_block_kind") or not second_block.has_method("get_block_kind"):
		return ""
	if first_block.get_block_kind() != "PRINT":
		return ""
	if second_block.get_block_kind() != "TEXT":
		return ""
	if not second_block.has_method("get_block_text"):
		return ""

	return second_block.get_block_text()


func _show_failure(message: String) -> void:
	if _screen != null and _screen.has_method("show_program_message"):
		_screen.show_program_message(message, false)


func _reset_program_blocks() -> void:
	for block in _program_blocks:
		if block != null and block.has_method("return_to_spawn"):
			block.return_to_spawn()

	_program_blocks.clear()
