class_name SaveManager
extends RefCounted

const DEFAULT_PATH := "user://save.json"

static func save(state: GameState, path: String = DEFAULT_PATH, now_unix: int = -1) -> void:
	var stamp := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	# 系统时钟回拨时保持时间戳单调，避免同一离线区间被再次领取。
	state.last_saved_unix = maxi(state.last_saved_unix, stamp)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写入存档: %s" % path)
		return
	f.store_string(JSON.stringify(state.to_dict()))
	f.close()

static func load_or_create(path: String = DEFAULT_PATH) -> GameState:
	if not FileAccess.file_exists(path):
		return GameState.new()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return GameState.new()
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return GameState.new()
	return GameState.from_dict(parsed)
