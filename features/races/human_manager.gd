class_name HumanManager
extends RefCounted

const HUMAN_AWAKEN_MEMORY := 2.0
const FAITH_PER_10_TICKS := 1.0
const MEMORY_PER_20_TICKS := 1.0

static func check_awaken(state: GameState) -> bool:
    if state.human_awakened:
        return false
    if not state.memory.is_greater_or_equal(BigNum.new(HUMAN_AWAKEN_MEMORY)):
        return false
    state.human_awakened = true
    return true

static func tick_human(state: GameState) -> void:
    if not state.human_awakened or state.tick <= 0:
        return
    if state.tick % 10 == 0:
        state.faith.add(BigNum.new(FAITH_PER_10_TICKS))
    if state.tick % 20 == 0:
        state.memory.add(BigNum.new(MEMORY_PER_20_TICKS))
