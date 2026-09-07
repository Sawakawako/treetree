extends GdUnitTestSuite

const TreeHeartPage := preload("res://features/ui/pages/tree_heart_page.gd")
const TreeHeartScene := preload("res://features/ui/pages/tree_heart_page.tscn")

func test_growth_stage_uses_current_run_progress_only() -> void:
	var state := GameState.new()
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("种子")
	state.seedling_level = 1
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("幼苗")
	state.races[&"human"] = {"awakened": true, "population": 1.0}
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("成树")
	state.lingua_life_level = 1
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("巨树")
	state.pending_ending = {"outcome": &"good", "phase": &"return"}
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("世界之轴")

func test_heart_text_reuses_existing_copy() -> void:
	var state := GameState.new()
	assert_that(TreeHeartPage.heart_text(state)).contains("风从旧土上经过")
	state.run_number = 2
	assert_that(TreeHeartPage.heart_text(state)).contains("你记得这缕光")

func test_next_goal_is_deterministic_and_side_effect_free() -> void:
	var state := GameState.new()
	var before := state.to_dict()
	var view := TreeHeartPage.next_goal_view(state, {"seedling": 20, "leaf": 10})
	assert_that(view.get("action", &"")).is_equal(&"seedling")
	assert_that(state.to_dict()).is_equal(before)

func test_realm_echoes_alone_do_not_raise_current_run_stage() -> void:
	var state := GameState.new()
	state.realm_echoes.append(&"midgard")
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("种子")
	state.deep_dream = true
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("幼苗")
	state.deep_dream = false
	state.wind_veil = true
	assert_that(TreeHeartPage.growth_stage(state)).is_equal("幼苗")

func test_next_goal_keeps_the_frozen_priority() -> void:
	var state := GameState.new()
	state.seedling_level = 3
	var costs := {
		"leaf": 500,
		"branch": 1200,
		"chloroplast": 800,
		"xylem": 50,
		"sunflower": 2000,
		"nautilus": 2000,
		"root_eff": 1000,
		"root": 200,
	}
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"leaf")
	state.leaf_level = 1
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"branch")
	state.branch_level = 1
	state.chloroplast_level = 1
	state.xylem_level = 1
	state.sunflower_level = 1
	state.nautilus_level = 1
	state.root_eff_level = 1
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"root")
	state.races[&"human"] = {"awakened": true, "population": 1.0}
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"lingua")
	state.faith = BigNum.new(1.0)
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"relic_9")
	state.relics_found.append(9)
	assert_that(TreeHeartPage.next_goal_view(state, costs).get("action")).is_equal(&"world_axis")

func test_world_axis_projection_keeps_legacy_copy_without_mutation() -> void:
	var state := GameState.new()
	var before := state.to_dict()
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：还差 9 个界域")
	state.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim", &"muspelheim", &"jotunheim",
		&"niflheim", &"vanaheim", &"helheim", &"asgard",
	])
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：天地一息未点亮")
	state.lingua_nodes.append(&"world_breath")
	assert_that(WorldAxisProjection.gap_text(state)).is_equal("世界之轴：九界正在同一口风里呼吸")
	state.realm_echoes.clear()
	state.lingua_nodes.clear()
	assert_that(state.to_dict()).is_equal(before)

func test_scene_contains_tree_heart_actions_with_touch_targets() -> void:
	var root := TreeHeartScene.instantiate()
	assert_that(root is UiPage).is_true()
	assert_that(root.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	var button_names := [
		"GatherButton", "LeafButton", "BranchButton", "ChloroplastButton", "XylemButton",
		"SunflowerButton", "NautilusButton", "RootEffButton", "RootExploreButton",
		"SeedlingButton", "DeepDreamButton", "WindVeilButton",
	]
	for node_name: String in button_names:
		var button := root.find_child(node_name, true, false) as Button
		assert_that(button).is_not_null()
		assert_that(button.custom_minimum_size.y).is_greater_equal(44.0)
	assert_that((root.find_child("GatherButton", true, false) as Button).custom_minimum_size.y).is_greater_equal(52.0)
	root.free()

func test_refresh_projects_without_mutating_state() -> void:
	var root := TreeHeartScene.instantiate() as TreeHeartPage
	add_child(root)
	var state := GameState.new()
	var before := state.to_dict()
	root.refresh(state)
	assert_that(state.to_dict()).is_equal(before)
	assert_that((root.find_child("StageLabel", true, false) as Label).text).contains("种子")
	root.free()

func test_one_button_click_emits_one_refresh_request() -> void:
	var previous_state: GameState = GameManager._state
	GameManager._state = GameState.new()
	var root := TreeHeartScene.instantiate() as TreeHeartPage
	add_child(root)
	var refreshes: Array[bool] = []
	root.refresh_requested.connect(func() -> void: refreshes.append(true))
	(root.find_child("GatherButton", true, false) as Button).emit_signal("pressed")
	assert_that(refreshes).has_size(1)
	root.free()
	GameManager._state = previous_state

func test_deep_dream_preserves_narrative_and_toast_feedback() -> void:
	var previous_state: GameState = GameManager._state
	GameManager._state = GameState.new()
	GameManager._state.sap = BigNum.new(3000.0)
	var root := TreeHeartScene.instantiate() as TreeHeartPage
	add_child(root)
	var feedback: Array[Dictionary] = []
	root.feedback_requested.connect(func(event: Dictionary) -> void: feedback.append(event))
	(root.find_child("DeepDreamButton", true, false) as Button).emit_signal("pressed")
	assert_that(feedback).has_size(2)
	if feedback.size() < 2:
		root.free()
		GameManager._state = previous_state
		return
	assert_that(feedback[0].get("kind")).is_equal(&"narrative")
	assert_that(str(feedback[0].get("body", ""))).contains("泥下的梦，比河里的更老")
	assert_that(feedback[1]).is_equal({"kind": &"toast", "body": "（深根梦 · 记忆 +15）"})
	root.free()
	GameManager._state = previous_state
