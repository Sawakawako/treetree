class_name SoulActions
extends RefCounted

const RIVER_TOTAL := 100
const REVIVE_COST_SOUL := 1
const REVIVE_COST_GROWTH := 500.0
const REVIVE_POP_GAIN := 10
const PLUNDER_SOUL_POP_LOSS := 3
const PLUNDER_SOUL_RELATION_LOSS := 1.0

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func river(state: GameState) -> int:
	return state.soul_river

static func can_revive(state: GameState, race_id: StringName) -> bool:
	if not _race_awakened(state, race_id):
		return false
	if state.soul_river < REVIVE_COST_SOUL:
		return false
	return state.growth.is_greater_or_equal(BigNum.new(REVIVE_COST_GROWTH))

static func revive(state: GameState, race_id: StringName) -> Dictionary:
	if not can_revive(state, race_id):
		return {"ok": false}
	state.soul_river -= REVIVE_COST_SOUL
	state.growth.sub(BigNum.new(REVIVE_COST_GROWTH))
	var pop := float(state.races[race_id]["population"]) + float(REVIVE_POP_GAIN)
	state.races[race_id]["population"] = pop
	return {"ok": true, "race_id": race_id, "pop": pop}

static func can_plunder_soul(state: GameState, race_id: StringName) -> bool:
	if not _race_awakened(state, race_id):
		return false
	if PlunderActions.reveal_stage(state, race_id) < 1:
		return false
	var pop := float(state.races[race_id].get("population", 0.0))
	if pop < float(PLUNDER_SOUL_POP_LOSS):
		return false
	return state.soul_river < RIVER_TOTAL

static func plunder_soul(state: GameState, race_id: StringName) -> Dictionary:
	if not can_plunder_soul(state, race_id):
		return {"ok": false}
	state.soul_river = mini(state.soul_river + 1, RIVER_TOTAL)
	var pop := float(state.races[race_id]["population"]) - float(PLUNDER_SOUL_POP_LOSS)
	state.races[race_id]["population"] = pop
	var rel := RelationActions.apply_change(state, race_id, -PLUNDER_SOUL_RELATION_LOSS)
	return {"ok": true, "race_id": race_id, "pop": pop, "relation": rel}
