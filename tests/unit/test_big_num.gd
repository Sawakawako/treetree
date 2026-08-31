extends GdUnitTestSuite

# 注：GdUnit4 6.2.1 的 is_equal_approx 签名是 (expected, approx) 双参数，
# 故按 brief 逐字写测试时需补容差参数（1e-4），详见 task-2-report.md。

func test_zero() -> void:
    var bn := BigNum.new(0.0)
    assert_that(bn.to_value()).is_equal(0.0)

func test_initialization_normalizes() -> void:
    var bn := BigNum.new(1234.5)
    assert_that(bn.mantissa).is_equal_approx(1.2345, 1e-4)
    assert_that(bn.exponent).is_equal(3)
    assert_that(bn.to_value()).is_equal_approx(1234.5, 1e-4)

func test_add_with_carry() -> void:
    var a := BigNum.new(9.5)
    var b := BigNum.new(0.8)
    a.add(b)
    assert_that(a.to_value()).is_equal_approx(10.3, 1e-4)
    assert_that(a.exponent).is_equal(1)

func test_sub() -> void:
    var a := BigNum.new(500.0)
    var b := BigNum.new(499.0)
    a.sub(b)
    assert_that(a.to_value()).is_equal_approx(1.0, 1e-4)

func test_mul_scalar() -> void:
    var a := BigNum.new(1234.0)
    var c := a.mul_scalar(0.1)
    assert_that(c.to_value()).is_equal_approx(123.4, 1e-4)
    assert_that(a.to_value()).is_equal_approx(1234.0, 1e-4)

func test_compare() -> void:
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(998.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(999.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(1000.0))).is_false()
    assert_that(BigNum.new(1e9).is_greater_or_equal(BigNum.new(9e8))).is_true()

func test_serialization_roundtrip() -> void:
    var bn := BigNum.new(5702887.0)
    var back := BigNum.from_dict(bn.to_dict())
    assert_that(back.to_value()).is_equal_approx(5702887.0, 1e-4)
