extends GdUnitTestSuite

func test_faith_engine_cost_formula() -> void:
	assert_that(CostCalculator.faith_engine_cost(0)).is_equal(200)   # 200×fib(1)=200×1
	assert_that(CostCalculator.faith_engine_cost(1)).is_equal(200)   # 200×fib(2)=200×1
	assert_that(CostCalculator.faith_engine_cost(2)).is_equal(400)   # 200×fib(3)=200×2

func test_memory_engine_cost_formula() -> void:
	assert_that(CostCalculator.memory_engine_cost(0)).is_equal(500)
	assert_that(CostCalculator.memory_engine_cost(1)).is_equal(500)
	assert_that(CostCalculator.memory_engine_cost(2)).is_equal(1000)

func test_buy_faith_engine_requires_cloud_crown() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(2000.0)
	assert_that(GameActions.buy_faith_engine(s)).is_false()  # 无云冠节点
	s.lingua_nodes.assign([&"cloud_crown"])
	assert_that(GameActions.buy_faith_engine(s)).is_true()
	assert_that(s.faith_engine_level).is_equal(1)
	assert_that(s.faith.to_value()).is_equal_approx(1800.0, 1e-4)  # 2000-200

func test_buy_faith_engine_insufficient() -> void:
	var s := GameState.new()
	s.lingua_nodes.assign([&"cloud_crown"])
	s.faith = BigNum.new(199.0)
	assert_that(GameActions.buy_faith_engine(s)).is_false()
	assert_that(s.faith_engine_level).is_equal(0)

func test_buy_memory_engine_requires_grace() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(5000.0)
	assert_that(GameActions.buy_memory_engine(s)).is_false()
	s.lingua_nodes.assign([&"grace"])
	assert_that(GameActions.buy_memory_engine(s)).is_true()
	assert_that(s.memory_engine_level).is_equal(1)
	assert_that(s.memory.to_value()).is_equal_approx(4500.0, 1e-4)  # 5000-500