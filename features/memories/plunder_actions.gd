class_name PlunderActions
extends RefCounted

const REVEAL_THRESHOLDS := [3, 6, 9]
const REVEAL_RELATION_LOSS := 0.5

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func count(state: GameState, race_id: StringName) -> int:
	return int(state.plundered.get(race_id, 0))

static func reveal_stage(state: GameState, race_id: StringName) -> int:
	var n := count(state, race_id)
	if n >= REVEAL_THRESHOLDS[2]:
		return 3
	if n >= REVEAL_THRESHOLDS[1]:
		return 2
	if n >= REVEAL_THRESHOLDS[0]:
		return 1
	return 0

static func is_frozen(state: GameState, race_id: StringName) -> bool:
	if race_id == &"stoneborn" or state.miracle_cleansed_races.has(race_id):
		return false
	return reveal_stage(state, race_id) >= 1

static func can_plunder(state: GameState, race_id: StringName) -> bool:
	return _race_awakened(state, race_id)

static func plunder(state: GameState, race_id: StringName) -> Dictionary:
	if not can_plunder(state, race_id):
		return {"ok": false}
	# 驱影只保护到下一次成功夺梦；先撤保护，再完成本次夺梦。
	state.miracle_cleansed_races.erase(race_id)
	var data := PlunderData.get_data(race_id)
	var yield_mem := float(data.get("yield", 0.0))
	var before := reveal_stage(state, race_id)
	# 石裔无梦：不涨 counter、无产出
	if yield_mem > 0.0:
		var boosted := yield_mem * (1.0 + 0.1 * float(state.root_eff_level))
		yield_mem = boosted
		state.memory.add(BigNum.new(boosted))
		state.plundered[race_id] = count(state, race_id) + 1
	var after := reveal_stage(state, race_id)
	var revealed := after > before
	if revealed:
		if not state.plunder_reveals.has(race_id):
			state.plunder_reveals.append(race_id)
		RelationActions.apply_change(state, race_id, -REVEAL_RELATION_LOSS)
		if race_id == &"wildfolk" and after == 1:
			# 惊扰：1 级揭示时人口 -20%（一次性，由 plunder_reveals 保证不重复）
			var pop := float(state.races[race_id].get("population", 0.0))
			state.races[race_id]["population"] = roundi(pop * 0.8)
		var reveals: Array = data.get("reveals", [])
		var idx := mini(after - 1, reveals.size() - 1)
		return {"ok": true, "memory": yield_mem, "text": str(reveals[maxi(idx, 0)]), "revealed": true}
	var text := PlunderData.signal_text(race_id, count(state, race_id))
	return {"ok": true, "memory": yield_mem, "text": text, "revealed": false}
