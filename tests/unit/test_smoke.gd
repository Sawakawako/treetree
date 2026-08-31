# tests/unit/test_smoke.gd
extends GdUnitTestSuite

func test_gdunit_works() -> void:
	assert_that(1 + 1).is_equal(2)
