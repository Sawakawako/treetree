extends GdUnitTestSuite

const TitleUI := preload("res://features/title/title.gd")

func test_title_scene_has_navigation_and_confirmation_nodes() -> void:
	var scene := load("res://features/title/title.tscn") as PackedScene
	var root := scene.instantiate()
	assert_that(root is Control).is_true()
	for node_name: String in [
		"TitleLabel", "HeartLabel", "ContinueButton", "NewRunButton", "LibraryButton",
		"StatusLabel", "ConfirmScrim", "ConfirmPanel", "ConfirmNewRunButton", "CancelNewRunButton",
	]:
		assert_that(root.find_child(node_name, true, false)).is_not_null()
	root.free()

func test_status_view_distinguishes_fresh_and_saved_runs() -> void:
	var archive := MemoryArchiveState.new()
	archive.relics.append(1)
	var fresh := TitleUI.status_view(false, 1, archive)
	assert_that(bool(fresh.get("continue_enabled", true))).is_false()
	assert_that(str(fresh.get("run_text", ""))).contains("尚未发芽")
	assert_that(str(fresh.get("library_text", ""))).contains("1/")
	var saved := TitleUI.status_view(true, 3, archive)
	assert_that(bool(saved.get("continue_enabled", false))).is_true()
	assert_that(str(saved.get("run_text", ""))).contains("第三个春天")

func test_complete_archive_uses_completion_copy() -> void:
	var archive := MemoryArchiveState.new()
	archive.mark_complete()
	var view := TitleUI.status_view(false, 1, archive)
	assert_that(str(view.get("library_text", ""))).contains("已经读完")
