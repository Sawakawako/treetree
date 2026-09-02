extends GdUnitTestSuite

func _fresh() -> GameState:
	var s := GameState.new()
	s.faith = BigNum.new(0.0)
	return s

func test_life_lv1_free_activate() -> void:
	var s := _fresh()
	assert_that(LinguaActions.can_upgrade_life(s)).is_true()   # Lv0→1 免费
	var r := LinguaActions.upgrade_life(s)
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(1)
	assert_that(s.faith.to_value()).is_equal_approx(0.0, 1e-4)  # 不扣信仰

func test_life_lv2_costs_200() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.faith = BigNum.new(199.0)
	assert_that(LinguaActions.can_upgrade_life(s)).is_false()   # 信仰不足
	s.faith = BigNum.new(200.0)
	assert_that(LinguaActions.can_upgrade_life(s)).is_true()
	var r := LinguaActions.upgrade_life(s)
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(2)
	assert_that(s.faith.to_value()).is_equal_approx(0.0, 1e-4)

func test_life_lv3_costs_800() -> void:
	var s := _fresh()
	s.lingua_life_level = 2
	s.faith = BigNum.new(800.0)
	assert_that(LinguaActions.upgrade_life(s).get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(3)

func test_unlock_node_requires_level_and_sap() -> void:
	var s := _fresh()
	s.sap = BigNum.new(3000.0)
	assert_that(LinguaActions.can_unlock_node(s, &"tree_canopy")).is_false()  # 生命之语 Lv0
	s.lingua_life_level = 1
	assert_that(LinguaActions.can_unlock_node(s, &"tree_canopy")).is_true()
	var r := LinguaActions.unlock_node(s, &"tree_canopy")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_nodes).contains(&"tree_canopy")
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)  # 3000-3000

func test_unlock_node_idempotent() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.sap = BigNum.new(3000.0)
	LinguaActions.unlock_node(s, &"tree_canopy")
	assert_that(LinguaActions.unlock_node(s, &"tree_canopy").get("ok", false)).is_false()  # 已购
	assert_that(s.lingua_nodes.size()).is_equal(1)

func test_mid_tier_requires_lv2_and_8000_sap() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.sap = BigNum.new(8000.0)
	assert_that(LinguaActions.can_unlock_node(s, &"cloud_crown")).is_false()  # 需 Lv2
	s.lingua_life_level = 2
	assert_that(LinguaActions.can_unlock_node(s, &"cloud_crown")).is_true()