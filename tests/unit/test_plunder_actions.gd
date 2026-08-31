extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
	state.races[id] = {"awakened": true, "population": 50.0}

func test_can_plunder_requires_awakened() -> void:
	var s := GameState.new()
	assert_that(PlunderActions.can_plunder(s, &"human")).is_false()
	_awaken(s, &"human")
	assert_that(PlunderActions.can_plunder(s, &"human")).is_true()

func test_plunder_yields_memory() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	var r := PlunderActions.plunder(s, &"human")
	assert_that(r.get("ok", false)).is_true()
	assert_that(float(r.get("memory", 0.0))).is_equal_approx(1.0, 1e-4)
	assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)
	assert_that(PlunderActions.count(s, &"human")).is_equal(1)
	assert_that(str(r.get("text", "")).length()).is_greater(5)

func test_stoneborn_no_memory_no_counter() -> void:
	var s := GameState.new()
	_awaken(s, &"stoneborn")
	var r := PlunderActions.plunder(s, &"stoneborn")
	assert_that(r.get("ok", false)).is_true()
	assert_that(float(r.get("memory", -1.0))).is_equal_approx(0.0, 1e-4)
	assert_that(PlunderActions.count(s, &"stoneborn")).is_equal(0)  # 无梦可夺，不涨
	assert_that(str(r.get("text", "")).contains("没有梦")).is_true()

func test_reveal_stage_thresholds() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.plundered["human"] = 2
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(0)
	s.plundered["human"] = 3
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(1)
	s.plundered["human"] = 6
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(2)
	s.plundered["human"] = 9
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(3)

func test_reveal_applies_relation_penalty() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.relations["human"] = 2
	for i in 3:
		PlunderActions.plunder(s, &"human")
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(1)
	assert_that(s.relations["human"]).is_equal(1)  # 关系 -1
	assert_that(s.plunder_reveals).contains(&"human")
	# 揭示文本（revealed=true 的那次）
	var last := PlunderActions.plunder(s, &"human")  # 第 4 次，正常信号
	assert_that(bool(last.get("revealed", false))).is_false()

func test_reveal_only_once_per_stage() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.relations["human"] = 2
	for i in 6:
		PlunderActions.plunder(s, &"human")
	assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(2)
	assert_that(s.relations["human"]).is_equal(0)  # -1 两次 = 累计 -2
	assert_that(PlunderActions.is_frozen(s, &"human")).is_true()

func test_wildfolk_population_loss_once() -> void:
	var s := GameState.new()
	_awaken(s, &"wildfolk")  # pop 50
	s.races["wildfolk"]["population"] = 100.0
	for i in 3:
		PlunderActions.plunder(s, &"wildfolk")
	# 1 级揭示：人口 -20%（100 → 80）
	assert_that(float(s.races["wildfolk"]["population"])).is_equal_approx(80.0, 1e-4)
	for i in 3:
		PlunderActions.plunder(s, &"wildfolk")
	# 2 级揭示：不再扣（仅 1 级一次性）
	assert_that(float(s.races["wildfolk"]["population"])).is_equal_approx(80.0, 1e-4)

func test_memory_yield_varied() -> void:
	var s := GameState.new()
	_awaken(s, &"wildfolk")
	PlunderActions.plunder(s, &"wildfolk")
	assert_that(s.memory.to_value()).is_equal_approx(2.0, 1e-4)  # 野民 +2
	var s2 := GameState.new()
	_awaken(s2, &"forestfolk")
	PlunderActions.plunder(s2, &"forestfolk")
	assert_that(s2.memory.to_value()).is_equal_approx(1.2, 1e-4)  # 林地民 +1.2

func test_plunder_reveals_set_semantics() -> void:
	# 防回归：夺梦 9 次触发 3 级揭示，plunder_reveals 每族至多一条（集合语义）
	var s := GameState.new()
	_awaken(s, &"human")
	for i in 9:
		PlunderActions.plunder(s, &"human")
	assert_that(s.plunder_reveals.size()).is_equal(1)

func test_root_eff_boosts_plunder() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.root_eff_level = 1
	var r := PlunderActions.plunder(s, &"human")
	assert_that(float(r.get("memory", 0.0))).is_equal_approx(1.1, 1e-4)  # 1.0×1.1
	assert_that(s.memory.to_value()).is_equal_approx(1.1, 1e-4)