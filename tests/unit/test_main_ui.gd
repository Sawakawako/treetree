extends GdUnitTestSuite

const MainUI := preload("res://features/ui/main.gd")

func test_scene_root_scrolls_at_small_viewport() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    assert_that(root is ScrollContainer).is_true()
    assert_that(root.get_node("VBox/StoryStatusLabel").autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
    assert_that(root.find_child("EarthSenseButton", true, false)).is_not_null()
    assert_that(root.find_child("SkyLightButton", true, false)).is_not_null()
    assert_that(root.find_child("WorldLinguaButton", true, false)).is_null()
    assert_that(root.find_child("MiracleButton", true, false)).is_null()
    assert_that(root.find_child("NineRealmsButton", true, false)).is_null()
    root.free()

func test_storyteller_hidden_before_discovery() -> void:
    assert_that(bool(MainUI.storyteller_view(GameState.new()).get("visible", true))).is_false()

func test_storyteller_shows_locked_hint_after_cave() -> void:
    var s := GameState.new()
    s.choice_flags.append(&"cave_found")
    var view: Dictionary = MainUI.storyteller_view(s)
    assert_that(view.get("visible", false)).is_true()
    assert_that(view.get("disabled", false)).is_true()
    assert_that(str(view.get("status_text", ""))).contains("被守住的梦")

func test_storyteller_shows_available_and_completed_states() -> void:
    var ready := GameState.new()
    ready.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
    var available: Dictionary = MainUI.storyteller_view(ready)
    assert_that(available.get("disabled", true)).is_false()
    assert_that(str(available.get("button_text", ""))).contains("已读 0/3")

    var done := GameState.new()
    done.choice_flags.append(&"cave_found")
    done.storyteller_stories.assign([&"story_4", &"story_5", &"story_6"])
    var completed: Dictionary = MainUI.storyteller_view(done)
    assert_that(completed.get("disabled", false)).is_true()
    assert_that(str(completed.get("button_text", ""))).contains("已读 3/3")

func test_m5h_ui_texts_are_archived_exactly() -> void:
    var file := FileAccess.open("res://docs/world-tree/narrative/09-ui-broadcast.md", FileAccess.READ)
    assert_that(file).is_not_null()
    var archive := file.get_as_text()
    file.close()
    for exact_text in [
        "九处旧梦，都已经收进年轮。土里只剩安静。",
        "火塘边，有一个故事正等着你。",
        "火已经安静下来。三个故事，都留在年轮里。",
        "记忆之语 Lv1 · 500 记忆 + 领悟 5（领悟不消耗）",
        "离开时，根仍听着大地。\\n%d 分钟里：%s",
    ]:
        assert_that(archive).contains(exact_text)
