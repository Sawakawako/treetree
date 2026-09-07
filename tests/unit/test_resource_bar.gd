extends GdUnitTestSuite

const ResourceBarScript := preload("res://features/ui/components/resource_bar.gd")
const ResourceBarScene := preload("res://features/ui/components/resource_bar.tscn")

func test_resource_view_has_four_stable_summary_items_and_complete_expansion() -> void:
	var state := GameState.new()
	state.sap = BigNum.new(12.0)
	state.growth = BigNum.new(3.0)
	state.memory = BigNum.new(4.0)
	state.faith = BigNum.new(5.0)
	state.soul_river = 90
	state.insight = 2
	state.hope = 1
	var view := ResourceBarScript.build_view(state, 100.0, &"beings")
	assert_that(view.get("summary", [])).has_size(4)
	assert_that(view.get("expanded", [])).has_size(8)
	assert_that(view.get("context", [])).is_equal([&"soul", &"insight"])

func test_resource_summary_keeps_its_declared_order() -> void:
	var view := ResourceBarScript.build_view(GameState.new(), 100.0, &"tree_heart")
	var ids: Array[StringName] = []
	for item: Dictionary in view.get("summary", []):
		ids.append(item.get("id", &""))
	assert_that(ids).is_equal([&"sap", &"growth", &"memory", &"faith"])

func test_resource_refresh_does_not_mutate_state() -> void:
	var state := GameState.new()
	var before := state.to_dict()
	ResourceBarScript.build_view(state, 100.0, &"tree_heart")
	assert_that(state.to_dict()).is_equal(before)

func test_resource_scene_exposes_fixed_summary_expansion_and_touch_target() -> void:
	var root := ResourceBarScene.instantiate()
	assert_that(root.find_child("SummaryPanel", true, false)).is_not_null()
	assert_that(root.find_child("ExpandedPanel", true, false)).is_not_null()
	assert_that(root.find_child("ExpandButton", true, false)).is_not_null()
	var values: Array[Node] = root.find_children("*ValueLabel", "Label", true, false)
	assert_that(values).has_size(8)
	var expand_button := root.find_child("ExpandButton", true, false) as Button
	assert_that(expand_button.custom_minimum_size.y).is_greater_equal(44.0)
	assert_that(expand_button.focus_mode).is_equal(Control.FOCUS_ALL)
	root.free()

func test_collapse_hides_expanded_panel_and_emits_false() -> void:
	var root := ResourceBarScene.instantiate()
	add_child(root)
	var emitted: Array[bool] = []
	root.expanded_changed.connect(func(expanded: bool) -> void: emitted.append(expanded))
	var button := root.find_child("ExpandButton", true, false) as Button
	button.emit_signal("pressed")
	root.collapse()
	assert_that((root.find_child("ExpandedPanel", true, false) as Control).visible).is_false()
	assert_that(emitted).is_equal([true, false])
	root.free()
