extends GdUnitTestSuite

func _story_four_ready() -> GameState:
	var s := GameState.new()
	s.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
	return s

func test_story_four_requires_cave_and_protected_dream() -> void:
	var s := GameState.new()
	assert_that(StoryActions.can_hear(s, &"story_4")).is_false()
	s.choice_flags.append(&"cave_found")
	assert_that(StoryActions.can_hear(s, &"story_4")).is_false()
	s.choice_flags.append(&"human_nightmare_protected")
	assert_that(StoryActions.can_hear(s, &"story_4")).is_true()

func test_story_four_rewards_human_relation_once() -> void:
	var s := _story_four_ready()
	assert_that(StoryActions.hear(s, &"story_4").get("ok", false)).is_true()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal_approx(0.5, 1e-4)
	assert_that(s.storyteller_stories).contains(&"story_4")
	assert_that(StoryActions.hear(s, &"story_4").get("ok", false)).is_false()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal_approx(0.5, 1e-4)

func test_story_five_requires_story_relation_and_insight() -> void:
	var s := _story_four_ready()
	StoryActions.hear(s, &"story_4")
	s.relations[&"human"] = 2.0
	s.insight = 4
	assert_that(StoryActions.can_hear(s, &"story_5")).is_false()
	s.insight = 5
	assert_that(StoryActions.can_hear(s, &"story_5")).is_true()
	var no_relation := _story_four_ready()
	no_relation.storyteller_stories.append(&"story_4")
	no_relation.insight = 5
	assert_that(StoryActions.can_hear(no_relation, &"story_5")).is_false()

func test_story_six_requires_story_flag_and_truth() -> void:
	var s := GameState.new()
	s.storyteller_stories.append(&"story_5")
	s.choice_flags.append(&"sky_rift_observed")
	s.truth = 3
	assert_that(StoryActions.can_hear(s, &"story_6")).is_false()
	s.truth = 4
	assert_that(StoryActions.can_hear(s, &"story_6")).is_true()

func test_story_six_rewards_insight_and_final_flag_once() -> void:
	var s := GameState.new()
	s.storyteller_stories.append(&"story_5")
	s.choice_flags.append(&"sky_rift_observed")
	s.truth = 4
	assert_that(StoryActions.hear(s, &"story_6").get("ok", false)).is_true()
	assert_that(s.insight).is_equal(1)
	assert_that(s.choice_flags).contains(&"storyteller_final_story")
	assert_that(StoryActions.hear(s, &"story_6").get("ok", false)).is_false()
	assert_that(s.insight).is_equal(1)

func test_easter_egg_does_not_block_main_story() -> void:
	var s := GameState.new()
	s.storyteller_stories.append(&"story_4")
	s.relations[&"human"] = 2.0
	s.insight = 5
	assert_that(StoryActions.available_easter_eggs(s)).contains(&"stream_and_current")
	assert_that(StoryActions.next_main_story(s)).is_equal(&"story_5")
	assert_that(StoryActions.hear(s, &"stream_and_current").get("ok", false)).is_true()
	assert_that(StoryActions.next_main_story(s)).is_equal(&"story_5")

func test_hearing_easter_egg_has_no_numeric_reward() -> void:
	var s := GameState.new()
	s.storyteller_stories.append(&"story_4")
	s.relations[&"human"] = 2.0
	var before_relation := RelationActions.get_relation(s, &"human")
	assert_that(StoryActions.hear(s, &"stream_and_current").get("ok", false)).is_true()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal_approx(before_relation, 1e-4)
	assert_that(s.insight).is_equal(0)

func test_unknown_story_is_rejected() -> void:
	assert_that(StoryActions.hear(GameState.new(), &"missing").get("ok", false)).is_false()
