extends GdUnitTestSuite

func test_totem_count() -> void:
	assert_that(TotemLibrary.totem_count()).is_equal(5)

func test_get_totem_fields() -> void:
	var t := TotemLibrary.get_totem(1)
	assert_that(int(t.get("id", 0))).is_equal(1)
	assert_that(t.has("threshold")).is_true()
	assert_that(t.has("reveal_text")).is_true()
	assert_that(t.has("interpret_text")).is_true()

func test_get_missing_totem_returns_empty() -> void:
	assert_that(TotemLibrary.get_totem(99).is_empty()).is_true()

func test_all_totems_unique_ids() -> void:
	var ids: Array = []
	for t in TotemLibrary.all_totems():
		var id: int = int(t.get("id", 0))
		assert_that(ids.has(id)).is_false()
		ids.append(id)

func test_thresholds_ascending() -> void:
	var prev := -1.0
	for t in TotemLibrary.all_totems():
		var th := float(t.get("threshold", -1.0))
		assert_that(th).is_greater(prev)
		prev = th

func test_texts_nonempty() -> void:
	# 文风交付物防漂移：浮现/解读文本不得为空或过短
	for t in TotemLibrary.all_totems():
		assert_that(str(t.get("reveal_text", "")).length()).is_greater(5)
		assert_that(str(t.get("interpret_text", "")).length()).is_greater(5)
