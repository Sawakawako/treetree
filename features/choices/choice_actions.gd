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
	if trigger.has("relic_found"):
		if not state.relics_found.has(int(trigger["relic_found"])):
			return false
	if trigger.has("relation_gte"):
		for rid2 in trigger["relation_gte"]:
			var need := float(trigger["relation_gte"][rid2])
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
	if trigger.has("soul_river_gte"):
		if state.soul_river < int(trigger["soul_river_gte"]):
			return false
	# M6：周目/结局侧触发键（world_axis d 选项 unlock 使用）
	if trigger.has("run_gte"):
		if state.run_number < int(trigger["run_gte"]):
			return false
	if trigger.has("relations_all_gte"):
		var need_all := float(trigger["relations_all_gte"])
		for rid_all: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
			if RelationActions.get_relation(state, rid_all) < need_all:
				return false
	if trigger.has("hope_gte"):
		if state.hope < int(trigger["hope_gte"]):
			return false
	return true

static func available(state: GameState) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in ChoiceLibrary.load_all():
		var id := StringName(str(c.get("id", "")))
		if state.choices_done.has(id):
			continue
		if id == &"world_axis":
			continue  # 终局由 EndingStateMachine.axis_ready 主动门控，不进 tick 轮询
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

static func _apply_effects(state: GameState, effects: Dictionary) -> void:
	if effects.has("memory"):
		state.memory.add(BigNum.new(float(effects["memory"])))
	if effects.has("faith"):
		state.faith.add(BigNum.new(float(effects["faith"])))
	if effects.has("growth_pct"):
		var p := float(effects["growth_pct"])
		state.growth.add(BigNum.new(state.growth.to_value() * p))
	if effects.has("faith_pct"):
		var p2 := float(effects["faith_pct"])
		state.faith.add(BigNum.new(state.faith.to_value() * p2))
	if effects.has("relation"):
		for rid in effects["relation"]:
			RelationActions.apply_change(state, StringName(str(rid)), float(effects["relation"][rid]))
	if effects.has("insight"):
		state.insight += int(effects["insight"])
	if effects.has("truth"):
		state.truth += int(effects["truth"])
	if effects.has("drift"):
		state.drift_extra += float(effects["drift"])
	if effects.has("memory_eff"):
		for rid2 in effects["memory_eff"]:
			state.race_memory_eff[rid2] = float(effects["memory_eff"][rid2])
	if effects.has("soul"):
		var soul_op: Dictionary = effects["soul"]
		if soul_op.has("soul_cost"):
			state.soul_river = maxi(state.soul_river - int(soul_op["soul_cost"]), 0)
		if soul_op.has("revive_pop"):
			for rid3 in soul_op["revive_pop"]:
				if not state.races.has(rid3):
					continue
				state.races[rid3]["population"] = float(state.races[rid3].get("population", 0.0)) + float(soul_op["revive_pop"][rid3])
		if soul_op.has("relation"):
			for rid4 in soul_op["relation"]:
				RelationActions.apply_change(state, StringName(str(rid4)), float(soul_op["relation"][rid4]))
	if effects.has("flags"):
		for f in effects["flags"]:
			var fn := StringName(str(f))
			if not state.choice_flags.has(fn):
				state.choice_flags.append(fn)
	# M6：终局意图只落 flag（world_axis_intent_<intent>），GameManager.resolve_choice 消费
	if effects.has("ending_intent"):
		state.choice_flags.append(StringName("world_axis_intent_" + str(effects["ending_intent"])))

static func resolve(state: GameState, choice_id: StringName, option_id: StringName) -> Dictionary:
	if not can_choose(state, choice_id):
		return {"ok": false}
	var c := ChoiceLibrary.get_choice(choice_id)
	for opt: Variant in c.get("options", []):
		if typeof(opt) != TYPE_DICTIONARY:
			continue
		if StringName(str(opt.get("id", ""))) != option_id:
			continue
		if not option_unlocked(state, choice_id, option_id):
			return {"ok": false}
		_apply_effects(state, opt.get("effects", {}))
		state.choices_done.append(choice_id)
		return {"ok": true, "id": choice_id, "option": option_id,
			"result_text": str(opt.get("result_text", "")), "effects": opt.get("effects", {})}
	return {"ok": false}
