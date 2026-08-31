extends Node

signal resources_changed
signal relic_discovered(relic_name: String, dream_text: String)
signal race_awakened(race_id: StringName, race_name: String, awaken_text: String)
signal totem_interpreted(totem_id: int, interpret_text: String)
signal relation_changed(race_id: StringName, relation: int)
signal plunder_done(race_id: StringName, text: String, revealed: bool)
signal intimate_done(race_id: StringName, text: String)
signal soul_changed(soul_river: int)
signal soul_revived(race_id: StringName, pop_gain: int)
signal soul_plundered(race_id: StringName, pop_loss: int)

const SAVE_PATH := "user://save.json"
const TICK_INTERVAL := 1.0

var _state: GameState
var _tick_accumulator := 0.0

func _ready() -> void:
    _state = SaveManager.load_or_create(SAVE_PATH)

func _process(delta: float) -> void:
    _tick_accumulator += delta
    if _tick_accumulator >= TICK_INTERVAL:
        _tick_accumulator -= TICK_INTERVAL
        GameLoop.tick(_state)
        var events: Array[Dictionary] = RaceManager.tick_races(_state)
        for ev in events:
            race_awakened.emit(ev["race_id"], ev["race_name"], ev["awaken_text"])
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

func buy_chloroplast() -> bool:
    var ok := GameActions.buy_chloroplast(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_xylem() -> bool:
    var ok := GameActions.buy_xylem(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_sunflower() -> bool:
    var ok := GameActions.buy_sunflower(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_nautilus() -> bool:
    var ok := GameActions.buy_nautilus(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_root_eff() -> bool:
    var ok := GameActions.buy_root_eff(_state)
    if ok:
        resources_changed.emit()
    return ok

func get_chloroplast_cost() -> int:
    return CostCalculator.chloroplast_cost(_state.chloroplast_level)

func get_xylem_cost() -> int:
    return CostCalculator.xylem_cost(_state.xylem_level)

func get_sunflower_cost() -> int:
    return CostCalculator.sunflower_cost(_state.sunflower_level)

func get_nautilus_cost() -> int:
    return CostCalculator.nautilus_cost(_state.nautilus_level)

func get_root_eff_cost() -> int:
    return CostCalculator.root_eff_cost(_state.root_eff_level)

func get_sap_cap() -> float:
    return GameLoop.sap_cap(_state)

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
    return _state.races.has(&"human") and bool(_state.races[&"human"].get("awakened", false))

func get_race(id: StringName) -> RaceData:
    return RaceManager.get_race(id)

func interpret_totem(totem_id: int) -> Dictionary:
    var result := TotemActions.interpret(_state, totem_id)
    if result.get("ok", false):
        totem_interpreted.emit(totem_id, str(result.get("text", "")))
        resources_changed.emit()
    return result

func interact_relation(race_id: StringName) -> Dictionary:
    var result := RelationActions.interact(_state, race_id)
    if result.get("ok", false):
        relation_changed.emit(race_id, int(result.get("relation", 0)))
        resources_changed.emit()
    return result

func plunder_race(race_id: StringName) -> Dictionary:
    var result := PlunderActions.plunder(_state, race_id)
    if result.get("ok", false):
        plunder_done.emit(race_id, str(result.get("text", "")), bool(result.get("revealed", false)))
        resources_changed.emit()
    return result

func intimate_race(race_id: StringName) -> Dictionary:
    var result := DriftActions.intimate(_state, race_id)
    if result.get("ok", false):
        intimate_done.emit(race_id, str(result.get("text", "")))
        resources_changed.emit()
    return result

func revive_race(race_id: StringName) -> Dictionary:
    var result := SoulActions.revive(_state, race_id)
    if result.get("ok", false):
        soul_revived.emit(race_id, SoulActions.REVIVE_POP_GAIN)
        soul_changed.emit(int(_state.soul_river))
        resources_changed.emit()
    return result

func plunder_soul_race(race_id: StringName) -> Dictionary:
    var result := SoulActions.plunder_soul(_state, race_id)
    if result.get("ok", false):
        soul_plundered.emit(race_id, SoulActions.PLUNDER_SOUL_POP_LOSS)
        soul_changed.emit(int(_state.soul_river))
        resources_changed.emit()
    return result
