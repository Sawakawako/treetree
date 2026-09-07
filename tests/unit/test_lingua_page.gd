extends GdUnitTestSuite

const LinguaPage := preload("res://features/ui/pages/lingua_page.gd")
const LinguaScene := preload("res://features/ui/pages/lingua_page.tscn")

const NODE_BUTTONS: Array[Dictionary] = [
	{"id": &"root_echo", "button": "RootEchoButton"},
	{"id": &"root_resonance", "button": "RootResonanceButton"},
	{"id": &"earth_sense", "button": "EarthSenseButton"},
	{"id": &"deep_root", "button": "DeepRootButton"},
	{"id": &"tree_canopy", "button": "TreeCanopyButton"},
	{"id": &"ring_memory", "button": "RingMemoryButton"},
	{"id": &"cloud_crown", "button": "CloudCrownButton"},
	{"id": &"wood_heart", "button": "WoodHeartButton"},
	{"id": &"sky_light", "button": "SkyLightButton"},
	{"id": &"song_resonance", "button": "SongResonanceButton"},
	{"id": &"village_heart", "button": "VillageHeartButton"},
	{"id": &"grace", "button": "GraceButton"},
	{"id": &"altar", "button": "AltarButton"},
]

func test_completed_node_stays_visible_as_disabled_completion() -> void:
	var state := GameState.new()
	state.lingua_life_level = 1
	state.lingua_nodes.append(&"root_echo")
	var view := LinguaPage.node_view(state, &"root_echo")
	assert_that(view.get("visible", false)).is_true()
	assert_that(view.get("disabled", false)).is_true()
	assert_that(view.get("status", "")).is_equal("已点亮")

func test_locked_node_names_its_first_existing_gap() -> void:
	var state := GameState.new()
	var view := LinguaPage.node_view(state, &"root_resonance")
	assert_that(view.get("visible", false)).is_true()
	assert_that(view.get("status", "")).contains("生命之语")

func test_projection_does_not_mutate_state() -> void:
	var state := GameState.new()
	var before := state.to_dict()
	LinguaPage.node_view(state, &"root_echo")
	assert_that(state.to_dict()).is_equal(before)

func test_node_view_reports_sap_gap_then_availability() -> void:
	var state := GameState.new()
	state.lingua_life_level = 1
	state.sap = BigNum.new(2999.0)
	assert_that(str(LinguaPage.node_view(state, &"root_echo").get("status", ""))).contains("树液还差 1")
	state.sap = BigNum.new(3000.0)
	var ready := LinguaPage.node_view(state, &"root_echo")
	assert_that(ready.get("disabled", true)).is_false()
	assert_that(ready.get("status", "")).is_equal("可以点亮")

func test_missing_node_is_hidden_and_disabled() -> void:
	var view := LinguaPage.node_view(GameState.new(), &"not_registered")
	assert_that(view).is_equal({"visible": false, "disabled": true, "status": "节点缺失"})

func test_scene_contains_only_the_thirteen_legacy_nodes_with_touch_targets() -> void:
	var root := LinguaScene.instantiate()
	assert_that(root is UiPage).is_true()
	assert_that(root.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	for card_name: String in [
		"PageHeader", "LanguageSummaryCard", "ConversionCard", "EngineCard",
		"LanguageUpgradeCard", "NodePathCard",
	]:
		assert_that(root.find_child(card_name, true, false)).is_not_null()
	for node_name: String in [
		"FaithConvertButton", "MemoryConvertButton", "FaithEngineButton", "MemoryEngineButton",
		"LifeUpgradeButton", "MemoryLinguaButton",
	]:
		_assert_single_touch_button(root, node_name)
	for row: Dictionary in NODE_BUTTONS:
		_assert_single_touch_button(root, str(row["button"]))
	for world_button: String in [
		"WorldTraceButton", "RainNameButton", "RiverHearingButton", "SkyLadderButton",
		"WorldShapingButton", "WorldBreathButton",
	]:
		assert_that(root.find_child(world_button, true, false)).is_null()
	root.free()

func test_refresh_projects_levels_actions_and_node_completion_without_mutation() -> void:
	var root := LinguaScene.instantiate() as LinguaPage
	add_child(root)
	var state := GameState.new()
	state.lingua_life_level = 1
	state.lingua_memory_level = 1
	state.insight = 5
	state.lingua_nodes.assign([&"root_echo", &"tree_canopy", &"root_resonance", &"cloud_crown", &"grace"])
	state.sap = BigNum.new(50000.0)
	state.faith = BigNum.new(200.0)
	state.memory = BigNum.new(500.0)
	var before := state.to_dict()
	root.refresh(state)
	assert_that(state.to_dict()).is_equal(before)
	assert_that(_label(root, "LifeLevelLabel").text).contains("Lv1")
	assert_that(_label(root, "MemoryLevelLabel").text).contains("Lv1")
	assert_that(_label(root, "InsightContextLabel").text).contains("5")
	assert_that(_button(root, "FaithConvertButton").visible).is_true()
	assert_that(_button(root, "MemoryConvertButton").visible).is_true()
	assert_that(_button(root, "FaithEngineButton").visible).is_true()
	assert_that(_button(root, "MemoryEngineButton").visible).is_true()
	assert_that(_button(root, "RootEchoButton").visible).is_true()
	assert_that(_button(root, "RootEchoButton").disabled).is_true()
	assert_that(_button(root, "RootEchoButton").text).is_equal("◆ 遗迹回声 · 已点亮")
	assert_that(_button(root, "SkyLightButton").disabled).is_false()
	assert_that(_button(root, "MemoryLinguaButton").visible).is_true()
	assert_that(_button(root, "MemoryLinguaButton").disabled).is_true()
	root.free()

func test_refresh_hides_action_cards_that_have_no_unlocked_entry() -> void:
	var root := LinguaScene.instantiate() as LinguaPage
	add_child(root)
	var state := GameState.new()
	root.refresh(state)
	assert_that(root.find_child("ConversionCard", true, false).visible).is_false()
	assert_that(root.find_child("EngineCard", true, false).visible).is_false()
	state.lingua_nodes.assign([&"tree_canopy", &"root_resonance", &"cloud_crown", &"grace"])
	root.refresh(state)
	assert_that(root.find_child("ConversionCard", true, false).visible).is_true()
	assert_that(root.find_child("EngineCard", true, false).visible).is_true()
	root.free()

func test_conversion_and_engine_buttons_dispatch_exact_public_actions_once() -> void:
	var previous_state: GameState = GameManager._state
	var cases: Array[Dictionary] = [
		{"button": "FaithConvertButton", "node": &"tree_canopy", "resource": &"sap", "before": 500.0, "after": 400.0, "gain": &"faith", "gain_after": 1.0},
		{"button": "MemoryConvertButton", "node": &"root_resonance", "resource": &"sap", "before": 500.0, "after": 0.0, "gain": &"memory", "gain_after": 1.0},
		{"button": "FaithEngineButton", "node": &"cloud_crown", "resource": &"faith", "before": 200.0, "after": 0.0, "level": &"faith_engine_level"},
		{"button": "MemoryEngineButton", "node": &"grace", "resource": &"memory", "before": 500.0, "after": 0.0, "level": &"memory_engine_level"},
	]
	for case: Dictionary in cases:
		var state := GameState.new()
		state.lingua_nodes.append(StringName(case["node"]))
		(state.get(StringName(case["resource"])) as BigNum).set_value(float(case["before"]))
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)
		_button(root, str(case["button"])).emit_signal("pressed")
		assert_float((state.get(StringName(case["resource"])) as BigNum).to_value()).is_equal_approx(float(case["after"]), 0.001)
		if case.has("gain"):
			assert_float((state.get(StringName(case["gain"])) as BigNum).to_value()).is_equal_approx(float(case["gain_after"]), 0.001)
		else:
			assert_int(int(state.get(StringName(case["level"])))).is_equal(1)
		assert_that(refreshes).has_size(1)
		assert_that(feedback).has_size(1)
		assert_that(feedback[0].get("kind")).is_equal(&"toast")
		root.free()
	GameManager._state = previous_state

func test_language_upgrade_buttons_dispatch_exact_actions_and_do_not_duplicate_feedback() -> void:
	var previous_state: GameState = GameManager._state
	var life := GameState.new()
	life.faith = BigNum.new(1.0)
	GameManager._state = life
	var life_root := _page_for(life)
	var life_feedback: Array[Dictionary] = []
	var life_refreshes: Array[bool] = []
	_watch_page(life_root, life_feedback, life_refreshes)
	_button(life_root, "LifeUpgradeButton").emit_signal("pressed")
	assert_int(life.lingua_life_level).is_equal(1)
	assert_that(life_feedback).is_equal([{"kind": &"toast", "body": "（生命之语 · 第 1 阶）"}])
	assert_that(life_refreshes).has_size(1)
	life_root.free()

	var memory := GameState.new()
	memory.memory = BigNum.new(500.0)
	memory.insight = 5
	GameManager._state = memory
	var memory_root := _page_for(memory)
	var memory_feedback: Array[Dictionary] = []
	var memory_refreshes: Array[bool] = []
	_watch_page(memory_root, memory_feedback, memory_refreshes)
	_button(memory_root, "MemoryLinguaButton").emit_signal("pressed")
	assert_int(memory.lingua_memory_level).is_equal(1)
	assert_float(memory.memory.to_value()).is_equal_approx(0.0, 0.001)
	assert_int(memory.insight).is_equal(5)
	assert_that(memory_feedback).is_equal([{"kind": &"toast", "body": "（旧梦在根间醒来。你仍记得它们。）"}])
	assert_that(memory_refreshes).has_size(1)
	memory_root.free()
	GameManager._state = previous_state

func test_each_legacy_node_button_unlocks_its_exact_id_with_one_feedback() -> void:
	var previous_state: GameState = GameManager._state
	for row: Dictionary in NODE_BUTTONS:
		var node_id := StringName(row["id"])
		var state := GameState.new()
		state.lingua_life_level = LinguaData.LIFE_MAX_LEVEL
		state.lingua_memory_level = LinguaData.MEMORY_MAX_LEVEL
		state.sap = BigNum.new(50000.0)
		GameManager._state = state
		var root := _page_for(state)
		var feedback: Array[Dictionary] = []
		var refreshes: Array[bool] = []
		_watch_page(root, feedback, refreshes)
		_button(root, str(row["button"])).emit_signal("pressed")
		assert_that(state.lingua_nodes).is_equal([node_id])
		assert_that(refreshes).has_size(1)
		assert_that(feedback).has_size(1)
		var expected_name := str(LinguaData.get_node(node_id).get("name", ""))
		assert_that(feedback[0]).is_equal({"kind": &"toast", "body": "（%s 已点亮）" % expected_name})
		root.free()
	GameManager._state = previous_state

func test_failed_button_is_silent_and_requests_one_refresh() -> void:
	var previous_state: GameState = GameManager._state
	var state := GameState.new()
	state.lingua_life_level = 1
	GameManager._state = state
	var root := _page_for(state)
	var feedback: Array[Dictionary] = []
	var refreshes: Array[bool] = []
	_watch_page(root, feedback, refreshes)
	var before := state.to_dict()
	_button(root, "LifeUpgradeButton").emit_signal("pressed")
	assert_that(state.to_dict()).is_equal(before)
	assert_that(feedback).is_empty()
	assert_that(refreshes).has_size(1)
	root.free()
	GameManager._state = previous_state

func test_conversion_buttons_use_conversion_resource_gates() -> void:
	var previous_state: GameState = GameManager._state
	var state := GameState.new()
	state.lingua_nodes.assign([&"tree_canopy", &"root_resonance"])
	state.sap = BigNum.new(99.0)
	GameManager._state = state
	var root := _page_for(state)
	assert_that(_button(root, "FaithConvertButton").disabled).is_true()
	assert_that(_button(root, "MemoryConvertButton").disabled).is_true()
	state.sap = BigNum.new(100.0)
	root.refresh(state)
	assert_that(_button(root, "FaithConvertButton").disabled).is_false()
	assert_that(_button(root, "MemoryConvertButton").disabled).is_true()
	state.sap = BigNum.new(499.0)
	root.refresh(state)
	assert_that(_button(root, "FaithConvertButton").disabled).is_false()
	assert_that(_button(root, "MemoryConvertButton").disabled).is_true()
	state.sap = BigNum.new(500.0)
	root.refresh(state)
	assert_that(_button(root, "FaithConvertButton").disabled).is_false()
	assert_that(_button(root, "MemoryConvertButton").disabled).is_false()
	root.free()
	GameManager._state = previous_state

func _assert_single_touch_button(root: Node, node_name: String) -> void:
	var matches := root.find_children(node_name, "Button", true, false)
	assert_that(matches).has_size(1)
	if matches.size() == 1:
		assert_that((matches[0] as Button).custom_minimum_size.y).is_greater_equal(44.0)

func _page_for(state: GameState) -> LinguaPage:
	var root := LinguaScene.instantiate() as LinguaPage
	add_child(root)
	root.refresh(state)
	return root

func _watch_page(root: LinguaPage, feedback: Array[Dictionary], refreshes: Array[bool]) -> void:
	root.feedback_requested.connect(func(event: Dictionary) -> void: feedback.append(event))
	root.refresh_requested.connect(func() -> void: refreshes.append(true))

func _button(root: Node, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button

func _label(root: Node, node_name: String) -> Label:
	return root.find_child(node_name, true, false) as Label
