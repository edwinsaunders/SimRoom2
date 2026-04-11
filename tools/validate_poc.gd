extends SceneTree


func _initialize() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Failed to load main scene")
		quit(1)
		return

	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var annex := world.get_node_or_null("PrototypeAnnex")
	if annex == null:
		push_error("PrototypeAnnex missing")
		quit(1)
		return

	var station := annex.get_node_or_null("PocStation")
	var screen := annex.get_node_or_null("PocScreen")
	if station == null or screen == null:
		push_error("POC station or screen missing")
		quit(1)
		return

	station.handle_button_press("MOVE_RIGHT")
	station.handle_button_press("SET_COLOR")
	station.handle_button_press("WAIT")
	if screen._program.size() != 3:
		push_error("Program queue did not update")
		quit(1)
		return

	station.handle_button_press("RUN")
	screen._process(0.6)
	screen._process(0.6)
	if screen._target_position <= 0.5:
		push_error("MOVE_RIGHT did not affect screen state")
		quit(1)
		return
	if screen._color_index != 1:
		push_error("SET_COLOR did not affect screen state")
		quit(1)
		return

	station.handle_button_press("RESET")
	if not screen._program.is_empty():
		push_error("RESET did not clear program")
		quit(1)
		return

	print("POC validation passed")
	quit()
