extends GdUnitTestSuite

func test_events_cover_four_races() -> void:
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(IntimateEvents.get_event(expected).is_empty()).is_false()

func test_event_text_nonempty() -> void:
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(str(IntimateEvents.get_event(expected).get("text", "")).length()).is_greater(20)

func test_get_missing_returns_empty() -> void:
	assert_that(IntimateEvents.get_event(&"nobody").is_empty()).is_true()