class_name MemoryArchive
extends RefCounted

const CATEGORIES: Array[Dictionary] = [
	{"id": &"relics", "title": "遗迹"},
	{"id": &"totems", "title": "图腾"},
	{"id": &"stories", "title": "说书人"},
	{"id": &"choices", "title": "明选"},
	{"id": &"realms", "title": "九界"},
	{"id": &"miracles", "title": "奇迹"},
	{"id": &"endings", "title": "结局"},
]

static func category_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for category: Dictionary in CATEGORIES:
		result.append(StringName(category["id"]))
	return result

static func category_title(category_id: StringName) -> String:
	for category: Dictionary in CATEGORIES:
		if StringName(category["id"]) == category_id:
			return str(category["title"])
	return ""

static func entries_for(archive: MemoryArchiveState, category_id: StringName) -> Array[Dictionary]:
	match category_id:
		&"relics": return _relic_entries(archive)
		&"totems": return _totem_entries(archive)
		&"stories": return _story_entries(archive)
		&"choices": return _choice_entries(archive)
		&"realms": return _realm_entries(archive)
		&"miracles": return _miracle_entries(archive)
		&"endings": return _ending_entries(archive)
	return []

static func summary(archive: MemoryArchiveState) -> Dictionary:
	var total := 0
	var unlocked := 0
	for category_id: StringName in category_ids():
		for entry: Dictionary in entries_for(archive, category_id):
			total += 1
			if bool(entry.get("unlocked", false)):
				unlocked += 1
	return {"unlocked": unlocked, "total": total, "complete": archive.library_complete}

static func _entry(id: Variant, title: String, body: String, unlocked: bool) -> Dictionary:
	if not unlocked:
		return {"id": id, "title": "尚未落进年轮", "body": "", "unlocked": false}
	return {"id": id, "title": title, "body": body, "unlocked": true}

static func _relic_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for relic: Dictionary in RelicLibrary.all_relics():
		var id := int(relic.get("id", 0))
		result.append(_entry(id, str(relic.get("name", "")), str(relic.get("dream_text", "")), archive.library_complete or archive.relics.has(id)))
	return result

static func _totem_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for totem: Dictionary in TotemLibrary.all_totems():
		var id := int(totem.get("id", 0))
		var body := "%s\n\n%s" % [totem.get("reveal_text", ""), totem.get("interpret_text", "")]
		result.append(_entry(id, "图腾 %d" % id, body, archive.library_complete or archive.totems.has(id)))
	return result

static func _story_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for story: Dictionary in StoryLibrary.all_stories():
		var id := StringName(str(story.get("id", "")))
		result.append(_entry(id, str(story.get("title", "")), str(story.get("text", "")), archive.library_complete or archive.stories.has(id)))
	return result

static func _choice_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice: Dictionary in ChoiceLibrary.load_all():
		var id := StringName(str(choice.get("id", "")))
		var body := str(choice.get("intro", ""))
		var selected: Array[StringName] = []
		if archive.choice_outcomes.has(id):
			selected.assign(archive.choice_outcomes[id])
		for option: Variant in choice.get("options", []):
			if typeof(option) != TYPE_DICTIONARY:
				continue
			var option_id := StringName(str(option.get("id", "")))
			var option_text := str(option.get("text", ""))
			body += "\n\n· %s" % option_text
			if selected.has(option_id):
				body += "\n年轮里的路 · %s\n%s" % [option_text, option.get("result_text", "")]
			elif archive.library_complete:
				body += "\n另一道回声\n%s" % option.get("result_text", "")
		result.append(_entry(id, str(choice.get("title", "")), body, archive.library_complete or archive.choices.has(id)))
	return result

static func _realm_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for realm: RealmDefinition in RealmCatalog.all_realms():
		result.append(_entry(realm.id, "%s · %s" % [realm.display_name, realm.subtitle], realm.discovery_text, archive.library_complete or archive.realms.has(realm.id)))
	return result

static func _miracle_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for miracle: MiracleDefinition in MiracleCatalog.all_miracles():
		var body := "%s\n\n再次施展\n%s" % [miracle.first_text, miracle.repeat_text]
		result.append(_entry(miracle.id, miracle.display_name, body, archive.library_complete or archive.miracles.has(miracle.id)))
	return result

static func _ending_entries(archive: MemoryArchiveState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ending_id: StringName in EndingArchive.IDS:
		var ending := EndingArchive.get_entry(ending_id)
		result.append(_entry(ending_id, str(ending.get("title", "")), str(ending.get("body", "")), archive.library_complete or archive.endings.has(ending_id)))
	return result

