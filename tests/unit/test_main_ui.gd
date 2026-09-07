extends GdUnitTestSuite

const LegacyContract := preload("res://tests/unit/test_main_ui_legacy_contract.gd")
const TreeHeartPage := preload("res://features/ui/pages/tree_heart_page.gd")
const BeingsPage := preload("res://features/ui/pages/beings_page.gd")
const LinguaPage := preload("res://features/ui/pages/lingua_page.gd")
const NineRealmsPage := preload("res://features/ui/pages/nine_realms_page.gd")

func test_main_scene_uses_fixed_shell_and_independent_pages() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    assert_that(root is Control).is_true()
    for node_name: String in [
        "ResourceBar", "PageStack", "TreeHeartPage", "BeingsPage",
        "LinguaPage", "NineRealmsPage", "BottomNavigation", "EventLayer",
    ]:
        assert_that(root.find_child(node_name, true, false)).is_not_null()
    assert_that(root.find_child("PageStack", true, false) is ScrollContainer).is_false()
    root.free()

func test_every_action_belongs_to_exactly_one_page_or_shell() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    for node_name: String in LegacyContract.ACTION_NODE_NAMES:
        var matches := root.find_children(node_name, "Button", true, false)
        assert_that(matches).has_size(1)
    root.free()

func test_m6d_ui_texts_are_archived_exactly() -> void:
    var file := FileAccess.open("res://docs/world-tree/narrative/09-ui-broadcast.md", FileAccess.READ)
    assert_that(file).is_not_null()
    var archive := file.get_as_text()
    file.close()
    for exact_text in [
        "近路 · 当前可抵达",
        "三域全景 · 冠 / 干 / 根",
        "九个名字比根先醒。你还没有伸出枝条，远处已经有回声。",
        "这一次，没有哪一界先开口。你知道每一条路，也知道路的尽头。",
        "世界之轴：天地一息未点亮",
    ]:
        assert_that(archive).contains(exact_text)

func test_nine_realms_projection_preserves_the_legacy_shortcut_contract() -> void:
    var state := GameState.new()
    assert_that(NineRealmsPage.realm_visible_in_panel(state, &"midgard")).is_true()
    assert_that(NineRealmsPage.realm_visible_in_panel(state, &"nidavellir")).is_false()

func test_storyteller_hidden_before_discovery() -> void:
    assert_that(bool(BeingsPage.storyteller_view(GameState.new()).get("visible", true))).is_false()

func test_lingua_page_projection_preserves_the_legacy_unlock_contract() -> void:
    var state := GameState.new()
    state.lingua_life_level = 1
    state.sap = BigNum.new(3000.0)
    var before := state.to_dict()
    var view := LinguaPage.node_view(state, &"root_echo")
    assert_that(view.get("disabled", true)).is_false()
    assert_that(view.get("status", "")).is_equal("可以点亮")
    assert_that(state.to_dict()).is_equal(before)

func test_storyteller_shows_locked_hint_after_cave() -> void:
    var s := GameState.new()
    s.choice_flags.append(&"cave_found")
    var view: Dictionary = BeingsPage.storyteller_view(s)
    assert_that(view.get("visible", false)).is_true()
    assert_that(view.get("disabled", false)).is_true()
    assert_that(str(view.get("status_text", ""))).contains("被守住的梦")

func test_storyteller_shows_available_and_completed_states() -> void:
    var ready := GameState.new()
    ready.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
    var available: Dictionary = BeingsPage.storyteller_view(ready)
    assert_that(available.get("disabled", true)).is_false()
    assert_that(str(available.get("button_text", ""))).contains("已读 0/3")

    var done := GameState.new()
    done.choice_flags.append(&"cave_found")
    done.storyteller_stories.assign([&"story_4", &"story_5", &"story_6"])
    var completed: Dictionary = BeingsPage.storyteller_view(done)
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

# ---------- M6 终局 UI：世界之轴入口 + 归还序列 + 结算画面 + 周目层叠 ----------

func test_m6_ending_scene_nodes_exist() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    # 世界之轴入口按钮：默认隐藏（axis_ready 门控后由 _refresh 显示）
    assert_that(root.find_child("WorldAxisButton", true, false)).is_not_null()
    assert_that(root.find_child("WorldAxisButton", true, false).visible).is_false()
    # 明选⑦ 第四选项（真结局隐藏项 ……）：通用弹层需支持 4 选项
    assert_that(root.find_child("ChoiceOptionDButton", true, false)).is_not_null()
    # 归还序列面板（逐步点击推进）+ 结算画面（结局文案/希望/再次醒来|回到标题）
    assert_that(root.find_child("ReturnPanel", true, false)).is_not_null()
    assert_that(root.find_child("ReturnProgressLabel", true, false)).is_not_null()
    assert_that(root.find_child("EndingPanel", true, false)).is_not_null()
    root.free()

func test_m6_world_axis_choice_has_four_options() -> void:
    var c := ChoiceLibrary.get_choice(&"world_axis")
    assert_that(c.get("options", [])).has_size(4)

func test_m6_world_axis_choice_has_hidden_self_option() -> void:
    # d「……」= 真结局隐藏项：unlock 门槛四锁（三周目/关系满/领悟满/希望≥2）
    var c := ChoiceLibrary.get_choice(&"world_axis")
    var opts: Array = c.get("options", [])
    var self_opt: Dictionary = {}
    for o: Variant in opts:
        if typeof(o) == TYPE_DICTIONARY and StringName(str(o.get("id", ""))) == &"d":
            self_opt = o
            break
    assert_that(self_opt).is_not_empty()
    var unlock: Dictionary = self_opt.get("unlock", {})
    assert_that(int(unlock.get("run_gte", 0))).is_equal(3)
    assert_that(int(unlock.get("hope_gte", 0))).is_equal(2)

func test_m6_run_opening_text_layers_by_run() -> void:
    # spec §8.6 / 设计 §5.3：二周目/三周目开局文本层叠；一周目无附加层
    assert_that(TreeHeartPage.run_opening_text(1)).is_equal("")
    assert_that(TreeHeartPage.run_opening_text(2)).contains("你记得这缕光。你曾把它交给下一个自己。")
    assert_that(TreeHeartPage.run_opening_text(3)).contains("一点半")
    assert_that(TreeHeartPage.run_opening_text(4)).is_equal("")

func test_m6_ending_ui_texts_are_archived_exactly() -> void:
    var file := FileAccess.open("res://docs/world-tree/narrative/09-ui-broadcast.md", FileAccess.READ)
    assert_that(file).is_not_null()
    var archive := file.get_as_text()
    file.close()
    for exact_text in [
        "走向世界之轴",
        "你记得这缕光。你曾把它交给下一个自己。",
        "希望长了一点：",
        "再次醒来",
        "回到标题",
    ]:
        assert_that(archive).contains(exact_text)
