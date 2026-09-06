class_name MemoryArchiveState
extends RefCounted

const CURRENT_VERSION := 1
const ENDING_IDS: Array[StringName] = [&"bad", &"normal", &"good", &"true"]

var relics: Array[int] = []
var totems: Array[int] = []
var stories: Array[StringName] = []
var choices: Array[StringName] = []
var choice_outcomes: Dictionary = {}
var realms: Array[StringName] = []
var miracles: Array[StringName] = []
var endings: Array[StringName] = []
var library_complete := false
var max_run_reached := 1

func capture_run(state: GameState) -> void:
	max_run_reached = maxi(max_run_reached, state.run_number)
	for id: int in state.relics_found:
		_append_unique_int(relics, id)
	for id: int in state.totem_interpreted:
		_append_unique_int(totems, id)
	for id: StringName in state.storyteller_stories:
		_append_unique_name(stories, id)
	for id: StringName in state.choices_done:
		_append_unique_name(choices, id)
	for id: StringName in state.realm_echoes:
		_append_unique_name(realms, id)
	for raw_id: Variant in state.miracle_counts:
		var id := StringName(str(raw_id))
		if int(state.miracle_counts[raw_id]) > 0:
			_append_unique_name(miracles, id)
	for id: StringName in state.ending_seen:
		_append_unique_name(endings, id)
	if endings.has(&"true"):
		library_complete = true

func record_choice(choice_id: StringName, option_id: StringName) -> void:
	var choice := ChoiceLibrary.get_choice(choice_id)
	if choice.is_empty() or not _choice_has_option(choice, option_id):
		return
	_append_unique_name(choices, choice_id)
	var selected: Array[StringName] = []
	if choice_outcomes.has(choice_id):
		selected.assign(choice_outcomes[choice_id])
	_append_unique_name(selected, option_id)
	choice_outcomes[choice_id] = selected

func mark_complete() -> void:
	library_complete = true

func to_dict() -> Dictionary:
	var serialized_outcomes := {}
	for choice_id: Variant in choice_outcomes:
		var option_names: Array[String] = []
		for option_id: StringName in choice_outcomes[choice_id]:
			option_names.append(str(option_id))
		serialized_outcomes[str(choice_id)] = option_names
	return {
		"version": CURRENT_VERSION,
		"library_complete": library_complete,
		"max_run_reached": max_run_reached,
		"relics": relics,
		"totems": totems,
		"stories": _names_to_strings(stories),
		"choices": _names_to_strings(choices),
		"choice_outcomes": serialized_outcomes,
		"realms": _names_to_strings(realms),
		"miracles": _names_to_strings(miracles),
		"endings": _names_to_strings(endings),
	}

static func from_dict(data: Dictionary) -> MemoryArchiveState:
	var archive := MemoryArchiveState.new()
	archive.library_complete = bool(data.get("library_complete", false))
	var max_run: Variant = data.get("max_run_reached", 1)
	archive.max_run_reached = maxi(int(max_run), 1) if typeof(max_run) == TYPE_INT or typeof(max_run) == TYPE_FLOAT else 1
	archive.relics.assign(_valid_int_ids(data.get("relics", []), &"relic"))
	archive.totems.assign(_valid_int_ids(data.get("totems", []), &"totem"))
	archive.stories.assign(_valid_name_ids(data.get("stories", []), &"story"))
	archive.choices.assign(_valid_name_ids(data.get("choices", []), &"choice"))
	archive.realms.assign(_valid_name_ids(data.get("realms", []), &"realm"))
	archive.miracles.assign(_valid_name_ids(data.get("miracles", []), &"miracle"))
	archive.endings.assign(_valid_name_ids(data.get("endings", []), &"ending"))
	var raw_outcomes: Variant = data.get("choice_outcomes", {})
	if typeof(raw_outcomes) == TYPE_DICTIONARY:
		for raw_choice_id: Variant in raw_outcomes:
			var choice_id := StringName(str(raw_choice_id))
			if not archive.choices.has(choice_id):
				continue
			var choice := ChoiceLibrary.get_choice(choice_id)
			var raw_options: Variant = raw_outcomes[raw_choice_id]
			if typeof(raw_options) != TYPE_ARRAY:
				continue
			var cleaned: Array[StringName] = []
			for raw_option_id: Variant in raw_options:
				if typeof(raw_option_id) != TYPE_STRING and typeof(raw_option_id) != TYPE_STRING_NAME:
					continue
				var option_id := StringName(str(raw_option_id))
				if _choice_has_option(choice, option_id) and not cleaned.has(option_id):
					cleaned.append(option_id)
			if not cleaned.is_empty():
				archive.choice_outcomes[choice_id] = cleaned
	return archive

static func _valid_int_ids(raw: Variant, kind: StringName) -> Array[int]:
	var result: Array[int] = []
	if typeof(raw) != TYPE_ARRAY:
		return result
	for value: Variant in raw:
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			continue
		var id := int(value)
		var known := not RelicLibrary.get_relic(id).is_empty() if kind == &"relic" else not TotemLibrary.get_totem(id).is_empty()
		if known and not result.has(id):
			result.append(id)
	return result

static func _valid_name_ids(raw: Variant, kind: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if typeof(raw) != TYPE_ARRAY:
		return result
	for value: Variant in raw:
		if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
			continue
		var id := StringName(str(value))
		var known := false
		match kind:
			&"story": known = not StoryLibrary.get_story(id).is_empty()
			&"choice": known = not ChoiceLibrary.get_choice(id).is_empty()
			&"realm": known = RealmCatalog.is_known(id)
			&"miracle": known = MiracleCatalog.is_known(id)
			&"ending": known = ENDING_IDS.has(id)
		if known and not result.has(id):
			result.append(id)
	return result

static func _choice_has_option(choice: Dictionary, option_id: StringName) -> bool:
	for option: Variant in choice.get("options", []):
		if typeof(option) == TYPE_DICTIONARY and StringName(str(option.get("id", ""))) == option_id:
			return true
	return false

static func _append_unique_int(values: Array[int], value: int) -> void:
	if not values.has(value):
		values.append(value)

static func _append_unique_name(values: Array[StringName], value: StringName) -> void:
	if value != &"" and not values.has(value):
		values.append(value)

static func _names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(str(value))
	return result

