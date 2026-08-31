extends Control

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
@onready var human_event_label: Label = %HumanEventLabel

func _ready() -> void:
    %GatherButton.pressed.connect(_on_gather_pressed)
    leaf_button.pressed.connect(_on_leaf_pressed)
    branch_button.pressed.connect(_on_branch_pressed)
    root_button.pressed.connect(_on_root_pressed)
    GameManager.resources_changed.connect(_refresh)
    GameManager.relic_discovered.connect(_on_relic_discovered)
    GameManager.human_awakened.connect(_on_human_awakened)
    # 读档恢复的唤醒发生在 autoload _ready（早于本场景），信号已发出——此处兜底播报
    if GameManager.is_human_awakened():
        _on_human_awakened()
    _refresh()

func _on_human_awakened() -> void:
    human_event_label.text = "土里传来一个苍老的声音：\n「你在听吗？……我是最后一个说梦的人。我梦见你很多年了。」"

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
