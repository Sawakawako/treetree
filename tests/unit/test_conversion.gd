extends GdUnitTestSuite

func _ready_state() -> GameState:
	var s := GameState.new()
	s.lingua_nodes.assign([&"tree_canopy", &"root_resonance"])
	return s

func test_convert_sap_to_faith() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(250.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_true()
	assert_that(s.faith.to_value()).is_equal_approx(1.0, 1e-4)   # 100→1
	assert_that(s.sap.to_value()).is_equal_approx(150.0, 1e-4)

func test_convert_faith_repeatable() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(1000.0)
	GameActions.convert_sap_to_faith(s)
	GameActions.convert_sap_to_faith(s)
	assert_that(s.faith.to_value()).is_equal_approx(2.0, 1e-4)   # 可重复
	assert_that(s.sap.to_value()).is_equal_approx(800.0, 1e-4)

func test_convert_faith_requires_node() -> void:
	var s := GameState.new()  # 无 tree_canopy
	s.sap = BigNum.new(500.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_false()

func test_convert_faith_insufficient_sap() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(99.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_false()

func test_convert_sap_to_memory() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(1000.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_true()
	assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)  # 500→1
	assert_that(s.sap.to_value()).is_equal_approx(500.0, 1e-4)

func test_convert_memory_requires_node_strict() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(1000.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_false()  # 无 root_resonance

func test_convert_memory_insufficient() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(499.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_false()