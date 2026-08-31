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
