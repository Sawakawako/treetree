extends GdUnitTestSuite

func _load(id: String) -> RaceData:
	return load("res://features/races/data/%s.tres" % id) as RaceData

func test_all_four_races_load() -> void:
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		assert_that(_load(id)).is_not_null()

func test_human_fields() -> void:
	var d := _load("human")
	assert_that(d.id).is_equal(&"human")
	assert_that(d.awaken_condition).is_equal("memory>=2")
	assert_that(d.awaken_pop).is_equal_approx(50.0, 1e-4)
	assert_that(d.produce_memory).is_true()
	assert_that(d.awaken_text.length()).is_greater(10)

func test_forestfolk_fields() -> void:
	var d := _load("forestfolk")
	assert_that(d.awaken_condition).is_equal("faith>=30")
	assert_that(d.devotion).is_equal_approx(1.8, 1e-4)
	assert_that(d.produce_memory).is_false()

func test_stoneborn_craft_sap() -> void:
	var d := _load("stoneborn")
	assert_that(d.awaken_condition).is_equal("faith>=60")
	assert_that(d.craft_sap).is_equal_approx(0.01, 1e-4)

func test_wildfolk_fields() -> void:
	var d := _load("wildfolk")
	assert_that(d.awaken_condition).is_equal("faith>=100")
	assert_that(d.devotion).is_equal_approx(0.3, 1e-4)
	assert_that(d.growth_rate).is_equal_approx(0.02, 1e-4)

func test_all_conditions_format_valid() -> void:
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		var cond := _load(id).awaken_condition
		var ok := cond == "memory>=2" or cond.begins_with("faith>=")
		assert_that(ok).is_true()
