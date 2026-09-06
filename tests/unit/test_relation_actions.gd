extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
	state.races[id] = {"awakened": true, "population": 50.0}

func test_get_relation_default_zero() -> void:
	var s := GameState.new()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal_approx(0.0, 1e-4)

func test_apply_change_clamps() -> void:
	var s := GameState.new()
	assert_that(RelationActions.apply_change(s, &"human", 5.0)).is_equal_approx(3.0, 1e-4)
	assert_that(RelationActions.apply_change(s, &"human", -8.0)).is_equal_approx(-3.0, 1e-4)
	assert_that(RelationActions.apply_change(s, &"human", 0.5)).is_equal_approx(-2.5, 1e-4)

func test_apply_change_preserves_half_steps() -> void:
	var s := GameState.new()
	assert_that(RelationActions.apply_change(s, &"human", 0.5)).is_equal_approx(0.5, 1e-4)
	assert_that(RelationActions.apply_change(s, &"human", 1.5)).is_equal_approx(2.0, 1e-4)
	assert_that(RelationActions.get_relation(s, &"human")).is_equal_approx(2.0, 1e-4)

func test_is_intimate_boundary() -> void:
	var s := GameState.new()
	s.relations["human"] = 1
	assert_that(RelationActions.is_intimate(s, &"human")).is_false()
	s.relations["human"] = 2
	assert_that(RelationActions.is_intimate(s, &"human")).is_true()

func test_can_interact_requires_awakened() -> void:
	var s := GameState.new()  # 人族未醒
	s.memory = BigNum.new(10.0)
	assert_that(RelationActions.can_interact(s, &"human")).is_false()

func test_can_interact_requires_resource() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(3.99)  # 需记忆>=4
	assert_that(RelationActions.can_interact(s, &"human")).is_false()
	s.memory = BigNum.new(4.0)
	assert_that(RelationActions.can_interact(s, &"human")).is_true()

func test_can_interact_once_only() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	assert_that(RelationActions.interact(s, &"human").get("ok", false)).is_true()
	assert_that(RelationActions.can_interact(s, &"human")).is_false()

func test_interact_gives_relation_and_text() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	var r := RelationActions.interact(s, &"human")
	assert_that(r.get("ok", false)).is_true()
	assert_that(float(r.get("relation", 0.0))).is_equal_approx(0.5, 1e-4)
	assert_that(str(r.get("text", "")).length()).is_greater(10)
	assert_that(float(s.relations["human"])).is_equal_approx(0.5, 1e-4)
	assert_that(s.relation_events).contains(&"human")

func test_interact_idempotent() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	RelationActions.interact(s, &"human")
	var again := RelationActions.interact(s, &"human")
	assert_that(again.get("ok", false)).is_false()
	assert_that(float(s.relations["human"])).is_equal_approx(0.5, 1e-4)  # 不重复 +0.5

func test_stoneborn_requires_sap() -> void:
	var s := GameState.new()
	_awaken(s, &"stoneborn")
	s.sap = BigNum.new(299.0)
	assert_that(RelationActions.can_interact(s, &"stoneborn")).is_false()
	s.sap = BigNum.new(300.0)
	assert_that(RelationActions.can_interact(s, &"stoneborn")).is_true()

func test_wildfolk_requires_totem_stage() -> void:
	var s := GameState.new()
	_awaken(s, &"wildfolk")
	s.memory = BigNum.new(4.0)  # totem stage 2 需记忆>=4
	assert_that(RelationActions.can_interact(s, &"wildfolk")).is_true()
	s.memory = BigNum.new(3.99)
	assert_that(RelationActions.can_interact(s, &"wildfolk")).is_false()

func _awaken_run(state: GameState, id: StringName, run: int) -> void:
	state.races[id] = {"awakened": true, "population": 10.0}
	state.run_number = run

func test_run2_events_hidden_in_run1() -> void:
	for ev in RelationEvents.extra_events():
		var s := GameState.new()
		_awaken_run(s, StringName(str(ev.get("race_id", &""))), 1)
		s.sap = BigNum.new(9999.0)
		assert_that(RelationActions.can_interact_event(s, StringName(str(ev.get("event_id", &""))))).is_false()

func test_run2_events_available_in_run2() -> void:
	for ev in RelationEvents.extra_events():
		var s := GameState.new()
		_awaken_run(s, StringName(str(ev.get("race_id", &""))), 2)
		s.sap = BigNum.new(9999.0)
		s.memory = BigNum.new(9999.0)
		assert_that(RelationActions.can_interact_event(s, StringName(str(ev.get("event_id", &""))))).is_true()

func test_run2_event_gives_half_and_once() -> void:
	var s := GameState.new()
	_awaken_run(s, &"stoneborn", 2)
	s.sap = BigNum.new(9999.0)
	var first_ev := RelationEvents.extra_events()[0]
	var eid := StringName(str(first_ev.get("event_id", &"")))
	var r := RelationActions.interact_event(s, eid)
	assert_that(r.get("ok", false)).is_true()
	assert_that(float(r.get("relation", 0.0))).is_equal_approx(0.5, 1e-4)
	assert_that(s.relation_events).contains(eid)
	assert_that(RelationActions.can_interact_event(s, eid)).is_false()  # 一次性

func test_extra_events_count_six() -> void:
	assert_that(RelationEvents.extra_events().size()).is_equal(6)

func test_extra_events_only_stoneborn_wildfolk() -> void:
	for ev in RelationEvents.extra_events():
		var race := StringName(str(ev.get("race_id", &"")))
		assert_that(race == &"stoneborn" or race == &"wildfolk").is_true()
