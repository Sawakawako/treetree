extends GdUnitTestSuite

const Navigation := preload("res://features/ui/components/bottom_navigation.gd")

func test_fresh_state_only_shows_tree_heart() -> void:
	assert_that(Navigation.visible_tabs(GameState.new())).is_equal([&"tree_heart"])

func test_tabs_appear_from_existing_progress_in_stable_order() -> void:
	var state := GameState.new()
	state.races[&"stoneborn"] = {"awakened": true, "population": 1.0}
	state.faith = BigNum.new(1.0)
	state.relics_found.append(9)
	assert_that(Navigation.visible_tabs(state)).is_equal([
		&"tree_heart", &"beings", &"lingua", &"nine_realms",
	])

func test_memory_boundary_unlocks_lingua_but_disabled_legacy_button_does_not() -> void:
	var fresh := GameState.new()
	assert_that(Navigation.visible_tabs(fresh).has(&"lingua")).is_false()
	fresh.memory = BigNum.new(500.0)
	fresh.insight = 5
	assert_that(Navigation.visible_tabs(fresh)).contains(&"lingua")

func test_existing_lingua_progress_keeps_tab_visible() -> void:
	var state := GameState.new()
	state.lingua_nodes.append(&"root_echo")
	assert_that(Navigation.visible_tabs(state)).contains(&"lingua")

func test_hidden_requested_tab_falls_back_to_tree_heart() -> void:
	assert_that(Navigation.normalize_active_tab(&"nine_realms", [&"tree_heart"])).is_equal(&"tree_heart")

func test_navigation_buttons_have_minimum_touch_height_and_fixed_order() -> void:
	var root := preload("res://features/ui/components/bottom_navigation.tscn").instantiate()
	for tab_id: StringName in Navigation.TAB_ORDER:
		var button: Button = root.get_node(String(tab_id).to_pascal_case() + "Tab")
		assert_that(button.custom_minimum_size.y).is_equal(48.0)
	assert_that(root.get_child(0).name).is_equal("TreeHeartTab")
	assert_that(root.get_child(1).name).is_equal("BeingsTab")
	assert_that(root.get_child(2).name).is_equal("LinguaTab")
	assert_that(root.get_child(3).name).is_equal("NineRealmsTab")
	root.free()

func test_refresh_hides_locked_tabs_and_emits_one_selection_signal() -> void:
	var root := preload("res://features/ui/components/bottom_navigation.tscn").instantiate()
	add_child(root)
	var emitted: Array[StringName] = []
	root.tab_selected.connect(func(tab_id: StringName) -> void: emitted.append(tab_id))
	var visible: Array[StringName] = [&"tree_heart"]
	root.refresh(visible, &"tree_heart")
	assert_that(root.get_node("BeingsTab").visible).is_false()
	root.get_node("TreeHeartTab").emit_signal("pressed")
	assert_that(emitted).is_equal([&"tree_heart"])
	root.free()
