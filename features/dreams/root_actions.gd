class_name RootActions
extends RefCounted

const EXPLORE_COST := 200.0

static func can_explore(state: GameState) -> bool:
    if state.root_depth >= RelicLibrary.relic_count():
        return false
    return state.sap.is_greater_or_equal(BigNum.new(EXPLORE_COST))

static func explore(state: GameState) -> Dictionary:
    if not can_explore(state):
        return {"ok": false}
    var relic := RelicLibrary.get_relic(state.root_depth + 1)
    state.sap.sub(BigNum.new(EXPLORE_COST))
    state.root_depth += 1
    state.memory.add(BigNum.new(float(relic.get("reward_memory", 1.0))))
    state.relics_found.append(int(relic.get("id", 0)))
    return {"ok": true, "relic": relic, "text": str(relic.get("dream_text", ""))}
