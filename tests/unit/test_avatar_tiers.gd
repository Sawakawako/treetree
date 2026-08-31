extends GdUnitTestSuite

func test_four_tiers() -> void:
	assert_that(AvatarTiers.TIERS.size()).is_equal(4)

func test_tiers_cover_drift_range() -> void:
	# 档位区间连续覆盖 0-10 且不重叠
	var prev_max := 0.0
	for t in AvatarTiers.TIERS:
		var min_v := float(t.get("min", -1.0))
		var max_v := float(t.get("max", -1.0))
		assert_that(min_v).is_equal_approx(prev_max, 1e-4)
		prev_max = max_v
	assert_that(prev_max).is_equal_approx(10.0, 1e-4)

func test_tier_text_returns_text() -> void:
	for i in 4:
		assert_that(str(AvatarTiers.tier_text(i)).length()).is_greater(5)

func test_tier_text_out_of_range_empty() -> void:
	assert_that(AvatarTiers.tier_text(9)).is_equal("")
	assert_that(AvatarTiers.tier_text(-1)).is_equal("")