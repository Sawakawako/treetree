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

func _ready() -> void:
    %GatherButton.pressed.connect(_on_gather_pressed)
    leaf_button.pressed.connect(_on_leaf_pressed)
    branch_button.pressed.connect(_on_branch_pressed)
    root_button.pressed.connect(_on_root_pressed)
    totem_button.pressed.connect(_on_totem_pressed)
    interact_human_button.pressed.connect(func(): _on_interact_pressed(&"human"))
    interact_forest_button.pressed.connect(func(): _on_interact_pressed(&"forestfolk"))
    interact_stone_button.pressed.connect(func(): _on_interact_pressed(&"stoneborn"))
    interact_wild_button.pressed.connect(func(): _on_interact_pressed(&"wildfolk"))
    GameManager.resources_changed.connect(_refresh)
    GameManager.relic_discovered.connect(_on_relic_discovered)
    GameManager.race_awakened.connect(_on_race_awakened)
    GameManager.totem_interpreted.connect(_on_totem_interpreted)
    # 读档恢复的唤醒发生在 autoload _ready（早于本场景），信号已发出——此处兜底播报
    if GameManager.is_human_awakened():
        var human := GameManager.get_race(&"human")
        if human != null:
            _on_race_awakened(human.id, human.display_name, human.awaken_text)
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
    sap_label.text = Formatter.format_number(s.sap)
    growth_label.text = Formatter.format_number(s.growth)
    memory_label.text = "记忆：" + Formatter.format_number(GameManager.get_memory())
    faith_label.text = "信仰：" + Formatter.format_number(GameManager.get_faith())
    leaf_cost_label.text = Formatter.format_cost(GameManager.get_leaf_cost())
    branch_cost_label.text = Formatter.format_cost(GameManager.get_branch_cost())
    leaf_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_leaf_cost())))
    branch_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_branch_cost())))
    root_button.disabled = not RootActions.can_explore(s)
    _refresh_race_rows()
    _refresh_totem()
    _refresh_interact_buttons()

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
