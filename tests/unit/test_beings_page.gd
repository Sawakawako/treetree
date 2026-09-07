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

func test_refresh_distinguishes_sleeping_and_awake_for_all_four_races() -> void:
	var root := BeingsScene.instantiate() as BeingsPage
	add_child(root)
	var state := GameState.new()
	var rows: Array[Dictionary] = [
		{"race_id": &"human", "label": "RaceHumanLabel", "interact": "InteractHumanButton", "plunder": "PlunderHumanButton", "facility": "FirepitButton"},
		{"race_id": &"forestfolk", "label": "RaceForestLabel", "interact": "InteractForestButton", "plunder": "PlunderForestButton", "facility": "RingButton"},
		{"race_id": &"stoneborn", "label": "RaceStoneLabel", "interact": "InteractStoneButton", "plunder": "PlunderStoneButton", "facility": "ForgeButton"},
		{"race_id": &"wildfolk", "label": "RaceWildLabel", "interact": "InteractWildButton", "plunder": "PlunderWildButton", "facility": "TotemPoleButton"},
	]
	root.refresh(state)
	for row: Dictionary in rows:
		assert_that((root.find_child(str(row["label"]), true, false) as Label).text).contains("时苏醒")
		assert_that(_button(root, str(row["interact"])).visible).is_false()
		assert_that(_button(root, str(row["plunder"])).visible).is_false()
		assert_that(_button(root, str(row["facility"])).visible).is_false()

	state.memory = BigNum.new(10.0)
	state.faith = BigNum.new(20.0)
	state.sap = BigNum.new(10000.0)
	for row: Dictionary in rows:
		var race_id := StringName(row["race_id"])
		state.races[race_id] = {"awakened": true, "population": 20.0}
	root.refresh(state)
	for row: Dictionary in rows:
		assert_that((root.find_child(str(row["label"]), true, false) as Label).text).contains("人口 20")
		assert_that(_button(root, str(row["interact"])).visible).is_true()
		assert_that(_button(root, str(row["plunder"])).visible).is_true()
		assert_that(_button(root, str(row["facility"])).visible).is_true()
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

func test_relation_buttons_dispatch_each_exact_race_and_own_feedback() -> void:
	var previous_state: GameState = GameManager._state
	var button_names := {
		&"human": "InteractHumanButton",
		&"forestfolk": "InteractForestButton",
		&"stoneborn": "InteractStoneButton",
		&"wildfolk": "InteractWildButton",
	}
	for race_id: StringName in GameState.RACE_IDS:
		var state := _action_ready_state(race_id)
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)

		_button(root, button_names[race_id]).emit_signal("pressed")

		assert_that(state.relation_events).contains(race_id)
		assert_float(float(state.relations.get(race_id, 0.0))).is_equal_approx(0.5, 0.001)
		for other_id: StringName in GameState.RACE_IDS:
			if other_id != race_id:
				assert_float(float(state.relations.get(other_id, 0.0))).is_equal_approx(0.0, 0.001)
		assert_that(refreshes).has_size(1)
		assert_that(_feedback_of_kind(feedback, &"narrative")).has_size(1)
		assert_that(_feedback_of_kind(feedback, &"toast")).has_size(1)
		if not feedback.is_empty():
			assert_that(str(feedback[0].get("body", ""))).is_equal(str(RelationEvents.get_event(race_id).get("text", "")))
		root.free()
	GameManager._state = previous_state

func test_plunder_buttons_preserve_four_race_yields_and_mapping() -> void:
	var previous_state: GameState = GameManager._state
	var cases: Array[Dictionary] = [
		{"race_id": &"human", "button": "PlunderHumanButton", "yield": 1.0, "count": 1},
		{"race_id": &"forestfolk", "button": "PlunderForestButton", "yield": 1.2, "count": 1},
		{"race_id": &"stoneborn", "button": "PlunderStoneButton", "yield": 0.0, "count": 0},
		{"race_id": &"wildfolk", "button": "PlunderWildButton", "yield": 2.0, "count": 1},
	]
	for case: Dictionary in cases:
		var race_id := StringName(case["race_id"])
		var state := GameState.new()
		state.races[race_id] = {"awakened": true, "population": 20.0}
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)

		_button(root, str(case["button"])).emit_signal("pressed")

		assert_float(state.memory.to_value()).is_equal_approx(float(case["yield"]), 0.001)
		assert_int(PlunderActions.count(state, race_id)).is_equal(int(case["count"]))
		for other_id: StringName in GameState.RACE_IDS:
			if other_id != race_id:
				assert_int(PlunderActions.count(state, other_id)).is_equal(0)
		assert_that(refreshes).has_size(1)
		assert_that(feedback).is_empty()
		root.free()
	GameManager._state = previous_state

func test_intimacy_buttons_enforce_gate_then_dispatch_each_exact_race() -> void:
	var previous_state: GameState = GameManager._state
	var button_names := {
		&"human": "IntimateHumanButton",
		&"forestfolk": "IntimateForestButton",
		&"stoneborn": "IntimateStoneButton",
		&"wildfolk": "IntimateWildButton",
	}
	for race_id: StringName in GameState.RACE_IDS:
		var state := GameState.new()
		state.memory = BigNum.new(30.0)
		state.races[race_id] = {"awakened": true, "population": 20.0}
		state.relations[race_id] = 1.5
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)

		_button(root, button_names[race_id]).emit_signal("pressed")
		assert_that(state.intimate_events).is_empty()
		assert_that(refreshes).has_size(1)
		assert_that(feedback).contains({"kind": &"toast", "body": "它还不想说。"})

		state.relations[race_id] = 2.0
		_button(root, button_names[race_id]).emit_signal("pressed")
		assert_that(state.intimate_events).contains(race_id)
		assert_that(state.intimate_events).has_size(1)
		assert_that(refreshes).has_size(2)
		assert_that(feedback).has_size(1)
		root.free()
	GameManager._state = previous_state

func test_facility_buttons_dispatch_exact_public_purchase() -> void:
	var previous_state: GameState = GameManager._state
	var cases: Array[Dictionary] = [
		{"race_id": &"human", "button": "FirepitButton", "field": &"firepit_level"},
		{"race_id": &"forestfolk", "button": "RingButton", "field": &"ring_level"},
		{"race_id": &"stoneborn", "button": "ForgeButton", "field": &"forge_level"},
		{"race_id": &"wildfolk", "button": "TotemPoleButton", "field": &"totem_pole_level"},
	]
	for case: Dictionary in cases:
		var race_id := StringName(case["race_id"])
		var field := StringName(case["field"])
		var state := GameState.new()
		state.sap = BigNum.new(10000.0)
		state.races[race_id] = {"awakened": true, "population": 20.0}
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)

		_button(root, str(case["button"])).emit_signal("pressed")

		assert_int(int(state.get(field))).is_equal(1)
		for other_field: StringName in [&"firepit_level", &"ring_level", &"forge_level", &"totem_pole_level"]:
			if other_field != field:
				assert_int(int(state.get(other_field))).is_equal(0)
		assert_that(refreshes).has_size(1)
		assert_that(_feedback_of_kind(feedback, &"toast")).has_size(1)
		root.free()
	GameManager._state = previous_state

func test_totem_stage_and_avatar_tier_projection_use_existing_boundaries() -> void:
	var root := BeingsScene.instantiate() as BeingsPage
	add_child(root)
	var state := GameState.new()
	state.races[&"wildfolk"] = {"awakened": true, "population": 20.0}
	var stage_memories := [0.0, 4.0, 10.0, 20.0, 35.0]
	for index: int in stage_memories.size():
		state.memory = BigNum.new(float(stage_memories[index]))
		root.refresh(state)
		assert_that((root.find_child("TotemLabel", true, false) as Label).text).contains("第 %d 幅" % (index + 1))
	state.memory = BigNum.new(30.0)
	var tier_names := ["清醒", "微漂", "深漂", "迷失"]
	for index: int in tier_names.size():
		state.drift_extra = float([0.0, 3.0, 6.0, 9.0][index])
		root.refresh(state)
		assert_that((root.find_child("AvatarLabel", true, false) as Label).text).contains(str(tier_names[index]))
	root.free()

func test_totem_button_interprets_current_stage_once_without_local_duplicate() -> void:
	var previous_state: GameState = GameManager._state
	var state := GameState.new()
	state.memory = BigNum.new(10.0)
	state.races[&"wildfolk"] = {"awakened": true, "population": 20.0}
	GameManager._state = state
	var root := _page_for(state)
	var feedback: Array[Dictionary] = []
	var refreshes: Array[bool] = []
	_watch_page(root, feedback, refreshes)

	_button(root, "TotemInterpretButton").emit_signal("pressed")

	assert_that(state.totem_interpreted).contains(3)
	assert_that(state.totem_interpreted).has_size(1)
	assert_int(state.insight).is_equal(1)
	assert_that(refreshes).has_size(1)
	assert_that(feedback).is_empty()
	root.free()
	GameManager._state = previous_state

func test_soul_buttons_dispatch_both_directions_for_every_race() -> void:
	var previous_state: GameState = GameManager._state
	var revive_buttons := {
		&"human": "ReviveHumanButton", &"forestfolk": "ReviveForestButton",
		&"stoneborn": "ReviveStoneButton", &"wildfolk": "ReviveWildButton",
	}
	var plunder_buttons := {
		&"human": "PlunderSoulHumanButton", &"forestfolk": "PlunderSoulForestButton",
		&"stoneborn": "PlunderSoulStoneButton", &"wildfolk": "PlunderSoulWildButton",
	}
	for race_id: StringName in GameState.RACE_IDS:
		var state := GameState.new()
		state.growth = BigNum.new(1000.0)
		state.soul_river = 50
		state.races[race_id] = {"awakened": true, "population": 20.0}
		state.plundered[race_id] = 3
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)

		_button(root, revive_buttons[race_id]).emit_signal("pressed")
		assert_float(float(state.races[race_id]["population"])).is_equal_approx(30.0, 0.001)
		assert_int(state.soul_river).is_equal(49)
		assert_float(state.growth.to_value()).is_equal_approx(500.0, 0.001)

		_button(root, plunder_buttons[race_id]).emit_signal("pressed")
		assert_float(float(state.races[race_id]["population"])).is_equal_approx(27.0, 0.001)
		assert_int(state.soul_river).is_equal(50)
		assert_float(float(state.relations.get(race_id, 0.0))).is_equal_approx(-1.0, 0.001)
		assert_that(refreshes).has_size(2)
		assert_that(feedback).is_empty()
		assert_that(state.races).has_size(1)
		root.free()
	GameManager._state = previous_state

func test_story_buttons_dispatch_main_and_easter_ids_without_local_duplicate() -> void:
	var previous_state: GameState = GameManager._state
	var state := GameState.new()
	state.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
	GameManager._state = state
	var root := _page_for(state)
	var feedback: Array[Dictionary] = []
	var refreshes: Array[bool] = []
	_watch_page(root, feedback, refreshes)

	_button(root, "StoryButton").emit_signal("pressed")
	assert_that(state.storyteller_stories).contains(&"story_4")
	assert_float(float(state.relations.get(&"human", 0.0))).is_equal_approx(0.5, 0.001)
	assert_that(refreshes).has_size(1)
	assert_that(feedback).is_empty()

	state.relations[&"human"] = 2.0
	_button(root, "StreamStoryButton").emit_signal("pressed")
	assert_that(state.storyteller_stories).contains(&"stream_and_current")
	assert_that(state.storyteller_stories).has_size(2)
	assert_that(refreshes).has_size(2)
	assert_that(feedback).is_empty()
	root.free()
	GameManager._state = previous_state

func test_failed_global_action_emits_one_failure_feedback_and_one_refresh() -> void:
	var previous_state: GameState = GameManager._state
	var state := GameState.new()
	GameManager._state = state
	var root := _page_for(state)
	var feedback: Array[Dictionary] = []
	var refreshes: Array[bool] = []
	_watch_page(root, feedback, refreshes)
	var before := state.to_dict()

	_button(root, "PlunderHumanButton").emit_signal("pressed")

	assert_that(state.to_dict()).is_equal(before)
	assert_that(refreshes).has_size(1)
	assert_that(feedback).contains({"kind": &"toast", "body": "它还在沉睡。"})
	assert_that(feedback).has_size(1)
	root.free()
	GameManager._state = previous_state

func _action_ready_state(race_id: StringName) -> GameState:
	var state := GameState.new()
	state.memory = BigNum.new(10.0)
	state.faith = BigNum.new(20.0)
	state.sap = BigNum.new(10000.0)
	state.races[race_id] = {"awakened": true, "population": 20.0}
	if race_id == &"wildfolk":
		state.races[&"wildfolk"] = {"awakened": true, "population": 20.0}
	return state

func _page_for(state: GameState) -> BeingsPage:
	var root := BeingsScene.instantiate() as BeingsPage
	add_child(root)
	root.refresh(state)
	return root

func _watch_page(root: BeingsPage, feedback: Array[Dictionary], refreshes: Array[bool]) -> void:
	root.feedback_requested.connect(func(event: Dictionary) -> void: feedback.append(event))
	root.refresh_requested.connect(func() -> void: refreshes.append(true))

func _button(root: BeingsPage, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button

func _feedback_of_kind(feedback: Array[Dictionary], kind: StringName) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for event: Dictionary in feedback:
		if StringName(event.get("kind", &"")) == kind:
			matches.append(event)
	return matches

func _contrast_ratio(foreground: Color, background: Color) -> float:
	var lighter := maxf(_relative_luminance(foreground), _relative_luminance(background))
	var darker := minf(_relative_luminance(foreground), _relative_luminance(background))
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
