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

func test_memory_lv1_rejects_499_memory() -> void:
	var s := _fresh()
	s.memory = BigNum.new(499.0)
	s.insight = 5
	assert_that(LinguaActions.can_upgrade_memory(s)).is_false()
	assert_that(LinguaActions.upgrade_memory(s).get("ok", false)).is_false()

func test_memory_lv1_rejects_four_insight() -> void:
	var s := _fresh()
	s.memory = BigNum.new(500.0)
	s.insight = 4
	assert_that(LinguaActions.can_upgrade_memory(s)).is_false()
	assert_that(s.memory.to_value()).is_equal_approx(500.0, 1e-4)

func test_memory_lv1_boundary_spends_memory_but_keeps_insight() -> void:
	var s := _fresh()
	s.memory = BigNum.new(500.0)
	s.insight = 5
	assert_that(LinguaActions.memory_cost(s)).is_equal(500)
	var result: Dictionary = LinguaActions.upgrade_memory(s)
	assert_that(result.get("ok", false)).is_true()
	assert_that(s.lingua_memory_level).is_equal(1)
	assert_that(s.memory.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(s.insight).is_equal(5)

func test_memory_lv1_cannot_repeat_or_spend_again() -> void:
	var s := _fresh()
	s.memory = BigNum.new(1000.0)
	s.insight = 8
	assert_that(LinguaActions.upgrade_memory(s).get("ok", false)).is_true()
	assert_that(LinguaActions.upgrade_memory(s).get("ok", false)).is_false()
	assert_that(s.lingua_memory_level).is_equal(1)
	assert_that(s.memory.to_value()).is_equal_approx(500.0, 1e-4)
	assert_that(s.insight).is_equal(8)

func test_offline_nodes_use_their_own_language_gate() -> void:
	var s := _fresh()
	s.sap = BigNum.new(20000.0)
	s.lingua_life_level = 1
	s.lingua_memory_level = 0
	assert_that(LinguaActions.can_unlock_node(s, &"earth_sense")).is_false()
	assert_that(LinguaActions.can_unlock_node(s, &"sky_light")).is_false()
	s.lingua_life_level = 2
	assert_that(LinguaActions.can_unlock_node(s, &"earth_sense")).is_true()
	s.lingua_memory_level = 1
	assert_that(LinguaActions.can_unlock_node(s, &"sky_light")).is_true()

func test_world_node_uses_realm_derived_level() -> void:
	var s := _fresh()
	s.sap = BigNum.new(8000.0)
	s.realm_echoes.assign([&"midgard", &"nidavellir"])
	assert_that(LinguaActions.can_unlock_node(s, &"world_trace")).is_false()
	s.realm_echoes.append(&"alfheim")
	assert_that(RealmActions.world_level(s)).is_equal(1)
	assert_that(LinguaActions.can_unlock_node(s, &"world_trace")).is_true()

func test_world_node_prerequisite_chain_is_enforced() -> void:
	var s := _fresh()
	s.sap = BigNum.new(50000.0)
	s.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim",
		&"muspelheim", &"jotunheim", &"niflheim",
	])
	assert_that(LinguaActions.can_unlock_node(s, &"sky_ladder")).is_false()
	s.lingua_nodes.assign([&"world_trace", &"river_hearing"])
	assert_that(LinguaActions.can_unlock_node(s, &"sky_ladder")).is_true()

func test_world_node_unlock_spends_sap_once() -> void:
	var s := _fresh()
	s.sap = BigNum.new(8000.0)
	s.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	var result := LinguaActions.unlock_node(s, &"world_trace")
	assert_that(result.get("ok", false)).is_true()
	assert_that(s.lingua_nodes).contains(&"world_trace")
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(LinguaActions.unlock_node(s, &"world_trace").get("ok", false)).is_false()
