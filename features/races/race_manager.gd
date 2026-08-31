class_name RaceManager
extends RefCounted

const FAITH_EFF := 0.002
const MEMORY_EFF := 0.001

static var _registry: Dictionary = {}
static var _registry_loaded := false

static func _ensure_registry() -> void:
	if _registry_loaded:
		return
	_registry_loaded = true
	_registry.clear()
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		var data := load("res://features/races/data/%s.tres" % id) as RaceData
		if data != null:
			_registry[data.id] = data

static func get_race(id: StringName) -> RaceData:
	_ensure_registry()
	return _registry.get(id)

static func all_races() -> Array[RaceData]:
	_ensure_registry()
	return _registry.values()

static func _is_awakened(state: GameState, id: StringName) -> bool:
	return state.races.has(id) and bool(state.races[id].get("awakened", false))

static func check_awaken(state: GameState, race: RaceData) -> bool:
	if _is_awakened(state, race.id):
		return false
	var ok := false
	if race.awaken_condition == "memory>=2":
		ok = state.memory.is_greater_or_equal(BigNum.new(2.0))
	elif race.awaken_condition.begins_with("faith>="):
		var threshold := float(race.awaken_condition.get_slice(">=", 1))
		ok = state.faith.is_greater_or_equal(BigNum.new(threshold))
	if ok:
		state.races[race.id] = {"awakened": true, "population": race.awaken_pop}
	return ok
