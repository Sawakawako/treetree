class_name GameLoop
extends RefCounted

static func tick(state: GameState) -> void:
    state.tick += 1
    var eff := 1.0 + 0.25 * float(state.leaf_level)
    var collected := BigNum.new(float(state.branch_level) * eff)
    state.daylight.add(collected)
    var converted := state.daylight.mul_scalar(0.1)
    state.sap.add(converted)
    var grown := state.sap.mul_scalar(0.01)
    state.growth.add(grown)

static func should_auto_save(state: GameState) -> bool:
    return state.tick > 0 and state.tick % 60 == 0
