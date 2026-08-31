extends GdUnitTestSuite

func test_small_numbers() -> void:
	assert_that(Formatter.format_number(BigNum.new(0.0))).is_equal("0")
	assert_that(Formatter.format_number(BigNum.new(12.5))).is_equal("12.5")
	assert_that(Formatter.format_number(BigNum.new(999.0))).is_equal("999")

func test_suffix_numbers() -> void:
	assert_that(Formatter.format_number(BigNum.new(1234.5))).is_equal("1.23K")
	assert_that(Formatter.format_number(BigNum.new(1234567.0))).is_equal("1.23M")
	assert_that(Formatter.format_number(BigNum.new(5702887.0))).is_equal("5.7M")

func test_cost_format() -> void:
	assert_that(Formatter.format_cost(500)).is_equal("500")
	assert_that(Formatter.format_cost(5000)).is_equal("5,000")
	assert_that(Formatter.format_cost(5702887)).is_equal("5,702,887")

func test_small_fraction() -> void:
	assert_that(Formatter.format_number(BigNum.new(0.5))).is_equal("0.5")
	assert_that(Formatter.format_number(BigNum.new(0.005))).is_equal("0.005")

func test_carry_rounding() -> void:
	assert_that(Formatter.format_number(BigNum.new(999999.0))).is_equal("1M")
	assert_that(Formatter.format_number(BigNum.new(999999999.0))).is_equal("1B")

func test_negative_carry_rounding() -> void:
	assert_that(Formatter.format_number(BigNum.new(-999999.0))).is_equal("-1M")
