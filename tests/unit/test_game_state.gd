extends GdUnitTestSuite

func test_initial_state() -> void:
    var s := GameState.new()
    assert_that(s.daylight.to_value()).is_equal(0.0)
    assert_that(s.sap.to_value()).is_equal(0.0)
    assert_that(s.growth.to_value()).is_equal(0.0)
    assert_that(s.leaf_level).is_equal(0)
    assert_that(s.branch_level).is_equal(0)
    assert_that(s.tick).is_equal(0)
    assert_that(s.hope).is_equal(1)

func test_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(42.0)
    s.leaf_level = 3
    s.tick = 60
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.daylight.to_value()).is_equal_approx(42.0, 1e-4)
    assert_that(back.leaf_level).is_equal(3)
    assert_that(back.tick).is_equal(60)

func test_from_dict_missing_fields_fallback() -> void:
    var back := GameState.from_dict({"sap": {"m": 7.0, "e": 0}})
    assert_that(back.sap.to_value()).is_equal_approx(7.0, 1e-4)
    assert_that(back.leaf_level).is_equal(0)
    assert_that(back.hope).is_equal(1)
