class_name LinguaActions
extends RefCounted

static func has_node(state: GameState, node_id: StringName) -> bool:
	return state.lingua_nodes.has(node_id)

static func life_cost(state: GameState) -> int:
	return LinguaData.life_cost(state.lingua_life_level)

static func can_upgrade_life(state: GameState) -> bool:
	var cost := LinguaData.life_cost(state.lingua_life_level)
	if cost < 0:
		return false  # 满级
	return state.faith.is_greater_or_equal(BigNum.new(float(cost)))

static func upgrade_life(state: GameState) -> Dictionary:
	if not can_upgrade_life(state):
		return {"ok": false}
	var cost := LinguaData.life_cost(state.lingua_life_level)
	if cost > 0:
		state.faith.sub(BigNum.new(float(cost)))
	state.lingua_life_level += 1
	return {"ok": true, "level": state.lingua_life_level}

static func memory_cost(state: GameState) -> int:
	return LinguaData.memory_cost(state.lingua_memory_level)

static func can_upgrade_memory(state: GameState) -> bool:
	var cost := memory_cost(state)
	if cost < 0:
		return false
	if state.insight < 5:
		return false
	return state.memory.is_greater_or_equal(BigNum.new(float(cost)))

static func upgrade_memory(state: GameState) -> Dictionary:
	if not can_upgrade_memory(state):
		return {"ok": false}
	var cost := memory_cost(state)
	state.memory.sub(BigNum.new(float(cost)))
	state.lingua_memory_level += 1
	return {"ok": true, "level": state.lingua_memory_level}

static func can_unlock_node(state: GameState, node_id: StringName) -> bool:
	if state.lingua_nodes.has(node_id):
		return false
	var node := LinguaData.get_node(node_id)
	if node.is_empty():
		return false
	var language := StringName(node.get("language", &"life"))
	var language_level := state.lingua_life_level
	if language == &"memory":
		language_level = state.lingua_memory_level
	elif language == &"world":
		language_level = RealmActions.world_level(state)
	if language_level < int(node.get("requirement", 99)):
		return false
	var prerequisites: Array = node.get("prerequisites", [])
	for prerequisite: Variant in prerequisites:
		if not state.lingua_nodes.has(StringName(str(prerequisite))):
			return false
	return state.sap.is_greater_or_equal(BigNum.new(float(node.get("sap_cost", 0))))

static func unlock_node(state: GameState, node_id: StringName) -> Dictionary:
	if not can_unlock_node(state, node_id):
		return {"ok": false}
	var node := LinguaData.get_node(node_id)
	state.sap.sub(BigNum.new(float(node.get("sap_cost", 0))))
	state.lingua_nodes.append(node_id)
	return {"ok": true, "node_id": node_id}
