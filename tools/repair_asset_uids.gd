extends SceneTree

var owners: Dictionary = {}
var repaired := 0

func _initialize() -> void:
	scan("res://vendor")
	print("ASSET_UID_REPAIR: ", repaired, " duplicate identifiers replaced")
	quit()

func scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	for name in dir.get_directories():
		if name not in ["__MACOSX", ".godot", ".git"]:
			scan(path.path_join(name))
	for name in dir.get_files():
		if not name.ends_with(".uid"):
			continue
		var file_path := path.path_join(name)
		var uid := FileAccess.get_file_as_string(file_path).strip_edges()
		if owners.has(uid):
			# Preserve the first owner's UID; use Godot's allocator for a fresh, valid ID.
			var fresh := ResourceUID.id_to_text(ResourceUID.create_id())
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			file.store_string(fresh + "\n")
			owners[fresh] = file_path
			repaired += 1
		else:
			owners[uid] = file_path
