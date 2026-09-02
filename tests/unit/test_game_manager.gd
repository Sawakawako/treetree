extends GdUnitTestSuite

const GameManagerScript := preload("res://autoloads/game_manager.gd")

var gm

func before_test() -> void:
    gm = GameManagerScript.new()

func after_test() -> void:
    gm.free()

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
    var got := {"ok": false, "rel": -99}
    gm.relation_changed.connect(func(id: StringName, rel: int) -> void:
        got["ok"] = true
        got["rel"] = rel)
    var result: Dictionary = gm.interact_relation(&"human")
    assert_that(result.get("ok", false)).is_true()
    assert_that(got["ok"]).is_true()
    assert_that(int(got["rel"])).is_equal(1)
    assert_that(gm.get_state().relations["human"]).is_equal(1)

func test_interact_relation_blocked_no_signal() -> void:
    gm._state = GameState.new()  # 人族未醒
    var got := {"ok": false}
    gm.relation_changed.connect(func(id: StringName, rel: int) -> void: got["ok"] = true)
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
