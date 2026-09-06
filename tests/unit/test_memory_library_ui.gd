extends GdUnitTestSuite

const LibraryUI := preload("res://features/memories/memory_library.gd")

func test_library_scene_has_category_list_reader_and_back_nodes() -> void:
	var scene := load("res://features/memories/memory_library.tscn") as PackedScene
	var root := scene.instantiate()
	assert_that(root is Control).is_true()
	for node_name: String in [
		"LibraryTitleLabel", "SummaryLabel", "CategoryOption", "EntryScroll", "EntryList",
		"DetailTitleLabel", "DetailScroll", "DetailText", "BackButton",
	]:
		assert_that(root.find_child(node_name, true, false)).is_not_null()
	root.free()

func test_entry_button_text_marks_locked_rows_without_leaking_title() -> void:
	assert_that(LibraryUI.entry_button_text({"title": "尚未落进年轮", "unlocked": false}, 2)).is_equal("02 · 尚未落进年轮")
	assert_that(LibraryUI.entry_button_text({"title": "城市废墟", "unlocked": true}, 1)).is_equal("01 · 城市废墟")

