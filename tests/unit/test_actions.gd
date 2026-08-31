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
