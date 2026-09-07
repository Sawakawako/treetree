extends GdUnitTestSuite

const NineRealmsPage := preload("res://features/ui/pages/nine_realms_page.gd")
const NineRealmsScene := preload("res://features/ui/pages/nine_realms_page.tscn")
const WorldAxisProjection := preload("res://features/ui/projections/world_axis_projection.gd")

const REALM_BUTTONS: Array[String] = [
	"AsgardButton", "VanaheimButton", "AlfheimButton",
	"JotunheimButton", "MidgardButton", "NidavellirButton",
	"NiflheimButton", "HelheimButton", "MuspelheimButton",
]
const WORLD_NODE_BUTTONS: Array[String] = [
	"WorldTraceButton", "RainNameButton", "RiverHearingButton",
	"SkyLadderButton", "WorldShapingButton", "WorldBreathButton",
]
const MIRACLE_BUTTONS: Array[String] = [
	"OasisButton", "RainButton", "BanishShadowButton", "CallSoulButton", "ShapeButton",
]
const MIRACLE_TARGET_BUTTONS: Array[String] = [
	"MiracleHumanButton", "MiracleForestButton", "MiracleStoneButton", "MiracleWildButton",
]

func test_shortcut_mode_expands_after_world_trace() -> void:
	var state := GameState.new()
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"midgard")).is_true()
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"nidavellir")).is_false()
	state.realm_echoes.append(&"midgard")
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"nidavellir")).is_true()
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"alfheim")).is_true()
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"muspelheim")).is_false()
	state.lingua_nodes.append(&"world_trace")
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"muspelheim")).is_true()
	assert_that(NineRealmsPage.realm_visible_in_panel(state, &"asgard")).is_true()

func test_realm_gap_names_primary_blocker_in_legacy_order() -> void:
	var state := GameState.new()
	var midgard := RealmCatalog.get_realm(&"midgard")
	assert_that(NineRealmsPage.realm_gap_text(state, midgard)).contains("遗迹 9")
	state.relics_found.append(9)
	assert_that(NineRealmsPage.realm_gap_text(state, midgard)).contains("生长")

func test_realm_echo_layers_by_run() -> void:
	assert_that(NineRealmsPage.realm_run_echo(1)).is_equal("")
	assert_that(NineRealmsPage.realm_run_echo(2)).contains("九个名字比根先醒")
	assert_that(NineRealmsPage.realm_run_echo(3)).contains("没有哪一界先开口")

func test_miracle_gap_retains_prerequisite_then_resource_order() -> void:
	var state := GameState.new()
	var oasis := MiracleCatalog.get_miracle(&"oasis")
	assert_that(NineRealmsPage.miracle_gap_text(state, oasis)).contains("米德加德")
	state.realm_echoes.append(&"midgard")
	assert_that(NineRealmsPage.miracle_gap_text(state, oasis)).contains("雨名")
	state.lingua_nodes.append(&"rain_name")
	state.lingua_life_level = 2
	assert_that(NineRealmsPage.miracle_gap_text(state, oasis)).is_equal("信仰不足")

func test_world_axis_gap_retains_realm_then_breath_order() -> void:
	var state := GameState.new()
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：还差 9 个界域")
	state.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim", &"muspelheim", &"jotunheim",
		&"niflheim", &"vanaheim", &"helheim", &"asgard",
	])
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：天地一息未点亮")
	state.lingua_nodes.append(&"world_breath")
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：九界正在同一口风里呼吸")

func test_world_node_completion_is_retained() -> void:
	var state := GameState.new()
	state.lingua_nodes.append(&"world_trace")
	var view := NineRealmsPage.world_node_view(state, &"world_trace")
	assert_that(view.get("status", "")).is_equal("已点亮")
	assert_that(view.get("disabled", false)).is_true()

func test_world_node_view_is_a_side_effect_free_projection() -> void:
	var state := GameState.new()
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	state.sap = BigNum.new(8000.0)
	var before := state.to_dict()
	var view := NineRealmsPage.world_node_view(state, &"world_trace")
	assert_that(view.get("status", "")).is_equal("可以点亮")
	assert_that(view.get("disabled", true)).is_false()
	assert_that(state.to_dict()).is_equal(before)

func test_scene_contains_scrollable_cards_and_every_legacy_action_once() -> void:
	var root := NineRealmsScene.instantiate()
	assert_that(root is UiPage).is_true()
	assert_that(root.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	for card_name: String in [
		"PageHeader", "WorldSummaryCard", "RealmCard", "WorldLinguaCard",
		"MiracleCard", "MiracleTargetCard",
	]:
		assert_that(root.find_child(card_name, true, false)).is_not_null()
	for flow_name: String in ["CrownFlow", "TrunkFlow", "RootDomainFlow", "WorldLinguaFlow", "MiracleFlow", "MiracleTargetFlow"]:
		assert_that(root.find_child(flow_name, true, false) is HFlowContainer).is_true()
	for node_name: String in REALM_BUTTONS + WORLD_NODE_BUTTONS + MIRACLE_BUTTONS + MIRACLE_TARGET_BUTTONS + ["WorldAxisButton"]:
		_assert_single_touch_button(root, node_name)
	root.free()

func test_refresh_projects_realm_node_miracle_and_axis_without_mutation() -> void:
	var state := _rich_state()
	state.run_number = 2
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	state.lingua_nodes.assign([&"world_trace"])
	var root := _page_for(state)
	var before := state.to_dict()
	root.refresh(state)
	assert_that(state.to_dict()).is_equal(before)
	assert_that(_label(root, "WorldHeaderLabel").text).contains("3/9")
	assert_that(_label(root, "WorldRunEchoLabel").visible).is_true()
	assert_that(_label(root, "WorldModeLabel").text).is_equal("三域全景 · 冠 / 干 / 根")
	assert_that(_button(root, "MidgardButton").text).contains("◇")
	assert_that(_button(root, "WorldTraceButton").text).contains("◆")
	assert_that(_label(root, "AxisGateLabel").text).is_equal(WorldAxisProjection.gap_text(state))
	root.free()

func test_realm_and_world_node_buttons_dispatch_their_exact_ids() -> void:
	var previous_state: GameState = GameManager._state
	var realm_state := _rich_state()
	GameManager._state = realm_state
	var realm_page := _page_for(realm_state)
	var realm_refreshes: Array[bool] = []
	realm_page.refresh_requested.connect(func() -> void: realm_refreshes.append(true))
	_button(realm_page, "MidgardButton").emit_signal("pressed")
	assert_that(realm_state.realm_echoes).is_equal([&"midgard"])
	assert_that(realm_refreshes).has_size(1)
	realm_page.free()

	var node_state := _rich_state()
	node_state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	GameManager._state = node_state
	var node_page := _page_for(node_state)
	var node_refreshes: Array[bool] = []
	node_page.refresh_requested.connect(func() -> void: node_refreshes.append(true))
	_button(node_page, "WorldTraceButton").emit_signal("pressed")
	assert_that(node_state.lingua_nodes).is_equal([&"world_trace"])
	assert_that(node_refreshes).has_size(1)
	node_page.free()
	GameManager._state = previous_state

func test_targeted_miracle_waits_for_target_then_dispatches_once() -> void:
	var previous_state: GameState = GameManager._state
	var state := _miracle_ready_state()
	GameManager._state = state
	var root := _page_for(state)
	var refreshes: Array[bool] = []
	root.refresh_requested.connect(func() -> void: refreshes.append(true))
	_button(root, "CallSoulButton").emit_signal("pressed")
	assert_that(state.miracle_counts).is_empty()
	assert_that(root.find_child("MiracleTargetCard", true, false).visible).is_true()
	_button(root, "MiracleHumanButton").emit_signal("pressed")
	assert_that(int(state.miracle_counts.get(&"call_soul", 0))).is_equal(1)
	assert_that(float(state.races[&"human"].get("population", 0.0))).is_equal_approx(60.0, 0.001)
	assert_that(refreshes).has_size(2)
	root.free()
	GameManager._state = previous_state

func test_world_axis_button_uses_game_manager_entrypoint() -> void:
	var previous_state: GameState = GameManager._state
	var previous_pending: StringName = GameManager._pending_choice
	var state := _axis_ready_state()
	GameManager._state = state
	GameManager._pending_choice = &""
	var root := _page_for(state)
	var refreshes: Array[bool] = []
	root.refresh_requested.connect(func() -> void: refreshes.append(true))
	_button(root, "WorldAxisButton").emit_signal("pressed")
	assert_that(GameManager._pending_choice).is_equal(&"world_axis")
	assert_that(refreshes).has_size(1)
	root.free()
	GameManager._state = previous_state
	GameManager._pending_choice = previous_pending

func _rich_state() -> GameState:
	var state := GameState.new()
	state.relics_found.append(9)
	state.root_depth = 9
	state.growth = BigNum.new(2000.0)
	state.sap = BigNum.new(100000.0)
	state.memory = BigNum.new(10000.0)
	state.faith = BigNum.new(10000.0)
	for race_id: StringName in GameState.RACE_IDS:
		state.races[race_id] = {"awakened": true, "population": 50.0}
	return state

func _miracle_ready_state() -> GameState:
	var state := _rich_state()
	state.lingua_life_level = 3
	state.lingua_nodes.assign([&"rain_name", &"river_hearing", &"world_shaping"])
	state.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim", &"muspelheim", &"jotunheim",
		&"niflheim", &"vanaheim", &"helheim", &"asgard",
	])
	state.soul_river = 1
	return state

func _axis_ready_state() -> GameState:
	var state := _miracle_ready_state()
	for choice: Dictionary in ChoiceLibrary.load_all():
		var choice_id := StringName(str(choice.get("id", "")))
		if choice_id != &"world_axis":
			state.choices_done.append(choice_id)
	state.storyteller_stories.append(&"story_6")
	state.lingua_nodes.append(&"world_breath")
	return state

func _page_for(state: GameState) -> NineRealmsPage:
	var root := NineRealmsScene.instantiate() as NineRealmsPage
	add_child(root)
	root.refresh(state)
	return root

func _assert_single_touch_button(root: Node, node_name: String) -> void:
	var matches := root.find_children(node_name, "Button", true, false)
	assert_that(matches).has_size(1)
	if matches.size() == 1:
		assert_that((matches[0] as Button).custom_minimum_size.y).is_greater_equal(44.0)

func _button(root: Node, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button

func _label(root: Node, node_name: String) -> Label:
	return root.find_child(node_name, true, false) as Label
