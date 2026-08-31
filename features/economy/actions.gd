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
