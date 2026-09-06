class_name RealmActions
extends RefCounted

static func world_level(state: GameState) -> int:
	var count := state.realm_echoes.size()
	if count >= 9:
		return 3
	if count >= 6:
		return 2
	if count >= 3:
		return 1
	return 0

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func can_explore(state: GameState, realm_id: StringName) -> bool:
	var realm := RealmCatalog.get_realm(realm_id)
	if realm == null or state.realm_echoes.has(realm_id):
		return false
	for prerequisite: StringName in realm.prerequisites:
		if not state.realm_echoes.has(prerequisite):
			return false
	for race_id: StringName in realm.required_races:
		if not _race_awakened(state, race_id):
			return false
	if realm.required_lingua_node != &"" and not state.lingua_nodes.has(realm.required_lingua_node):
		return false
	if realm.required_relic > 0 and not state.relics_found.has(realm.required_relic):
		return false
	if state.root_depth < realm.min_root_depth:
		return false
	if not state.growth.is_greater_or_equal(BigNum.new(realm.min_growth)):
		return false
	if not state.sap.is_greater_or_equal(BigNum.new(realm.sap_cost)):
		return false
	if not state.memory.is_greater_or_equal(BigNum.new(realm.memory_cost)):
		return false
	return state.faith.is_greater_or_equal(BigNum.new(realm.faith_cost))

static func explore(state: GameState, realm_id: StringName) -> Dictionary:
	if not can_explore(state, realm_id):
		return {"ok": false}
	var realm := RealmCatalog.get_realm(realm_id)
	var level_before := world_level(state)
	state.sap.sub(BigNum.new(realm.sap_cost))
	state.memory.sub(BigNum.new(realm.memory_cost))
	state.faith.sub(BigNum.new(realm.faith_cost))
	state.realm_echoes.append(realm.id)
	return {
		"ok": true,
		"realm_id": realm.id,
		"text": realm.discovery_text,
		"world_level_before": level_before,
		"world_level": world_level(state),
	}
