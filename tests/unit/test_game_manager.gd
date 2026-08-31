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
    gm._state.human_awakened = true
    assert_that(gm.get_memory().to_value()).is_equal_approx(5.0, 1e-4)
    assert_that(gm.get_faith().to_value()).is_equal_approx(3.0, 1e-4)
    assert_that(gm.get_root_depth()).is_equal(2)
    assert_that(gm.is_human_awakened()).is_true()
