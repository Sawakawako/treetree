extends GdUnitTestSuite

func _state_axis_ready() -> GameState:
	var s := GameState.new()
	s.growth = BigNum.new(1000.0)
	s.relics_found.append(9)
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.races[rid] = {"awakened": true, "population": 10.0}
	# 明选①—⑥ 完成（8 卡除 world_axis 外全做）
	for c in ChoiceLibrary.load_all():
		var cid := StringName(str(c.get("id", "")))
		if cid != &"world_axis":
			s.choices_done.append(cid)
	s.storyteller_stories.append(&"story_6")
	return s

func test_axis_not_ready_missing_relic() -> void:
	var s := _state_axis_ready()
	s.relics_found = []
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_not_ready_low_growth() -> void:
	var s := _state_axis_ready()
	s.growth = BigNum.new(999.0)
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_not_ready_missing_choice() -> void:
	var s := _state_axis_ready()
	s.choices_done.remove_at(0)
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_ready_when_all_met() -> void:
	var s := _state_axis_ready()
	assert_that(EndingStateMachine.axis_ready(s)).is_true()

func test_bad_when_no_insight_no_bonds() -> void:
	var s := _state_axis_ready()  # insight 0, relations 空
	var r := EndingStateMachine.resolve_ending(s, &"condense")
	assert_that(str(r.get("outcome", ""))).is_equal("bad")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)
	assert_that(s.ending_seen).contains(&"bad")

func test_normal_when_insight_no_bonds() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	var r := EndingStateMachine.resolve_ending(s, &"condense")
	assert_that(str(r.get("outcome", ""))).is_equal("normal")

func test_condense_stays_normal_even_with_full_bonds() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"condense")
	assert_that(str(r.get("outcome", ""))).is_equal("normal")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)

func test_bonds_require_all_three() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0
	s.relations[&"forestfolk"] = 3.0
	s.relations[&"stoneborn"] = 3.0
	s.relations[&"wildfolk"] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"return")
	assert_that(str(r.get("outcome", ""))).is_equal("good")
	assert_that(int(r.get("hope_after", 0))).is_equal(2)
	assert_that(s.ending_seen).contains(&"good")

func test_return_without_full_bonds_is_normal() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0  # 只一族满
	var r := EndingStateMachine.resolve_ending(s, &"return")
	assert_that(str(r.get("outcome", ""))).is_equal("normal")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)

func test_return_without_enough_insight_is_bad() -> void:
	var s := _state_axis_ready()
	s.insight = 9
	var r := EndingStateMachine.resolve_ending(s, &"return")
	assert_that(str(r.get("outcome", ""))).is_equal("bad")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)

func test_refuse_is_bad() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"refuse")
	assert_that(str(r.get("outcome", ""))).is_equal("bad")

func test_true_requires_run3_full_hope2() -> void:
	var s := _state_axis_ready()
	s.run_number = 3
	s.hope = 2
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"self")
	assert_that(str(r.get("outcome", ""))).is_equal("true")
	assert_that(s.ending_seen).contains(&"true")

func test_self_blocked_below_run3() -> void:
	var s := _state_axis_ready()
	s.run_number = 2
	s.hope = 2
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"self")
	assert_that(r.get("ok", false)).is_false()  # 三周目前 d 不亮不可选

func test_true_consumes_all_hope() -> void:
	var s := _state_axis_ready()
	s.run_number = 3
	s.hope = 3  # 跨周目可达状态（多周目各拿一次好结局）
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"self")
	assert_that(str(r.get("outcome", ""))).is_equal("true")
	assert_that(int(r.get("hope_after", -1))).is_equal(0)  # 真结局清零（裁决语义）
	assert_that(int(s.hope)).is_equal(0)
