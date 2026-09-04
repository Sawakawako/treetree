extends GdUnitTestSuite

func test_drift_zero_by_default() -> void:
	var s := GameState.new()
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.0, 1e-4)

func test_drift_from_plunder() -> void:
	var s := GameState.new()
	s.plundered["human"] = 3
	s.plundered["wildfolk"] = 1
	# 4 × 0.5 = 2.0（memory 0 无记忆加成）
	assert_that(DriftActions.drift_value(s)).is_equal_approx(2.0, 1e-4)

func test_drift_from_memory_after_30() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(50.0)
	# (50-30) × 0.02 = 0.4
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.4, 1e-4)
	s.memory = BigNum.new(20.0)
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.0, 1e-4)  # 30 以下不计

func test_drift_clamped() -> void:
	var s := GameState.new()
	s.plundered["human"] = 100
	assert_that(DriftActions.drift_value(s)).is_equal_approx(10.0, 1e-4)

func test_drift_tier_boundaries() -> void:
	var s := GameState.new()
	s.plundered["human"] = 5   # 2.5 → tier 0
	assert_that(DriftActions.drift_tier(s)).is_equal(0)
	s.plundered["human"] = 6   # 3.0 → tier 1
	assert_that(DriftActions.drift_tier(s)).is_equal(1)
	s.plundered["human"] = 12  # 6.0 → tier 2
	assert_that(DriftActions.drift_tier(s)).is_equal(2)
	s.plundered["human"] = 18  # 9.0 → tier 3
	assert_that(DriftActions.drift_tier(s)).is_equal(3)

func test_nine_plunders_at_avatar_memory_is_micro_drift() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(30.0)
	s.plundered["human"] = 9
	assert_that(DriftActions.drift_value(s)).is_equal_approx(4.5, 1e-4)
	assert_that(DriftActions.drift_tier(s)).is_equal(1)

func test_is_avatar_awakened_boundary() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(29.99)
	assert_that(DriftActions.is_avatar_awakened(s)).is_false()
	s.memory = BigNum.new(30.0)
	assert_that(DriftActions.is_avatar_awakened(s)).is_true()

func test_avatar_tier_text_matches_tier() -> void:
	var s := GameState.new()
	s.plundered["human"] = 18  # tier 3
	assert_that(DriftActions.avatar_tier_text(s)).is_equal(AvatarTiers.tier_text(3))

func test_can_intimate_requires_relation_and_awaken() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(40.0)
	s.relations["human"] = 1
	assert_that(DriftActions.can_intimate(s, &"human")).is_false()  # 关系不足
	s.relations["human"] = 2
	assert_that(DriftActions.can_intimate(s, &"human")).is_true()
	s.memory = BigNum.new(20.0)  # 未觉醒
	assert_that(DriftActions.can_intimate(s, &"human")).is_false()

func test_intimate_once_only() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(40.0)
	s.relations["human"] = 2
	var r := DriftActions.intimate(s, &"human")
	assert_that(r.get("ok", false)).is_true()
	assert_that(str(r.get("text", "")).length()).is_greater(20)
	assert_that(s.intimate_events).contains(&"human")
	var again := DriftActions.intimate(s, &"human")
	assert_that(again.get("ok", false)).is_false()

func test_unknown_race_cannot_trigger_intimate_event() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(40.0)
	s.relations["unknown"] = 3.0
	assert_that(DriftActions.can_intimate(s, &"unknown")).is_false()
	var before := s.intimate_events.duplicate()
	assert_that(DriftActions.intimate(s, &"unknown").get("ok", false)).is_false()
	assert_that(s.intimate_events).is_equal(before)

func test_drift_extra_adds_to_pure_state() -> void:
	var s := GameState.new()
	s.drift_extra = 1.0
	assert_that(DriftActions.drift_value(s)).is_equal_approx(1.0, 1e-4)
	assert_that(DriftActions.drift_tier(s)).is_equal(0)  # <3

func test_drift_extra_pushes_tier() -> void:
	var s := GameState.new()
	s.drift_extra = 4.0
	assert_that(DriftActions.drift_value(s)).is_equal_approx(4.0, 1e-4)
	assert_that(DriftActions.drift_tier(s)).is_equal(1)  # ≥3

func test_drift_extra_clamped_at_max() -> void:
	var s := GameState.new()
	s.plundered["human"] = 20  # 20×0.5 = 10（已满）
	s.drift_extra = 3.0
	assert_that(DriftActions.drift_value(s)).is_equal_approx(10.0, 1e-4)  # clamp 不溢出
