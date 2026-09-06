extends ScrollContainer

const RACE_ROWS := {
    &"human": "人族",
    &"forestfolk": "林地民",
    &"stoneborn": "石裔",
    &"wildfolk": "野民",
}
static func relation_label(value: float) -> String:
    if value <= -2.0:
        return "敌意"
    if value <= -0.5:
        return "冷淡"
    if value < 0.5:
        return "平常"
    if value < 2.0:
        return "友善"
    if value < 3.0:
        return "亲近"
    return "挚友"

static func relation_color(value: float) -> Color:
    if value <= -2.0:
        return Color("#7a8a99")
    if value <= -0.5:
        return Color("#9aa5ad")
    if value < 0.5:
        return Color.WHITE
    if value < 2.0:
        return Color("#c9a25c")
    if value < 3.0:
        return Color("#e6a23c")
    return Color("#f0b64e")

static func format_relation(value: float) -> String:
    var text := "%.1f" % value
    return "+" + text if value > 0.0 else text

static func realm_run_echo(run_number: int) -> String:
    match run_number:
        2:
            return "九个名字比根先醒。你还没有伸出枝条，远处已经有回声。"
        3:
            return "这一次，没有哪一界先开口。你知道每一条路，也知道路的尽头。"
        _:
            return ""

static func realm_visible_in_panel(state: GameState, realm_id: StringName) -> bool:
    if realm_id == &"midgard" or state.realm_echoes.has(realm_id):
        return true
    if realm_id == &"nidavellir" or realm_id == &"alfheim":
        return state.realm_echoes.has(&"midgard")
    return state.lingua_nodes.has(&"world_trace")

static func realm_gap_text(state: GameState, realm: RealmDefinition) -> String:
    if realm == null:
        return "界名尚未醒来"
    if state.realm_echoes.has(realm.id):
        return "已抵达"
    for prerequisite: StringName in realm.prerequisites:
        if not state.realm_echoes.has(prerequisite):
            var previous := RealmCatalog.get_realm(prerequisite)
            return "还差%s" % (previous.display_name if previous != null else str(prerequisite))
    for race_id: StringName in realm.required_races:
        if not state.races.has(race_id) or not bool(state.races[race_id].get("awakened", false)):
            return "还差%s醒来" % RACE_ROWS.get(race_id, str(race_id))
    if realm.required_lingua_node != &"" and not state.lingua_nodes.has(realm.required_lingua_node):
        var node := LinguaData.get_node(realm.required_lingua_node)
        return "还差%s" % str(node.get("name", realm.required_lingua_node))
    if realm.required_relic > 0 and not state.relics_found.has(realm.required_relic):
        return "还差遗迹 %d" % realm.required_relic
    if state.root_depth < realm.min_root_depth:
        return "根深还差 %d" % (realm.min_root_depth - state.root_depth)
    if not state.growth.is_greater_or_equal(BigNum.new(realm.min_growth)):
        return "生长还差 %s" % Formatter.format_cost(int(realm.min_growth - state.growth.to_value()))
    if not state.sap.is_greater_or_equal(BigNum.new(realm.sap_cost)):
        return "树液还差 %s" % Formatter.format_cost(int(realm.sap_cost - state.sap.to_value()))
    if not state.memory.is_greater_or_equal(BigNum.new(realm.memory_cost)):
        return "记忆还差 %s" % Formatter.format_cost(int(realm.memory_cost - state.memory.to_value()))
    if not state.faith.is_greater_or_equal(BigNum.new(realm.faith_cost)):
        return "信仰还差 %s" % Formatter.format_cost(int(realm.faith_cost - state.faith.to_value()))
    return "可以抵达"

static func miracle_gap_text(state: GameState, miracle: MiracleDefinition) -> String:
    if miracle == null:
        return "奇迹尚未醒来"
    for realm_id: StringName in miracle.required_realms:
        if not state.realm_echoes.has(realm_id):
            var realm := RealmCatalog.get_realm(realm_id)
            return "还差%s" % (realm.display_name if realm != null else str(realm_id))
    if miracle.required_lingua_node != &"" and not state.lingua_nodes.has(miracle.required_lingua_node):
        var node := LinguaData.get_node(miracle.required_lingua_node)
        return "还差%s" % str(node.get("name", miracle.required_lingua_node))
    if state.lingua_life_level < miracle.required_life_level:
        return "生命之语还差 Lv%d" % (miracle.required_life_level - state.lingua_life_level)
    if miracle.max_uses > 0 and MiracleActions.count(state, miracle.id) >= miracle.max_uses:
        return "本轮已满"
    if miracle.id == &"rain" and state.miracle_rain_ticks > 0:
        return "雨还在落 · %d" % state.miracle_rain_ticks
    if miracle.id == &"call_soul" and state.soul_river < SoulActions.REVIVE_COST_SOUL:
        return "河里没有可唤的灵魂"
    if not state.faith.is_greater_or_equal(BigNum.new(float(MiracleActions.faith_cost(state, miracle.id)))):
        return "信仰不足"
    if miracle.target_mode == "race":
        for race_id: StringName in GameState.RACE_IDS:
            if MiracleActions.can_perform(state, miracle.id, race_id):
                return "选择四族"
        return "没有可回应的目标"
    return "可以施展"

static func world_axis_gap_text(state: GameState) -> String:
    var remaining := maxi(RealmCatalog.all_realms().size() - state.realm_echoes.size(), 0)
    if remaining > 0:
        return "世界之轴：还差 %d 个界域" % remaining
    if not state.lingua_nodes.has(&"world_breath"):
        return "世界之轴：天地一息未点亮"
    return "世界之轴：九界正在同一口风里呼吸"

@onready var return_title_button: Button = %ReturnTitleButton
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
@onready var story_button: Button = %StoryButton
@onready var stream_story_button: Button = %StreamStoryButton
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
@onready var choice_option_d_button: Button = %ChoiceOptionDButton
@onready var world_axis_button: Button = %WorldAxisButton
@onready var return_panel: PanelContainer = %ReturnPanel
@onready var return_title_label: Label = %ReturnTitleLabel
@onready var return_text_label: Label = %ReturnTextLabel
@onready var return_progress_label: Label = %ReturnProgressLabel
@onready var return_advance_button: Button = %ReturnAdvanceButton
@onready var ending_panel: PanelContainer = %EndingPanel
@onready var ending_title_label: Label = %EndingTitleLabel
@onready var ending_body_label: Label = %EndingBodyLabel
@onready var ending_hope_label: Label = %EndingHopeLabel
@onready var ending_action_button: Button = %EndingActionButton
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
@onready var memory_lingua_button: Button = %MemoryLinguaButton
@onready var memory_lingua_cost_label: Label = %MemoryLinguaCostLabel
@onready var faith_engine_button: Button = %FaithEngineButton
@onready var faith_engine_cost_label: Label = %FaithEngineCostLabel
@onready var memory_engine_button: Button = %MemoryEngineButton
@onready var memory_engine_cost_label: Label = %MemoryEngineCostLabel
@onready var root_echo_button: Button = %RootEchoButton
@onready var root_resonance_button: Button = %RootResonanceButton
@onready var earth_sense_button: Button = %EarthSenseButton
@onready var deep_root_button: Button = %DeepRootButton
@onready var tree_canopy_button: Button = %TreeCanopyButton
@onready var ring_memory_button: Button = %RingMemoryButton
@onready var cloud_crown_button: Button = %CloudCrownButton
@onready var wood_heart_button: Button = %WoodHeartButton
@onready var sky_light_button: Button = %SkyLightButton
@onready var song_resonance_button: Button = %SongResonanceButton
@onready var village_heart_button: Button = %VillageHeartButton
@onready var grace_button: Button = %GraceButton
@onready var altar_button: Button = %AltarButton
@onready var story_status_label: Label = %StoryStatusLabel
@onready var nine_realms_panel: PanelContainer = %NineRealmsPanel
@onready var world_header_label: Label = %WorldHeaderLabel
@onready var world_run_echo_label: Label = %WorldRunEchoLabel
@onready var world_mode_label: Label = %WorldModeLabel
@onready var crown_label: Label = %CrownLabel
@onready var crown_flow: HFlowContainer = %CrownFlow
@onready var trunk_label: Label = %TrunkLabel
@onready var root_domain_label: Label = %RootDomainLabel
@onready var root_domain_flow: HFlowContainer = %RootDomainFlow
@onready var asgard_button: Button = %AsgardButton
@onready var vanaheim_button: Button = %VanaheimButton
@onready var alfheim_button: Button = %AlfheimButton
@onready var jotunheim_button: Button = %JotunheimButton
@onready var midgard_button: Button = %MidgardButton
@onready var nidavellir_button: Button = %NidavellirButton
@onready var niflheim_button: Button = %NiflheimButton
@onready var helheim_button: Button = %HelheimButton
@onready var muspelheim_button: Button = %MuspelheimButton
@onready var world_trace_button: Button = %WorldTraceButton
@onready var rain_name_button: Button = %RainNameButton
@onready var river_hearing_button: Button = %RiverHearingButton
@onready var sky_ladder_button: Button = %SkyLadderButton
@onready var world_shaping_button: Button = %WorldShapingButton
@onready var world_breath_button: Button = %WorldBreathButton
@onready var oasis_button: Button = %OasisButton
@onready var rain_button: Button = %RainButton
@onready var banish_shadow_button: Button = %BanishShadowButton
@onready var call_soul_button: Button = %CallSoulButton
@onready var shape_button: Button = %ShapeButton
@onready var miracle_target_label: Label = %MiracleTargetLabel
@onready var miracle_target_flow: HFlowContainer = %MiracleTargetFlow
@onready var miracle_human_button: Button = %MiracleHumanButton
@onready var miracle_forest_button: Button = %MiracleForestButton
@onready var miracle_stone_button: Button = %MiracleStoneButton
@onready var miracle_wild_button: Button = %MiracleWildButton
@onready var axis_gate_label: Label = %AxisGateLabel

var _pending_miracle_target_id: StringName = &""

# ---------- M6 终局 UI：世界之轴 / 归还序列 / 结算 / 周目层叠 ----------

const RUN2_OPENING_TEXT := "你记得这缕光。你曾把它交给下一个自己。"
const RUN3_OPENING_TEXT := "你醒来时，手里有一点希望。不是「一点」——是一点半。\n像有人在你睡着的时候，往你手心里添了一勺。\n土壤是软的。你低头，看见自己脚下有一圈新芽的痕迹——\n圆的，像一个拥抱留下的。\n你不知道那是谁种的。但你认得那个形状：那是你的形状。"

# 周目开局层叠文本（spec §8.6 权威；一周目 = 原始开局，无附加层）
static func run_opening_text(run_number: int) -> String:
    match run_number:
        2:
            return RUN2_OPENING_TEXT
        3:
            return RUN3_OPENING_TEXT
        _:
            return ""

# 结算画面数据（结局文案 + 希望变化 + 动作）。loops=false 仅真结局（循环终止 → 回到标题）
static func settlement_view(outcome: StringName, hope_before: int, hope_after: int) -> Dictionary:
    return EndingArchive.settlement_view(outcome, hope_before, hope_after)

static func storyteller_view(state: GameState) -> Dictionary:
    var main_ids := StoryLibrary.main_story_ids()
    var read_count := 0
    for story_id in main_ids:
        if state.storyteller_stories.has(story_id):
            read_count += 1
    var discovered := state.choice_flags.has(&"cave_found") or read_count > 0
    if not discovered:
        return {"visible": false}
    var next_id := StoryActions.next_main_story(state)
    if next_id != &"":
        return {
            "visible": true,
            "disabled": false,
            "button_text": "听她讲下一个故事（已读 %d/%d）" % [read_count, main_ids.size()],
            "status_text": "火塘边，有一个故事正等着你。",
        }
    if read_count >= main_ids.size():
        return {
            "visible": true,
            "disabled": true,
            "button_text": "火边的故事 · 已读 %d/%d" % [read_count, main_ids.size()],
            "status_text": "火已经安静下来。三个故事，都留在年轮里。",
        }
    var status := "她在等一个被守住的梦。"
    if state.storyteller_stories.has(&"story_5"):
        status = "最后一夜还没来：看见天裂，真相达到 4。"
    elif state.storyteller_stories.has(&"story_4"):
        status = "下一夜还没来：人族关系达到 2.0，领悟达到 5。"
    return {
        "visible": true,
        "disabled": true,
        "button_text": "火边的故事 · 已读 %d/%d" % [read_count, main_ids.size()],
        "status_text": status,
    }

func _ready() -> void:
    GameManager.enter_run_scene()
    return_title_button.pressed.connect(_on_return_title_pressed)
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
    choice_option_d_button.pressed.connect(func(): _on_choice_pressed(&"d"))
    world_axis_button.pressed.connect(_on_world_axis_pressed)
    return_advance_button.pressed.connect(_on_return_advance_pressed)
    ending_action_button.pressed.connect(_on_ending_action_pressed)
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
    memory_lingua_button.pressed.connect(_on_memory_lingua_pressed)
    faith_engine_button.pressed.connect(_on_engine_faith_pressed)
    memory_engine_button.pressed.connect(_on_engine_memory_pressed)
    _wire_node_buttons()
    _wire_world_ui()
    GameManager.choice_available.connect(_on_choice_available)
    GameManager.choice_resolved.connect(_on_choice_resolved)
    GameManager.ending_resolved.connect(_on_ending_resolved)
    GameManager.run_restarted.connect(_on_run_restarted)
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
    story_button.pressed.connect(_on_story_pressed)
    stream_story_button.pressed.connect(_on_stream_story_pressed)
    GameManager.story_heard.connect(_on_story_heard)
    GameManager.resources_changed.connect(_refresh)
    GameManager.relic_discovered.connect(_on_relic_discovered)
    GameManager.race_awakened.connect(_on_race_awakened)
    GameManager.totem_interpreted.connect(_on_totem_interpreted)
    GameManager.realm_explored.connect(_on_realm_explored)
    GameManager.world_language_changed.connect(_on_world_language_changed)
    GameManager.miracle_performed.connect(_on_miracle_performed)
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
    _resume_pending_ending()
    _show_offline_summary(GameManager.take_offline_summary())

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
        match String(result.get("reason", "")):
            "insufficient_sap":
                log_label.text = "树液还不够。根须在浅土里停下。"
            "no_available_relic":
                log_label.text = "根须摸到一片安静。这里暂时没有愿意醒来的遗迹。"
            "all_relics_found":
                log_label.text = "九处旧梦，都已经收进年轮。土里只剩安静。"
            _:
                log_label.text = "根须停下了。土里没有回声。"

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
    _refresh_world_axis()
    _refresh_race_rows()
    _refresh_totem()
    _refresh_interact_buttons()
    _refresh_plunder_buttons()
    _refresh_avatar()
    _refresh_intimate_buttons()
    _refresh_soul()
    _refresh_storyteller()
    _refresh_m5d2()
    _refresh_lingua()
    _refresh_world_ui()

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
            label.text = "%s：人口 %d · %s（%s）" % [RACE_ROWS[id], int(pop), relation_label(rel), format_relation(rel)]
            label.add_theme_color_override("font_color", relation_color(rel))
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
        btn.visible = GameManager.can_interact_relation(rid)

func _on_interact_pressed(race_id: StringName) -> void:
    var result: Dictionary = GameManager.interact_relation(race_id)
    if result.get("ok", false):
        race_event_label.text = str(result.get("text", ""))
        log_label.text = "关系 · 靠近了半步。"
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
    var buttons := [choice_option_a_button, choice_option_b_button, choice_option_c_button, choice_option_d_button]
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
    call_deferred("_ensure_visible", choice_panel)

func _on_choice_pressed(option_id: StringName) -> void:
    # 当前弹层的 choice_id 由 GameManager._pending_choice 持有，经 resolve_choice 校验
    var cid := GameManager._pending_choice
    var result: Dictionary = GameManager.resolve_choice(cid, option_id)
    if bool(result.get("ok", false)) and cid == &"world_axis":
        # world_axis 结算不发 choice_resolved——把选项叙事桥（凝/拒/还/自）播进事件位，
        # 与普通明选 choice_resolved → race_event_label 的惯例对齐
        race_event_label.text = str(result.get("result_text", ""))
    # 成功显示由 _on_choice_resolved / _on_ending_resolved 处理；失败静默（门槛拦截已在按钮 disabled 挡住）

func _on_choice_resolved(choice_id: StringName, option_id: StringName, result_text: String, option_text: String) -> void:
    race_event_label.text = result_text
    log_label.text = "（明选·%s）" % option_text
    choice_panel.visible = false
    _refresh()

# ---------- M6 终局 UI：世界之轴入口 / 归还序列 / 结算 / 周目层叠 ----------

var _ending_loops := true               # 结算动作：true=再次醒来（restart_run）；false=回到标题

# 世界之轴入口按钮 pressed → 主动进入终局（GameManager 内 axis_ready 完整门控）
func _on_world_axis_pressed() -> void:
    GameManager.try_start_world_axis()

func _refresh_world_axis() -> void:
    # 已结算（choices_done 含 world_axis）后按钮隐藏——P4 守门镜像（防再次入场软锁）
    var s := GameManager.get_state()
    world_axis_button.visible = not s.choices_done.has(&"world_axis") \
        and EndingStateMachine.axis_ready(s)

# ending_resolved（明选⑦ 结算）：仅 c「把记忆还给河」进归还序列（good 满 7 / normal+bad 4 步停）；
# a/b（凝/拒）与 d（真）直接结算画面（spec §8.3：归还序列只在「还给河」路径触发）
func _on_ending_resolved(_outcome: StringName, _hope_after: int) -> void:
    choice_panel.visible = false
    _resume_pending_ending()

func _resume_pending_ending() -> void:
    var pending := GameManager.get_pending_ending()
    if pending.is_empty():
        return
    var outcome := StringName(str(pending.get("outcome", &"")))
    var phase := StringName(str(pending.get("phase", &"settlement")))
    if phase != &"return":
        return_panel.visible = false
        _show_settlement(settlement_view(outcome, int(pending.get("hope_before", 1)), GameManager.get_state().hope))
        return
    var run_number := GameManager.get_state().run_number
    var step := int(pending.get("return_step", 1))
    var halted := bool(pending.get("return_halted", false))
    var max_step := ReturnSequence.max_step_for(outcome)
    choice_panel.visible = false
    ending_panel.visible = false
    return_panel.visible = true
    call_deferred("_ensure_visible", return_panel)
    return_title_label.text = "归还序列 · 周目 %d" % run_number
    return_text_label.text = ReturnSequence.halt_text(run_number) if halted else ReturnSequence.text_for(run_number, step)
    var progress := ReturnSequence.progress_for(step)
    return_progress_label.text = "树的余形 %d%% · 世界复苏 %d%%" % [
        int(progress.get("tree_remaining", 100)), int(progress.get("world_restored", 0))]
    return_advance_button.visible = true
    if halted or (outcome == &"good" and step >= max_step):
        return_advance_button.text = "完成归还"
    elif step >= max_step:
        return_advance_button.text = "停在这里"
    else:
        return_advance_button.text = "继续归还"

func _on_return_advance_pressed() -> void:
    var result := GameManager.advance_return_sequence()
    if result.get("ok", false):
        _resume_pending_ending()

func _show_settlement(view: Dictionary) -> void:
    ending_title_label.text = str(view.get("title", ""))
    ending_body_label.text = str(view.get("body", ""))
    ending_hope_label.text = str(view.get("hope_line", ""))
    ending_action_button.text = str(view.get("action_text", "再次醒来"))
    _ending_loops = bool(view.get("loops", true))
    ending_panel.visible = true
    call_deferred("_ensure_visible", ending_panel)
    race_event_label.text = str(view.get("title", "")) + " · " + str(view.get("hope_line", ""))
    _refresh()

func _ensure_visible(control: Control) -> void:
    if is_instance_valid(control) and control.visible:
        ensure_control_visible(control)

# 结算动作：再次醒来 → restart_run；回到标题 → GameManager.reset_to_title()
func _on_ending_action_pressed() -> void:
    ending_panel.visible = false
    if _ending_loops:
        GameManager.restart_run()
    else:
        GameManager.reset_to_title()

func _on_return_title_pressed() -> void:
    GameManager.return_to_title()

# run_restarted：周目重启 → 关闭终局层，播报周目层叠文本（spec §8.6）
func _on_run_restarted(run_number: int) -> void:
    ending_panel.visible = false
    return_panel.visible = false
    choice_panel.visible = false
    var opening := run_opening_text(run_number)
    if opening != "":
        race_event_label.text = opening
        log_label.text = "第 %d 个春天。你记得上一程的光。" % run_number
    else:
        race_event_label.text = "第 %d 个春天。你在土里醒来。" % run_number
    _refresh()

func _refresh_storyteller() -> void:
    var s := GameManager.get_state()
    var view := storyteller_view(s)
    var visible := bool(view.get("visible", false))
    story_status_label.visible = visible
    story_button.visible = visible
    if visible:
        story_status_label.text = str(view.get("status_text", ""))
        story_button.text = str(view.get("button_text", ""))
        story_button.disabled = bool(view.get("disabled", true))
    var stream_available := not StoryActions.available_easter_eggs(s).is_empty()
    var stream_read := s.storyteller_stories.has(&"stream_and_current")
    stream_story_button.visible = stream_available or stream_read
    stream_story_button.disabled = not stream_available
    stream_story_button.text = "听她讲《小溪与激流》" if stream_available else "《小溪与激流》· 已读"

func _on_story_pressed() -> void:
    var story_id := StoryActions.next_main_story(GameManager.get_state())
    if story_id != &"":
        GameManager.hear_story(story_id)

func _on_stream_story_pressed() -> void:
    var available := StoryActions.available_easter_eggs(GameManager.get_state())
    if not available.is_empty():
        GameManager.hear_story(available[0])

func _on_story_heard(story_id: StringName, title: String, story_text: String) -> void:
    race_event_label.text = "%s\n\n%s" % [title, story_text]
    log_label.text = "（火塘边，又安静了一会儿。）"
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
    # 与 LinguaData.NODES 注册序一致（M5e 批 1 + M5h：13 节点）
    return [
        [&"root_echo", root_echo_button],
        [&"root_resonance", root_resonance_button],
        [&"earth_sense", earth_sense_button],
        [&"deep_root", deep_root_button],
        [&"tree_canopy", tree_canopy_button],
        [&"ring_memory", ring_memory_button],
        [&"cloud_crown", cloud_crown_button],
        [&"wood_heart", wood_heart_button],
        [&"sky_light", sky_light_button],
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
    memory_lingua_button.visible = s.lingua_memory_level < LinguaData.MEMORY_MAX_LEVEL
    memory_lingua_button.disabled = not LinguaActions.can_upgrade_memory(s)
    memory_lingua_cost_label.visible = true
    memory_lingua_cost_label.text = "记忆之语 Lv1 · 500 记忆 + 领悟 5（领悟不消耗）" if s.lingua_memory_level == 0 else "记忆之语 Lv1 · 已醒来"
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
        # 显示门槛：未购 + 对应树语达到 requirement；disabled 由 sap 决定
        var node := LinguaData.get_node(nid)
        var req := int(node.get("requirement", 99))
        var language := StringName(node.get("language", &"life"))
        var level := s.lingua_memory_level if language == &"memory" else s.lingua_life_level
        btn.visible = not LinguaActions.has_node(s, nid) and level >= req
        btn.disabled = not LinguaActions.can_unlock_node(s, nid)

func _show_offline_summary(summary: Dictionary) -> void:
    if not summary.get("applied", false):
        return
    var gains: Array[String] = []
    for entry in [["daylight", "日光"], ["sap", "树液"], ["growth", "生长"], ["faith", "信仰"], ["memory", "记忆"]]:
        var amount := float(summary.get(entry[0], 0.0))
        if amount > 0.000001:
            gains.append("%s +%s" % [entry[1], Formatter.format_number(BigNum.new(amount))])
    var population: Dictionary = summary.get("population", {})
    for race_id in population:
        var amount := float(population[race_id])
        if amount <= 0.000001:
            continue
        var race := GameManager.get_race(StringName(str(race_id)))
        var race_name := str(race.display_name) if race != null else str(race_id)
        gains.append("%s人口 +%s" % [race_name, Formatter.format_number(BigNum.new(amount))])
    if gains.is_empty():
        return
    var minutes := maxi(int(summary.get("seconds", 0)) / 60, 1)
    log_label.text = "离开时，根仍听着大地。\n%d 分钟里：%s" % [minutes, " · ".join(gains)]

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

func _on_memory_lingua_pressed() -> void:
    if GameManager.upgrade_memory():
        log_label.text = "（旧梦在根间醒来。你仍记得它们。）"
    _refresh()

func _on_node_unlock_pressed(node_id: StringName) -> void:
    if GameManager.unlock_node(node_id):
        var node := LinguaData.get_node(node_id)
        log_label.text = "（%s 已点亮）" % str(node.get("name", ""))
    _refresh()

# ---------- M6-D 九界 / 世界之语 / 奇迹 ----------

func _realm_buttons() -> Array:
    return [
        [&"asgard", asgard_button],
        [&"vanaheim", vanaheim_button],
        [&"alfheim", alfheim_button],
        [&"jotunheim", jotunheim_button],
        [&"midgard", midgard_button],
        [&"nidavellir", nidavellir_button],
        [&"niflheim", niflheim_button],
        [&"helheim", helheim_button],
        [&"muspelheim", muspelheim_button],
    ]

func _world_node_buttons() -> Array:
    return [
        [&"world_trace", world_trace_button],
        [&"rain_name", rain_name_button],
        [&"river_hearing", river_hearing_button],
        [&"sky_ladder", sky_ladder_button],
        [&"world_shaping", world_shaping_button],
        [&"world_breath", world_breath_button],
    ]

func _miracle_buttons() -> Array:
    return [
        [&"oasis", oasis_button],
        [&"rain", rain_button],
        [&"banish_shadow", banish_shadow_button],
        [&"call_soul", call_soul_button],
        [&"shape", shape_button],
    ]

func _miracle_target_buttons() -> Array:
    return [
        [&"human", miracle_human_button],
        [&"forestfolk", miracle_forest_button],
        [&"stoneborn", miracle_stone_button],
        [&"wildfolk", miracle_wild_button],
    ]

func _wire_world_ui() -> void:
    for pair in _realm_buttons():
        var realm_id: StringName = pair[0]
        var button: Button = pair[1]
        button.pressed.connect(_on_realm_pressed.bind(realm_id))
    for pair in _world_node_buttons():
        var node_id: StringName = pair[0]
        var button: Button = pair[1]
        button.pressed.connect(_on_node_unlock_pressed.bind(node_id))
    for pair in _miracle_buttons():
        var miracle_id: StringName = pair[0]
        var button: Button = pair[1]
        button.pressed.connect(_on_miracle_pressed.bind(miracle_id))
    for pair in _miracle_target_buttons():
        var race_id: StringName = pair[0]
        var button: Button = pair[1]
        button.pressed.connect(_on_miracle_target_pressed.bind(race_id))

func _world_node_gap_text(state: GameState, node: Dictionary) -> String:
    var node_id := StringName(str(node.get("id", &"")))
    if state.lingua_nodes.has(node_id):
        return "已点亮"
    var requirement := int(node.get("requirement", 99))
    var level := RealmActions.world_level(state)
    if level < requirement:
        return "还差世界之语 Lv%d" % (requirement - level)
    for prerequisite: Variant in node.get("prerequisites", []):
        var prerequisite_id := StringName(str(prerequisite))
        if not state.lingua_nodes.has(prerequisite_id):
            return "还差%s" % str(LinguaData.get_node(prerequisite_id).get("name", prerequisite_id))
    var cost := int(node.get("sap_cost", 0))
    if not state.sap.is_greater_or_equal(BigNum.new(float(cost))):
        return "树液还差 %s" % Formatter.format_cost(int(cost - state.sap.to_value()))
    return "可以点亮"

func _refresh_world_ui() -> void:
    var state := GameManager.get_state()
    nine_realms_panel.visible = state.relics_found.has(9)
    if not nine_realms_panel.visible:
        miracle_target_flow.visible = false
        miracle_target_label.visible = false
        return
    var world_level := RealmActions.world_level(state)
    world_header_label.text = "九界之树 · 世界之语 %d/9 · Lv%d" % [state.realm_echoes.size(), world_level]
    var echo := realm_run_echo(state.run_number)
    world_run_echo_label.text = echo
    world_run_echo_label.visible = echo != "" and not state.realm_echoes.is_empty()
    var expanded := state.lingua_nodes.has(&"world_trace") or state.run_number >= 2 and not state.realm_echoes.is_empty()
    world_mode_label.text = "三域全景 · 冠 / 干 / 根" if expanded else "近路 · 当前可抵达"
    crown_label.visible = expanded
    trunk_label.visible = expanded
    root_domain_label.visible = expanded
    crown_flow.visible = expanded or realm_visible_in_panel(state, &"alfheim")
    root_domain_flow.visible = expanded
    for pair in _realm_buttons():
        var realm_id: StringName = pair[0]
        var button: Button = pair[1]
        var realm := RealmCatalog.get_realm(realm_id)
        button.visible = realm_visible_in_panel(state, realm_id)
        if realm == null:
            button.disabled = true
            continue
        var found := state.realm_echoes.has(realm_id)
        var marker := "◇" if found and state.run_number >= 2 else ("●" if found else "○")
        var gap := realm_gap_text(state, realm)
        button.text = "%s %s" % [marker, realm.display_name]
        if not found:
            button.text += " · %s" % gap
        button.disabled = found or not RealmActions.can_explore(state, realm_id)
    for pair in _world_node_buttons():
        var node_id: StringName = pair[0]
        var button: Button = pair[1]
        var node := LinguaData.get_node(node_id)
        var gap := _world_node_gap_text(state, node)
        button.text = "%s%s · %s" % ["◆ " if state.lingua_nodes.has(node_id) else "", str(node.get("name", "")), gap]
        button.disabled = not LinguaActions.can_unlock_node(state, node_id)
    for pair in _miracle_buttons():
        var miracle_id: StringName = pair[0]
        var button: Button = pair[1]
        var miracle := MiracleCatalog.get_miracle(miracle_id)
        var gap := miracle_gap_text(state, miracle)
        var count_text := ""
        if miracle != null and miracle.max_uses > 0:
            count_text = " %d/%d" % [MiracleActions.count(state, miracle_id), miracle.max_uses]
        var cost := MiracleActions.faith_cost(state, miracle_id)
        button.text = "%s%s · %d 信仰 · %s" % [miracle.display_name if miracle != null else str(miracle_id), count_text, cost, gap]
        button.disabled = gap != "可以施展" and gap != "选择四族"
    axis_gate_label.text = world_axis_gap_text(state)
    _refresh_miracle_targets()

func _refresh_miracle_targets() -> void:
    var state := GameManager.get_state()
    var active := _pending_miracle_target_id != &""
    miracle_target_label.visible = active
    miracle_target_flow.visible = active
    if not active:
        return
    var miracle := MiracleCatalog.get_miracle(_pending_miracle_target_id)
    miracle_target_label.text = "%s，要落向谁？" % (miracle.display_name if miracle != null else "奇迹")
    for pair in _miracle_target_buttons():
        var race_id: StringName = pair[0]
        var button: Button = pair[1]
        var can_perform := GameManager.can_perform_miracle(_pending_miracle_target_id, race_id)
        var gap := "可以回应"
        if not can_perform:
            if not state.races.has(race_id) or not bool(state.races[race_id].get("awakened", false)):
                gap = "尚未醒来"
            elif _pending_miracle_target_id == &"banish_shadow" and race_id == &"stoneborn":
                gap = "石中没有影"
            elif _pending_miracle_target_id == &"banish_shadow" and not PlunderActions.is_frozen(state, race_id):
                gap = "没有待驱的影"
            else:
                gap = miracle_gap_text(state, miracle)
        button.text = "%s · %s" % [RACE_ROWS.get(race_id, str(race_id)), gap]
        button.disabled = not can_perform

func _on_realm_pressed(realm_id: StringName) -> void:
    GameManager.explore_realm(realm_id)

func _on_realm_explored(_realm_id: StringName, realm_name: String, discovery_text: String, _world_level: int) -> void:
    race_event_label.text = "%s\n\n%s" % [realm_name, discovery_text]
    log_label.text = "（远处的一界，在年轮里有了名字。）"

func _on_world_language_changed(_node_id: StringName, node_name: String, effect: String) -> void:
    log_label.text = "（%s醒来。%s。）" % [node_name, effect]

func _on_miracle_pressed(miracle_id: StringName) -> void:
    var miracle := MiracleCatalog.get_miracle(miracle_id)
    if miracle == null:
        return
    if miracle.target_mode == "race":
        _pending_miracle_target_id = miracle_id
        _refresh_miracle_targets()
        return
    _pending_miracle_target_id = &""
    _refresh_miracle_targets()
    GameManager.perform_miracle(miracle_id)

func _on_miracle_target_pressed(race_id: StringName) -> void:
    if _pending_miracle_target_id == &"":
        return
    var result := GameManager.perform_miracle(_pending_miracle_target_id, race_id)
    if result.get("ok", false):
        _pending_miracle_target_id = &""
        _refresh_miracle_targets()

func _on_miracle_performed(_miracle_id: StringName, _target_race_id: StringName, result_text: String, _count: int) -> void:
    race_event_label.text = result_text
    log_label.text = "（信仰落回土地，像雨落回河。）"
