extends GdUnitTestSuite

func _awaken_wildfolk(state: GameState) -> void:
	state.races["wildfolk"] = {"awakened": true, "population": 80.0}

func test_visible_stage_zero_when_wildfolk_sleeping() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(50.0)
	assert_that(TotemActions.visible_stage(s)).is_equal(0)

func test_visible_stage_bounds() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(3.99)
	assert_that(TotemActions.visible_stage(s)).is_equal(1)  # 幅 1 阈值 0
	s.memory = BigNum.new(4.0)
	assert_that(TotemActions.visible_stage(s)).is_equal(2)
	s.memory = BigNum.new(10.0)
	assert_that(TotemActions.visible_stage(s)).is_equal(3)
	s.memory = BigNum.new(35.0)
	assert_that(TotemActions.visible_stage(s)).is_equal(5)

func test_can_interpret_not_revealed() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(4.0)
	assert_that(TotemActions.can_interpret(s, 5)).is_false()  # 幅 5 未浮现

func test_can_interpret_revealed() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(4.0)
	assert_that(TotemActions.can_interpret(s, 2)).is_true()

func test_can_interpret_after_interpreted() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(35.0)
	s.totem_interpreted.assign([1, 2, 3, 4, 5])
	assert_that(TotemActions.can_interpret(s, 5)).is_false()

func test_interpret_gives_insight() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(4.0)
	var r := TotemActions.interpret(s, 2)
	assert_that(r.get("ok", false)).is_true()
	assert_that(int(r.get("insight", 0))).is_equal(1)
	assert_that(str(r.get("text", "")).length()).is_greater(5)
	assert_that(s.insight).is_equal(1)
	assert_that(s.totem_interpreted).contains(2)

func test_interpret_idempotent() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(4.0)
	TotemActions.interpret(s, 2)
	var again := TotemActions.interpret(s, 2)
	assert_that(again.get("ok", false)).is_false()
	assert_that(s.insight).is_equal(1)  # 不重复 +1

func test_interpret_not_revealed() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(4.0)
	assert_that(TotemActions.interpret(s, 5).get("ok", false)).is_false()

func test_next_interpretable() -> void:
	var s := GameState.new()
	_awaken_wildfolk(s)
	s.memory = BigNum.new(10.0)  # 幅 1-3 可见
	s.totem_interpreted.assign([1, 2])
	assert_that(TotemActions.next_interpretable(s)).is_equal(3)  # 最新未解读
	s.totem_interpreted.assign([1, 2, 3])
	assert_that(TotemActions.next_interpretable(s)).is_equal(0)  # 全解读完
