extends SceneTree

const OUTPUT_PATH := "build/android/SimRoom.pck"
const ROOT_ENTRIES := [
	"project.godot",
	"icon.svg",
	"scenes",
	"scripts"
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/android")

	var packer := PCKPacker.new()
	var err := packer.pck_start(OUTPUT_PATH)
	if err != OK:
		push_error("pck_start failed: %s" % err)
		quit(1)
		return

	for relative_path in _collect_paths():
		err = packer.add_file("res://%s" % relative_path, "res://%s" % relative_path)
		if err != OK:
			push_error("add_file failed for %s: %s" % [relative_path, err])
			quit(1)
			return

	err = packer.flush()
	if err != OK:
		push_error("flush failed: %s" % err)
		quit(1)
		return

	print("Built ", OUTPUT_PATH)
	quit()


func _collect_paths() -> PackedStringArray:
	var results := PackedStringArray()

	for entry in ROOT_ENTRIES:
		if DirAccess.dir_exists_absolute("res://%s" % entry):
			_collect_dir(entry, results)
		elif FileAccess.file_exists("res://%s" % entry):
			results.append(entry)

	return results


func _collect_dir(relative_dir: String, results: PackedStringArray) -> void:
	var dir := DirAccess.open("res://%s" % relative_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue

		var child_relative := "%s/%s" % [relative_dir, name]
		if dir.current_is_dir():
			_collect_dir(child_relative, results)
		else:
			results.append(child_relative)

		name = dir.get_next()
	dir.list_dir_end()
