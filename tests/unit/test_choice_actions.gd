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

# ---------- 后果执行 ----------

func _ready_choice(state: GameState) -> void:
	_awaken(state, &"human")
	_awaken(state, &"forestfolk")
	state.memory = BigNum.new(40.0)
	state.faith = BigNum.new(200.0)
	state.growth = BigNum.new(1000.0)
	state.soul_river = 98

func test_resolve_human_nightmare_a() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	# A 采梦：memory+3 truth+1 relation-2 memory_eff 0.7
	var r := ChoiceActions.resolve(s, &"human_nightmare", &"a")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.memory.to_value()).is_equal_approx(3.0, 1e-4)
	assert_that(s.truth).is_equal(1)
	assert_that(int(s.relations["human"])).is_equal(-2)
	assert_that(float(s.race_memory_eff["human"])).is_equal_approx(0.7, 1e-4)
	assert_that(s.choices_done).contains(&"human_nightmare")
	assert_that(str(r.get("result_text", "")).length()).is_greater(5)

func test_resolve_marks_done_and_blocks_rechoose() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	assert_that(ChoiceActions.resolve(s, &"human_nightmare", &"b").get("ok", false)).is_true()
	# 已 done：再次 resolve 失败
	assert_that(ChoiceActions.resolve(s, &"human_nightmare", &"a").get("ok", false)).is_false()

func test_resolve_odin_b_drift_and_memory() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(30.0)
	var r := ChoiceActions.resolve(s, &"odin_sacrifice", &"b")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.memory.to_value()).is_equal_approx(36.0, 1e-4)
	assert_that(s.drift_extra).is_equal_approx(1.0, 1e-4)
	assert_that(s.choice_flags).contains(&"odin_name")

func test_resolve_odin_a_growth_pct() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(30.0)
	s.growth = BigNum.new(1000.0)
	var r := ChoiceActions.resolve(s, &"odin_sacrifice", &"a")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.growth.to_value()).is_equal_approx(700.0, 1e-4)  # -30%
	assert_that(s.truth).is_equal(2)

func test_resolve_norne_now_a_soul_operation() -> void:
	var s := GameState.new()
	_awaken(s, &"forestfolk")
	s.memory = BigNum.new(40.0)
	s.soul_river = 98
	var r := ChoiceActions.resolve(s, &"norne_now", &"a")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.soul_river).is_equal(96)  # -2 缕
	assert_that(float(s.races["forestfolk"]["population"])).is_equal_approx(53.0, 1e-4)  # 50+3
	assert_that(int(s.relations["forestfolk"])).is_equal(1)
	assert_that(s.choice_flags).contains(&"norne_now_saved")

func test_resolve_norne_now_b_let_go() -> void:
	var s := GameState.new()
	_awaken(s, &"forestfolk")
	s.memory = BigNum.new(40.0)
	var r := ChoiceActions.resolve(s, &"norne_now", &"b")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.soul_river).is_equal(100)  # 无变化
	assert_that(int(s.relations["forestfolk"])).is_equal(-1)
	assert_that(s.choice_flags).contains(&"norne_now_let_go")

func test_resolve_dodder_a_faith_pct_relation() -> void:
	var s := GameState.new()
	s.plundered["forestfolk"] = 1
	s.faith = BigNum.new(200.0)
	var r := ChoiceActions.resolve(s, &"dodder", &"a")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.faith.to_value()).is_equal_approx(140.0, 1e-4)  # -30%
	assert_that(int(s.relations["forestfolk"])).is_equal(3)
	assert_that(s.choice_flags).contains(&"dodder_released")

func test_resolve_theseus_b_four_race_relations() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(30.0)
	var r := ChoiceActions.resolve(s, &"theseus", &"b")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.drift_extra).is_equal_approx(1.0, 1e-4)
	for rid in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(int(s.relations[rid])).is_equal(1)
	assert_that(s.choice_flags).contains(&"theseus_uncertain")

func test_resolve_theseus_c_requires_unlock() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(30.0)
	s.insight = 7
	assert_that(ChoiceActions.resolve(s, &"theseus", &"c").get("ok", false)).is_false()  # 门槛不够
	s.insight = 8
	var r := ChoiceActions.resolve(s, &"theseus", &"c")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.insight).is_equal(10)  # +2
	assert_that(s.truth).is_equal(1)
	assert_that(s.choice_flags).contains(&"theseus_remembered")

func test_resolve_before_trigger_fails() -> void:
	var s := GameState.new()  # 人未醒
	assert_that(ChoiceActions.resolve(s, &"human_nightmare", &"a").get("ok", false)).is_false()
	assert_that(s.choices_done.is_empty()).is_true()