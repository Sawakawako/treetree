extends GdUnitTestSuite

const GameManagerScript := preload("res://autoloads/game_manager.gd")

var gm

# 世界之轴结算会写真实 SAVE_PATH（user://save.json）——测试前后备份/还原，避免污染真档
var _save_backup: Variant = null

func _state_axis_ready() -> GameState:
    var s := GameState.new()
    s.growth = BigNum.new(1000.0)
    s.relics_found.append(9)
    for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
        s.races[rid] = {"awakened": true, "population": 10.0}
    # 明选①—⑥（8 卡除 world_axis 外全做）
    for c in ChoiceLibrary.load_all():
        var cid := StringName(str(c.get("id", "")))
        if cid != &"world_axis":
            s.choices_done.append(cid)
    s.storyteller_stories.append(&"story_6")
    return s

func before_test() -> void:
    gm = GameManagerScript.new()
    var path := "user://save.json"
    _save_backup = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func after_test() -> void:
    gm.free()
    var path := "user://save.json"
    if _save_backup != null:
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f != null:
            f.store_buffer(_save_backup)
            f.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    _save_backup = null

func test_explore_relic_signal() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(200.0)
    # GDScript lambda 按值捕获局部变量——用 Dictionary 包装才能回写
    var got := {"relic": false, "text": ""}
    gm.relic_discovered.connect(func(name: String, text: String) -> void:
        got["relic"] = true
        got["text"] = text)
    var result: Dictionary = gm.explore_relic()
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["relic"]).is_true()
    assert_that(str(got["text"]).length()).is_greater(10)

func test_getters() -> void:
    gm._state = GameState.new()
    gm._state.memory = BigNum.new(5.0)
    gm._state.faith = BigNum.new(3.0)
    gm._state.root_depth = 2
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    assert_that(gm.get_memory().to_value()).is_equal_approx(5.0, 1e-4)
    assert_that(gm.get_faith().to_value()).is_equal_approx(3.0, 1e-4)
    assert_that(gm.get_root_depth()).is_equal(2)
    assert_that(gm.is_human_awakened()).is_true()

func test_interact_relation_advances_into_run2_extra_events() -> void:
    gm._state = GameState.new()
    gm._state.run_number = 2
    gm._state.races[&"stoneborn"] = {"awakened": true, "population": 10.0}
    gm._state.sap = BigNum.new(9999.0)
    gm._state.relation_events.append(&"stoneborn")  # 基础互动已完成

    assert_that(gm.can_interact_relation(&"stoneborn")).is_true()
    var first: Dictionary = gm.interact_relation(&"stoneborn")
    assert_that(first.get("ok", false)).is_true()
    assert_that(gm._state.relation_events).contains(&"stoneborn_r2a")

    gm.interact_relation(&"stoneborn")
    gm.interact_relation(&"stoneborn")
    assert_that(gm._state.relation_events).contains(&"stoneborn_r2b")
    assert_that(gm._state.relation_events).contains(&"stoneborn_r2c")
    assert_that(gm.can_interact_relation(&"stoneborn")).is_false()
    assert_that(RelationActions.get_relation(gm._state, &"stoneborn")).is_equal_approx(1.5, 1e-4)

func test_human_awakens_during_play() -> void:
    # C1 回归（M3 语义）：游戏中记忆≥2 后，tick 链路必须触发唤醒
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    assert_that(gm.get_memory().to_value()).is_equal_approx(2.0, 1e-4)
    assert_that(gm.is_human_awakened()).is_false()
    gm._process(1.0)
    assert_that(gm.is_human_awakened()).is_true()

func test_race_awakened_signal_emitted() -> void:
    # I4 回归（M3）：唤醒时发出 race_awakened（含种族名与文本）
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    var got := {"awakened": false, "name": ""}
    gm.race_awakened.connect(func(id: StringName, name: String, text: String) -> void:
        got["awakened"] = true
        got["name"] = name)
    gm._process(1.0)
    assert_that(got["awakened"]).is_true()
    assert_that(got["name"]).is_equal("人族")

func test_human_produces_faith_after_awaken() -> void:
    # M3 公式：唤醒后每 tick 产 50×1.0×0.002 = 0.1 信仰（原 M2 平铺 +1.0 已废弃）
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    gm._state.sap = BigNum.new(200.0)
    gm.explore_relic()
    gm._state.tick = 9
    gm._process(1.0)
    assert_that(gm.is_human_awakened()).is_true()
    assert_that(gm.get_faith().to_value()).is_equal_approx(0.1, 1e-4)

func test_interpret_totem_signal() -> void:
    # 野民唤醒 + 记忆达标 → 解读 → 信号 + 领悟 +1
    gm._state = GameState.new()
    gm._state.races["wildfolk"] = {"awakened": true, "population": 80.0}
    gm._state.memory = BigNum.new(4.0)
    var got := {"ok": false, "text": ""}
    gm.totem_interpreted.connect(func(id: int, text: String) -> void:
        got["ok"] = true
        got["text"] = text)
    var result: Dictionary = gm.interpret_totem(2)
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(str(got["text"]).length()).is_greater(5)
    assert_that(gm.get_state().insight).is_equal(1)

func test_interpret_totem_blocked_no_signal() -> void:
    # 野民未醒 → 不可解读 → ok:false 且不发信号
    gm._state = GameState.new()
    gm._state.memory = BigNum.new(50.0)
    var got := {"ok": false}
    gm.totem_interpreted.connect(func(id: int, text: String) -> void: got["ok"] = true)
    var result: Dictionary = gm.interpret_totem(1)
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_interact_relation_signal() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    gm._state.memory = BigNum.new(4.0)
    var got := {"ok": false, "rel": -99.0}
    gm.relation_changed.connect(func(id: StringName, rel: float) -> void:
        got["ok"] = true
        got["rel"] = rel)
    var result: Dictionary = gm.interact_relation(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(float(got["rel"])).is_equal_approx(0.5, 1e-4)
    assert_that(float(gm.get_state().relations["human"])).is_equal_approx(0.5, 1e-4)

func test_interact_relation_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 人族未醒
    var got := {"ok": false}
    gm.relation_changed.connect(func(id: StringName, rel: float) -> void: got["ok"] = true)
    var result: Dictionary = gm.interact_relation(&"human")
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_plunder_race_signal() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    var got := {"ok": false, "revealed": false}
    gm.plunder_done.connect(func(id: StringName, text: String, revealed: bool) -> void:
        got["ok"] = true
        got["revealed"] = revealed)
    var result: Dictionary = gm.plunder_race(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(gm.get_state().memory.to_value()).is_equal_approx(1.0, 1e-4)

func test_plunder_race_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 人族未醒
    var got := {"ok": false}
    gm.plunder_done.connect(func(id: StringName, text: String, revealed: bool) -> void: got["ok"] = true)
    var result: Dictionary = gm.plunder_race(&"human")
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_buy_upgrade_entrances() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(10000.0)
    assert_that(gm.buy_chloroplast()).is_true()
    assert_that(gm.buy_xylem()).is_true()
    assert_that(gm.buy_sunflower()).is_true()
    assert_that(gm.buy_nautilus()).is_true()
    assert_that(gm.buy_root_eff()).is_true()
    assert_that(gm.get_chloroplast_cost()).is_greater(0)
    # 买螺舱后 nautilus_level=1 → cap = 10000 + 5000×1 = 15000（计划原文 10000 与设计 §3.4 公式冲突，按设计权威修正）
    assert_that(gm.get_sap_cap()).is_equal_approx(15000.0, 1e-4)

func test_buy_upgrade_insufficient() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(1.0)
    assert_that(gm.buy_sunflower()).is_false()
    assert_that(gm.get_state().sunflower_level).is_equal(0)

func test_intimate_race_signal() -> void:
    gm._state = GameState.new()
    gm._state.memory = BigNum.new(40.0)
    gm._state.relations["human"] = 2
    var got := {"ok": false, "text": ""}
    gm.intimate_done.connect(func(id: StringName, text: String) -> void:
        got["ok"] = true
        got["text"] = text)
    var result: Dictionary = gm.intimate_race(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(str(got["text"]).length()).is_greater(20)
    assert_that(gm.get_state().intimate_events).contains(&"human")

func test_intimate_race_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 未觉醒
    var got := {"ok": false}
    gm.intimate_done.connect(func(id: StringName, text: String) -> void: got["ok"] = true)
    var result: Dictionary = gm.intimate_race(&"human")
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_revive_race_signal() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    gm._state.growth = BigNum.new(600.0)
    var got := {"ok": false, "pop": -1, "river": -1}
    gm.soul_revived.connect(func(id: StringName, pop_gain: int) -> void:
        got["ok"] = true
        got["pop"] = pop_gain)
    gm.soul_changed.connect(func(r: int) -> void: got["river"] = r)
    var result: Dictionary = gm.revive_race(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(int(got["pop"])).is_equal(10)
    assert_that(int(got["river"])).is_equal(99)
    assert_that(gm.get_state().soul_river).is_equal(99)

func test_revive_race_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 未唤醒
    var got := {"ok": false}
    gm.soul_revived.connect(func(id: StringName, pop_gain: int) -> void: got["ok"] = true)
    var result: Dictionary = gm.revive_race(&"human")
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_plunder_soul_race_signal() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    gm._state.plundered["human"] = 3  # 先夺梦揭示（人口冻结但可夺魂）
    gm._state.soul_river = 99
    var got := {"ok": false, "loss": -1}
    gm.soul_plundered.connect(func(id: StringName, pop_loss: int) -> void:
        got["ok"] = true
        got["loss"] = pop_loss)
    var result: Dictionary = gm.plunder_soul_race(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(int(got["loss"])).is_equal(3)
    assert_that(gm.get_state().soul_river).is_equal(100)

func test_plunder_soul_race_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 未唤醒
    var got := {"ok": false}
    gm.soul_plundered.connect(func(id: StringName, pop_loss: int) -> void: got["ok"] = true)
    var result: Dictionary = gm.plunder_soul_race(&"human")
    assert_that(result.get("ok", false)).is_false()
    assert_that(got["ok"]).is_false()

func test_choice_available_emitted_on_tick() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    var got := {"ok": false, "title": ""}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        got["ok"] = true
        got["title"] = title)
    gm._process(1.0)  # tick 触发人族召唤 → 明选检测
    assert_that(got["ok"]).is_true()
    assert_that(str(got["title"])).is_equal("人族噩梦")

func test_choice_pending_blocks_second_emit() -> void:
    # 一次只弹一个：pending 未清前不重复发
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    gm._state.memory = BigNum.new(30.0)  # 3 个 available，但只弹第一个
    # GDScript lambda 按值捕获局部变量（CONTINUE.md 六·二 #5）——用 Dictionary 包装回写
    var count := {"n": 0}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        count["n"] += 1)
    gm._process(1.0)
    gm._process(1.0)
    assert_that(count["n"]).is_equal(1)
    assert_that(gm._pending_choice).is_equal(&"human_nightmare")

func test_resolve_choice_signal_and_effect() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    var got := {"ok": false, "text": ""}
    gm.choice_resolved.connect(func(id: StringName, opt: StringName, text: String, opt_text: String) -> void:
        got["ok"] = true
        got["text"] = text)
    gm._process(1.0)  # 弹 human_nightmare
    var r: Dictionary = gm.resolve_choice(&"human_nightmare", &"a")
    assert_that(r.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(str(got["text"]).length()).is_greater(10)
    assert_that(gm.get_state().choices_done).contains(&"human_nightmare")
    assert_that(gm._pending_choice).is_equal(&"")

func test_resolve_choice_wrong_pending_fails() -> void:
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    gm._process(1.0)
    # 尝试解一个非 pending 的明选（未触发）
    var r: Dictionary = gm.resolve_choice(&"theseus", &"a")
    assert_that(r.get("ok", false)).is_false()
    assert_that(gm._pending_choice).is_equal(&"human_nightmare")  # pending 不被误清

func test_resolve_choice_no_pending_fails() -> void:
    gm._state = GameState.new()  # 无触发
    var r: Dictionary = gm.resolve_choice(&"human_nightmare", &"a")
    assert_that(r.get("ok", false)).is_false()

func test_hear_story_emits_only_on_success() -> void:
    gm._state = GameState.new()
    gm._state.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
    var got := {"count": 0, "title": "", "text": ""}
    gm.story_heard.connect(func(id: StringName, title: String, story_text: String) -> void:
        got["count"] += 1
        got["title"] = title
        got["text"] = story_text)
    assert_that(gm.hear_story(&"story_4").get("ok", false)).is_true()
    assert_that(got["count"]).is_equal(1)
    assert_that(str(got["title"])).is_equal("故事④·火边的人")
    assert_that(str(got["text"])).is_not_empty()
    assert_that(gm.hear_story(&"story_4").get("ok", false)).is_false()
    assert_that(got["count"]).is_equal(1)

func test_buy_seedling_entrance() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(100.0)
    assert_that(gm.buy_seedling()).is_true()
    assert_that(gm.get_state().seedling_level).is_equal(1)
    assert_that(gm.get_seedling_cost()).is_equal(20)  # 下一级

func test_buy_deep_dream_entrance() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(3000.0)
    assert_that(gm.buy_deep_dream()).is_true()
    assert_that(gm.get_state().deep_dream).is_true()

func test_buy_firepit_entrance_requires_awaken() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(5000.0)
    assert_that(gm.buy_firepit()).is_false()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    assert_that(gm.buy_firepit()).is_true()
    assert_that(gm.get_firepit_cost()).is_equal(1000)  # Lv1 后下一级仍 1000×fib(2)=1000

func test_convert_entrances() -> void:
    gm._state = GameState.new()
    gm._state.lingua_nodes.assign([&"tree_canopy", &"root_resonance"])
    gm._state.sap = BigNum.new(600.0)
    assert_that(gm.convert_faith()).is_true()
    assert_that(gm.get_state().faith.to_value()).is_equal_approx(1.0, 1e-4)
    assert_that(gm.convert_memory()).is_true()
    assert_that(gm.get_state().memory.to_value()).is_equal_approx(1.0, 1e-4)
    assert_that(gm.get_state().sap.to_value()).is_equal_approx(0.0, 1e-4)  # 600-100-500

func test_convert_blocked() -> void:
    gm._state = GameState.new()  # 无节点
    gm._state.sap = BigNum.new(1000.0)
    assert_that(gm.convert_faith()).is_false()
    assert_that(gm.convert_memory()).is_false()

func test_engine_entrances() -> void:
    gm._state = GameState.new()
    gm._state.lingua_nodes.assign([&"cloud_crown", &"grace"])
    gm._state.faith = BigNum.new(1000.0)
    gm._state.memory = BigNum.new(1000.0)
    assert_that(gm.buy_faith_engine()).is_true()
    assert_that(gm.buy_memory_engine()).is_true()
    assert_that(gm.get_state().faith_engine_level).is_equal(1)
    assert_that(gm.get_state().memory_engine_level).is_equal(1)

func test_lingua_entrances() -> void:
    gm._state = GameState.new()
    gm._state.faith = BigNum.new(1000.0)
    assert_that(gm.upgrade_life()).is_true()  # Lv0→1 免费
    assert_that(gm.upgrade_life()).is_true()  # Lv1→2 扣 200
    assert_that(gm.get_state().lingua_life_level).is_equal(2)
    gm._state.sap = BigNum.new(3000.0)
    assert_that(gm.unlock_node(&"tree_canopy")).is_true()
    assert_that(gm.get_state().lingua_nodes).contains(&"tree_canopy")

func test_upgrade_memory_emits_resources_only_on_success() -> void:
    gm._state = GameState.new()
    gm._state.memory = BigNum.new(500.0)
    gm._state.insight = 5
    var got := {"count": 0}
    gm.resources_changed.connect(func() -> void: got["count"] += 1)
    assert_that(gm.upgrade_memory()).is_true()
    assert_that(got["count"]).is_equal(1)
    assert_that(gm.get_state().lingua_memory_level).is_equal(1)
    assert_that(gm.upgrade_memory()).is_false()
    assert_that(got["count"]).is_equal(1)

func test_settle_offline_is_idempotent_for_same_now() -> void:
    gm._state = GameState.new()
    gm._state.lingua_nodes.assign([&"earth_sense"])
    gm._state.branch_level = 1
    gm._state.last_saved_unix = 1000
    var first: Dictionary = gm.settle_offline(1060)
    var after_first: float = gm.get_state().daylight.to_value()
    var second: Dictionary = gm.settle_offline(1060)
    assert_that(first.get("applied", false)).is_true()
    assert_that(after_first).is_greater(0.0)
    assert_that(second.get("applied", false)).is_false()
    assert_that(gm.get_state().daylight.to_value()).is_equal_approx(after_first, 1e-4)

func test_old_save_timestamp_zero_only_records_now() -> void:
    gm._state = GameState.new()
    gm._state.lingua_nodes.assign([&"earth_sense"])
    gm._state.branch_level = 1
    var result: Dictionary = gm.settle_offline(5000)
    assert_that(result.get("applied", false)).is_false()
    assert_that(gm.get_state().last_saved_unix).is_equal(5000)
    assert_that(gm.get_state().daylight.to_value()).is_equal_approx(0.0, 1e-4)

func test_clock_rollback_does_not_move_timestamp_or_grant() -> void:
    gm._state = GameState.new()
    gm._state.lingua_nodes.assign([&"earth_sense"])
    gm._state.branch_level = 1
    gm._state.last_saved_unix = 5000
    var result: Dictionary = gm.settle_offline(4000)
    assert_that(result.get("applied", false)).is_false()
    assert_that(gm.get_state().last_saved_unix).is_equal(5000)
    assert_that(gm.get_state().daylight.to_value()).is_equal_approx(0.0, 1e-4)

func test_offline_summary_can_only_be_taken_once() -> void:
    gm._pending_offline_summary = {"applied": true, "seconds": 60, "sap": 12.0}
    var first: Dictionary = gm.take_offline_summary()
    var second: Dictionary = gm.take_offline_summary()
    assert_that(first.get("applied", false)).is_true()
    assert_that(first.get("sap", 0.0)).is_equal(12.0)
    assert_that(second.is_empty()).is_true()

func test_unlock_blocked() -> void:
    gm._state = GameState.new()
    gm._state.faith = BigNum.new(1000.0)
    gm.upgrade_life()  # Lv1
    gm._state.sap = BigNum.new(3000.0)
    assert_that(gm.unlock_node(&"root_resonance")).is_true()
    assert_that(gm.unlock_node(&"cloud_crown")).is_false()  # 需 Lv2

# ---------- M6 世界之轴：主动入口 + 终局结算 ----------

func test_try_start_world_axis_gated_on_axis_ready() -> void:
    gm._state = _state_axis_ready()  # axis_ready 全满足
    gm._pending_choice = &""
    var got := {"ok": false, "title": ""}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        got["ok"] = true
        got["title"] = title)
    assert_that(gm.try_start_world_axis()).is_true()
    assert_that(gm._pending_choice).is_equal(&"world_axis")
    assert_that(got["ok"]).is_true()
    assert_that(str(got["title"])).is_equal("世界之轴")

func test_try_start_world_axis_blocked_when_not_ready() -> void:
    gm._state = GameState.new()  # 无遗迹/未醒/卡未做/无 story_6/growth 0
    var got := {"n": 0}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        got["n"] += 1)
    assert_that(gm.try_start_world_axis()).is_false()
    assert_that(gm._pending_choice).is_equal(&"")
    assert_that(got["n"]).is_equal(0)

func test_try_start_world_axis_blocked_when_pending_choice() -> void:
    gm._state = _state_axis_ready()
    gm._pending_choice = &"human_nightmare"  # 已有待决明选
    var got := {"n": 0}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        got["n"] += 1)
    assert_that(gm.try_start_world_axis()).is_false()
    assert_that(gm._pending_choice).is_equal(&"human_nightmare")

func test_resolve_world_axis_settles_via_ending_machine() -> void:
    gm._state = _state_axis_ready()
    gm._state.run_number = 3
    gm._state.hope = 2
    gm._state.insight = 10
    for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
        gm._state.relations[rid] = 3.0
    gm._pending_choice = &"world_axis"
    var got := {"resolved": false, "ended": false, "outcome": "", "hope_after": -1}
    gm.choice_resolved.connect(func(id: StringName, opt: StringName, text: String, opt_text: String) -> void:
        got["resolved"] = true)
    gm.ending_resolved.connect(func(outcome: StringName, hope_after: int) -> void:
        got["ended"] = true
        got["outcome"] = outcome
        got["hope_after"] = hope_after)
    var r: Dictionary = gm.resolve_choice(&"world_axis", &"d")
    assert_that(r.get("ok", false)).is_true()
    assert_that(str(r.get("outcome", ""))).is_equal("true")
    assert_that(got["ended"]).is_true()
    assert_that(str(got["outcome"])).is_equal("true")
    assert_that(int(got["hope_after"])).is_equal(0)
    assert_that(gm._pending_choice).is_equal(&"")
    assert_that(gm.get_state().choices_done).contains(&"world_axis")

func test_resolve_world_axis_condense_emits_good() -> void:
    # 三周目希望不靠 d；用 condense 验证 hope+1 后结算通路
    gm._state = _state_axis_ready()
    gm._state.run_number = 3
    gm._state.insight = 10
    for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
        gm._state.relations[rid] = 3.0
    gm._state.hope = 1
    gm._pending_choice = &"world_axis"
    var got := {"ended": false, "outcome": "", "hope_after": -1}
    gm.ending_resolved.connect(func(outcome: StringName, hope_after: int) -> void:
        got["ended"] = true
        got["outcome"] = outcome
        got["hope_after"] = hope_after)
    var r: Dictionary = gm.resolve_choice(&"world_axis", &"a")
    assert_that(r.get("ok", false)).is_true()
    assert_that(str(r.get("outcome", ""))).is_equal("good")
    assert_that(got["ended"]).is_true()
    assert_that(int(got["hope_after"])).is_equal(2)
    var pending: Dictionary = gm.get_pending_ending()
    assert_that(pending.get("outcome")).is_equal(&"good")
    assert_that(pending.get("intent")).is_equal(&"condense")
    assert_that(pending.get("phase")).is_equal(&"settlement")

func test_return_ending_progress_is_saved_and_restored() -> void:
    gm._state = _state_axis_ready()
    gm._state.insight = 10
    for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
        gm._state.relations[rid] = 3.0
    gm._pending_choice = &"world_axis"
    var settled: Dictionary = gm.resolve_choice(&"world_axis", &"c")
    assert_that(settled.get("ok", false)).is_true()
    assert_that(gm.get_pending_ending().get("return_step")).is_equal(1)

    gm.advance_return_sequence()
    gm.advance_return_sequence()
    var restored := SaveManager.load_or_create("user://save.json")
    assert_that(restored.pending_ending.get("outcome")).is_equal(&"good")
    assert_that(restored.pending_ending.get("intent")).is_equal(&"return")
    assert_that(restored.pending_ending.get("phase")).is_equal(&"return")
    assert_that(restored.pending_ending.get("return_step")).is_equal(3)

func test_resolve_world_axis_still_requires_pending() -> void:
    gm._state = _state_axis_ready()  # axis 全就绪
    gm._pending_choice = &""  # 但无待决
    var r: Dictionary = gm.resolve_choice(&"world_axis", &"a")
    assert_that(r.get("ok", false)).is_false()

func test_ending_blocked_returns_ok_false() -> void:
    # d 在 <run3 时 UI 不可选，但 resolve 入口若被强行调用 self：状态机挡回
    gm._state = _state_axis_ready()
    gm._pending_choice = &"world_axis"
    var got := {"n": 0}
    gm.ending_resolved.connect(func(outcome: StringName, hope_after: int) -> void: got["n"] += 1)
    var r: Dictionary = gm.resolve_choice(&"world_axis", &"d")  # run_number=1, hope=1
    assert_that(r.get("ok", false)).is_false()
    assert_that(got["n"]).is_equal(0)

func test_resolve_non_axis_choice_still_works() -> void:
    # 回归：普通明选（非 world_axis）走原流程——choice_resolved + pending 清空，不发 ending_resolved
    gm._state = GameState.new()
    gm._state.races["human"] = {"awakened": true, "population": 50.0}
    var got := {"resolved": false, "ended": false}
    gm.choice_resolved.connect(func(id: StringName, opt: StringName, text: String, opt_text: String) -> void:
        got["resolved"] = true)
    gm.ending_resolved.connect(func(outcome: StringName, hope_after: int) -> void: got["ended"] = true)
    gm._process(1.0)  # 弹 human_nightmare
    var r: Dictionary = gm.resolve_choice(&"human_nightmare", &"b")
    assert_that(r.get("ok", false)).is_true()
    assert_that(got["resolved"]).is_true()
    assert_that(got["ended"]).is_false()
    assert_that(gm._pending_choice).is_equal(&"")

# ---------- M6 周目切换：restart_run ----------

func test_restart_run_preserves_and_increments() -> void:
    # 余烬保留：hope/insight 跨周目保留，relations 等周目内状态清空；run_number+1
    gm._state = GameState.new()
    gm._state.hope = 2
    gm._state.insight = 11
    gm._state.relations[&"human"] = 3.0
    var r: Dictionary = gm.restart_run()
    assert_that(r.get("ok", false)).is_true()
    assert_that(int(r.get("run_number", 0))).is_equal(2)
    assert_that(gm.get_state().hope).is_equal(2)
    assert_that(gm.get_state().insight).is_equal(11)
    assert_that(gm.get_state().relations).is_empty()

func test_restart_into_run3_applies_boost() -> void:
    # M6 三周目浓缩快进：restart 落入 run3（2→3）即开局赠予资源/解锁，直扑终局；
    # run<3 不触发由 RunBoost.apply_boost 守卫测试 + 既有 1→2 restart 测试锁定
    gm._state = GameState.new()
    gm._state.hope = 2
    gm._state.run_number = 2
    var first: Dictionary = gm.restart_run()
    assert_that(int(first.get("run_number", 0))).is_equal(3)
    assert_that(gm.get_state().sap.to_value()).is_greater(0.0)
    assert_that(gm.get_state().lingua_life_level).is_equal(RunBoost.BOOST_LIFE_LV)
    assert_that(gm.get_state().leaf_level).is_equal(RunBoost.BOOST_LEAF)
    assert_that(gm.get_state().root_depth).is_equal(RunBoost.BOOST_ROOT)
    for n: StringName in RunBoost.BOOST_NODES:
        assert_that(gm.get_state().lingua_nodes).contains(n)

func test_restart_run_clears_pending_emits_signal_and_saves() -> void:
    # 契约：清 _pending_choice、发 run_restarted(新周目号)、新档落盘 user://save.json
    gm._state = GameState.new()
    gm._state.hope = 1
    gm._state.run_number = 1
    gm._pending_choice = &"world_axis"
    var got := {"restarted": false, "run": -1}
    gm.run_restarted.connect(func(n: int) -> void:
        got["restarted"] = true
        got["run"] = n)
    var r: Dictionary = gm.restart_run()
    assert_that(r.get("ok", false)).is_true()
    assert_that(int(r.get("run_number", 0))).is_equal(2)
    assert_that(got["restarted"]).is_true()
    assert_that(int(got["run"])).is_equal(2)
    assert_that(gm._pending_choice).is_equal(&"")
    assert_that(gm.get_state().run_number).is_equal(2)
    # 存档已写盘（含新 run_number）
    var f := FileAccess.open("user://save.json", FileAccess.READ)
    var parsed: Variant = null
    if f != null:
        parsed = JSON.parse_string(f.get_as_text())
        f.close()
    assert_that(parsed != null and typeof(parsed) == TYPE_DICTIONARY).is_true()
    assert_that(int((parsed as Dictionary).get("run_number", 0))).is_equal(2)

func test_restart_run_keeps_endgame_meta_flags() -> void:
    # M6 语义：真相/知识解锁（choice_flags/totem/story 等）跨周目保留；结局归档保留
    gm._state = GameState.new()
    gm._state.hope = 2
    gm._state.insight = 11
    gm._state.truth = 3
    gm._state.choice_flags.assign([&"cave_found"])
    gm._state.totem_interpreted.append(2)
    gm._state.storyteller_stories.append(&"story_6")
    gm._state.ending_seen.append(&"good")
    gm._state.choices_done.append(&"world_axis")  # 周目内进度（应清空）
    gm._state.relics_found.append(9)
    gm._state.soul_river = 90
    var r: Dictionary = gm.restart_run()
    assert_that(r.get("ok", false)).is_true()
    var st: GameState = gm.get_state()
    assert_that(st.truth).is_equal(3)
    assert_that(st.choice_flags).contains(&"cave_found")
    assert_that(st.totem_interpreted).contains(2)
    assert_that(st.storyteller_stories).contains(&"story_6")
    assert_that(st.ending_seen).contains(&"good")
    assert_that(st.choices_done).is_empty()
    assert_that(st.relics_found).is_empty()
    assert_that(st.soul_river).is_equal(100)  # 灵魂守恒回归初始

func test_reset_to_title_clears_to_fresh_run1() -> void:
    # M6 真结局「回到标题」：整档清空回 run1（无余烬保留），发 run_restarted(1)
    gm._state = GameState.new()
    gm._state.hope = 2
    gm._state.insight = 11
    gm._state.run_number = 3
    gm._state.choice_flags.assign([&"cave_found"])
    gm._pending_choice = &"world_axis"
    var got := {"restarted": false, "run": -1}
    gm.run_restarted.connect(func(n: int) -> void:
        got["restarted"] = true
        got["run"] = n)
    var r: Dictionary = gm.reset_to_title()
    assert_that(r.get("ok", false)).is_true()
    assert_that(int(r.get("run_number", 0))).is_equal(1)
    assert_that(got["restarted"]).is_true()
    assert_that(int(got["run"])).is_equal(1)
    assert_that(gm._pending_choice).is_equal(&"")
    var st: GameState = gm.get_state()
    assert_that(st.run_number).is_equal(1)
    assert_that(st.hope).is_equal(1)
    assert_that(st.insight).is_equal(0)
    assert_that(st.choice_flags).is_empty()

func test_try_start_world_axis_refused_after_axis_settled() -> void:
    # P4 守门：世界之轴已结算（choices_done 含 world_axis）后不得再次入场——
    # 否则返回 true 会把 _pending_choice 卡死在 world_axis（resolve 必败软锁）
    gm._state = _state_axis_ready()
    gm._state.insight = 10
    for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
        gm._state.relations[rid] = 3.0
    gm._pending_choice = &"world_axis"
    var settled: Dictionary = gm.resolve_choice(&"world_axis", &"a")
    assert_that(settled.get("ok", false)).is_true()
    assert_that(gm.get_state().choices_done).contains(&"world_axis")
    var got := {"n": 0}
    gm.choice_available.connect(func(id: StringName, title: String, intro: String, options: Array) -> void:
        got["n"] += 1)
    assert_that(gm.try_start_world_axis()).is_false()
    assert_that(gm._pending_choice).is_equal(&"")
    assert_that(got["n"]).is_equal(0)
