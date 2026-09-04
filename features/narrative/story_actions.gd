class_name StoryActions
extends RefCounted

static func _conditions_met(state: GameState, conditions: Dictionary) -> bool:
	for key in conditions:
		match str(key):
			"flags_all":
				for flag in conditions[key]:
					if not state.choice_flags.has(StringName(str(flag))):
						return false
			"story_done":
				if not state.storyteller_stories.has(StringName(str(conditions[key]))):
					return false
			"relation_gte":
				for race_id in conditions[key]:
					if RelationActions.get_relation(state, StringName(str(race_id))) < float(conditions[key][race_id]):
						return false
			"insight_gte":
				if state.insight < int(conditions[key]):
					return false
			"truth_gte":
				if state.truth < int(conditions[key]):
					return false
			_:
				return false
	return true

static func can_hear(state: GameState, story_id: StringName) -> bool:
	if state.storyteller_stories.has(story_id):
		return false
	var story := StoryLibrary.get_story(story_id)
	if story.is_empty():
		return false
	return _conditions_met(state, story.get("conditions", {}))

static func _available_for_kind(state: GameState, kind: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for story in StoryLibrary.all_stories():
		var id := StringName(story.get("id", &""))
		if StringName(story.get("kind", &"")) == kind and can_hear(state, id):
			out.append(id)
	return out

static func available_main_stories(state: GameState) -> Array[StringName]:
	return _available_for_kind(state, &"main")

static func available_easter_eggs(state: GameState) -> Array[StringName]:
	return _available_for_kind(state, &"easter_egg")

static func next_main_story(state: GameState) -> StringName:
	var available := available_main_stories(state)
	return &"" if available.is_empty() else available[0]

static func _apply_effects(state: GameState, effects: Dictionary) -> void:
	if effects.has("relation"):
		for race_id in effects["relation"]:
			RelationActions.apply_change(state, StringName(str(race_id)), float(effects["relation"][race_id]))
	if effects.has("insight"):
		state.insight += int(effects["insight"])
	if effects.has("flags"):
		for flag in effects["flags"]:
			var flag_id := StringName(str(flag))
			if not state.choice_flags.has(flag_id):
				state.choice_flags.append(flag_id)

static func hear(state: GameState, story_id: StringName) -> Dictionary:
	if not can_hear(state, story_id):
		return {"ok": false}
	var story := StoryLibrary.get_story(story_id)
	_apply_effects(state, story.get("effects", {}))
	state.storyteller_stories.append(story_id)
	return {
		"ok": true,
		"id": story_id,
		"title": str(story.get("title", "")),
		"text": str(story.get("text", "")),
		"effects": story.get("effects", {}).duplicate(true),
	}
