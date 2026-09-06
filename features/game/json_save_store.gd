class_name JsonSaveStore
extends RefCounted

static func write(data: Dictionary, path: String) -> bool:
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	_delete_one(temp_path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("无法写入临时存档: %s" % temp_path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	if _read_dictionary(temp_path).is_empty() and not data.is_empty():
		_delete_one(temp_path)
		push_error("临时存档校验失败: %s" % temp_path)
		return false
	if FileAccess.file_exists(path):
		_delete_one(backup_path)
		var copy_error := DirAccess.copy_absolute(_absolute(path), _absolute(backup_path))
		if copy_error != OK:
			_delete_one(temp_path)
			push_error("无法备份存档: %s" % path)
			return false
		if not _delete_one(path):
			_delete_one(temp_path)
			return false
	var rename_error := DirAccess.rename_absolute(_absolute(temp_path), _absolute(path))
	if rename_error != OK:
		push_error("无法替换存档: %s" % path)
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(path):
			DirAccess.copy_absolute(_absolute(backup_path), _absolute(path))
		return false
	return true

static func read(path: String) -> Dictionary:
	var data := _read_dictionary(path)
	if not data.is_empty():
		return data
	return _read_dictionary(path + ".bak")

static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)

static func delete(path: String) -> bool:
	var ok := true
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			ok = _delete_one(candidate) and ok
	return ok

static func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func _delete_one(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var error := DirAccess.remove_absolute(_absolute(path))
	if error != OK:
		push_error("无法删除存档文件: %s" % path)
		return false
	return true

static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)
