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
