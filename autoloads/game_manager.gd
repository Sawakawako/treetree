extends Node

signal resources_changed
signal relic_discovered(relic_name: String, dream_text: String)
signal race_awakened(race_id: StringName, race_name: String, awaken_text: String)
signal totem_interpreted(totem_id: int, interpret_text: String)
signal relation_changed(race_id: StringName, relation: float)
signal plunder_done(race_id: StringName, text: String, revealed: bool)
signal intimate_done(race_id: StringName, text: String)
signal choice_available(choice_id: StringName, title: String, intro: String, options: Array)
signal choice_resolved(choice_id: StringName, option_id: StringName, result_text: String, option_text: String)
signal soul_changed(soul_river: int)
signal soul_revived(race_id: StringName, pop_gain: int)
signal soul_plundered(race_id: StringName, pop_loss: int)
signal story_heard(story_id: StringName, title: String, story_text: String)
# M6 终局：结局已结算（outcome + 结算后希望）；周目已重启（下一周目号）
signal ending_resolved(outcome: StringName, hope_after: int)
signal run_restarted(run_number: int)

const SAVE_PATH := "user://save.json"
const TICK_INTERVAL := 1.0

var _state: GameState
var _tick_accumulator := 0.0
var _pending_choice: StringName = &""
var _pending_offline_summary: Dictionary = {}

func _ready() -> void:
    _state = SaveManager.load_or_create(SAVE_PATH)
    var now_unix := int(Time.get_unix_time_from_system())
    _pending_offline_summary = settle_offline(now_unix)
    SaveManager.save(_state, SAVE_PATH, now_unix)

func settle_offline(now_unix: int) -> Dictionary:
    var saved_at := _state.last_saved_unix
    _state.last_saved_unix = maxi(saved_at, maxi(now_unix, 0))
    if saved_at <= 0:
        return {"applied": false, "seconds": 0}
    var seconds := OfflineProgress.effective_seconds(_state, saved_at, now_unix)
    return OfflineProgress.apply(_state, seconds)

func take_offline_summary() -> Dictionary:
    var summary := _pending_offline_summary.duplicate(true)
    _pending_offline_summary.clear()
    return summary

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
        _check_choice_trigger()
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

func buy_seedling() -> bool:
    var ok := GameActions.buy_seedling(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_firepit() -> bool:
    var ok := GameActions.buy_firepit(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_ring() -> bool:
    var ok := GameActions.buy_ring(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_forge() -> bool:
    var ok := GameActions.buy_forge(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_totem_pole() -> bool:
    var ok := GameActions.buy_totem_pole(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_deep_dream() -> bool:
    var ok := GameActions.buy_deep_dream(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_wind_veil() -> bool:
    var ok := GameActions.buy_wind_veil(_state)
    if ok:
        resources_changed.emit()
    return ok

func get_seedling_cost() -> int:
    return CostCalculator.seedling_cost(_state.seedling_level)

func get_firepit_cost() -> int:
    return CostCalculator.firepit_cost(_state.firepit_level)

func get_ring_cost() -> int:
    return CostCalculator.ring_cost(_state.ring_level)

func get_forge_cost() -> int:
    return CostCalculator.forge_cost(_state.forge_level)

func get_totem_pole_cost() -> int:
    return CostCalculator.totem_pole_cost(_state.totem_pole_level)

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

func can_interact_relation(race_id: StringName) -> bool:
    if RelationActions.can_interact(_state, race_id):
        return true
    for event: Dictionary in RelationEvents.extra_events():
        if StringName(str(event.get("race_id", &""))) != race_id:
            continue
        var event_id := StringName(str(event.get("event_id", &"")))
        if RelationActions.can_interact_event(_state, event_id):
            return true
    return false

func interact_relation(race_id: StringName) -> Dictionary:
    var result := RelationActions.interact(_state, race_id)
    if not result.get("ok", false):
        for event: Dictionary in RelationEvents.extra_events():
            if StringName(str(event.get("race_id", &""))) != race_id:
                continue
            var event_id := StringName(str(event.get("event_id", &"")))
            if not RelationActions.can_interact_event(_state, event_id):
                continue
            result = RelationActions.interact_event(_state, event_id)
            break
    if result.get("ok", false):
        relation_changed.emit(race_id, float(result.get("relation", 0.0)))
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

func _check_choice_trigger() -> void:
    if _pending_choice != &"":
        return
    var cid := ChoiceActions.first_available(_state)
    if cid == &"":
        return
    _pending_choice = cid
    var c := ChoiceLibrary.get_choice(cid)
    choice_available.emit(cid, str(c.get("title", "")), str(c.get("intro", "")), c.get("options", []))

func try_start_world_axis() -> bool:
    # P4 守门：世界之轴一旦结算（choices_done 含 world_axis）即不可再次入场。
    # 否则会返回 true 并把 _pending_choice 卡死在 world_axis——resolve 因 can_choose 失败必败 → 软锁。
    if _state.choices_done.has(&"world_axis"):
        return false
    if _pending_choice != &"":
        return false
    if not EndingStateMachine.axis_ready(_state):
        return false
    _pending_choice = &"world_axis"
    var c := ChoiceLibrary.get_choice(&"world_axis")
    if c.is_empty():
        _pending_choice = &""
        return false
    choice_available.emit(&"world_axis", str(c.get("title", "")), str(c.get("intro", "")), c.get("options", []))
    return true

func resolve_choice(choice_id: StringName, option_id: StringName) -> Dictionary:
    if _pending_choice != choice_id:
        return {"ok": false}
    var result := ChoiceActions.resolve(_state, choice_id, option_id)
    if not result.get("ok", false):
        return result
    _pending_choice = &""
    # M6：world_axis 结算 → 终局状态机（不回调 choice_resolved，以 ending_resolved 终结）
    if choice_id == &"world_axis":
        return _settle_world_axis(option_id, result)
    # 第 4 参 = 所选选项的按钮文字（从 JSON options 按 option_id 取 text）
    var c := ChoiceLibrary.get_choice(choice_id)
    var opt_text := ""
    for opt: Variant in c.get("options", []):
        if typeof(opt) == TYPE_DICTIONARY and StringName(str(opt.get("id", ""))) == option_id:
            opt_text = str(opt.get("text", ""))
            break
    choice_resolved.emit(choice_id, option_id, str(result.get("result_text", "")), opt_text)
    resources_changed.emit()
    return result

func _settle_world_axis(option_id: StringName, result: Dictionary) -> Dictionary:
    var intent := &"condense"
    match option_id:
        &"a": intent = &"condense"
        &"b": intent = &"refuse"
        &"c": intent = &"return"
        &"d": intent = &"self"
    var er := EndingStateMachine.resolve_ending(_state, intent)
    if not er.get("ok", false):
        return {"ok": false, "reason": "ending_blocked"}
    var outcome := StringName(str(er.get("outcome", &"")))
    _state.pending_ending = {
        "outcome": outcome,
        "intent": intent,
        "hope_before": int(er.get("hope_before", _state.hope)),
        "phase": &"return" if intent == &"return" else &"settlement",
        "return_step": 1 if intent == &"return" else 0,
        "return_halted": false,
    }
    SaveManager.save(_state, SAVE_PATH)
    ending_resolved.emit(outcome, int(er.get("hope_after", 0)))
    return er

func get_pending_ending() -> Dictionary:
    return _state.pending_ending.duplicate(true)

func advance_return_sequence() -> Dictionary:
    if _state.pending_ending.is_empty():
        return {"ok": false}
    var pending: Dictionary = _state.pending_ending
    if StringName(str(pending.get("intent", &""))) != &"return" \
            or StringName(str(pending.get("phase", &""))) != &"return":
        return {"ok": false}
    var outcome := StringName(str(pending.get("outcome", &"")))
    var max_step := ReturnSequence.max_step_for(outcome)
    var step := clampi(int(pending.get("return_step", 1)), 1, max_step)
    var halted := bool(pending.get("return_halted", false))
    if step < max_step:
        pending["return_step"] = step + 1
    elif outcome != &"good" and not halted:
        pending["return_halted"] = true
    else:
        pending["phase"] = &"settlement"
    _state.pending_ending = pending
    SaveManager.save(_state, SAVE_PATH)
    var result := pending.duplicate(true)
    result["ok"] = true
    return result

# M6 周目切换：余烬保留重置（GameState.new_run_preserved），清待决明选，落盘，广播 run_restarted
func restart_run() -> Dictionary:
    _state = GameState.new_run_preserved(_state)
    _pending_choice = &""
    # M6 三周目浓缩快进（spec §8.6）：进入 run>=3 的开局即赠予，直扑终局
    if _state.run_number >= 3:
        RunBoost.apply_boost(_state)
    SaveManager.save(_state, SAVE_PATH)
    run_restarted.emit(int(_state.run_number))
    return {"ok": true, "run_number": int(_state.run_number)}

# M6 真结局「回到标题」：清档回全新一周目开局（run 1），落盘并广播 run_restarted(1)
# 说明：项目无独立标题场景（main.tscn 即根场景），真结局循环终止的最小落地 = 重置为一周目新档。
func reset_to_title() -> Dictionary:
    _state = GameState.new()
    _pending_choice = &""
    SaveManager.save(_state, SAVE_PATH)
    run_restarted.emit(int(_state.run_number))
    return {"ok": true, "run_number": int(_state.run_number)}

func hear_story(story_id: StringName) -> Dictionary:
    var result := StoryActions.hear(_state, story_id)
    if result.get("ok", false):
        story_heard.emit(story_id, str(result.get("title", "")), str(result.get("text", "")))
        resources_changed.emit()
    return result

func convert_faith() -> bool:
    var ok := GameActions.convert_sap_to_faith(_state)
    if ok:
        resources_changed.emit()
    return ok

func convert_memory() -> bool:
    var ok := GameActions.convert_sap_to_memory(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_faith_engine() -> bool:
    var ok := GameActions.buy_faith_engine(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_memory_engine() -> bool:
    var ok := GameActions.buy_memory_engine(_state)
    if ok:
        resources_changed.emit()
    return ok

func upgrade_life() -> bool:
    var ok := LinguaActions.upgrade_life(_state)
    if ok.get("ok", false):
        resources_changed.emit()
        return true
    return false

func upgrade_memory() -> bool:
    var result := LinguaActions.upgrade_memory(_state)
    if result.get("ok", false):
        resources_changed.emit()
        return true
    return false

func unlock_node(node_id: StringName) -> bool:
    var ok := LinguaActions.unlock_node(_state, node_id)
    if ok.get("ok", false):
        resources_changed.emit()
        return true
    return false
