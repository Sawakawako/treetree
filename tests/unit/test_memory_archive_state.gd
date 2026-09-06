extends GdUnitTestSuite

func test_capture_run_merges_known_discoveries_without_duplicates() -> void:
	var archive := MemoryArchiveState.new()
	var state := GameState.new()
	state.run_number = 2
	state.relics_found.assign([1, 9, 9])
	state.totem_interpreted.assign([2, 5])
	state.storyteller_stories.assign([&"story_4"])
	state.choices_done.assign([&"human_nightmare", &"world_axis"])
	state.realm_echoes.assign([&"midgard", &"asgard"])
	state.miracle_counts = {&"rain": 2, &"shape": 0}
	state.ending_seen.assign([&"good"])

	archive.capture_run(state)
	archive.capture_run(state)

	assert_that(archive.max_run_reached).is_equal(2)
	assert_that(archive.relics).contains_exactly([1, 9])
	assert_that(archive.totems).contains_exactly([2, 5])
	assert_that(archive.stories).contains_exactly([&"story_4"])
	assert_that(archive.choices).contains_exactly([&"human_nightmare", &"world_axis"])
	assert_that(archive.realms).contains_exactly([&"midgard", &"asgard"])
	assert_that(archive.miracles).contains_exactly([&"rain"])
	assert_that(archive.endings).contains_exactly([&"good"])

func test_record_choice_keeps_each_path_once() -> void:
	var archive := MemoryArchiveState.new()
	archive.record_choice(&"theseus", &"c")
	archive.record_choice(&"theseus", &"c")
	archive.record_choice(&"theseus", &"b")

	assert_that(archive.choices).contains_exactly([&"theseus"])
	assert_that(archive.choice_outcomes[&"theseus"]).contains_exactly([&"c", &"b"])

func test_from_dict_filters_unknown_and_invalid_ids() -> void:
	var archive := MemoryArchiveState.from_dict({
		"version": 1,
		"relics": [1, 99, "bad"],
		"totems": [1, 8],
		"stories": ["story_4", "missing"],
		"choices": ["theseus", "missing"],
		"choice_outcomes": {"theseus": ["a", "z"], "missing": ["a"]},
		"realms": ["midgard", "missing"],
		"miracles": ["rain", "missing"],
		"endings": ["good", "missing"],
		"max_run_reached": -3,
	})

	assert_that(archive.relics).contains_exactly([1])
	assert_that(archive.totems).contains_exactly([1])
	assert_that(archive.stories).contains_exactly([&"story_4"])
	assert_that(archive.choices).contains_exactly([&"theseus"])
	assert_that(archive.choice_outcomes[&"theseus"]).contains_exactly([&"a"])
	assert_that(archive.realms).contains_exactly([&"midgard"])
	assert_that(archive.miracles).contains_exactly([&"rain"])
	assert_that(archive.endings).contains_exactly([&"good"])
	assert_that(archive.max_run_reached).is_equal(1)

func test_true_ending_marks_library_complete() -> void:
	var archive := MemoryArchiveState.new()
	var state := GameState.new()
	state.ending_seen.append(&"true")
	archive.capture_run(state)
	assert_that(archive.library_complete).is_true()

