extends GdUnitTestSuite

const MainUI := preload("res://features/ui/main.gd")
const BeingsPage := preload("res://features/ui/pages/beings_page.gd")
const WorldAxisView := preload("res://features/ui/projections/world_axis_projection.gd")

func test_scene_root_scrolls_at_small_viewport() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    assert_that(root is ScrollContainer).is_true()
    assert_that(root.get_node("VBox/StoryStatusLabel").autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
    assert_that(root.find_child("EarthSenseButton", true, false)).is_not_null()
    assert_that(root.find_child("SkyLightButton", true, false)).is_not_null()
    assert_that(root.find_child("NineRealmsPanel", true, false)).is_not_null()
    assert_that(root.find_child("ReturnTitleButton", true, false)).is_not_null()
    root.free()

func test_m6d_world_ui_nodes_exist() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    for node_name in [
        "MidgardButton", "NidavellirButton", "AlfheimButton", "MuspelheimButton",
        "JotunheimButton", "NiflheimButton", "VanaheimButton", "HelheimButton", "AsgardButton",
        "WorldTraceButton", "RainNameButton", "RiverHearingButton", "SkyLadderButton",
        "WorldShapingButton", "WorldBreathButton",
        "OasisButton", "RainButton", "BanishShadowButton", "CallSoulButton", "ShapeButton",
        "MiracleHumanButton", "MiracleForestButton", "MiracleStoneButton", "MiracleWildButton",
    ]:
        assert_that(root.find_child(node_name, true, false)).is_not_null()
    root.free()

func test_m6d_shortcut_mode_expands_after_world_trace() -> void:
    var s := GameState.new()
    assert_that(MainUI.realm_visible_in_panel(s, &"midgard")).is_true()
    assert_that(MainUI.realm_visible_in_panel(s, &"nidavellir")).is_false()
    s.realm_echoes.append(&"midgard")
    assert_that(MainUI.realm_visible_in_panel(s, &"nidavellir")).is_true()
    assert_that(MainUI.realm_visible_in_panel(s, &"alfheim")).is_true()
    assert_that(MainUI.realm_visible_in_panel(s, &"muspelheim")).is_false()
    s.lingua_nodes.append(&"world_trace")
    assert_that(MainUI.realm_visible_in_panel(s, &"muspelheim")).is_true()
    assert_that(MainUI.realm_visible_in_panel(s, &"asgard")).is_true()

func test_m6d_realm_gap_names_primary_blocker() -> void:
    var s := GameState.new()
    var midgard := RealmCatalog.get_realm(&"midgard")
    assert_that(MainUI.realm_gap_text(s, midgard)).contains("遗迹 9")
    s.relics_found.append(9)
    assert_that(MainUI.realm_gap_text(s, midgard)).contains("生长")

func test_m6d_realm_echo_layers_by_run() -> void:
    assert_that(MainUI.realm_run_echo(1)).is_equal("")
    assert_that(MainUI.realm_run_echo(2)).contains("九个名字比根先醒")
    assert_that(MainUI.realm_run_echo(3)).contains("没有哪一界先开口")

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

func test_m6d_world_axis_projection_matches_legacy_main_shell() -> void:
    var state := GameState.new()
    assert_that(WorldAxisView.gap_text(state)).is_equal(MainUI.world_axis_gap_text(state))

func test_storyteller_hidden_before_discovery() -> void:
    assert_that(bool(BeingsPage.storyteller_view(GameState.new()).get("visible", true))).is_false()

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
    assert_that(MainUI.run_opening_text(1)).is_equal("")
    assert_that(MainUI.run_opening_text(2)).contains("你记得这缕光。你曾把它交给下一个自己。")
    assert_that(MainUI.run_opening_text(3)).contains("一点半")
    assert_that(MainUI.run_opening_text(4)).is_equal("")

func test_m6_settlement_view_loop_outcomes() -> void:
    # 好结局：hope +1（1→2），仍可「再次醒来」
    var good: Dictionary = MainUI.settlement_view(&"good", 1, 2)
    assert_that(str(good.get("title", ""))).is_equal("好结局")
    assert_that(str(good.get("hope_line", ""))).contains("1 → 2")
    assert_that(str(good.get("action_text", ""))).is_equal("再次醒来")
    assert_that(bool(good.get("loops", true))).is_true()
    # 坏/普通：hope 不变，仍循环
    var bad: Dictionary = MainUI.settlement_view(&"bad", 1, 1)
    assert_that(str(bad.get("title", ""))).is_equal("坏结局")
    assert_that(str(bad.get("hope_line", ""))).contains("1")
    assert_that(str(bad.get("action_text", ""))).is_equal("再次醒来")
    var normal: Dictionary = MainUI.settlement_view(&"normal", 1, 1)
    assert_that(str(normal.get("title", ""))).is_equal("普通结局")
    assert_that(str(normal.get("action_text", ""))).is_equal("再次醒来")

func test_m6_settlement_view_true_ends_loop() -> void:
    # 真结局：循环终止 → 「回到标题」，无「再次醒来」
    var view: Dictionary = MainUI.settlement_view(&"true", 2, 0)
    assert_that(str(view.get("title", ""))).is_equal("真结局")
    assert_that(str(view.get("action_text", ""))).is_equal("回到标题")
    assert_that(bool(view.get("loops", true))).is_false()
    assert_that(str(view.get("body", "")).length()).is_greater(10)

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
