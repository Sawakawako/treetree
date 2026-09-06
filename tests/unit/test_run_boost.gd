extends GdUnitTestSuite

func test_no_boost_below_run3() -> void:
	var s := GameState.new()
	s.run_number = 2
	RunBoost.apply_boost(s)
	assert_that(float(s.sap.to_value())).is_equal_approx(0.0, 1e-4)
	assert_that(s.lingua_life_level).is_equal(0)

func test_boost_run3_gives_headstart() -> void:
	var s := GameState.new()
	s.run_number = 3
	RunBoost.apply_boost(s)
	assert_that(s.sap.to_value()).is_greater(0.0)
	assert_that(s.memory.to_value()).is_greater(0.0)
	assert_that(s.faith.to_value()).is_greater(0.0)
	assert_that(s.growth.to_value()).is_greater(0.0)

# —— 补充断言（brief 之外自审加强）：等级与明选 flag 赠予锁定 ——

func test_boost_run3_raises_levels_and_flags() -> void:
	var s := GameState.new()
	s.run_number = 3
	RunBoost.apply_boost(s)
	assert_that(s.leaf_level).is_equal(RunBoost.BOOST_LEAF)
	assert_that(s.root_depth).is_equal(RunBoost.BOOST_ROOT)
	assert_that(s.lingua_life_level).is_equal(RunBoost.BOOST_LIFE_LV)
	for f: StringName in RunBoost.BOOST_FLAGS:
		assert_that(s.choice_flags).contains(f)

func test_boost_run3_keeps_higher_existing_levels_and_dedupes_flags() -> void:
	# maxi 语义：已有更高等级不降；flag 已存在（周目保留）不重复 append
	var s := GameState.new()
	s.run_number = 3
	s.leaf_level = 9
	s.root_depth = 9
	s.lingua_life_level = 9
	s.choice_flags.assign(RunBoost.BOOST_FLAGS)
	RunBoost.apply_boost(s)
	assert_that(s.leaf_level).is_equal(9)
	assert_that(s.root_depth).is_equal(9)
	assert_that(s.lingua_life_level).is_equal(9)
	assert_that(s.choice_flags.size()).is_equal(RunBoost.BOOST_FLAGS.size())
