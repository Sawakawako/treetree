class_name BottomNavigation
extends HBoxContainer

signal tab_selected(tab_id: StringName)

const TAB_ORDER: Array[StringName] = [&"tree_heart", &"beings", &"lingua", &"nine_realms"]
const INTRO_DURATION := 0.16
const WARM_GOLD := Color("e6a23c")

var _buttons: Dictionary = {}
var _seen_tabs: Array[StringName] = []
var _tab_tweens: Dictionary = {}
var _initialized := false

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_buttons = {
		&"tree_heart": get_node("TreeHeartTab"),
		&"beings": get_node("BeingsTab"),
		&"lingua": get_node("LinguaTab"),
		&"nine_realms": get_node("NineRealmsTab"),
	}
	for tab_id: StringName in TAB_ORDER:
		var button: Button = _buttons[tab_id]
		button.pressed.connect(_on_tab_pressed.bind(tab_id))

static func visible_tabs(state: GameState) -> Array[StringName]:
	var result: Array[StringName] = [&"tree_heart"]
	for race_id: StringName in GameState.RACE_IDS:
		if state.races.has(race_id) and bool(state.races[race_id].get("awakened", false)):
			result.append(&"beings")
			break
	var lingua_started := state.lingua_life_level > 0 \
		or state.lingua_memory_level > 0 \
		or not state.lingua_nodes.is_empty() \
		or state.faith_engine_level > 0 \
		or state.memory_engine_level > 0 \
		or state.faith.is_greater_or_equal(BigNum.new(1.0)) \
		or LinguaActions.can_upgrade_memory(state)
	if lingua_started:
		result.append(&"lingua")
	if state.relics_found.has(9):
		result.append(&"nine_realms")
	return result

static func normalize_active_tab(requested: StringName, visible_tabs: Array[StringName]) -> StringName:
	return requested if visible_tabs.has(requested) else &"tree_heart"

func refresh(visible_tabs: Array[StringName], active_tab: StringName) -> void:
	for tab_id: StringName in TAB_ORDER:
		var button: Button = _buttons[tab_id]
		var is_visible := visible_tabs.has(tab_id)
		var introduced := _initialized and is_visible and not _seen_tabs.has(tab_id)
		button.visible = is_visible
		button.theme_type_variation = &"BottomTabSelected" if tab_id == active_tab else &"BottomTab"
		if introduced:
			_animate_introduction(button)
		if is_visible and not _seen_tabs.has(tab_id):
			_seen_tabs.append(tab_id)
	_initialized = true

func _on_tab_pressed(tab_id: StringName) -> void:
	tab_selected.emit(tab_id)

func _animate_introduction(button: Button) -> void:
	if _tab_tweens.has(button):
		var previous: Tween = _tab_tweens[button]
		if previous and previous.is_valid():
			previous.kill()
	button.modulate = Color(WARM_GOLD.r, WARM_GOLD.g, WARM_GOLD.b, 0.0)
	if not is_inside_tree():
		button.modulate = Color.WHITE
		return
	var tween := create_tween().bind_node(button)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "modulate", Color.WHITE, INTRO_DURATION)
	_tab_tweens[button] = tween
