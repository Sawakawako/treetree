class_name MetaSaveManager
extends RefCounted

const DEFAULT_PATH := "user://meta.json"

static func save(state: MemoryArchiveState, path: String = DEFAULT_PATH) -> bool:
	return JsonSaveStore.write(state.to_dict(), path)

static func load_or_create(path: String = DEFAULT_PATH) -> MemoryArchiveState:
	var data := JsonSaveStore.read(path)
	return MemoryArchiveState.from_dict(data) if not data.is_empty() else MemoryArchiveState.new()

static func exists(path: String = DEFAULT_PATH) -> bool:
	return JsonSaveStore.exists(path)

static func delete(path: String = DEFAULT_PATH) -> bool:
	return JsonSaveStore.delete(path)

