class_name ChoiceActions
extends RefCounted

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func _trigger_met(state: GameState, trigger: Dictionary) -> bool:
	if trigger.is_empty():
		return true
	if trigger.has("races_awakened"):
		var list: Array = trigger["races_awakened"]
		for rid in list:
			if not _race_awakened(state, StringName(str(rid))):
				return false
	if trigger.has("memory_gte"):
		if not state.memory.is_greater_or_equal(BigNum.new(float(trigger["memory_gte"]))):
			return false
	if trigger.has("faith_gte"):
		if not state.faith.is_greater_or_equal(BigNum.new(float(trigger["faith_gte"]))):
			return false
	if trigger.has("growth_gte"):
		if not state.growth.is_greater_or_equal(BigNum.new(float(trigger["growth_gte"]))):
			return false
	if trigger.has("insight_gte"):
		if state.insight < int(trigger["insight_gte"]):
			return false
	if trigger.has("relation_gte"):
		for rid2 in trigger["relation_gte"]:
			var need := int(trigger["relation_gte"][rid2])
			if RelationActions.get_relation(state, StringName(str(rid2))) < need:
				return false
	if trigger.has("plundered_gte"):
		for rid3 in trigger["plundered_gte"]:
			var need2 := int(trigger["plundered_gte"][rid3])
			if PlunderActions.count(state, StringName(str(rid3))) < need2:
				return false
	if trigger.has("soul_revived") and bool(trigger["soul_revived"]):
		if state.soul_river >= SoulActions.RIVER_TOTAL:
			return false  # 河底满 = 从未复活（复活必 -1）
	if trigger.has("soul_river_lte"):
		if state.soul_river > int(trigger["soul_river_lte"]):
			return false
	return true

static func available(state: GameState) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in ChoiceLibrary.load_all():
		var id := StringName(str(c.get("id", "")))
		if state.choices_done.has(id):
			continue
		if _trigger_met(state, c.get("trigger", {})):
			out.append(id)
	return out

static func first_available(state: GameState) -> StringName:
	var list := available(state)
	if list.is_empty():
		return &""
	return list[0]

static func can_choose(state: GameState, choice_id: StringName) -> bool:
	if state.choices_done.has(choice_id):
		return false
	var c := ChoiceLibrary.get_choice(choice_id)
	if c.is_empty():
		return false
	return _trigger_met(state, c.get("trigger", {}))

static func option_unlocked(state: GameState, choice_id: StringName, option_id: StringName) -> bool:
	var c := ChoiceLibrary.get_choice(choice_id)
	if c.is_empty():
		return false
	for opt: Variant in c.get("options", []):
		if typeof(opt) != TYPE_DICTIONARY:
			continue
		if StringName(str(opt.get("id", ""))) != option_id:
			continue
		var unlock: Variant = opt.get("unlock", {})
		if typeof(unlock) != TYPE_DICTIONARY:
			return true
		return _trigger_met(state, unlock)
	return false