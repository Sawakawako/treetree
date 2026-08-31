extends Node

signal resources_changed
signal relic_discovered(relic_name: String, dream_text: String)

const SAVE_PATH := "user://save.json"
const TICK_INTERVAL := 1.0

var _state: GameState
var _tick_accumulator := 0.0

func _ready() -> void:
    _state = SaveManager.load_or_create(SAVE_PATH)
    HumanManager.check_awaken(_state)

func _process(delta: float) -> void:
    _tick_accumulator += delta
    if _tick_accumulator >= TICK_INTERVAL:
        _tick_accumulator -= TICK_INTERVAL
        GameLoop.tick(_state)
        HumanManager.tick_human(_state)
        if GameLoop.should_auto_save(_state):
            SaveManager.save(_state, SAVE_PATH)
        resources_changed.emit()

func get_state() -> GameState:
    return _state

func gather() -> void:
    GameActions.gather_daylight(_state)
    resources_changed.emit()

func buy_leaf() -> bool:
    var ok := GameActions.buy_leaf(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_branch() -> bool:
    var ok := GameActions.buy_branch(_state)
    if ok:
        resources_changed.emit()
    return ok

func get_leaf_cost() -> int:
    return CostCalculator.leaf_cost(_state.leaf_level)

func get_branch_cost() -> int:
    return CostCalculator.branch_cost(_state.branch_level)

func explore_relic() -> Dictionary:
    var result := RootActions.explore(_state)
    if result.get("ok", false):
        var relic: Dictionary = result.get("relic", {})
        relic_discovered.emit(str(relic.get("name", "")), str(relic.get("dream_text", "")))
        resources_changed.emit()
    return result

func get_memory() -> BigNum:
    return _state.memory

func get_faith() -> BigNum:
    return _state.faith

func get_root_depth() -> int:
    return _state.root_depth

func is_human_awakened() -> bool:
    return _state.human_awakened
