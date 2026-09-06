class_name MiracleCatalog
extends RefCounted

const PATHS: Array[String] = [
	"res://features/world/data/miracles/oasis.tres",
	"res://features/world/data/miracles/rain.tres",
	"res://features/world/data/miracles/banish_shadow.tres",
	"res://features/world/data/miracles/call_soul.tres",
	"res://features/world/data/miracles/shape.tres",
]

static var _cache: Array[MiracleDefinition] = []

static func all_miracles() -> Array[MiracleDefinition]:
	if _cache.is_empty():
		for path: String in PATHS:
			var definition := load(path) as MiracleDefinition
			if definition == null:
				push_error("无法加载奇迹数据: %s" % path)
				continue
			_cache.append(definition)
	return _cache

static func get_miracle(id: StringName) -> MiracleDefinition:
	for miracle: MiracleDefinition in all_miracles():
		if miracle.id == id:
			return miracle
	return null

static func is_known(id: StringName) -> bool:
	return get_miracle(id) != null
