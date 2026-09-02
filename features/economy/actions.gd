class_name GameActions
extends RefCounted

static func gather_daylight(state: GameState) -> void:
	var gain := BigNum.new(1.0 * (1.0 + 0.25 * float(state.leaf_level)))
	state.daylight.add(gain)

static func buy_leaf(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.leaf_cost(state.leaf_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.leaf_level += 1
	return true

static func buy_branch(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.branch_cost(state.branch_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.branch_level += 1
	return true

static func buy_chloroplast(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.chloroplast_cost(state.chloroplast_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.chloroplast_level += 1
	return true

static func buy_xylem(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.xylem_cost(state.xylem_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.xylem_level += 1
	return true

static func buy_sunflower(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.sunflower_cost(state.sunflower_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.sunflower_level += 1
	return true

static func buy_nautilus(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.nautilus_cost(state.nautilus_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.nautilus_level += 1
	return true

static func buy_root_eff(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.root_eff_cost(state.root_eff_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.root_eff_level += 1
	return true

const SEEDLING_MAX_LEVEL := 3

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func buy_seedling(state: GameState) -> bool:
	if state.seedling_level >= SEEDLING_MAX_LEVEL:
		return false
	var cost := BigNum.new(float(CostCalculator.seedling_cost(state.seedling_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.seedling_level += 1
	return true

static func buy_firepit(state: GameState) -> bool:
	if not _race_awakened(state, &"human"):
		return false
	var cost := BigNum.new(float(CostCalculator.firepit_cost(state.firepit_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.firepit_level += 1
	return true

static func buy_ring(state: GameState) -> bool:
	if not _race_awakened(state, &"forestfolk"):
		return false
	var cost := BigNum.new(float(CostCalculator.ring_cost(state.ring_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.ring_level += 1
	return true

static func buy_forge(state: GameState) -> bool:
	if not _race_awakened(state, &"stoneborn"):
		return false
	var cost := BigNum.new(float(CostCalculator.forge_cost(state.forge_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.forge_level += 1
	return true

static func buy_totem_pole(state: GameState) -> bool:
	if not _race_awakened(state, &"wildfolk"):
		return false
	var cost := BigNum.new(float(CostCalculator.totem_pole_cost(state.totem_pole_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.totem_pole_level += 1
	return true

static func buy_deep_dream(state: GameState) -> bool:
	if state.deep_dream:
		return false
	var cost := BigNum.new(3000.0)
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.memory.add(BigNum.new(15.0))
	state.deep_dream = true
	return true

static func buy_wind_veil(state: GameState) -> bool:
	if state.wind_veil:
		return false
	var cost := BigNum.new(2500.0)
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.faith.add(BigNum.new(30.0))
	state.wind_veil = true
	return true
