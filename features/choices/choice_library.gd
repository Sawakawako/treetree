class_name ChoiceLibrary
extends RefCounted

const DATA_PATH := "res://features/choices/data/choices.json"

static var _cache: Array[Dictionary] = []
static var _cache_loaded := false

static func _load_raw() -> Array[Dictionary]:
	if _cache_loaded:
		return _cache
	_cache_loaded = true
	_cache.clear()
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取明选数据: %s" % DATA_PATH)
		return _cache
	var text := f.get_as_text()
	f.close()
	_cache.assign(_parse_content(text))
	return _cache

static func _parse_content(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("明选 JSON 解析失败")
		return out
	var list: Variant = parsed.get("choices", [])
	if typeof(list) != TYPE_ARRAY:
		return out
	var seen: Dictionary = {}
	for item: Variant in list:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var id := StringName(str(item.get("id", "")))
		if id == &"" or seen.has(id):
			continue  # 空 id 或重复 id 跳过
		var opts: Variant = item.get("options", [])
		if typeof(opts) != TYPE_ARRAY or opts.is_empty():
			continue  # 无选项不可玩
		if str(item.get("title", "")).is_empty() or str(item.get("intro", "")).is_empty():
			continue
		seen[id] = true
		out.append(item)
	return out

static func load_all() -> Array[Dictionary]:
	return _load_raw()

static func get_choice(id: StringName) -> Dictionary:
	for c in _load_raw():
		if StringName(str(c.get("id", ""))) == id:
			return c.duplicate(true)
	return {}

static func choice_count() -> int:
	return _load_raw().size()

static func valid_choice_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for c in _load_raw():
		out.append(StringName(str(c.get("id", ""))))
	return out