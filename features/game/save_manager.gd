class_name SaveManager
extends RefCounted

const DEFAULT_PATH := "user://save.json"
const CURRENT_VERSION := 1

static func save(state: GameState, path: String = DEFAULT_PATH, now_unix: int = -1) -> bool:
	var stamp := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	# 系统时钟回拨时保持时间戳单调，避免同一离线区间被再次领取。
	state.last_saved_unix = maxi(state.last_saved_unix, stamp)
	var data := state.to_dict()
	data["version"] = CURRENT_VERSION
	return JsonSaveStore.write(data, path)

static func load_or_create(path: String = DEFAULT_PATH) -> GameState:
	var data := JsonSaveStore.read(path)
	return GameState.from_dict(data) if not data.is_empty() else GameState.new()

static func exists(path: String = DEFAULT_PATH) -> bool:
	return JsonSaveStore.exists(path)

static func delete(path: String = DEFAULT_PATH) -> bool:
	return JsonSaveStore.delete(path)
