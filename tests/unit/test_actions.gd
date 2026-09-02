extends GdUnitTestSuite

func test_gather_basic() -> void:
    var s := GameState.new()
    GameActions.gather_daylight(s)
    assert_that(s.daylight.to_value()).is_equal_approx(1.0, 1e-4)

func test_gather_with_leaf_bonus() -> void:
    var s := GameState.new()
    s.leaf_level = 2  # 1 + 0.25*2 = 1.5
    GameActions.gather_daylight(s)
    assert_that(s.daylight.to_value()).is_equal_approx(1.5, 1e-4)

func test_buy_leaf_success() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(500.0)
    assert_that(GameActions.buy_leaf(s)).is_true()
    assert_that(s.leaf_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_buy_leaf_insufficient() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(499.0)
    assert_that(GameActions.buy_leaf(s)).is_false()
    assert_that(s.leaf_level).is_equal(0)
    assert_that(s.sap.to_value()).is_equal_approx(499.0, 1e-4)

func test_buy_branch_success() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(1200.0)
    assert_that(GameActions.buy_branch(s)).is_true()
    assert_that(s.branch_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_buy_chloroplast_success() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(800.0)
    assert_that(GameActions.buy_chloroplast(s)).is_true()
    assert_that(s.chloroplast_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_buy_chloroplast_insufficient() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(799.0)
    assert_that(GameActions.buy_chloroplast(s)).is_false()
    assert_that(s.chloroplast_level).is_equal(0)

func test_buy_xylem_sunflower_nautilus_root() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(10000.0)
    assert_that(GameActions.buy_xylem(s)).is_true()
    assert_that(GameActions.buy_sunflower(s)).is_true()
    assert_that(GameActions.buy_nautilus(s)).is_true()
    assert_that(GameActions.buy_root_eff(s)).is_true()
    assert_that(s.xylem_level).is_equal(1)
    assert_that(s.sunflower_level).is_equal(1)
    assert_that(s.nautilus_level).is_equal(1)
    assert_that(s.root_eff_level).is_equal(1)

func _awaken(state: GameState, id: StringName) -> void:
    state.races[id] = {"awakened": true, "population": 50.0}

func test_buy_seedling_three_levels_cap() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(1000.0)
    assert_that(GameActions.buy_seedling(s)).is_true()   # 10
    assert_that(GameActions.buy_seedling(s)).is_true()   # 20
    assert_that(GameActions.buy_seedling(s)).is_true()   # 30
    assert_that(s.seedling_level).is_equal(3)
    assert_that(GameActions.buy_seedling(s)).is_false()  # 3 级封顶
    assert_that(s.sap.to_value()).is_equal_approx(940.0, 1e-4)  # 1000-60

func test_buy_deep_dream_once() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(3000.0)
    assert_that(GameActions.buy_deep_dream(s)).is_true()
    assert_that(s.memory.to_value()).is_equal_approx(15.0, 1e-4)
    assert_that(s.deep_dream).is_true()
    assert_that(GameActions.buy_deep_dream(s)).is_false()  # 一次性幂等
    s.sap = BigNum.new(1000.0)
    assert_that(s.sap.to_value()).is_equal_approx(1000.0, 1e-4)  # 二次不扣

func test_buy_wind_veil_once() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(2500.0)
    assert_that(GameActions.buy_wind_veil(s)).is_true()
    assert_that(s.faith.to_value()).is_equal_approx(30.0, 1e-4)
    assert_that(s.wind_veil).is_true()
    assert_that(GameActions.buy_wind_veil(s)).is_false()

func test_buy_facility_requires_awakened() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(5000.0)
    assert_that(GameActions.buy_firepit(s)).is_false()  # 人族未醒
    _awaken(s, &"human")
    assert_that(GameActions.buy_firepit(s)).is_true()
    assert_that(s.firepit_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(4000.0, 1e-4)  # 5000-1000

func test_buy_facility_insufficient() -> void:
    var s := GameState.new()
    _awaken(s, &"forestfolk")
    s.sap = BigNum.new(999.0)
    assert_that(GameActions.buy_ring(s)).is_false()

func test_all_facilities_gate_by_race() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(100000.0)
    _awaken(s, &"human"); _awaken(s, &"forestfolk"); _awaken(s, &"stoneborn"); _awaken(s, &"wildfolk")
    assert_that(GameActions.buy_firepit(s)).is_true()
    assert_that(GameActions.buy_ring(s)).is_true()
    assert_that(GameActions.buy_forge(s)).is_true()
    assert_that(GameActions.buy_totem_pole(s)).is_true()
    assert_that(s.firepit_level).is_equal(1)
    assert_that(s.ring_level).is_equal(1)
    assert_that(s.forge_level).is_equal(1)
    assert_that(s.totem_pole_level).is_equal(1)
