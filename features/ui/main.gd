extends Control

const RACE_ROWS := {
    &"human": "人族",
    &"forestfolk": "林地民",
    &"stoneborn": "石裔",
    &"wildfolk": "野民",
}
const RELATION_LABELS := {
    -3: "敌意", -2: "敌意", -1: "冷淡", 0: "平常",
    1: "友善", 2: "亲近", 3: "挚友",
}
const RELATION_COLORS := {
    -3: Color("#7a8a99"), -2: Color("#7a8a99"), -1: Color("#9aa5ad"),
    0: Color.WHITE, 1: Color("#c9a25c"), 2: Color("#e6a23c"), 3: Color("#f0b64e"),
}

@onready var daylight_label: Label = %DaylightLabel
@onready var sap_label: Label = %SapLabel
@onready var growth_label: Label = %GrowthLabel
@onready var leaf_cost_label: Label = %LeafCostLabel
@onready var branch_cost_label: Label = %BranchCostLabel
@onready var leaf_button: Button = %LeafButton
@onready var branch_button: Button = %BranchButton
@onready var log_label: Label = %LogLabel
@onready var memory_label: Label = %MemoryLabel
@onready var faith_label: Label = %FaithLabel
@onready var root_button: Button = %RootExploreButton
@onready var dream_text_label: Label = %DreamTextLabel
@onready var race_event_label: Label = %RaceEventLabel
@onready var race_human_label: Label = %RaceHumanLabel
@onready var race_forest_label: Label = %RaceForestLabel
@onready var race_stone_label: Label = %RaceStoneLabel
@onready var race_wild_label: Label = %RaceWildLabel
@onready var totem_panel: PanelContainer = %TotemPanel
@onready var totem_label: Label = %TotemLabel
@onready var totem_button: Button = %TotemInterpretButton
@onready var insight_label: Label = %InsightLabel
@onready var interact_human_button: Button = %InteractHumanButton
@onready var interact_forest_button: Button = %InteractForestButton
@onready var interact_stone_button: Button = %InteractStoneButton
@onready var interact_wild_button: Button = %InteractWildButton
@onready var plunder_human_button: Button = %PlunderHumanButton
@onready var plunder_forest_button: Button = %PlunderForestButton
@onready var plunder_stone_button: Button = %PlunderStoneButton
@onready var plunder_wild_button: Button = %PlunderWildButton
@onready var avatar_panel: PanelContainer = %AvatarPanel
@onready var avatar_label: Label = %AvatarLabel
@onready var intimate_human_button: Button = %IntimateHumanButton
@onready var intimate_forest_button: Button = %IntimateForestButton
@onready var intimate_stone_button: Button = %IntimateStoneButton
@onready var intimate_wild_button: Button = %IntimateWildButton
@onready var chloroplast_button: Button = %ChloroplastButton
@onready var chloroplast_cost_label: Label = %ChloroplastCostLabel
@onready var xylem_button: Button = %XylemButton
@onready var xylem_cost_label: Label = %XylemCostLabel
@onready var sunflower_button: Button = %SunflowerButton
@onready var sunflower_cost_label: Label = %SunflowerCostLabel
@onready var nautilus_button: Button = %NautilusButton
@onready var nautilus_cost_label: Label = %NautilusCostLabel
@onready var root_eff_button: Button = %RootEffButton
@onready var root_eff_cost_label: Label = %RootEffCostLabel
@onready var soul_label: Label = %SoulLabel
@onready var revive_human_button: Button = %ReviveHumanButton
@onready var revive_forest_button: Button = %ReviveForestButton
@onready var revive_stone_button: Button = %ReviveStoneButton
@onready var revive_wild_button: Button = %ReviveWildButton
@onready var plunder_soul_human_button: Button = %PlunderSoulHumanButton
@onready var plunder_soul_forest_button: Button = %PlunderSoulForestButton
@onready var plunder_soul_stone_button: Button = %PlunderSoulStoneButton
@onready var plunder_soul_wild_button: Button = %PlunderSoulWildButton
@onready var choice_panel: PanelContainer = %ChoicePanel
@onready var choice_title_label: Label = %ChoiceTitleLabel
@onready var choice_intro_label: Label = %ChoiceIntroLabel
@onready var choice_option_a_button: Button = %ChoiceOptionAButton
@onready var choice_option_b_button: Button = %ChoiceOptionBButton
@onready var choice_option_c_button: Button = %ChoiceOptionCButton
@onready var seedling_button: Button = %SeedlingButton
@onready var seedling_cost_label: Label = %SeedlingCostLabel
@onready var deep_dream_button: Button = %DeepDreamButton
@onready var wind_veil_button: Button = %WindVeilButton
@onready var firepit_button: Button = %FirepitButton
@onready var ring_button: Button = %RingButton
@onready var forge_button: Button = %ForgeButton
@onready var totem_pole_button: Button = %TotemPoleButton
@onready var faith_convert_button: Button = %FaithConvertButton
@onready var memory_convert_button: Button = %MemoryConvertButton
@onready var life_upgrade_button: Button = %LifeUpgradeButton
@onready var life_cost_label: Label = %LifeCostLabel
@onready var faith_engine_button: Button = %FaithEngineButton
@onready var faith_engine_cost_label: Label = %FaithEngineCostLabel
@onready var memory_engine_button: Button = %MemoryEngineButton
@onready var memory_engine_cost_label: Label = %MemoryEngineCostLabel
@onready var root_echo_button: Button = %RootEchoButton
@onready var root_resonance_button: Button = %RootResonanceButton
@onready var deep_root_button: Button = %DeepRootButton
@onready var tree_canopy_button: Button = %TreeCanopyButton
@onready var ring_memory_button: Button = %RingMemoryButton
@onready var cloud_crown_button: Button = %CloudCrownButton
@onready var wood_heart_button: Button = %WoodHeartButton
@onready var song_resonance_button: Button = %SongResonanceButton
@onready var village_heart_button: Button = %VillageHeartButton
@onready var grace_button: Button = %GraceButton
@onready var altar_button: Button = %AltarButton

func _ready() -> void:
    %GatherButton.pressed.connect(_on_gather_pressed)
    leaf_button.pressed.connect(_on_leaf_pressed)
    branch_button.pressed.connect(_on_branch_pressed)
    chloroplast_button.pressed.connect(_on_chloroplast_pressed)
    xylem_button.pressed.connect(_on_xylem_pressed)
    sunflower_button.pressed.connect(_on_sunflower_pressed)
    nautilus_button.pressed.connect(_on_nautilus_pressed)
    root_eff_button.pressed.connect(_on_root_eff_pressed)
    root_button.pressed.connect(_on_root_pressed)
    totem_button.pressed.connect(_on_totem_pressed)
    interact_human_button.pressed.connect(func(): _on_interact_pressed(&"human"))
    interact_forest_button.pressed.connect(func(): _on_interact_pressed(&"forestfolk"))
    interact_stone_button.pressed.connect(func(): _on_interact_pressed(&"stoneborn"))
    interact_wild_button.pressed.connect(func(): _on_interact_pressed(&"wildfolk"))
    plunder_human_button.pressed.connect(func(): _on_plunder_pressed(&"human"))
    plunder_forest_button.pressed.connect(func(): _on_plunder_pressed(&"forestfolk"))
    plunder_stone_button.pressed.connect(func(): _on_plunder_pressed(&"stoneborn"))
    plunder_wild_button.pressed.connect(func(): _on_plunder_pressed(&"wildfolk"))
    GameManager.plunder_done.connect(_on_plunder_done)
    intimate_human_button.pressed.connect(func(): _on_intimate_pressed(&"human"))
    intimate_forest_button.pressed.connect(func(): _on_intimate_pressed(&"forestfolk"))
    intimate_stone_button.pressed.connect(func(): _on_intimate_pressed(&"stoneborn"))
    intimate_wild_button.pressed.connect(func(): _on_intimate_pressed(&"wildfolk"))
    GameManager.intimate_done.connect(_on_intimate_done)
    choice_option_a_button.pressed.connect(func(): _on_choice_pressed(&"a"))
    choice_option_b_button.pressed.connect(func(): _on_choice_pressed(&"b"))
    choice_option_c_button.pressed.connect(func(): _on_choice_pressed(&"c"))
    seedling_button.pressed.connect(_on_seedling_pressed)
    deep_dream_button.pressed.connect(_on_deep_dream_pressed)
    wind_veil_button.pressed.connect(_on_wind_veil_pressed)
    firepit_button.pressed.connect(func(): _on_facility_pressed(&"human", "firepit_level"))
    ring_button.pressed.connect(func(): _on_facility_pressed(&"forestfolk", "ring_level"))
    forge_button.pressed.connect(func(): _on_facility_pressed(&"stoneborn", "forge_level"))
    totem_pole_button.pressed.connect(func(): _on_facility_pressed(&"wildfolk", "totem_pole_level"))
    faith_convert_button.pressed.connect(_on_convert_faith_pressed)
    memory_convert_button.pressed.connect(_on_convert_memory_pressed)
    life_upgrade_button.pressed.connect(_on_life_upgrade_pressed)
    faith_engine_button.pressed.connect(_on_engine_faith_pressed)
    memory_engine_button.pressed.connect(_on_engine_memory_pressed)
    _wire_node_buttons()
    GameManager.choice_available.connect(_on_choice_available)
    GameManager.choice_resolved.connect(_on_choice_resolved)
    revive_human_button.pressed.connect(func(): _on_revive_pressed(&"human"))
    revive_forest_button.pressed.connect(func(): _on_revive_pressed(&"forestfolk"))
    revive_stone_button.pressed.connect(func(): _on_revive_pressed(&"stoneborn"))
    revive_wild_button.pressed.connect(func(): _on_revive_pressed(&"wildfolk"))
    plunder_soul_human_button.pressed.connect(func(): _on_plunder_soul_pressed(&"human"))
    plunder_soul_forest_button.pressed.connect(func(): _on_plunder_soul_pressed(&"forestfolk"))
    plunder_soul_stone_button.pressed.connect(func(): _on_plunder_soul_pressed(&"stoneborn"))
    plunder_soul_wild_button.pressed.connect(func(): _on_plunder_soul_pressed(&"wildfolk"))
    GameManager.soul_revived.connect(_on_soul_revived)
    GameManager.soul_plundered.connect(_on_soul_plundered)
    GameManager.resources_changed.connect(_refresh)
    GameManager.relic_discovered.connect(_on_relic_discovered)
    GameManager.race_awakened.connect(_on_race_awakened)
    GameManager.totem_interpreted.connect(_on_totem_interpreted)
    # 读档恢复的唤醒发生在 autoload _ready（早于本场景），信号已发出——此处兜底播报
    if GameManager.is_human_awakened():
        var human := GameManager.get_race(&"human")
        if human != null:
            _on_race_awakened(human.id, human.display_name, human.awaken_text)
    # 读档恢复兜底：_pending_choice 非空（同进程场景重载）时重发弹层
    if GameManager._pending_choice != &"":
        var c := ChoiceLibrary.get_choice(GameManager._pending_choice)
        if not c.is_empty():
            _on_choice_available(GameManager._pending_choice, str(c.get("title", "")), str(c.get("intro", "")), c.get("options", []))
    _refresh()

func _on_race_awakened(race_id: StringName, race_name: String, awaken_text: String) -> void:
    race_event_label.text = awaken_text

func _on_gather_pressed() -> void:
    GameManager.gather()

func _on_leaf_pressed() -> void:
    if GameManager.buy_leaf():
        log_label.text = "叶序螺旋升至 %d 级。" % GameManager.get_state().leaf_level
    _refresh()

func _on_branch_pressed() -> void:
    if GameManager.buy_branch():
        log_label.text = "分枝序升至 %d 级。" % GameManager.get_state().branch_level
    _refresh()

func _on_chloroplast_pressed() -> void:
    if GameManager.buy_chloroplast():
        log_label.text = "叶绿体升至 %d 级。" % GameManager.get_state().chloroplast_level
    _refresh()

func _on_xylem_pressed() -> void:
    if GameManager.buy_xylem():
        log_label.text = "木质部升至 %d 级。" % GameManager.get_state().xylem_level
    _refresh()

func _on_sunflower_pressed() -> void:
    if GameManager.buy_sunflower():
        log_label.text = "花盘升至 %d 级。" % GameManager.get_state().sunflower_level
    _refresh()

func _on_nautilus_pressed() -> void:
    if GameManager.buy_nautilus():
        log_label.text = "螺舱升至 %d 级。" % GameManager.get_state().nautilus_level
    _refresh()

func _on_root_eff_pressed() -> void:
    if GameManager.buy_root_eff():
        log_label.text = "根须等级升至 %d 级。" % GameManager.get_state().root_eff_level
    _refresh()

func _on_root_pressed() -> void:
    var result: Dictionary = GameManager.explore_relic()
    if not result.get("ok", false):
        log_label.text = "树液不够。或者……地下已经空了。"

func _on_relic_discovered(relic_name: String, dream_text: String) -> void:
    dream_text_label.text = dream_text
    log_label.text = "你在「%s」找到了一段记忆。" % relic_name

func _refresh() -> void:
    var s := GameManager.get_state()
    daylight_label.text = Formatter.format_number(s.daylight)
    sap_label.text = "树液：%s / %s" % [Formatter.format_number(s.sap), Formatter.format_cost(int(GameManager.get_sap_cap()))]
    growth_label.text = Formatter.format_number(s.growth)
    memory_label.text = "记忆：" + Formatter.format_number(GameManager.get_memory())
    faith_label.text = "信仰：" + Formatter.format_number(GameManager.get_faith())
    leaf_cost_label.text = Formatter.format_cost(GameManager.get_leaf_cost())
    branch_cost_label.text = Formatter.format_cost(GameManager.get_branch_cost())
    chloroplast_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_chloroplast_cost())
    xylem_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_xylem_cost())
    sunflower_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_sunflower_cost())
    nautilus_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_nautilus_cost())
    root_eff_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_root_eff_cost())
    leaf_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_leaf_cost())))
    branch_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_branch_cost())))
    chloroplast_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_chloroplast_cost())))
    xylem_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_xylem_cost())))
    sunflower_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_sunflower_cost())))
    nautilus_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_nautilus_cost())))
    root_eff_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_root_eff_cost())))
    root_button.disabled = not RootActions.can_explore(s)
    _refresh_race_rows()
    _refresh_totem()
    _refresh_interact_buttons()
    _refresh_plunder_buttons()
    _refresh_avatar()
    _refresh_intimate_buttons()
    _refresh_soul()
    _refresh_m5d2()
    _refresh_lingua()

func _refresh_race_rows() -> void:
    var s := GameManager.get_state()
    for id: StringName in RACE_ROWS:
        var data := GameManager.get_race(id)
        var label: Label = null
        match id:
            &"human": label = race_human_label
            &"forestfolk": label = race_forest_label
            &"stoneborn": label = race_stone_label
            &"wildfolk": label = race_wild_label
        if label == null:
            continue
        if s.races.has(id) and bool(s.races[id].get("awakened", false)):
            var pop := float(s.races[id].get("population", 0.0))
            var rel := RelationActions.get_relation(s, id)
            label.text = "%s：人口 %d · %s" % [RACE_ROWS[id], int(pop), RELATION_LABELS.get(rel, "平常")]
            label.add_theme_color_override("font_color", RELATION_COLORS.get(rel, Color.WHITE))
        else:
            label.text = "%s：%s 时苏醒" % [RACE_ROWS[id], _awaken_hint(data)]
            label.add_theme_color_override("font_color", Color.WHITE)

func _awaken_hint(data: RaceData) -> String:
    if data == null:
        return "条件缺失"
    if data.awaken_condition == "memory>=2":
        return "记忆 2"
    if data.awaken_condition.begins_with("faith>="):
        return "信仰 " + data.awaken_condition.get_slice(">=", 1)
    return data.awaken_condition

func _refresh_totem() -> void:
    var s := GameManager.get_state()
    var stage := TotemActions.visible_stage(s)
    if stage <= 0:
        totem_panel.visible = false
        totem_button.visible = false
        insight_label.visible = false
        return
    totem_panel.visible = true
    totem_button.visible = true
    insight_label.visible = true
    var totem := TotemLibrary.get_totem(stage)
    totem_label.text = "图腾·第 %d 幅\n%s" % [stage, str(totem.get("reveal_text", ""))]
    insight_label.text = "领悟：%d" % s.insight
    var next_id := TotemActions.next_interpretable(s)
    totem_button.disabled = next_id <= 0

func _on_totem_pressed() -> void:
    var s := GameManager.get_state()
    var next_id := TotemActions.next_interpretable(s)
    if next_id <= 0:
        return
    var result: Dictionary = GameManager.interpret_totem(next_id)
    if not result.get("ok", false):
        log_label.text = "画还看不清。再等等。"
    # 成功播报由 _on_totem_interpreted 处理

func _on_totem_interpreted(totem_id: int, interpret_text: String) -> void:
    race_event_label.text = interpret_text + "\n（领悟 +1）"

func _refresh_interact_buttons() -> void:
    var s := GameManager.get_state()
    var pairs := [
        [&"human", interact_human_button],
        [&"forestfolk", interact_forest_button],
        [&"stoneborn", interact_stone_button],
        [&"wildfolk", interact_wild_button],
    ]
    for p in pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = RelationActions.can_interact(s, rid)

func _on_interact_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.interact_relation(race_id)
    if result.get("ok", false):
        race_event_label.text = str(result.get("text", ""))
        log_label.text = "关系 · 亲近了一分。"
    _refresh()

func _refresh_plunder_buttons() -> void:
    var s := GameManager.get_state()
    var pairs := [
        [&"human", plunder_human_button],
        [&"forestfolk", plunder_forest_button],
        [&"stoneborn", plunder_stone_button],
        [&"wildfolk", plunder_wild_button],
    ]
    for p in pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = PlunderActions.can_plunder(s, rid)

func _on_plunder_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.plunder_race(race_id)
    if not result.get("ok", false):
        log_label.text = "它还在沉睡。"
    # 成功显示由 _on_plunder_done 处理

func _on_plunder_done(race_id: StringName, text: String, revealed: bool) -> void:
    race_event_label.text = text
    if revealed:
        log_label.text = "（你忽然意识到什么。）"

func _refresh_avatar() -> void:
    var s := GameManager.get_state()
    if not DriftActions.is_avatar_awakened(s):
        avatar_panel.visible = false
        return
    avatar_panel.visible = true
    var tier := DriftActions.drift_tier(s)
    var tier_names := ["清醒", "微漂", "深漂", "迷失"]
    avatar_label.text = "化身 · %s\n%s" % [tier_names[tier], DriftActions.avatar_tier_text(s)]

func _refresh_intimate_buttons() -> void:
    var s := GameManager.get_state()
    var pairs := [
        [&"human", intimate_human_button],
        [&"forestfolk", intimate_forest_button],
        [&"stoneborn", intimate_stone_button],
        [&"wildfolk", intimate_wild_button],
    ]
    for p in pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = DriftActions.can_intimate(s, rid)

func _on_intimate_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.intimate_race(race_id)
    if not result.get("ok", false):
        log_label.text = "它还不想说。"
    # 成功显示由 _on_intimate_done 处理

func _on_intimate_done(race_id: StringName, text: String) -> void:
    race_event_label.text = text
    log_label.text = "（你以「人」的样子，坐在了它身边。）"

func _refresh_soul() -> void:
    var s := GameManager.get_state()
    soul_label.text = "灵魂：%d / %d" % [s.soul_river, SoulActions.RIVER_TOTAL]
    var revive_pairs := [
        [&"human", revive_human_button],
        [&"forestfolk", revive_forest_button],
        [&"stoneborn", revive_stone_button],
        [&"wildfolk", revive_wild_button],
    ]
    for p in revive_pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = SoulActions.can_revive(s, rid)
    var soul_pairs := [
        [&"human", plunder_soul_human_button],
        [&"forestfolk", plunder_soul_forest_button],
        [&"stoneborn", plunder_soul_stone_button],
        [&"wildfolk", plunder_soul_wild_button],
    ]
    for p in soul_pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = SoulActions.can_plunder_soul(s, rid)

func _on_revive_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.revive_race(race_id)
    if not result.get("ok", false):
        log_label.text = "河水太远了。"
    # 成功播报由 _on_soul_revived 处理

func _on_plunder_soul_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.plunder_soul_race(race_id)
    if not result.get("ok", false):
        log_label.text = "它还在岸上。"
    # 成功播报由 _on_soul_plundered 处理

func _on_soul_revived(race_id: StringName, pop_gain: int) -> void:
    race_event_label.text = "河水浅了一分。有人醒来了。"
    log_label.text = "（你从河里，唤回 %d 人。）" % pop_gain
    _refresh()

func _on_soul_plundered(race_id: StringName, pop_loss: int) -> void:
    race_event_label.text = "河水满了一分。有人沉默了。"
    log_label.text = "（你让 %d 人，沉回河底。）" % pop_loss
    _refresh()

func _on_choice_available(choice_id: StringName, title: String, intro: String, options: Array) -> void:
    choice_title_label.text = title
    choice_intro_label.text = intro
    var s := GameManager.get_state()
    var buttons := [choice_option_a_button, choice_option_b_button, choice_option_c_button]
    for i in mini(options.size(), buttons.size()):
        var opt: Variant = options[i]
        if typeof(opt) != TYPE_DICTIONARY:
            buttons[i].visible = false
            continue
        var opt_id := StringName(str(opt.get("id", "")))
        buttons[i].visible = true
        buttons[i].text = str(opt.get("text", ""))
        buttons[i].disabled = not ChoiceActions.option_unlocked(s, choice_id, opt_id)
    for i in range(options.size(), buttons.size()):
        buttons[i].visible = false
    choice_panel.visible = true

func _on_choice_pressed(option_id: StringName) -> void:
    # 当前弹层的 choice_id 由 GameManager._pending_choice 持有，经 resolve_choice 校验
    var s := GameManager.get_state()
    var cid := GameManager._pending_choice
    var result: Dictionary = GameManager.resolve_choice(cid, option_id)
    # 成功显示由 _on_choice_resolved 处理；失败静默（门槛拦截已在按钮 disabled 挡住）

func _on_choice_resolved(choice_id: StringName, option_id: StringName, result_text: String, option_text: String) -> void:
    race_event_label.text = result_text
    log_label.text = "（明选·%s）" % option_text
    choice_panel.visible = false
    _refresh()

func _refresh_m5d2() -> void:
    var s := GameManager.get_state()
    seedling_button.visible = s.seedling_level < 3
    seedling_cost_label.visible = s.seedling_level < 3
    seedling_cost_label.text = "价格：%d" % GameManager.get_seedling_cost()
    seedling_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_seedling_cost())))
    deep_dream_button.visible = not s.deep_dream
    deep_dream_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(3000.0))
    wind_veil_button.visible = not s.wind_veil
    wind_veil_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(2500.0))
    var facility_pairs := [
        [&"human", firepit_button, GameManager.get_firepit_cost()],
        [&"forestfolk", ring_button, GameManager.get_ring_cost()],
        [&"stoneborn", forge_button, GameManager.get_forge_cost()],
        [&"wildfolk", totem_pole_button, GameManager.get_totem_pole_cost()],
    ]
    for p in facility_pairs:
        var rid: StringName = p[0]
        var btn: Button = p[1]
        btn.visible = s.races.has(rid) and bool(s.races[rid].get("awakened", false))
        btn.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(p[2])))

func _on_seedling_pressed() -> void:
    if GameManager.buy_seedling():
        log_label.text = "嫩叶舒展开了。"
    _refresh()

func _on_deep_dream_pressed() -> void:
    if GameManager.buy_deep_dream():
        race_event_label.text = "你把根须往更深处送。泥下的梦，比河里的更老——老到分不清是记忆，还是地质层。\n你梦见一棵树。不是你自己。是很多年前，一棵真正的、普通的树。\n它不知道什么叫世界。它只知道向上，向光。\n醒来时，你的根须里多了一点暖意。像有什么东西，在你身体里扎了根。"
        log_label.text = "（深根梦 · 记忆 +15）"
    _refresh()

func _on_wind_veil_pressed() -> void:
    if GameManager.buy_wind_veil():
        race_event_label.text = "风从旧世界的方向吹来。你在风里，听见很远的说话声——\n有人在河边洗衣服。有孩子在追一只蜻蜓。有人在天裂之前，最后看了一眼太阳。\n声音很轻，像隔着水面。\n你听了一整个下午。风停的时候，你发现自己记下了它们的声音——像记下了某种信仰。"
        log_label.text = "（风语膜 · 信仰 +30）"
    _refresh()

func _on_facility_pressed(race_id: StringName, field: String) -> void:
    var ok := false
    match field:
        "firepit_level": ok = GameManager.buy_firepit()
        "ring_level": ok = GameManager.buy_ring()
        "forge_level": ok = GameManager.buy_forge()
        "totem_pole_level": ok = GameManager.buy_totem_pole()
    if ok:
        var names := {&"human": "火塘", &"forestfolk": "歌之环", &"stoneborn": "铸根坊", &"wildfolk": "图腾柱"}
        log_label.text = "（%s 立起来了。）" % names.get(race_id, "设施")
    _refresh()

func _node_buttons() -> Array:
    # 与 LinguaData.NODES 注册序一致（M5e 批 1：11 节点）
    return [
        [&"root_echo", root_echo_button],
        [&"root_resonance", root_resonance_button],
        [&"deep_root", deep_root_button],
        [&"tree_canopy", tree_canopy_button],
        [&"ring_memory", ring_memory_button],
        [&"cloud_crown", cloud_crown_button],
        [&"wood_heart", wood_heart_button],
        [&"song_resonance", song_resonance_button],
        [&"village_heart", village_heart_button],
        [&"grace", grace_button],
        [&"altar", altar_button],
    ]

func _wire_node_buttons() -> void:
    for p in _node_buttons():
        var nid: StringName = p[0]
        var btn: Button = p[1]
        btn.pressed.connect(_on_node_unlock_pressed.bind(nid))

func _refresh_lingua() -> void:
    var s := GameManager.get_state()
    # 兑换按钮：对应节点已购才显示
    faith_convert_button.visible = LinguaActions.has_node(s, &"tree_canopy")
    memory_convert_button.visible = LinguaActions.has_node(s, &"root_resonance")
    # 生命之语：Lv≥1 后常显（免费激活即出现）；未激活前隐藏，避免开局刷脸
    life_upgrade_button.visible = s.lingua_life_level > 0 or s.faith.is_greater_or_equal(BigNum.new(1.0))
    life_cost_label.visible = s.lingua_life_level > 0
    var lc := LinguaActions.life_cost(s)
    life_cost_label.text = "生命之语 Lv%d → %s" % [s.lingua_life_level, ("免费" if lc == 0 else ("%d 信仰" % lc)) if lc >= 0 else "已满级"]
    life_upgrade_button.disabled = not LinguaActions.can_upgrade_life(s)
    # 引擎按钮：对应节点已购才显示；成本 Label 同步
    faith_engine_button.visible = LinguaActions.has_node(s, &"cloud_crown")
    faith_engine_cost_label.visible = LinguaActions.has_node(s, &"cloud_crown")
    faith_engine_cost_label.text = "价格：%d" % CostCalculator.faith_engine_cost(s.faith_engine_level)
    faith_engine_button.disabled = not s.faith.is_greater_or_equal(BigNum.new(float(CostCalculator.faith_engine_cost(s.faith_engine_level))))
    memory_engine_button.visible = LinguaActions.has_node(s, &"grace")
    memory_engine_cost_label.visible = LinguaActions.has_node(s, &"grace")
    memory_engine_cost_label.text = "价格：%d" % CostCalculator.memory_engine_cost(s.memory_engine_level)
    memory_engine_button.disabled = not s.memory.is_greater_or_equal(BigNum.new(float(CostCalculator.memory_engine_cost(s.memory_engine_level))))
    _refresh_node_buttons()

func _refresh_node_buttons() -> void:
    var s := GameManager.get_state()
    for p in _node_buttons():
        var nid: StringName = p[0]
        var btn: Button = p[1]
        # 显示门槛：未购 + 生命之语达到 requirement；disabled 由 sap 决定
        var node := LinguaData.get_node(nid)
        var req := int(node.get("requirement", 99))
        btn.visible = not LinguaActions.has_node(s, nid) and s.lingua_life_level >= req
        btn.disabled = not LinguaActions.can_unlock_node(s, nid)

func _on_convert_faith_pressed() -> void:
    if GameManager.convert_faith():
        log_label.text = "（献祭 · 信仰 +1）"
    _refresh()

func _on_convert_memory_pressed() -> void:
    if GameManager.convert_memory():
        log_label.text = "（挖梦 · 记忆 +1）"
    _refresh()

func _on_engine_faith_pressed() -> void:
    if GameManager.buy_faith_engine():
        log_label.text = "（信仰引擎升至 %d 级）" % GameManager.get_state().faith_engine_level
    _refresh()

func _on_engine_memory_pressed() -> void:
    if GameManager.buy_memory_engine():
        log_label.text = "（记忆引擎升至 %d 级）" % GameManager.get_state().memory_engine_level
    _refresh()

func _on_life_upgrade_pressed() -> void:
    if GameManager.upgrade_life():
        log_label.text = "（生命之语 · 第 %d 阶）" % GameManager.get_state().lingua_life_level
    _refresh()

func _on_node_unlock_pressed(node_id: StringName) -> void:
    if GameManager.unlock_node(node_id):
        var node := LinguaData.get_node(node_id)
        log_label.text = "（%s 已点亮）" % str(node.get("name", ""))
    _refresh()
