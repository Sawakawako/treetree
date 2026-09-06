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

func test_detail_text_keeps_readable_contrast_against_library_background() -> void:
	var scene := load("res://features/memories/memory_library.tscn") as PackedScene
	var root := scene.instantiate()
	add_child(root)
	var detail_text := root.find_child("DetailText", true, false) as RichTextLabel
	var background := root.find_child("Background", true, false) as ColorRect
	var text_color := detail_text.get_theme_color("default_color")
	assert_that(_contrast_ratio(text_color, background.color)).is_greater_equal(4.5)
	root.free()

func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

