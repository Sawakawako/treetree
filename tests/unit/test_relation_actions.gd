extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
	state.races[id] = {"awakened": true, "population": 50.0}

func test_get_relation_default_zero() -> void:
	var s := GameState.new()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal(0)

func test_apply_change_clamps() -> void:
	var s := GameState.new()
	assert_that(RelationActions.apply_change(s, &"human", 5)).is_equal(3)
	assert_that(RelationActions.apply_change(s, &"human", -8)).is_equal(-3)
	assert_that(RelationActions.apply_change(s, &"human", 1)).is_equal(-2)

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
	assert_that(int(r.get("relation", 0))).is_equal(1)
	assert_that(str(r.get("text", "")).length()).is_greater(10)
	assert_that(s.relations["human"]).is_equal(1)
	assert_that(s.relation_events).contains(&"human")

func test_interact_idempotent() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	RelationActions.interact(s, &"human")
	var again := RelationActions.interact(s, &"human")
	assert_that(again.get("ok", false)).is_false()
	assert_that(s.relations["human"]).is_equal(1)  # 不重复 +1

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
