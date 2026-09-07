class_name LinguaPage
extends UiPage

const NODE_ROWS: Array[Dictionary] = [
	{"id": &"root_echo", "button": &"RootEchoButton"},
	{"id": &"root_resonance", "button": &"RootResonanceButton"},
	{"id": &"earth_sense", "button": &"EarthSenseButton"},
	{"id": &"deep_root", "button": &"DeepRootButton"},
	{"id": &"tree_canopy", "button": &"TreeCanopyButton"},
	{"id": &"ring_memory", "button": &"RingMemoryButton"},
	{"id": &"cloud_crown", "button": &"CloudCrownButton"},
	{"id": &"wood_heart", "button": &"WoodHeartButton"},
	{"id": &"sky_light", "button": &"SkyLightButton"},
	{"id": &"song_resonance", "button": &"SongResonanceButton"},
	{"id": &"village_heart", "button": &"VillageHeartButton"},
	{"id": &"grace", "button": &"GraceButton"},
	{"id": &"altar", "button": &"AltarButton"},
]

var _node_buttons: Dictionary = {}

@onready var _insight_context_label: Label = %InsightContextLabel
@onready var _life_level_label: Label = %LifeLevelLabel
@onready var _memory_level_label: Label = %MemoryLevelLabel
@onready var _suggested_node_label: Label = %SuggestedNodeLabel
@onready var _conversion_card: PanelContainer = %ConversionCard
@onready var _faith_convert_button: Button = %FaithConvertButton
@onready var _memory_convert_button: Button = %MemoryConvertButton
@onready var _engine_card: PanelContainer = %EngineCard
@onready var _faith_engine_button: Button = %FaithEngineButton
@onready var _faith_engine_cost_label: Label = %FaithEngineCostLabel
@onready var _memory_engine_button: Button = %MemoryEngineButton
@onready var _memory_engine_cost_label: Label = %MemoryEngineCostLabel
@onready var _life_upgrade_button: Button = %LifeUpgradeButton
@onready var _life_cost_label: Label = %LifeCostLabel
@onready var _memory_lingua_button: Button = %MemoryLinguaButton
@onready var _memory_lingua_cost_label: Label = %MemoryLinguaCostLabel

func _ready() -> void:
	_faith_convert_button.pressed.connect(_on_convert_faith_pressed)
	_memory_convert_button.pressed.connect(_on_convert_memory_pressed)
	_faith_engine_button.pressed.connect(_on_engine_faith_pressed)
	_memory_engine_button.pressed.connect(_on_engine_memory_pressed)
	_life_upgrade_button.pressed.connect(_on_life_upgrade_pressed)
	_memory_lingua_button.pressed.connect(_on_memory_lingua_pressed)
	for row: Dictionary in NODE_ROWS:
		var node_id := StringName(row["id"])
		var button := find_child(str(row["button"]), true, false) as Button
		_node_buttons[node_id] = button
		button.pressed.connect(_on_node_unlock_pressed.bind(node_id))

static func node_view(state: GameState, node_id: StringName) -> Dictionary:
	var node := LinguaData.get_node(node_id)
	if node.is_empty():
		return {"visible": false, "disabled": true, "status": "节点缺失"}
	if LinguaActions.has_node(state, node_id):
		return {"visible": true, "disabled": true, "status": "已点亮", "node": node}
	var language := StringName(node.get("language", &"life"))
	var level := state.lingua_memory_level if language == &"memory" else state.lingua_life_level
	var requirement := int(node.get("requirement", 99))
	if level < requirement:
		var language_name := "记忆之语" if language == &"memory" else "生命之语"
		return {"visible": true, "disabled": true, "status": "%s还差 Lv%d" % [language_name, requirement - level], "node": node}
	for raw_id: Variant in node.get("prerequisites", []):
		var prerequisite := StringName(str(raw_id))
		if not state.lingua_nodes.has(prerequisite):
			return {"visible": true, "disabled": true, "status": "还差%s" % LinguaData.get_node(prerequisite).get("name", prerequisite), "node": node}
	var cost := int(node.get("sap_cost", 0))
	var status := "可以点亮" if LinguaActions.can_unlock_node(state, node_id) else "树液还差 %s" % Formatter.format_cost(maxi(cost - int(state.sap.to_value()), 0))
	return {"visible": true, "disabled": not LinguaActions.can_unlock_node(state, node_id), "status": status, "node": node}

func refresh(state: GameState) -> void:
	_insight_context_label.text = "领悟：%d" % state.insight
	_life_level_label.text = "生命之语 · Lv%d / %d" % [state.lingua_life_level, LinguaData.LIFE_MAX_LEVEL]
	_memory_level_label.text = "记忆之语 · Lv%d / %d" % [state.lingua_memory_level, LinguaData.MEMORY_MAX_LEVEL]
	_refresh_conversions(state)
	_refresh_engines(state)
	_refresh_language_upgrades(state)
	_refresh_nodes(state)

func _refresh_conversions(state: GameState) -> void:
	_faith_convert_button.visible = LinguaActions.has_node(state, &"tree_canopy")
	_memory_convert_button.visible = LinguaActions.has_node(state, &"root_resonance")
	_conversion_card.visible = _faith_convert_button.visible or _memory_convert_button.visible

func _refresh_engines(state: GameState) -> void:
	var faith_visible := LinguaActions.has_node(state, &"cloud_crown")
	var faith_cost := CostCalculator.faith_engine_cost(state.faith_engine_level)
	_faith_engine_button.visible = faith_visible
	_faith_engine_cost_label.visible = faith_visible
	_faith_engine_cost_label.text = "价格：%d" % faith_cost
	_faith_engine_button.disabled = not state.faith.is_greater_or_equal(BigNum.new(float(faith_cost)))
	var memory_visible := LinguaActions.has_node(state, &"grace")
	var memory_cost := CostCalculator.memory_engine_cost(state.memory_engine_level)
	_memory_engine_button.visible = memory_visible
	_memory_engine_cost_label.visible = memory_visible
	_memory_engine_cost_label.text = "价格：%d" % memory_cost
	_memory_engine_button.disabled = not state.memory.is_greater_or_equal(BigNum.new(float(memory_cost)))
	_engine_card.visible = faith_visible or memory_visible

func _refresh_language_upgrades(state: GameState) -> void:
	var life_cost := LinguaActions.life_cost(state)
	_life_upgrade_button.visible = state.lingua_life_level > 0 or state.faith.is_greater_or_equal(BigNum.new(1.0))
	_life_upgrade_button.disabled = not LinguaActions.can_upgrade_life(state)
	_life_cost_label.visible = state.lingua_life_level > 0
	_life_cost_label.text = "生命之语 Lv%d → %s" % [state.lingua_life_level, ("免费" if life_cost == 0 else ("%d 信仰" % life_cost)) if life_cost >= 0 else "已满级"]
	_memory_lingua_button.visible = true
	_memory_lingua_button.disabled = not LinguaActions.can_upgrade_memory(state)
	_memory_lingua_cost_label.text = "记忆之语 Lv1 · 500 记忆 + 领悟 5（领悟不消耗）" if state.lingua_memory_level == 0 else "记忆之语 Lv1 · 已醒来"

func _refresh_nodes(state: GameState) -> void:
	var suggested := ""
	for row: Dictionary in NODE_ROWS:
		var node_id := StringName(row["id"])
		var view := node_view(state, node_id)
		var node: Dictionary = view.get("node", {})
		var button := _node_buttons[node_id] as Button
		button.visible = bool(view.get("visible", false))
		button.disabled = bool(view.get("disabled", true))
		var name := str(node.get("name", node_id))
		var status := str(view.get("status", ""))
		if status == "已点亮":
			button.text = "◆ %s · 已点亮" % name
		else:
			button.text = "%s（%s） · %s" % [name, str(node.get("effect", "")), status]
			if suggested.is_empty():
				suggested = "建议节点：%s · %s" % [name, status]
	_suggested_node_label.text = suggested if not suggested.is_empty() else "建议节点：十三缕树语都已点亮"

func _on_convert_faith_pressed() -> void:
	if GameManager.convert_faith():
		_emit_toast("（献祭 · 信仰 +1）")
	refresh_requested.emit()

func _on_convert_memory_pressed() -> void:
	if GameManager.convert_memory():
		_emit_toast("（挖梦 · 记忆 +1）")
	refresh_requested.emit()

func _on_engine_faith_pressed() -> void:
	if GameManager.buy_faith_engine():
		_emit_toast("（信仰引擎升至 %d 级）" % GameManager.get_state().faith_engine_level)
	refresh_requested.emit()

func _on_engine_memory_pressed() -> void:
	if GameManager.buy_memory_engine():
		_emit_toast("（记忆引擎升至 %d 级）" % GameManager.get_state().memory_engine_level)
	refresh_requested.emit()

func _on_life_upgrade_pressed() -> void:
	if GameManager.upgrade_life():
		_emit_toast("（生命之语 · 第 %d 阶）" % GameManager.get_state().lingua_life_level)
	refresh_requested.emit()

func _on_memory_lingua_pressed() -> void:
	if GameManager.upgrade_memory():
		_emit_toast("（旧梦在根间醒来。你仍记得它们。）")
	refresh_requested.emit()

func _on_node_unlock_pressed(node_id: StringName) -> void:
	if GameManager.unlock_node(node_id):
		var node := LinguaData.get_node(node_id)
		_emit_toast("（%s 已点亮）" % str(node.get("name", "")))
	refresh_requested.emit()

func _emit_toast(body: String) -> void:
	feedback_requested.emit({"kind": &"toast", "body": body})
