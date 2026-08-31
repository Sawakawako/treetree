extends GdUnitTestSuite

func test_fib_first_terms() -> void:
	assert_that(CostCalculator.fib(1)).is_equal(1)
	assert_that(CostCalculator.fib(2)).is_equal(1)
	assert_that(CostCalculator.fib(3)).is_equal(2)
	assert_that(CostCalculator.fib(4)).is_equal(3)
	assert_that(CostCalculator.fib(5)).is_equal(5)
	assert_that(CostCalculator.fib(6)).is_equal(8)

func test_fib_34_is_easter_egg_number() -> void:
	assert_that(CostCalculator.fib(34)).is_equal(5702887)

func test_leaf_cost() -> void:
	assert_that(CostCalculator.leaf_cost(0)).is_equal(500)
	assert_that(CostCalculator.leaf_cost(1)).is_equal(500)
	assert_that(CostCalculator.leaf_cost(2)).is_equal(1000)
	assert_that(CostCalculator.leaf_cost(3)).is_equal(1500)

func test_branch_cost() -> void:
	assert_that(CostCalculator.branch_cost(0)).is_equal(1200)
	assert_that(CostCalculator.branch_cost(1)).is_equal(1200)
	assert_that(CostCalculator.branch_cost(2)).is_equal(2400)
