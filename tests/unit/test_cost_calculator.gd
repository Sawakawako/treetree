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

func test_chloroplast_cost_exponential() -> void:
	assert_that(CostCalculator.chloroplast_cost(0)).is_equal(800)
	assert_that(CostCalculator.chloroplast_cost(1)).is_equal(1280)   # 800×1.6
	assert_that(CostCalculator.chloroplast_cost(2)).is_equal(2048)   # 800×1.6²

func test_xylem_cost_linear() -> void:
	assert_that(CostCalculator.xylem_cost(0)).is_equal(50)
	assert_that(CostCalculator.xylem_cost(1)).is_equal(100)
	assert_that(CostCalculator.xylem_cost(2)).is_equal(150)

func test_sunflower_cost_fibonacci() -> void:
	assert_that(CostCalculator.sunflower_cost(0)).is_equal(2000)    # 2000×fib(1)
	assert_that(CostCalculator.sunflower_cost(1)).is_equal(2000)    # 2000×fib(2)
	assert_that(CostCalculator.sunflower_cost(2)).is_equal(4000)    # 2000×fib(3)

func test_nautilus_cost_fibonacci() -> void:
	assert_that(CostCalculator.nautilus_cost(0)).is_equal(2000)
	assert_that(CostCalculator.nautilus_cost(2)).is_equal(4000)

func test_root_eff_cost_exponential() -> void:
	assert_that(CostCalculator.root_eff_cost(0)).is_equal(1000)
	assert_that(CostCalculator.root_eff_cost(1)).is_equal(1800)     # 1000×1.8
	assert_that(CostCalculator.root_eff_cost(2)).is_equal(3240)     # 1000×1.8²

func test_m5d2_seedling_cost_linear() -> void:
	assert_that(CostCalculator.seedling_cost(0)).is_equal(10)
	assert_that(CostCalculator.seedling_cost(1)).is_equal(20)
	assert_that(CostCalculator.seedling_cost(2)).is_equal(30)

func test_m5d2_facility_costs_fib() -> void:
	assert_that(CostCalculator.firepit_cost(0)).is_equal(1000)   # 1000×fib(1)
	assert_that(CostCalculator.ring_cost(0)).is_equal(1000)
	assert_that(CostCalculator.forge_cost(0)).is_equal(1000)
	assert_that(CostCalculator.totem_pole_cost(0)).is_equal(1000)
	assert_that(CostCalculator.firepit_cost(2)).is_equal(2000)   # 1000×fib(3)=1000×2
