extends GdUnitTestSuite

func test_story_library_has_three_main_stories_and_one_easter_egg() -> void:
	assert_that(StoryLibrary.story_count()).is_equal(4)
	assert_that(StoryLibrary.main_story_ids()).is_equal([&"story_4", &"story_5", &"story_6"])
	assert_that(StoryLibrary.easter_egg_ids()).is_equal([&"stream_and_current"])

func test_all_stories_have_complete_schema_and_text() -> void:
	for story in StoryLibrary.all_stories():
		assert_that(StringName(str(story.get("id", "")))).is_not_equal(&"")
		assert_that(str(story.get("title", ""))).is_not_empty()
		assert_that(str(story.get("text", ""))).is_not_empty()
		assert_that(typeof(story.get("conditions", null))).is_equal(TYPE_DICTIONARY)
		assert_that(typeof(story.get("effects", null))).is_equal(TYPE_DICTIONARY)

func test_story_six_writes_final_flag_and_one_insight() -> void:
	var story := StoryLibrary.get_story(&"story_6")
	assert_that(int(story.get("effects", {}).get("insight", 0))).is_equal(1)
	assert_that(story.get("effects", {}).get("flags", [])).contains(&"storyteller_final_story")

func test_library_returns_deep_copies() -> void:
	var story := StoryLibrary.get_story(&"story_4")
	story["effects"]["relation"]["human"] = 99.0
	assert_that(float(StoryLibrary.get_story(&"story_4").get("effects", {}).get("relation", {}).get("human", 0.0))).is_equal_approx(0.5, 1e-4)
