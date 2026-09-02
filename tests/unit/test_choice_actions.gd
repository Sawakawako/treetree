extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
	state.races[id] = {"awakened": true, "population": 50.0}

func test_trigger_races_awakened() -> void:
	var s := GameState.new()
	var tr := {"races_awakened": ["human"]}
	assert_that(ChoiceActions._trigger_met(s, tr)).is_false()
	_awaken(s, &"human")
	assert_that(ChoiceActions._trigger_met(s, tr)).is_true()

func test_trigger_memory_gte() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(29.0)
	assert_that(ChoiceActions._trigger_met(s, {"memory_gte": 30.0})).is_false()
	s.memory = BigNum.new(30.0)
	assert_that(ChoiceActions._trigger_met(s, {"memory_gte": 30.0})).is_true()

func test_trigger_faith_growth_insight() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(100.0)
	s.growth = BigNum.new(500.0)
	s.insight = 8
	assert_that(ChoiceActions._trigger_met(s, {"faith_gte": 100.0, "growth_gte": 500.0, "insight_gte": 8})).is_true()
	assert_that(ChoiceActions._trigger_met(s, {"faith_gte": 101.0})).is_false()

func test_trigger_relation_plundered() -> void:
	var s := GameState.new()
	s.relations["human"] = 2
	s.plundered["forestfolk"] = 1
	assert_that(ChoiceActions._trigger_met(s, {"relation_gte": {"human": 2}})).is_true()
	assert_that(ChoiceActions._trigger_met(s, {"relation_gte": {"human": 3}})).is_false()
	assert_that(ChoiceActions._trigger_met(s, {"plundered_gte": {"forestfolk": 1}})).is_true()

func test_trigger_soul_conditions() -> void:
	var s := GameState.new()
	assert_that(ChoiceActions._trigger_met(s, {"soul_revived": true})).is_false()  # river 100 未复活过
	s.soul_river = 99
	assert_that(ChoiceActions._trigger_met(s, {"soul_revived": true})).is_true()
	assert_that(ChoiceActions._trigger_met(s, {"soul_river_lte": 98})).is_false()
	s.soul_river = 88
	assert_that(ChoiceActions._trigger_met(s, {"soul_river_lte": 98})).is_true()

func test_trigger_multiple_all_and() -> void:
	var s := GameState.new()
	_awaken(s, &"forestfolk")
	s.memory = BigNum.new(30.0)
	var tr := {"memory_gte": 30.0, "races_awakened": ["forestfolk"]}
	assert_that(ChoiceActions._trigger_met(s, tr)).is_true()
	s.memory = BigNum.new(29.0)
	assert_that(ChoiceActions._trigger_met(s, tr)).is_false()

func test_available_excludes_done() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(30.0)
	assert_that(s.choices_done.is_empty()).is_true()
	var avail := ChoiceActions.available(s)
	assert_that(avail.size()).is_equal(3)  # human_nightmare + odin_sacrifice + theseus
	assert_that(avail).contains(&"human_nightmare")
	assert_that(avail).contains(&"odin_sacrifice")
	assert_that(avail).contains(&"theseus")

func test_first_available_returns_json_order() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(30.0)
	assert_that(ChoiceActions.first_available(s)).is_equal(&"human_nightmare")  # 数组序第一条

func test_first_available_empty() -> void:
	var s := GameState.new()
	assert_that(ChoiceActions.first_available(s)).is_equal(&"")

func test_can_choose_after_done_false() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.choices_done.assign([&"human_nightmare"])
	assert_that(ChoiceActions.can_choose(s, &"human_nightmare")).is_false()

func test_can_choose_before_trigger_false() -> void:
	var s := GameState.new()  # 人未醒
	assert_that(ChoiceActions.can_choose(s, &"human_nightmare")).is_false()

func test_option_unlocked_no_gate_always_true() -> void:
	var s := GameState.new()
	assert_that(ChoiceActions.option_unlocked(s, &"human_nightmare", &"a")).is_true()

func test_option_unlocked_insight_gate() -> void:
	var s := GameState.new()
	s.insight = 7
	assert_that(ChoiceActions.option_unlocked(s, &"theseus", &"c")).is_false()
	s.insight = 8
	assert_that(ChoiceActions.option_unlocked(s, &"theseus", &"c")).is_true()