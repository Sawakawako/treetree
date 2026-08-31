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
