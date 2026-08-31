class_name DriftActions
extends RefCounted

const DRIFT_MAX := 10.0
const PLUNDER_DRIFT := 0.5
const MEMORY_DRIFT_RATE := 0.02
const AVATAR_MEMORY := 30.0

static func drift_value(state: GameState) -> float:
	var total_plundered := 0
	for race_id in state.plundered:
		total_plundered += int(state.plundered[race_id])
	var memory_drift := 0.0
	if state.memory.to_value() > AVATAR_MEMORY:
		memory_drift = (state.memory.to_value() - AVATAR_MEMORY) * MEMORY_DRIFT_RATE
	return clampf(float(total_plundered) * PLUNDER_DRIFT + memory_drift, 0.0, DRIFT_MAX)

static func drift_tier(state: GameState) -> int:
	var v := drift_value(state)
	if v >= 9.0:
		return 3
	if v >= 6.0:
		return 2
	if v >= 3.0:
		return 1
	return 0

static func is_avatar_awakened(state: GameState) -> bool:
	return state.memory.is_greater_or_equal(BigNum.new(AVATAR_MEMORY))

static func avatar_tier_text(state: GameState) -> String:
	return AvatarTiers.tier_text(drift_tier(state))

static func can_intimate(state: GameState, race_id: StringName) -> bool:
	if not is_avatar_awakened(state):
		return false
	if not RelationActions.is_intimate(state, race_id):
		return false
	return not state.intimate_events.has(race_id)

static func intimate(state: GameState, race_id: StringName) -> Dictionary:
	if not can_intimate(state, race_id):
		return {"ok": false}
	var ev := IntimateEvents.get_event(race_id)
	state.intimate_events.append(race_id)
	return {"ok": true, "text": str(ev.get("text", ""))}