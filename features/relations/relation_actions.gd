class_name RelationActions
extends RefCounted

const RELATION_MIN := -3
const RELATION_MAX := 3

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func get_relation(state: GameState, race_id: StringName) -> int:
	return int(state.relations.get(race_id, 0))

static func apply_change(state: GameState, race_id: StringName, delta: int) -> int:
	if delta == 0:
		return get_relation(state, race_id)
	var new_val := clampi(get_relation(state, race_id) + delta, RELATION_MIN, RELATION_MAX)
	state.relations[race_id] = new_val
	return new_val

static func is_intimate(state: GameState, race_id: StringName) -> bool:
	return get_relation(state, race_id) >= 2

static func _condition_met(state: GameState, race_id: StringName) -> bool:
	var ev := RelationEvents.get_event(race_id)
	if ev.is_empty():
		return false
	var cond := str(ev.get("condition", ""))
	if cond.begins_with("memory>="):
		return state.memory.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("faith>="):
		return state.faith.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("sap>="):
		return state.sap.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("totem>="):
		return TotemActions.visible_stage(state) >= int(float(cond.get_slice(">=", 1)))
	return false

static func can_interact(state: GameState, race_id: StringName) -> bool:
	if not _race_awakened(state, race_id):
		return false
	if state.relation_events.has(race_id):
		return false
	return _condition_met(state, race_id)

static func interact(state: GameState, race_id: StringName) -> Dictionary:
	if not can_interact(state, race_id):
		return {"ok": false}
	var ev := RelationEvents.get_event(race_id)
	apply_change(state, race_id, 1)
	state.relation_events.append(race_id)
	return {"ok": true, "text": str(ev.get("text", "")), "relation": get_relation(state, race_id)}
