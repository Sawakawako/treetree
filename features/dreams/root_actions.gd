class_name RootActions
extends RefCounted

const EXPLORE_COST := 200.0

static func explore_cost(state: GameState) -> float:
    if state.lingua_nodes.has(&"deep_root"):
        return EXPLORE_COST * 0.5
    return EXPLORE_COST

static func can_explore(state: GameState) -> bool:
    if state.relics_found.size() >= RelicLibrary.relic_count():
        return false
    return state.sap.is_greater_or_equal(BigNum.new(explore_cost(state)))

static func explore(state: GameState) -> Dictionary:
    if not can_explore(state):
        return {"ok": false}
    var relic := _next_relic(state)
    if relic.is_empty():
        return {"ok": false}
    state.sap.sub(BigNum.new(explore_cost(state)))
    state.root_depth += 1
    state.memory.add(BigNum.new(float(relic.get("reward_memory", 1.0))))
    state.relics_found.append(int(relic.get("id", 0)))
    return {"ok": true, "relic": relic, "text": str(relic.get("dream_text", ""))}

# 以 relics_found 为权威选择下一个未探索遗迹，不假定 id 与 root_depth 连续
static func _next_relic(state: GameState) -> Dictionary:
    for r in RelicLibrary.all_relics():
        if not state.relics_found.has(int(r.get("id", 0))):
            return r
    return {}
