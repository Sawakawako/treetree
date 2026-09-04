extends GdUnitTestSuite

const MainUi = preload("res://features/ui/main.gd")

func test_half_step_relation_display() -> void:
	assert_that(MainUi.relation_label(0.5)).is_equal("友善")
	assert_that(MainUi.relation_label(1.5)).is_equal("友善")
	assert_that(MainUi.relation_label(2.5)).is_equal("亲近")
	assert_that(MainUi.format_relation(0.5)).is_equal("+0.5")
	assert_that(MainUi.format_relation(-1.5)).is_equal("-1.5")

func test_relation_display_boundaries() -> void:
	assert_that(MainUi.relation_label(-3.0)).is_equal("敌意")
	assert_that(MainUi.relation_label(-0.5)).is_equal("冷淡")
	assert_that(MainUi.relation_label(0.0)).is_equal("平常")
	assert_that(MainUi.relation_label(2.0)).is_equal("亲近")
	assert_that(MainUi.relation_label(3.0)).is_equal("挚友")
