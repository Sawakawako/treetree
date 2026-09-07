class_name NineRealmsPage
extends UiPage

const REALMS: Array[Dictionary] = [
	{"id": &"asgard", "button": &"AsgardButton"}, {"id": &"vanaheim", "button": &"VanaheimButton"},
	{"id": &"alfheim", "button": &"AlfheimButton"}, {"id": &"jotunheim", "button": &"JotunheimButton"},
	{"id": &"midgard", "button": &"MidgardButton"}, {"id": &"nidavellir", "button": &"NidavellirButton"},
	{"id": &"niflheim", "button": &"NiflheimButton"}, {"id": &"helheim", "button": &"HelheimButton"},
	{"id": &"muspelheim", "button": &"MuspelheimButton"},
]
const WORLD_NODES: Array[StringName] = [&"world_trace", &"rain_name", &"river_hearing", &"sky_ladder", &"world_shaping", &"world_breath"]
const MIRACLES: Array[StringName] = [&"oasis", &"rain", &"banish_shadow", &"call_soul", &"shape"]
const MIRACLE_BUTTON_NAMES := {&"oasis": "OasisButton", &"rain": "RainButton", &"banish_shadow": "BanishShadowButton", &"call_soul": "CallSoulButton", &"shape": "ShapeButton"}
const NODE_BUTTON_NAMES := {&"world_trace": "WorldTraceButton", &"rain_name": "RainNameButton", &"river_hearing": "RiverHearingButton", &"sky_ladder": "SkyLadderButton", &"world_shaping": "WorldShapingButton", &"world_breath": "WorldBreathButton"}
const RACES: Array[StringName] = [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]
const RACE_ROWS := {&"human": "人族", &"forestfolk": "林地民", &"stoneborn": "石裔", &"wildfolk": "野民"}

var _pending_miracle: StringName = &""
var _realm_buttons: Dictionary = {}
var _node_buttons: Dictionary = {}
var _miracle_buttons: Dictionary = {}
var _target_buttons: Dictionary = {}

@onready var _world_header: Label = %WorldHeaderLabel
@onready var _run_echo: Label = %WorldRunEchoLabel
@onready var _mode: Label = %WorldModeLabel
@onready var _axis_gate: Label = %AxisGateLabel
@onready var _target_card: PanelContainer = %MiracleTargetCard
@onready var _target_label: Label = %MiracleTargetLabel

static func realm_run_echo(run_number: int) -> String:
	if run_number == 2: return "九个名字比根先醒。你还没有伸出枝条，远处已经有回声。"
	if run_number == 3: return "这一次，没有哪一界先开口。你知道每一条路，也知道路的尽头。"
	return ""

static func realm_visible_in_panel(state: GameState, realm_id: StringName) -> bool:
	if realm_id == &"midgard" or state.realm_echoes.has(realm_id): return true
	if realm_id == &"nidavellir" or realm_id == &"alfheim": return state.realm_echoes.has(&"midgard")
	return state.lingua_nodes.has(&"world_trace")

static func realm_gap_text(state: GameState, realm: RealmDefinition) -> String:
	if realm == null: return "界名尚未醒来"
	if state.realm_echoes.has(realm.id): return "已抵达"
	for prerequisite: StringName in realm.prerequisites:
		if not state.realm_echoes.has(prerequisite):
			var previous := RealmCatalog.get_realm(prerequisite)
			return "还差%s" % (previous.display_name if previous != null else str(prerequisite))
	for race_id: StringName in realm.required_races:
		if not bool(state.races.get(race_id, {}).get("awakened", false)): return "还差%s醒来" % RACE_ROWS.get(race_id, str(race_id))
	if realm.required_lingua_node != &"" and not state.lingua_nodes.has(realm.required_lingua_node): return "还差%s" % str(LinguaData.get_node(realm.required_lingua_node).get("name", realm.required_lingua_node))
	if realm.required_relic > 0 and not state.relics_found.has(realm.required_relic): return "还差遗迹 %d" % realm.required_relic
	if state.root_depth < realm.min_root_depth: return "根深还差 %d" % (realm.min_root_depth - state.root_depth)
	if not state.growth.is_greater_or_equal(BigNum.new(realm.min_growth)): return "生长还差 %s" % Formatter.format_cost(int(realm.min_growth - state.growth.to_value()))
	if not state.sap.is_greater_or_equal(BigNum.new(realm.sap_cost)): return "树液还差 %s" % Formatter.format_cost(int(realm.sap_cost - state.sap.to_value()))
	if not state.memory.is_greater_or_equal(BigNum.new(realm.memory_cost)): return "记忆还差 %s" % Formatter.format_cost(int(realm.memory_cost - state.memory.to_value()))
	if not state.faith.is_greater_or_equal(BigNum.new(realm.faith_cost)): return "信仰还差 %s" % Formatter.format_cost(int(realm.faith_cost - state.faith.to_value()))
	return "可以抵达"

static func miracle_gap_text(state: GameState, miracle: MiracleDefinition) -> String:
	if miracle == null: return "奇迹尚未醒来"
	for realm_id: StringName in miracle.required_realms:
		if not state.realm_echoes.has(realm_id):
			var realm := RealmCatalog.get_realm(realm_id)
			return "还差%s" % (realm.display_name if realm != null else str(realm_id))
	if miracle.required_lingua_node != &"" and not state.lingua_nodes.has(miracle.required_lingua_node): return "还差%s" % str(LinguaData.get_node(miracle.required_lingua_node).get("name", miracle.required_lingua_node))
	if state.lingua_life_level < miracle.required_life_level: return "生命之语还差 Lv%d" % (miracle.required_life_level - state.lingua_life_level)
	if miracle.max_uses > 0 and MiracleActions.count(state, miracle.id) >= miracle.max_uses: return "本轮已满"
	if miracle.id == &"rain" and state.miracle_rain_ticks > 0: return "雨还在落 · %d" % state.miracle_rain_ticks
	if miracle.id == &"call_soul" and state.soul_river < SoulActions.REVIVE_COST_SOUL: return "河里没有可唤的灵魂"
	if not state.faith.is_greater_or_equal(BigNum.new(float(MiracleActions.faith_cost(state, miracle.id)))): return "信仰不足"
	if miracle.target_mode == "race":
		for race_id in RACES:
			if MiracleActions.can_perform(state, miracle.id, race_id): return "选择四族"
		return "没有可回应的目标"
	return "可以施展"

static func world_node_view(state: GameState, node_id: StringName) -> Dictionary:
	var node := LinguaData.get_node(node_id)
	if node.is_empty(): return {"visible": false, "disabled": true, "completed": false, "name": str(node_id), "status": "节点缺失"}
	var node_name := str(node.get("name", node_id))
	if state.lingua_nodes.has(node_id): return {"visible": true, "disabled": true, "completed": true, "name": node_name, "status": "已点亮", "node": node}
	var level := RealmActions.world_level(state)
	var requirement := int(node.get("requirement", 99))
	if level < requirement: return {"visible": true, "disabled": true, "completed": false, "name": node_name, "status": "还差世界之语 Lv%d" % (requirement - level), "node": node}
	for raw in node.get("prerequisites", []):
		var p := StringName(str(raw))
		if not state.lingua_nodes.has(p): return {"visible": true, "disabled": true, "completed": false, "name": node_name, "status": "还差%s" % str(LinguaData.get_node(p).get("name", p)), "node": node}
	var cost := int(node.get("sap_cost", 0))
	var ok := state.sap.is_greater_or_equal(BigNum.new(float(cost)))
	return {"visible": true, "disabled": not ok, "completed": false, "name": node_name, "status": "可以点亮" if ok else "树液还差 %s" % Formatter.format_cost(maxi(cost - int(state.sap.to_value()), 0)), "node": node}

func _ready() -> void:
	for row in REALMS:
		var b := find_child(str(row.button), true, false) as Button; _realm_buttons[row.id] = b; b.pressed.connect(_on_realm_pressed.bind(row.id))
	for node_id in WORLD_NODES:
		var b := find_child(NODE_BUTTON_NAMES[node_id], true, false) as Button
		_node_buttons[node_id] = b; b.pressed.connect(_on_node_pressed.bind(node_id))
	for miracle_id in MIRACLES:
		var b := find_child(MIRACLE_BUTTON_NAMES[miracle_id], true, false) as Button
		_miracle_buttons[miracle_id] = b; b.pressed.connect(_on_miracle_pressed.bind(miracle_id))
	for race_id in RACES:
		var suffix: String = {&"human":"Human", &"forestfolk":"Forest", &"stoneborn":"Stone", &"wildfolk":"Wild"}[race_id]
		var b := find_child("Miracle%sButton" % suffix, true, false) as Button; _target_buttons[race_id] = b; b.pressed.connect(_on_target_pressed.bind(race_id))
	%WorldAxisButton.pressed.connect(_on_axis_pressed)

func refresh(state: GameState) -> void:
	_world_header.text = "九界之树 · %d/9 · Lv%d" % [state.realm_echoes.size(), RealmActions.world_level(state)]
	_run_echo.text = realm_run_echo(state.run_number); _run_echo.visible = _run_echo.text != "" and not state.realm_echoes.is_empty()
	_mode.text = "三域全景 · 冠 / 干 / 根" if state.lingua_nodes.has(&"world_trace") or state.run_number >= 2 and not state.realm_echoes.is_empty() else "近路 · 当前可抵达"
	for row in REALMS:
		var id: StringName = row.id; var b: Button = _realm_buttons[id]; var realm := RealmCatalog.get_realm(id); var found := state.realm_echoes.has(id)
		b.visible = realm_visible_in_panel(state, id); b.text = ("◇" if found and state.run_number >= 2 else ("●" if found else "○")) + " " + realm.display_name + (" · " + realm_gap_text(state, realm) if not found else ""); b.disabled = found or not RealmActions.can_explore(state, id)
	for node_id in WORLD_NODES:
		var b: Button = _node_buttons[node_id]; var view := world_node_view(state, node_id); var node: Dictionary = view.get("node", {})
		b.text = ("◆ " if view.get("status") == "已点亮" else "") + str(node.get("name", node_id)) + " · " + str(view.get("status", "")); b.disabled = bool(view.get("disabled", true))
	for miracle_id in MIRACLES:
		var b: Button = _miracle_buttons[miracle_id]; var miracle := MiracleCatalog.get_miracle(miracle_id); var gap := miracle_gap_text(state, miracle); b.text = "%s · %d 信仰 · %s" % [miracle.display_name, MiracleActions.faith_cost(state, miracle_id), gap]; b.disabled = gap != "可以施展" and gap != "选择四族"
	_axis_gate.text = WorldAxisProjection.gap_text(state)
	%WorldAxisButton.visible = EndingStateMachine.axis_ready(state) and not state.choices_done.has(&"world_axis")
	_refresh_targets(state)

func _refresh_targets(state: GameState) -> void:
	_target_card.visible = _pending_miracle != &""; _target_label.text = "%s，要落向谁？" % MiracleCatalog.get_miracle(_pending_miracle).display_name if _pending_miracle != &"" else ""
	for race_id in RACES:
		var b: Button = _target_buttons[race_id]; b.disabled = _pending_miracle == &"" or not GameManager.can_perform_miracle(_pending_miracle, race_id)

func _on_realm_pressed(id: StringName) -> void: GameManager.explore_realm(id); refresh_requested.emit()
func _on_node_pressed(id: StringName) -> void: GameManager.unlock_node(id); refresh_requested.emit()
func _on_miracle_pressed(id: StringName) -> void:
	var m := MiracleCatalog.get_miracle(id)
	if m != null and m.target_mode == "race":
		_pending_miracle = id
		_refresh_targets(GameManager.get_state())
		refresh_requested.emit()
	else: GameManager.perform_miracle(id); refresh_requested.emit()
func _on_target_pressed(id: StringName) -> void:
	if _pending_miracle == &"": return
	var result := GameManager.perform_miracle(_pending_miracle, id)
	if result.get("ok", false): _pending_miracle = &""; refresh_requested.emit()
func _on_axis_pressed() -> void: GameManager.try_start_world_axis(); refresh_requested.emit()
