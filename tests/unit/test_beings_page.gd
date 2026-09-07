extends GdUnitTestSuite

const BeingsPage := preload("res://features/ui/pages/beings_page.gd")
const BeingsScene := preload("res://features/ui/pages/beings_page.tscn")

const ACTION_NODE_NAMES: Array[String] = [
	"InteractHumanButton", "InteractForestButton", "InteractStoneButton", "InteractWildButton",
	"PlunderHumanButton", "PlunderForestButton", "PlunderStoneButton", "PlunderWildButton",
	"IntimateHumanButton", "IntimateForestButton", "IntimateStoneButton", "IntimateWildButton",
	"FirepitButton", "RingButton", "ForgeButton", "TotemPoleButton", "TotemInterpretButton",
	"ReviveHumanButton", "ReviveForestButton", "ReviveStoneButton", "ReviveWildButton",
	"PlunderSoulHumanButton", "PlunderSoulForestButton", "PlunderSoulStoneButton", "PlunderSoulWildButton",
	"StoryButton", "StreamStoryButton",
]

func test_race_view_has_awake_population_relation_and_text_backup() -> void:
	var state := GameState.new()
	state.races[&"human"] = {"awakened": true, "population": 12.0}
	state.relations[&"human"] = 0.5
	var before := state.to_dict()
	var view := BeingsPage.race_view(state, &"human")
	assert_that(view.get("awakened", false)).is_true()
	assert_that(view.get("summary", "")).contains("人口 12")
	assert_that(view.get("summary", "")).contains("友善")
	assert_that(view.get("relation_label", "")).is_equal("友善")
	assert_that(view.get("relation_text", "")).is_equal("+0.5")
	assert_that(state.to_dict()).is_equal(before)

func test_unawakened_race_view_keeps_existing_hint() -> void:
	var view := BeingsPage.race_view(GameState.new(), &"forestfolk")
	assert_that(view.get("awakened", true)).is_false()
	assert_that(view.get("summary", "")).contains("信仰 30")
	assert_that(view.get("awaken_hint", "")).is_equal("信仰 30")

func test_relation_colors_remain_readable_on_warm_cards() -> void:
	var card_background := Color(1.0, 0.984314, 0.945098, 1.0)
	for relation: float in [-3.0, -0.5, 0.0, 0.5, 2.0, 3.0]:
		assert_that(_contrast_ratio(BeingsPage.relation_color(relation), card_background)).is_greater_equal(4.5)

func test_storyteller_projection_remains_compatible() -> void:
	var state := GameState.new()
	assert_that(BeingsPage.storyteller_view(state).get("visible", true)).is_false()
	state.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
	assert_that(BeingsPage.storyteller_view(state).get("disabled", true)).is_false()
	assert_that(BeingsPage.storyteller_view(state).get("button_text", "")).contains("已读 0/3")
	state.storyteller_stories.assign([&"story_4", &"story_5", &"story_6"])
	assert_that(BeingsPage.storyteller_view(state).get("disabled", false)).is_true()
	assert_that(BeingsPage.storyteller_view(state).get("button_text", "")).contains("已读 3/3")

func test_scene_contains_each_beings_action_once_with_touch_targets() -> void:
	var root := BeingsScene.instantiate()
	assert_that(root is UiPage).is_true()
	assert_that(root.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	for card_name: String in [
		"PageHeader", "RaceSummaryCard", "RelationCard", "DreamCard", "FacilityCard",
		"TotemCard", "AvatarCard", "SoulCard", "StoryCard",
	]:
		assert_that(root.find_child(card_name, true, false)).is_not_null()
	for node_name: String in ACTION_NODE_NAMES:
		var matches := root.find_children(node_name, "Button", true, false)
		assert_that(matches).has_size(1)
		if matches.size() == 1:
			assert_that((matches[0] as Button).custom_minimum_size.y).is_greater_equal(44.0)
	root.free()

func test_refresh_projects_awake_actions_without_mutating_state() -> void:
	var root := BeingsScene.instantiate() as BeingsPage
	add_child(root)
	var state := GameState.new()
	var before := state.to_dict()
	root.refresh(state)
	assert_that(state.to_dict()).is_equal(before)
	assert_that((root.find_child("RaceHumanLabel", true, false) as Label).text).contains("记忆 2")
	assert_that((root.find_child("InteractHumanButton", true, false) as Button).visible).is_false()

	state.sap = BigNum.new(10000.0)
	state.memory = BigNum.new(100.0)
	state.faith = BigNum.new(100.0)
	state.growth = BigNum.new(1000.0)
	state.soul_river = 50
	for race_id: StringName in GameState.RACE_IDS:
		state.races[race_id] = {"awakened": true, "population": 20.0}
		state.relations[race_id] = 2.0
		state.plundered[race_id] = 3
	root.refresh(state)
	assert_that((root.find_child("RaceHumanLabel", true, false) as Label).text).contains("亲近")
	assert_that((root.find_child("InteractHumanButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("PlunderHumanButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("IntimateHumanButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("FirepitButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("TotemPanel", true, false) as PanelContainer).visible).is_true()
	assert_that((root.find_child("AvatarPanel", true, false) as PanelContainer).visible).is_true()
	assert_that((root.find_child("ReviveHumanButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("PlunderSoulHumanButton", true, false) as Button).visible).is_true()
	assert_that((root.find_child("RaceHumanLabel", true, false) as Label).text).contains("人口停滞")
	root.free()

func test_refresh_projects_story_and_stream_states() -> void:
	var root := BeingsScene.instantiate() as BeingsPage
	add_child(root)
	var state := GameState.new()
	root.refresh(state)
	assert_that((root.find_child("StoryButton", true, false) as Button).visible).is_false()
	state.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
	root.refresh(state)
	assert_that((root.find_child("StoryButton", true, false) as Button).text).contains("已读 0/3")
	assert_that((root.find_child("StoryButton", true, false) as Button).disabled).is_false()
	assert_that((root.find_child("StreamStoryButton", true, false) as Button).visible).is_false()
	state.storyteller_stories.append(&"story_4")
	state.relations[&"human"] = 2.0
	root.refresh(state)
	assert_that((root.find_child("StreamStoryButton", true, false) as Button).visible).is_true()
	state.storyteller_stories.assign([&"story_4", &"story_5", &"story_6", &"stream_and_current"])
	root.refresh(state)
	assert_that((root.find_child("StoryButton", true, false) as Button).text).contains("已读 3/3")
	assert_that((root.find_child("StoryButton", true, false) as Button).disabled).is_true()
	assert_that((root.find_child("StreamStoryButton", true, false) as Button).text).contains("已读")
	root.free()

func _contrast_ratio(foreground: Color, background: Color) -> float:
	var lighter := maxf(_relative_luminance(foreground), _relative_luminance(background))
	var darker := minf(_relative_luminance(foreground), _relative_luminance(background))
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
