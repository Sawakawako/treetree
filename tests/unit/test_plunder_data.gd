extends GdUnitTestSuite

func test_data_covers_four_races() -> void:
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(PlunderData.get_data(expected).is_empty()).is_false()

func test_yields() -> void:
	assert_that(float(PlunderData.get_data(&"human").get("yield", -1.0))).is_equal_approx(1.0, 1e-4)
	assert_that(float(PlunderData.get_data(&"forestfolk").get("yield", -1.0))).is_equal_approx(1.2, 1e-4)
	assert_that(float(PlunderData.get_data(&"wildfolk").get("yield", -1.0))).is_equal_approx(2.0, 1e-4)
	assert_that(float(PlunderData.get_data(&"stoneborn").get("yield", -1.0))).is_equal_approx(0.0, 1e-4)

func test_signal_pool_nonempty() -> void:
	for id in [&"human", &"forestfolk", &"wildfolk"]:
		var signals: Array = PlunderData.get_data(id).get("signals", [])
		assert_that(signals.size()).is_greater(0)

func test_signal_text_rotates() -> void:
	# 按 plundered 计数取模轮换——同一族不同计数给出信号池内文本
	var t0 := PlunderData.signal_text(&"human", 0)
	var t1 := PlunderData.signal_text(&"human", 1)
	var t2 := PlunderData.signal_text(&"human", 2)
	var t3 := PlunderData.signal_text(&"human", 3)  # 3 % 3 == 0，应回到 t0
	assert_that(str(t0).length()).is_greater(5)
	assert_that(t3).is_equal(t0)
	# 三个信号互不相同（池有 3 句）
	assert_that(t0).is_not_equal(t1)
	assert_that(t1).is_not_equal(t2)
	assert_that(t0).is_not_equal(t2)

func test_reveals_three_levels_for_dream_races() -> void:
	for id in [&"human", &"forestfolk", &"wildfolk"]:
		var reveals: Array = PlunderData.get_data(id).get("reveals", [])
		assert_that(reveals.size()).is_equal(3)
	# 石裔无揭示
	assert_that(PlunderData.get_data(&"stoneborn").get("reveals", []).size()).is_equal(0)

func test_get_missing_returns_empty() -> void:
	assert_that(PlunderData.get_data(&"nobody").is_empty()).is_true()