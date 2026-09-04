class_name RootActions
extends RefCounted

const EXPLORE_COST := 200.0

static func explore_cost(state: GameState) -> float:
    if state.lingua_nodes.has(&"deep_root"):
        return EXPLORE_COST * 0.5
    return EXPLORE_COST

static func can_explore(state: GameState) -> bool:
    if _next_relic(state).is_empty():
        return false
    return state.sap.is_greater_or_equal(BigNum.new(explore_cost(state)))

static func explore_block_reason(state: GameState) -> StringName:
    if not _next_relic(state).is_empty():
        return &"insufficient_sap" if not state.sap.is_greater_or_equal(BigNum.new(explore_cost(state))) else &""
    for relic in RelicLibrary.all_relics():
        if not state.relics_found.has(int(relic.get("id", 0))):
            return &"no_available_relic"
    return &"all_relics_found"

static func explore(state: GameState) -> Dictionary:
    var relic := _next_relic(state)
    if relic.is_empty():
        return {"ok": false, "reason": explore_block_reason(state)}
    if not state.sap.is_greater_or_equal(BigNum.new(explore_cost(state))):
        return {"ok": false, "reason": "insufficient_sap"}
    state.sap.sub(BigNum.new(explore_cost(state)))
    state.root_depth += 1
    _apply_reward(state, relic.get("reward", {}))
    state.relics_found.append(int(relic.get("id", 0)))
    for flag in relic.get("flags", []):
        var flag_id := StringName(str(flag))
        if not state.choice_flags.has(flag_id):
            state.choice_flags.append(flag_id)
    return {"ok": true, "relic": relic, "text": str(relic.get("dream_text", ""))}

static func _apply_reward(state: GameState, reward: Dictionary) -> void:
    if reward.has("memory"):
        state.memory.add(BigNum.new(float(reward["memory"])))
    if reward.has("insight"):
        state.insight += int(reward["insight"])
    if reward.has("truth"):
        state.truth += int(reward["truth"])

static func _unlock_met(state: GameState, unlock: Dictionary) -> bool:
    for key in unlock:
        match str(key):
            "relic_found":
                if not state.relics_found.has(int(unlock[key])):
                    return false
            "race_awakened":
                var race_id := StringName(str(unlock[key]))
                if not state.races.has(race_id) or not bool(state.races[race_id].get("awakened", false)):
                    return false
            "memory_gte":
                if not state.memory.is_greater_or_equal(BigNum.new(float(unlock[key]))):
                    return false
            "insight_gte":
                if state.insight < int(unlock[key]):
                    return false
            "truth_gte":
                if state.truth < int(unlock[key]):
                    return false
            _:
                return false
    return true

# 以 relics_found 为权威选择下一个未探索遗迹，不假定 id 与 root_depth 连续
static func _next_relic(state: GameState) -> Dictionary:
    for r in RelicLibrary.all_relics():
        if not state.relics_found.has(int(r.get("id", 0))) and _unlock_met(state, r.get("unlock", {})):
            return r
    return {}
