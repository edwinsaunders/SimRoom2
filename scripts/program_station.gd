extends Node3D

@onready var machine: Node3D = $HelloWorldMachine
@onready var print_block: Node3D = $PrintBlock
@onready var text_block: Node3D = $TextBlock


func configure(player: Node3D, screen: Node, interaction_distance: float) -> void:
	machine.configure(player, screen, interaction_distance)
	print_block.configure(player, "PRINT", "PRINT", false, Color(0.26, 0.75, 1.0, 1.0), interaction_distance)
	text_block.configure(player, "TEXT", "HELLO WORLD", true, Color(1.0, 0.74, 0.24, 1.0), interaction_distance)
