class_name TotemActions
extends RefCounted

static func _wildfolk_awakened(state: GameState) -> bool:
	return state.races.has(&"wildfolk") and bool(state.races[&"wildfolk"].get("awakened", false))

static func visible_stage(state: GameState) -> int:
	if not _wildfolk_awakened(state):
		return 0
	var stage := 0
	for t in TotemLibrary.all_totems():
		if state.memory.is_greater_or_equal(BigNum.new(float(t.get("threshold", 0.0)))):
			stage = maxi(stage, int(t.get("id", 0)))
	return stage

static func can_interpret(state: GameState, totem_id: int) -> bool:
	if totem_id <= 0 or totem_id > visible_stage(state):
		return false
	return not state.totem_interpreted.has(totem_id)

static func next_interpretable(state: GameState) -> int:
	for id in range(visible_stage(state), 0, -1):
		if not state.totem_interpreted.has(id):
			return id
	return 0

static func interpret(state: GameState, totem_id: int) -> Dictionary:
	if not can_interpret(state, totem_id):
		return {"ok": false}
	var totem := TotemLibrary.get_totem(totem_id)
	state.insight += 1
	state.totem_interpreted.append(totem_id)
	return {"ok": true, "insight": state.insight, "text": str(totem.get("interpret_text", ""))}
