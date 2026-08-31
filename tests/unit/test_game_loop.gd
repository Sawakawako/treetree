extends GdUnitTestSuite

func test_tick_increments_and_photosynthesis() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(100.0)
    GameLoop.tick(s)
    assert_that(s.tick).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(10.0, 1e-4)  # 100 × 0.1
    assert_that(s.daylight.to_value()).is_equal_approx(100.0, 1e-4)  # 无分支时日光不变

func test_tick_auto_collect() -> void:
    var s := GameState.new()
    s.branch_level = 3
    s.daylight = BigNum.new(10.0)
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(13.0, 1e-4)  # 10 + 3×1

func test_tick_auto_collect_with_leaf_bonus() -> void:
    var s := GameState.new()
    s.branch_level = 2
    s.leaf_level = 2  # 2 × 1.5 = 3
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(3.0, 1e-4)

func test_tick_growth() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    GameLoop.tick(s)
    assert_that(s.growth.to_value()).is_equal_approx(2.0, 1e-4)  # 200 × 0.01

func test_should_auto_save() -> void:
    var s := GameState.new()
    s.tick = 60
    assert_that(GameLoop.should_auto_save(s)).is_true()
    s.tick = 61
    assert_that(GameLoop.should_auto_save(s)).is_false()
