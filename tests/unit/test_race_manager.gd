extends GdUnitTestSuite

func test_registry_four_races() -> void:
	assert_that(RaceManager.all_races().size()).is_equal(4)
	assert_that(RaceManager.get_race(&"human")).is_not_null()
	assert_that(RaceManager.get_race(&"wildfolk")).is_not_null()

func test_human_awaken_at_memory_2() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(2.0)
	var race := RaceManager.get_race(&"human")
	assert_that(RaceManager.check_awaken(s, race)).is_true()
	assert_that(s.races["human"]["awakened"]).is_true()
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.0, 1e-4)
	# 幂等：已唤醒不再触发
	assert_that(RaceManager.check_awaken(s, race)).is_false()

func test_human_not_awaken_below_2() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(1.99)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"human"))).is_false()

func test_forestfolk_awaken_at_faith_30() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(30.0)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"forestfolk"))).is_true()
	assert_that(float(s.races["forestfolk"]["population"])).is_equal_approx(30.0, 1e-4)

func test_forestfolk_not_awaken_below_30() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(29.9)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"forestfolk"))).is_false()

func test_stoneborn_wildfolk_thresholds() -> void:
	var s1 := GameState.new()
	s1.faith = BigNum.new(60.0)
	assert_that(RaceManager.check_awaken(s1, RaceManager.get_race(&"stoneborn"))).is_true()
	var s2 := GameState.new()
	s2.faith = BigNum.new(100.0)
	assert_that(RaceManager.check_awaken(s2, RaceManager.get_race(&"wildfolk"))).is_true()

func _awaken(state: GameState, id: StringName) -> void:
	# 直接注册唤醒（初始人口），不依赖 check_awaken 的资源条件：
	# brief 数值断言假设已唤醒（如 human pop 50），默认 GameState(memory=0/faith=0) 无法满足唤醒条件
	var race := RaceManager.get_race(id)
	state.races[id] = {"awakened": true, "population": race.awaken_pop}

func test_support_deducted() -> void:
	var s := GameState.new()
	_awaken(s, &"human")  # pop 50 × 0.002 = 0.1
	s.sap = BigNum.new(10.0)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(9.9, 1e-4)

func test_support_clamps_at_zero() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.sap = BigNum.new(0.05)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_logistic_growth() -> void:
	var s := GameState.new()
	_awaken(s, &"human")  # pop 50, rate 0.01, cap 100
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	# 50 + 50×0.01×(1−50/100) = 50.25
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.25, 1e-4)

func test_growth_frozen_when_sap_zero() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.sap = BigNum.new(0.0)
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.0, 1e-4)

func test_growth_capped_at_capacity() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.growth = BigNum.new(100.0)  # cap 200
	s.sap = BigNum.new(1000.0)
	s.races["human"]["population"] = 199.0
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_less_equal(200.0)

func test_faith_production() -> void:
	var s := GameState.new()
	_awaken(s, &"human")      # 增长后 pop 50.25 → 50.25×1.0×0.002 = 0.1005
	_awaken(s, &"forestfolk") # 增长后 pop 30.126 → 30.126×1.8×0.002 = 0.1084536
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	assert_that(s.faith.to_value()).is_equal_approx(0.2089536, 1e-4)

func test_memory_production_human_only() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	_awaken(s, &"forestfolk")
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	# 人族增长后 50.25 × 0.001 = 0.05025；林地民不产记忆
	assert_that(s.memory.to_value()).is_equal_approx(0.05025, 1e-4)

func test_stoneborn_craft_sap() -> void:
	var s := GameState.new()
	_awaken(s, &"stoneborn")  # pop 20 → 增长后 20.08；供养 0.06；献工 20.08×0.01=0.2008
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(100.1408, 1e-4)  # 100 − 0.06 + 0.2008

func test_capacity_growth_mapping() -> void:
	var s := GameState.new()
	s.growth = BigNum.new(99.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(100.0, 1e-4)
	s.growth = BigNum.new(100.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(200.0, 1e-4)
	s.growth = BigNum.new(300.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(300.0, 1e-4)

func test_tick_returns_awaken_events() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(100.0)
	s.sap = BigNum.new(1000.0)
	var events: Array[Dictionary] = RaceManager.tick_races(s)
	assert_that(events.size()).is_equal(3)  # 林地民/石裔/野民同 tick 苏醒
	assert_that(events[0].has("race_name")).is_true()
	assert_that(str(events[0]["awaken_text"]).length()).is_greater(10)

func test_frozen_race_does_not_grow() -> void:
	# 夺梦揭示后（plundered >= 3）该族人口冻结
	var s := GameState.new()
	_awaken(s, &"human")
	s.races["human"]["population"] = 50.0
	s.plundered["human"] = 3  # 揭示 1 级 → 冻结
	s.sap = BigNum.new(1000.0)
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.0, 1e-4)  # 不增长

func test_non_frozen_race_grows() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.races["human"]["population"] = 50.0
	s.sap = BigNum.new(1000.0)
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_greater(50.0)  # 正常增长
