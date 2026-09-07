class_name TreeHeartPage
extends UiPage

const DEFAULT_HEART_TEXT := "风从旧土上经过。\n有些名字，还在叶脉里。"
const RUN2_OPENING_TEXT := "你记得这缕光。你曾把它交给下一个自己。"
const RUN3_OPENING_TEXT := "你醒来时，手里有一点希望。不是「一点」——是一点半。\n像有人在你睡着的时候，往你手心里添了一勺。\n土壤是软的。你低头，看见自己脚下有一圈新芽的痕迹——\n圆的，像一个拥抱留下的。\n你不知道那是谁种的。但你认得那个形状：那是你的形状。"
const DEEP_DREAM_TEXT := "你把根须往更深处送。泥下的梦，比河里的更老——老到分不清是记忆，还是地质层。\n你梦见一棵树。不是你自己。是很多年前，一棵真正的、普通的树。\n它不知道什么叫世界。它只知道向上，向光。\n醒来时，你的根须里多了一点暖意。像有什么东西，在你身体里扎了根。"
const WIND_VEIL_TEXT := "风从旧世界的方向吹来。你在风里，听见很远的说话声——\n有人在河边洗衣服。有孩子在追一只蜻蜓。有人在天裂之前，最后看了一眼太阳。\n声音很轻，像隔着水面。\n你听了一整个下午。风停的时候，你发现自己记下了它们的声音——像记下了某种信仰。"

const BASIC_GOALS: Array[Dictionary] = [
	{"action": &"leaf", "level": &"leaf_level", "title": "叶序螺旋"},
	{"action": &"branch", "level": &"branch_level", "title": "分枝序"},
	{"action": &"chloroplast", "level": &"chloroplast_level", "title": "叶绿体"},
	{"action": &"xylem", "level": &"xylem_level", "title": "木质部"},
	{"action": &"sunflower", "level": &"sunflower_level", "title": "花盘"},
	{"action": &"nautilus", "level": &"nautilus_level", "title": "螺舱"},
	{"action": &"root_eff", "level": &"root_eff_level", "title": "根须等级"},
]

@onready var _stage_label: Label = %StageLabel
@onready var _heart_label: Label = %HeartLabel
@onready var _goal_label: Label = %GoalLabel
@onready var _root_status_label: Label = %RootStatusLabel
@onready var _leaf_cost_label: Label = %LeafCostLabel
@onready var _branch_cost_label: Label = %BranchCostLabel
@onready var _chloroplast_cost_label: Label = %ChloroplastCostLabel
@onready var _xylem_cost_label: Label = %XylemCostLabel
@onready var _sunflower_cost_label: Label = %SunflowerCostLabel
@onready var _nautilus_cost_label: Label = %NautilusCostLabel
@onready var _root_eff_cost_label: Label = %RootEffCostLabel
@onready var _seedling_cost_label: Label = %SeedlingCostLabel
@onready var _leaf_button: Button = %LeafButton
@onready var _branch_button: Button = %BranchButton
@onready var _chloroplast_button: Button = %ChloroplastButton
@onready var _xylem_button: Button = %XylemButton
@onready var _sunflower_button: Button = %SunflowerButton
@onready var _nautilus_button: Button = %NautilusButton
@onready var _root_eff_button: Button = %RootEffButton
@onready var _root_explore_button: Button = %RootExploreButton
@onready var _seedling_button: Button = %SeedlingButton
@onready var _deep_dream_button: Button = %DeepDreamButton
@onready var _wind_veil_button: Button = %WindVeilButton

func _ready() -> void:
	%GatherButton.pressed.connect(_on_gather_pressed)
	_leaf_button.pressed.connect(_on_leaf_pressed)
	_branch_button.pressed.connect(_on_branch_pressed)
	_chloroplast_button.pressed.connect(_on_chloroplast_pressed)
	_xylem_button.pressed.connect(_on_xylem_pressed)
	_sunflower_button.pressed.connect(_on_sunflower_pressed)
	_nautilus_button.pressed.connect(_on_nautilus_pressed)
	_root_eff_button.pressed.connect(_on_root_eff_pressed)
	_root_explore_button.pressed.connect(_on_root_pressed)
	_seedling_button.pressed.connect(_on_seedling_pressed)
	_deep_dream_button.pressed.connect(_on_deep_dream_pressed)
	_wind_veil_button.pressed.connect(_on_wind_veil_pressed)

static func growth_stage(state: GameState) -> String:
	if not state.pending_ending.is_empty() \
			or state.choices_done.has(&"world_axis") \
			or EndingStateMachine.axis_ready(state):
		return "世界之轴"
	if state.lingua_life_level > 0 \
			or state.lingua_memory_level > 0 \
			or not state.lingua_nodes.is_empty() \
			or state.faith_engine_level > 0 \
			or state.memory_engine_level > 0 \
			or TotemActions.visible_stage(state) > 0:
		return "巨树"
	for race_id: StringName in GameState.RACE_IDS:
		if state.races.has(race_id) and bool(state.races[race_id].get("awakened", false)):
			return "成树"
	if state.seedling_level > 0 \
			or state.deep_dream \
			or state.wind_veil \
			or state.leaf_level > 0 \
			or state.branch_level > 0 \
			or state.chloroplast_level > 0 \
			or state.xylem_level > 0 \
			or state.sunflower_level > 0 \
			or state.nautilus_level > 0 \
			or state.root_eff_level > 0:
		return "幼苗"
	return "种子"

static func heart_text(state: GameState) -> String:
	match state.run_number:
		2:
			return RUN2_OPENING_TEXT
		3:
			return RUN3_OPENING_TEXT
		_:
			return DEFAULT_HEART_TEXT

static func next_goal_view(state: GameState, costs: Dictionary) -> Dictionary:
	if state.seedling_level < 3:
		return {
			"action": &"seedling",
			"title": "嫩叶教学",
			"detail": "%d/3 · 价格 %s 树液" % [state.seedling_level, Formatter.format_cost(int(costs.get("seedling", 0)))],
		}
	for goal: Dictionary in BASIC_GOALS:
		var level_name := StringName(str(goal.get("level", &"")))
		if int(state.get(level_name)) == 0:
			var action := StringName(str(goal.get("action", &"")))
			return {
				"action": action,
				"title": str(goal.get("title", "")),
				"detail": "0 级 · 价格 %s 树液" % Formatter.format_cost(_goal_cost(costs, action)),
			}
	if not _any_race_awakened(state):
		return {
			"action": &"root",
			"title": "根须探索",
			"detail": "遗迹 %d/9 · 价格 %s 树液" % [state.relics_found.size(), Formatter.format_cost(int(costs.get("root", 0)))],
		}
	if not _lingua_visible(state):
		return {"action": &"lingua", "title": "唤醒树语", "detail": "信仰达到 1"}
	if not state.relics_found.has(9):
		return {
			"action": &"relic_9",
			"title": "找到第九处遗迹",
			"detail": "遗迹 %d/9 · 探索价格 %s 树液" % [state.relics_found.size(), Formatter.format_cost(int(costs.get("root", 0)))],
		}
	return {"action": &"world_axis", "title": "走向世界之轴", "detail": WorldAxisProjection.gap_text(state)}

static func _goal_cost(costs: Dictionary, action: StringName) -> int:
	return int(costs.get(action, costs.get(str(action), 0)))

static func _any_race_awakened(state: GameState) -> bool:
	for race_id: StringName in GameState.RACE_IDS:
		if state.races.has(race_id) and bool(state.races[race_id].get("awakened", false)):
			return true
	return false

static func _lingua_visible(state: GameState) -> bool:
	return state.lingua_life_level > 0 \
		or state.lingua_memory_level > 0 \
		or not state.lingua_nodes.is_empty() \
		or state.faith_engine_level > 0 \
		or state.memory_engine_level > 0 \
		or state.faith.is_greater_or_equal(BigNum.new(1.0)) \
		or LinguaActions.can_upgrade_memory(state)

func refresh(state: GameState) -> void:
	var costs := _costs()
	var goal := next_goal_view(state, costs)
	_stage_label.text = "当前阶段 · %s" % growth_stage(state)
	_heart_label.text = heart_text(state)
	_goal_label.text = "下一目标 · %s\n%s" % [str(goal.get("title", "")), str(goal.get("detail", ""))]
	_leaf_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"leaf"]))
	_branch_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"branch"]))
	_chloroplast_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"chloroplast"]))
	_xylem_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"xylem"]))
	_sunflower_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"sunflower"]))
	_nautilus_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"nautilus"]))
	_root_eff_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"root_eff"]))
	_seedling_cost_label.text = "价格：%s" % Formatter.format_cost(int(costs[&"seedling"]))
	_root_status_label.text = "遗迹：%d/9 · 探索价格：%s 树液" % [state.relics_found.size(), Formatter.format_cost(int(costs[&"root"]))]
	_leaf_button.disabled = not _can_afford_sap(state, int(costs[&"leaf"]))
	_branch_button.disabled = not _can_afford_sap(state, int(costs[&"branch"]))
	_chloroplast_button.disabled = not _can_afford_sap(state, int(costs[&"chloroplast"]))
	_xylem_button.disabled = not _can_afford_sap(state, int(costs[&"xylem"]))
	_sunflower_button.disabled = not _can_afford_sap(state, int(costs[&"sunflower"]))
	_nautilus_button.disabled = not _can_afford_sap(state, int(costs[&"nautilus"]))
	_root_eff_button.disabled = not _can_afford_sap(state, int(costs[&"root_eff"]))
	_root_explore_button.disabled = not RootActions.can_explore(state)
	_seedling_button.visible = state.seedling_level < 3
	_seedling_cost_label.visible = state.seedling_level < 3
	_seedling_button.disabled = not _can_afford_sap(state, int(costs[&"seedling"]))
	_deep_dream_button.visible = not state.deep_dream
	_deep_dream_button.disabled = not _can_afford_sap(state, 3000)
	_wind_veil_button.visible = not state.wind_veil
	_wind_veil_button.disabled = not _can_afford_sap(state, 2500)

func _costs() -> Dictionary:
	return {
		&"seedling": GameManager.get_seedling_cost(),
		&"leaf": GameManager.get_leaf_cost(),
		&"branch": GameManager.get_branch_cost(),
		&"chloroplast": GameManager.get_chloroplast_cost(),
		&"xylem": GameManager.get_xylem_cost(),
		&"sunflower": GameManager.get_sunflower_cost(),
		&"nautilus": GameManager.get_nautilus_cost(),
		&"root_eff": GameManager.get_root_eff_cost(),
		&"root": int(RootActions.explore_cost(GameManager.get_state())),
	}

func _can_afford_sap(state: GameState, cost: int) -> bool:
	return state.sap.is_greater_or_equal(BigNum.new(float(cost)))

func _on_gather_pressed() -> void:
	GameManager.gather()
	refresh_requested.emit()

func _on_leaf_pressed() -> void:
	if GameManager.buy_leaf():
		_emit_toast("叶序螺旋升至 %d 级。" % GameManager.get_state().leaf_level)
	refresh_requested.emit()

func _on_branch_pressed() -> void:
	if GameManager.buy_branch():
		_emit_toast("分枝序升至 %d 级。" % GameManager.get_state().branch_level)
	refresh_requested.emit()

func _on_chloroplast_pressed() -> void:
	if GameManager.buy_chloroplast():
		_emit_toast("叶绿体升至 %d 级。" % GameManager.get_state().chloroplast_level)
	refresh_requested.emit()

func _on_xylem_pressed() -> void:
	if GameManager.buy_xylem():
		_emit_toast("木质部升至 %d 级。" % GameManager.get_state().xylem_level)
	refresh_requested.emit()

func _on_sunflower_pressed() -> void:
	if GameManager.buy_sunflower():
		_emit_toast("花盘升至 %d 级。" % GameManager.get_state().sunflower_level)
	refresh_requested.emit()

func _on_nautilus_pressed() -> void:
	if GameManager.buy_nautilus():
		_emit_toast("螺舱升至 %d 级。" % GameManager.get_state().nautilus_level)
	refresh_requested.emit()

func _on_root_eff_pressed() -> void:
	if GameManager.buy_root_eff():
		_emit_toast("根须等级升至 %d 级。" % GameManager.get_state().root_eff_level)
	refresh_requested.emit()

func _on_root_pressed() -> void:
	var reason := RootActions.explore_block_reason(GameManager.get_state())
	var result: Dictionary = GameManager.explore_relic()
	if not bool(result.get("ok", false)):
		_emit_toast(_root_failure_text(reason))
	refresh_requested.emit()

func _on_seedling_pressed() -> void:
	if GameManager.buy_seedling():
		_emit_toast("嫩叶舒展开了。")
	refresh_requested.emit()

func _on_deep_dream_pressed() -> void:
	if GameManager.buy_deep_dream():
		feedback_requested.emit({"kind": &"narrative", "body": DEEP_DREAM_TEXT})
		_emit_toast("（深根梦 · 记忆 +15）")
	refresh_requested.emit()

func _on_wind_veil_pressed() -> void:
	if GameManager.buy_wind_veil():
		feedback_requested.emit({"kind": &"narrative", "body": WIND_VEIL_TEXT})
		_emit_toast("（风语膜 · 信仰 +30）")
	refresh_requested.emit()

func _emit_toast(body: String) -> void:
	feedback_requested.emit({"kind": &"toast", "body": body})

func _root_failure_text(reason: StringName) -> String:
	match reason:
		&"insufficient_sap":
			return "树液还不够。根须在浅土里停下。"
		&"no_available_relic":
			return "根须摸到一片安静。这里暂时没有愿意醒来的遗迹。"
		&"all_relics_found":
			return "九处旧梦，都已经收进年轮。土里只剩安静。"
		_:
			return "根须停下了。土里没有回声。"
