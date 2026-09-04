class_name OfflineProgress
extends RefCounted

const MAX_OFFLINE_SECONDS := 8 * 60 * 60

static func elapsed_seconds(saved_at: int, now: int, cap: int = MAX_OFFLINE_SECONDS) -> int:
	return mini(maxi(now - saved_at, 0), maxi(cap, 0))

static func effective_seconds(state: GameState, saved_at: int, now: int) -> int:
	var raw := maxi(now - saved_at, 0)
	var multiplier := 2 if LinguaActions.has_node(state, &"sky_light") else 1
	return mini(raw * multiplier, MAX_OFFLINE_SECONDS)

static func _empty_summary() -> Dictionary:
	return {
		"applied": false,
		"seconds": 0,
		"daylight": 0.0,
		"sap": 0.0,
		"growth": 0.0,
		"faith": 0.0,
		"memory": 0.0,
		"population": {},
	}

static func calculate(state: GameState, seconds: int) -> Dictionary:
	if seconds <= 0 or not LinguaActions.has_node(state, &"earth_sense"):
		return _empty_summary()
	var duration := mini(seconds, MAX_OFFLINE_SECONDS)
	var simulated := GameState.from_dict(state.to_dict())
	var before_population: Dictionary = {}
	for race_id in simulated.races:
		before_population[race_id] = float(simulated.races[race_id].get("population", 0.0))
	for _second in range(duration):
		GameLoop.tick(simulated)
		RaceManager.tick_races_offline(simulated)
	var population_delta: Dictionary = {}
	for race_id in simulated.races:
		var delta := float(simulated.races[race_id].get("population", 0.0)) - float(before_population.get(race_id, 0.0))
		if absf(delta) > 0.000001:
			population_delta[race_id] = delta
	return {
		"applied": true,
		"seconds": duration,
		"daylight": simulated.daylight.to_value() - state.daylight.to_value(),
		"sap": simulated.sap.to_value() - state.sap.to_value(),
		"growth": simulated.growth.to_value() - state.growth.to_value(),
		"faith": simulated.faith.to_value() - state.faith.to_value(),
		"memory": simulated.memory.to_value() - state.memory.to_value(),
		"population": population_delta,
		"_final_state": simulated.to_dict(),
	}

static func apply(state: GameState, seconds: int) -> Dictionary:
	var summary := calculate(state, seconds)
	if not summary.get("applied", false):
		return summary
	var final_state := GameState.from_dict(summary["_final_state"])
	state.tick = final_state.tick
	state.daylight = final_state.daylight
	state.sap = final_state.sap
	state.growth = final_state.growth
	state.faith = final_state.faith
	state.memory = final_state.memory
	state.races = final_state.races.duplicate(true)
	summary.erase("_final_state")
	return summary
