class_name MiracleActions
extends RefCounted

const RAIN_TICKS := 120
const CALL_SOUL_POP_GAIN := 10.0

static func count(state: GameState, miracle_id: StringName) -> int:
	return maxi(int(state.miracle_counts.get(miracle_id, 0)), 0)

static func faith_cost(state: GameState, miracle_id: StringName) -> int:
	var definition := MiracleCatalog.get_miracle(miracle_id)
	if definition == null or definition.faith_costs.is_empty():
		return 0
	var cost_index := mini(count(state, miracle_id), definition.faith_costs.size() - 1)
	return definition.faith_costs[cost_index]

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func can_perform(state: GameState, miracle_id: StringName, target_race_id: StringName = &"") -> bool:
	var definition := MiracleCatalog.get_miracle(miracle_id)
	if definition == null:
		return false
	for realm_id: StringName in definition.required_realms:
		if not state.realm_echoes.has(realm_id):
			return false
	if definition.required_lingua_node != &"" and not state.lingua_nodes.has(definition.required_lingua_node):
		return false
	if state.lingua_life_level < definition.required_life_level:
		return false
	if definition.max_uses > 0 and count(state, miracle_id) >= definition.max_uses:
		return false
	if definition.target_mode == "none":
		if target_race_id != &"":
			return false
	elif definition.target_mode == "race":
		if not GameState.RACE_IDS.has(target_race_id) or not _race_awakened(state, target_race_id):
			return false
	else:
		return false
	if miracle_id == &"rain" and state.miracle_rain_ticks > 0:
		return false
	if miracle_id == &"banish_shadow":
		if target_race_id == &"stoneborn" or not PlunderActions.is_frozen(state, target_race_id):
			return false
	if miracle_id == &"call_soul" and state.soul_river < SoulActions.REVIVE_COST_SOUL:
		return false
	var cost := float(faith_cost(state, miracle_id))
	return state.faith.to_value() + 0.000001 >= cost

static func perform(state: GameState, miracle_id: StringName, target_race_id: StringName = &"") -> Dictionary:
	if not can_perform(state, miracle_id, target_race_id):
		return {"ok": false}
	var definition := MiracleCatalog.get_miracle(miracle_id)
	var previous_count := count(state, miracle_id)
	var cost := faith_cost(state, miracle_id)
	state.faith.sub(BigNum.new(float(cost)))
	if absf(state.faith.to_value()) < 0.000001:
		state.faith = BigNum.new(0.0)
	state.miracle_counts[miracle_id] = previous_count + 1
	match miracle_id:
		&"rain":
			state.miracle_rain_ticks = RAIN_TICKS
		&"banish_shadow":
			state.miracle_cleansed_races.append(target_race_id)
		&"call_soul":
			state.soul_river -= SoulActions.REVIVE_COST_SOUL
			var population := float(state.races[target_race_id].get("population", 0.0))
			state.races[target_race_id]["population"] = population + CALL_SOUL_POP_GAIN
	var result := {
		"ok": true,
		"miracle_id": miracle_id,
		"count": previous_count + 1,
		"faith_cost": cost,
		"text": definition.first_text if previous_count == 0 else definition.repeat_text,
	}
	if target_race_id != &"":
		result["target_race_id"] = target_race_id
	return result

static func rain_growth_multiplier(state: GameState) -> float:
	return 2.0 if state.miracle_rain_ticks > 0 else 1.0

static func advance_tick(state: GameState) -> void:
	if state.miracle_rain_ticks > 0:
		state.miracle_rain_ticks -= 1
