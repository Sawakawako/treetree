extends GdUnitTestSuite

func test_event_count() -> void:
	assert_that(RelationEvents.event_count()).is_equal(4)

func test_get_event_fields() -> void:
	var e := RelationEvents.get_event(&"human")
	assert_that(e.has("race_id")).is_true()
	assert_that(e.has("condition")).is_true()
	assert_that(e.has("text")).is_true()
	assert_that(str(e.get("text", "")).length()).is_greater(10)

func test_get_missing_event_returns_empty() -> void:
	assert_that(RelationEvents.get_event(&"nobody").is_empty()).is_true()

func test_events_cover_four_races() -> void:
	var ids: Array = []
	for e in RelationEvents.EVENTS:
		ids.append(e.get("race_id"))
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(ids.has(expected)).is_true()

func test_conditions_format_valid() -> void:
	for e in RelationEvents.EVENTS:
		var cond := str(e.get("condition", ""))
		var ok := false
		for prefix in ["memory>=", "faith>=", "sap>=", "totem>="]:
			if cond.begins_with(prefix):
				ok = float(cond.get_slice(">=", 1)) >= 0.0
		assert_that(ok).is_true()
