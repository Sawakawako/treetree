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
		if data == null:
			push_error("无法加载种族数据: %s" % id)
			continue
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

static func capacity(state: GameState) -> float:
	var boom := 0
	if state.growth.to_value() >= 300.0:
		boom = 2
	elif state.growth.to_value() >= 100.0:
		boom = 1
	return 100.0 * (1.0 + float(boom))

static func tick_races(state: GameState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	# 1) 唤醒判定
	for race in all_races():
		if check_awaken(state, race):
			events.append({
				"race_id": race.id, "race_name": race.display_name,
				"awaken_text": race.awaken_text,
			})
	# 2) 供养
	var support := 0.0
	for race in all_races():
		if _is_awakened(state, race.id):
			support += float(state.races[race.id]["population"]) * race.support_cost
	state.sap.sub(BigNum.new(support))
	if state.sap.to_value() < 0.0:
		state.sap = BigNum.new(0.0)
	# 3) 人口增长（供养后 sap > 0 才增长）
	if state.sap.to_value() > 0.0:
		var cap := capacity(state)
		for race in all_races():
			if not _is_awakened(state, race.id):
				continue
			if PlunderActions.is_frozen(state, race.id):
				continue  # 夺梦揭示后人口冻结
			var pop := float(state.races[race.id]["population"])
			var growth := pop * race.growth_rate * (1.0 - pop / cap)
			state.races[race.id]["population"] = minf(pop + growth, cap)
	# 4) 产出
	for race in all_races():
		if not _is_awakened(state, race.id):
			continue
		var pop := float(state.races[race.id]["population"])
		state.faith.add(BigNum.new(pop * race.devotion * FAITH_EFF))
		if race.produce_memory:
			state.memory.add(BigNum.new(pop * MEMORY_EFF * (1.0 + 0.1 * float(state.root_eff_level))))
		if race.craft_sap > 0.0:
			state.sap.add(BigNum.new(pop * race.craft_sap))
	# 花盘：独立信仰产出（与人口无关）
	if state.sunflower_level > 0:
		state.faith.add(BigNum.new(0.5 * float(state.sunflower_level)))
	return events
