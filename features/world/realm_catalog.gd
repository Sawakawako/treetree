class_name RealmCatalog
extends RefCounted

const PATHS: Array[String] = [
	"res://features/world/data/realms/midgard.tres",
	"res://features/world/data/realms/nidavellir.tres",
	"res://features/world/data/realms/alfheim.tres",
	"res://features/world/data/realms/muspelheim.tres",
	"res://features/world/data/realms/jotunheim.tres",
	"res://features/world/data/realms/niflheim.tres",
	"res://features/world/data/realms/vanaheim.tres",
	"res://features/world/data/realms/helheim.tres",
	"res://features/world/data/realms/asgard.tres",
]

static var _cache: Array[RealmDefinition] = []

static func all_realms() -> Array[RealmDefinition]:
	if _cache.is_empty():
		for path: String in PATHS:
			var definition := load(path) as RealmDefinition
			if definition == null:
				push_error("无法加载九界数据: %s" % path)
				continue
			_cache.append(definition)
	return _cache

static func get_realm(id: StringName) -> RealmDefinition:
	for realm: RealmDefinition in all_realms():
		if realm.id == id:
			return realm
	return null

static func is_known(id: StringName) -> bool:
	return get_realm(id) != null
