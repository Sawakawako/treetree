extends GdUnitTestSuite

func test_awaken_when_memory_enough() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(2.0)
    assert_that(HumanManager.check_awaken(s)).is_true()
    assert_that(s.human_awakened).is_true()
    # 不重复触发
    assert_that(HumanManager.check_awaken(s)).is_false()

func test_no_awaken_before_threshold() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(1.99)
    assert_that(HumanManager.check_awaken(s)).is_false()
    assert_that(s.human_awakened).is_false()

func test_faith_production_on_tick() -> void:
    var s := GameState.new()
    s.human_awakened = true
    s.tick = 10
    HumanManager.tick_human(s)
    assert_that(s.faith.to_value()).is_equal_approx(1.0, 1e-4)

func test_memory_production_on_tick_20() -> void:
    var s := GameState.new()
    s.human_awakened = true
    s.tick = 20
    HumanManager.tick_human(s)
    assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)

func test_no_production_before_awaken() -> void:
    var s := GameState.new()
    s.tick = 20
    HumanManager.tick_human(s)
    assert_that(s.faith.to_value()).is_equal(0.0)
    assert_that(s.memory.to_value()).is_equal(0.0)
