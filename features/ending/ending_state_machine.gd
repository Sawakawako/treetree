class_name EndingStateMachine
extends RefCounted

const INSIGHT_GOOD := 10
const GROWTH_AXIS := 1000.0
const HOPE_GOOD_GAIN := 1

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func _choices_before_axis_done(state: GameState) -> bool:
	for c in ChoiceLibrary.load_all():
		var cid := StringName(str(c.get("id", "")))
		if cid == &"world_axis":
			continue
		if not state.choices_done.has(cid):
			return false
	return true

static func _all_races_awakened(state: GameState) -> bool:
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		if not _race_awakened(state, rid):
			return false
	return true

static func axis_ready(state: GameState) -> bool:
	if not state.relics_found.has(9):
		return false
	if not _all_races_awakened(state):
		return false
	if not _choices_before_axis_done(state):
		return false
	if not state.storyteller_stories.has(&"story_6"):
		return false
	if not state.growth.is_greater_or_equal(BigNum.new(GROWTH_AXIS)):
		return false
	return true

static func _bonds_full(state: GameState) -> bool:
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		if RelationActions.get_relation(state, rid) < 3.0:
			return false
	return true

static func _can_true(state: GameState) -> bool:
	return state.run_number >= 3 and state.hope >= 2 \
		and state.insight >= INSIGHT_GOOD and _bonds_full(state)

static func outcome_of(state: GameState, intent: StringName) -> StringName:
	match intent:
		&"refuse":
			return &"bad"
		&"self":
			return &"true" if _can_true(state) else &""
		&"return":
			if state.insight >= INSIGHT_GOOD and _bonds_full(state):
				return &"good"
			return &"normal"
		&"condense":
			return &"good" if state.insight >= INSIGHT_GOOD and _bonds_full(state) else (&"normal" if state.insight >= INSIGHT_GOOD else &"bad")
		_:
			return &""

static func resolve_ending(state: GameState, intent: StringName) -> Dictionary:
	var outcome := outcome_of(state, intent)
	if outcome == &"":
		return {"ok": false}
	var hope_before := state.hope
	if outcome == &"good":
		state.hope += HOPE_GOOD_GAIN
	if outcome == &"true":
		state.hope = 0  # 用在自己身上，圆满了
	if not state.ending_seen.has(outcome):
		state.ending_seen.append(outcome)
	return {"ok": true, "outcome": outcome, "hope_before": hope_before, "hope_after": state.hope}
