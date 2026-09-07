class_name BeingsPage
extends UiPage

const RACE_ROWS := {
	&"human": "人族",
	&"forestfolk": "林地民",
	&"stoneborn": "石裔",
	&"wildfolk": "野民",
}

var _race_labels: Dictionary = {}
var _interact_buttons: Dictionary = {}
var _plunder_buttons: Dictionary = {}
var _intimate_buttons: Dictionary = {}
var _facility_buttons: Dictionary = {}
var _revive_buttons: Dictionary = {}
var _plunder_soul_buttons: Dictionary = {}

@onready var _soul_context_label: Label = %SoulContextLabel
@onready var _insight_context_label: Label = %InsightContextLabel
@onready var _totem_panel: PanelContainer = %TotemPanel
@onready var _totem_label: Label = %TotemLabel
@onready var _totem_button: Button = %TotemInterpretButton
@onready var _avatar_panel: PanelContainer = %AvatarPanel
@onready var _avatar_label: Label = %AvatarLabel
@onready var _soul_label: Label = %SoulLabel
@onready var _story_status_label: Label = %StoryStatusLabel
@onready var _story_button: Button = %StoryButton
@onready var _stream_story_button: Button = %StreamStoryButton

func _ready() -> void:
	_race_labels = {
		&"human": %RaceHumanLabel,
		&"forestfolk": %RaceForestLabel,
		&"stoneborn": %RaceStoneLabel,
		&"wildfolk": %RaceWildLabel,
	}
	_interact_buttons = {
		&"human": %InteractHumanButton,
		&"forestfolk": %InteractForestButton,
		&"stoneborn": %InteractStoneButton,
		&"wildfolk": %InteractWildButton,
	}
	_plunder_buttons = {
		&"human": %PlunderHumanButton,
		&"forestfolk": %PlunderForestButton,
		&"stoneborn": %PlunderStoneButton,
		&"wildfolk": %PlunderWildButton,
	}
	_intimate_buttons = {
		&"human": %IntimateHumanButton,
		&"forestfolk": %IntimateForestButton,
		&"stoneborn": %IntimateStoneButton,
		&"wildfolk": %IntimateWildButton,
	}
	_facility_buttons = {
		&"human": %FirepitButton,
		&"forestfolk": %RingButton,
		&"stoneborn": %ForgeButton,
		&"wildfolk": %TotemPoleButton,
	}
	_revive_buttons = {
		&"human": %ReviveHumanButton,
		&"forestfolk": %ReviveForestButton,
		&"stoneborn": %ReviveStoneButton,
		&"wildfolk": %ReviveWildButton,
	}
	_plunder_soul_buttons = {
		&"human": %PlunderSoulHumanButton,
		&"forestfolk": %PlunderSoulForestButton,
		&"stoneborn": %PlunderSoulStoneButton,
		&"wildfolk": %PlunderSoulWildButton,
	}
	for race_id: StringName in GameState.RACE_IDS:
		(_interact_buttons[race_id] as Button).pressed.connect(_on_interact_pressed.bind(race_id))
		(_plunder_buttons[race_id] as Button).pressed.connect(_on_plunder_pressed.bind(race_id))
		(_intimate_buttons[race_id] as Button).pressed.connect(_on_intimate_pressed.bind(race_id))
		(_revive_buttons[race_id] as Button).pressed.connect(_on_revive_pressed.bind(race_id))
		(_plunder_soul_buttons[race_id] as Button).pressed.connect(_on_plunder_soul_pressed.bind(race_id))
	%FirepitButton.pressed.connect(_on_facility_pressed.bind(&"human", &"firepit_level"))
	%RingButton.pressed.connect(_on_facility_pressed.bind(&"forestfolk", &"ring_level"))
	%ForgeButton.pressed.connect(_on_facility_pressed.bind(&"stoneborn", &"forge_level"))
	%TotemPoleButton.pressed.connect(_on_facility_pressed.bind(&"wildfolk", &"totem_pole_level"))
	_totem_button.pressed.connect(_on_totem_pressed)
	_story_button.pressed.connect(_on_story_pressed)
	_stream_story_button.pressed.connect(_on_stream_story_pressed)

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
		return Color("#455564")
	if value <= -0.5:
		return Color("#5f6b72")
	if value < 0.5:
		return Color("#5b5140")
	if value < 2.0:
		return Color("#765514")
	if value < 3.0:
		return Color("#70420b")
	return Color("#5c3b0a")

static func format_relation(value: float) -> String:
	var text := "%.1f" % value
	return "+" + text if value > 0.0 else text

static func race_view(state: GameState, race_id: StringName) -> Dictionary:
	var data := RaceManager.get_race(race_id)
	var display_name := data.display_name if data != null else str(RACE_ROWS.get(race_id, race_id))
	var relation := RelationActions.get_relation(state, race_id)
	var label := relation_label(relation)
	var relation_text := format_relation(relation)
	var hint := _awaken_hint(data)
	var awakened := _race_awakened(state, race_id)
	var summary := "%s：%s 时苏醒" % [display_name, hint]
	if awakened:
		var population := float(state.races[race_id].get("population", 0.0))
		summary = "%s：人口 %d · %s（%s）" % [display_name, int(population), label, relation_text]
		if PlunderActions.is_frozen(state, race_id):
			summary += " · 夺梦揭示 · 人口停滞"
	return {
		"awakened": awakened,
		"summary": summary,
		"relation_label": label,
		"relation_text": relation_text,
		"relation_color": relation_color(relation),
		"awaken_hint": hint,
	}

static func storyteller_view(state: GameState) -> Dictionary:
	var main_ids := StoryLibrary.main_story_ids()
	var read_count := 0
	for story_id: StringName in main_ids:
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

func refresh(state: GameState) -> void:
	_soul_context_label.text = "河底灵魂：%d / %d" % [state.soul_river, SoulActions.RIVER_TOTAL]
	_insight_context_label.text = "领悟：%d" % state.insight
	_soul_label.text = "灵魂：%d / %d" % [state.soul_river, SoulActions.RIVER_TOTAL]
	for race_id: StringName in GameState.RACE_IDS:
		var view := race_view(state, race_id)
		var race_label := _race_labels[race_id] as Label
		race_label.text = str(view.get("summary", ""))
		race_label.add_theme_color_override("font_color", view.get("relation_color", Color("#5b5140")))
		(_interact_buttons[race_id] as Button).visible = _can_interact(state, race_id)
		(_plunder_buttons[race_id] as Button).visible = PlunderActions.can_plunder(state, race_id)
		(_intimate_buttons[race_id] as Button).visible = DriftActions.can_intimate(state, race_id)
		(_revive_buttons[race_id] as Button).visible = SoulActions.can_revive(state, race_id)
		(_plunder_soul_buttons[race_id] as Button).visible = SoulActions.can_plunder_soul(state, race_id)
	_refresh_facilities(state)
	_refresh_totem(state)
	_refresh_avatar(state)
	_refresh_storyteller(state)

static func _awaken_hint(data: RaceData) -> String:
	if data == null:
		return "条件缺失"
	if data.awaken_condition == "memory>=2":
		return "记忆 2"
	if data.awaken_condition.begins_with("faith>="):
		return "信仰 " + data.awaken_condition.get_slice(">=", 1)
	return data.awaken_condition

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func _can_interact(state: GameState, race_id: StringName) -> bool:
	if RelationActions.can_interact(state, race_id):
		return true
	for event: Dictionary in RelationEvents.extra_events():
		if StringName(str(event.get("race_id", &""))) != race_id:
			continue
		if RelationActions.can_interact_event(state, StringName(str(event.get("event_id", &"")))):
			return true
	return false

func _refresh_facilities(state: GameState) -> void:
	var costs := {
		&"human": GameManager.get_firepit_cost(),
		&"forestfolk": GameManager.get_ring_cost(),
		&"stoneborn": GameManager.get_forge_cost(),
		&"wildfolk": GameManager.get_totem_pole_cost(),
	}
	for race_id: StringName in GameState.RACE_IDS:
		var button := _facility_buttons[race_id] as Button
		button.visible = _race_awakened(state, race_id)
		button.disabled = not state.sap.is_greater_or_equal(BigNum.new(float(costs[race_id])))
		button.tooltip_text = "价格：%s 树液" % Formatter.format_cost(int(costs[race_id]))

func _refresh_totem(state: GameState) -> void:
	var stage := TotemActions.visible_stage(state)
	var visible := stage > 0
	_totem_panel.visible = visible
	_totem_button.visible = visible
	if not visible:
		return
	var totem := TotemLibrary.get_totem(stage)
	_totem_label.text = "图腾·第 %d 幅\n%s" % [stage, str(totem.get("reveal_text", ""))]
	_totem_button.disabled = TotemActions.next_interpretable(state) <= 0

func _refresh_avatar(state: GameState) -> void:
	var visible := DriftActions.is_avatar_awakened(state)
	_avatar_panel.visible = visible
	if not visible:
		return
	var tier_names := ["清醒", "微漂", "深漂", "迷失"]
	var tier := DriftActions.drift_tier(state)
	_avatar_label.text = "化身 · %s\n%s" % [tier_names[tier], DriftActions.avatar_tier_text(state)]

func _refresh_storyteller(state: GameState) -> void:
	var view := storyteller_view(state)
	var visible := bool(view.get("visible", false))
	_story_status_label.visible = visible
	_story_button.visible = visible
	if visible:
		_story_status_label.text = str(view.get("status_text", ""))
		_story_button.text = str(view.get("button_text", ""))
		_story_button.disabled = bool(view.get("disabled", true))
	var stream_available := not StoryActions.available_easter_eggs(state).is_empty()
	var stream_read := state.storyteller_stories.has(&"stream_and_current")
	_stream_story_button.visible = stream_available or stream_read
	_stream_story_button.disabled = not stream_available
	_stream_story_button.text = "听她讲《小溪与激流》" if stream_available else "《小溪与激流》· 已读"

func _on_interact_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.interact_relation(race_id)
	if bool(result.get("ok", false)):
		_emit_narrative(str(result.get("text", "")))
		_emit_toast("关系 · 靠近了半步。")
	refresh_requested.emit()

func _on_plunder_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.plunder_race(race_id)
	if not bool(result.get("ok", false)):
		_emit_toast("它还在沉睡。")
	refresh_requested.emit()

func _on_intimate_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.intimate_race(race_id)
	if not bool(result.get("ok", false)):
		_emit_toast("它还不想说。")
	refresh_requested.emit()

func _on_revive_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.revive_race(race_id)
	if not bool(result.get("ok", false)):
		_emit_toast("河水太远了。")
	refresh_requested.emit()

func _on_plunder_soul_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.plunder_soul_race(race_id)
	if not bool(result.get("ok", false)):
		_emit_toast("它还在岸上。")
	refresh_requested.emit()

func _on_totem_pressed() -> void:
	var next_id := TotemActions.next_interpretable(GameManager.get_state())
	if next_id > 0:
		var result: Dictionary = GameManager.interpret_totem(next_id)
		if not bool(result.get("ok", false)):
			_emit_toast("画还看不清。再等等。")
	refresh_requested.emit()

func _on_facility_pressed(race_id: StringName, field: StringName) -> void:
	var ok := false
	match field:
		&"firepit_level": ok = GameManager.buy_firepit()
		&"ring_level": ok = GameManager.buy_ring()
		&"forge_level": ok = GameManager.buy_forge()
		&"totem_pole_level": ok = GameManager.buy_totem_pole()
	if ok:
		var names := {&"human": "火塘", &"forestfolk": "歌之环", &"stoneborn": "铸根坊", &"wildfolk": "图腾柱"}
		_emit_toast("（%s 立起来了。）" % names.get(race_id, "设施"))
	refresh_requested.emit()

func _on_story_pressed() -> void:
	var story_id := StoryActions.next_main_story(GameManager.get_state())
	if story_id != &"":
		GameManager.hear_story(story_id)
	refresh_requested.emit()

func _on_stream_story_pressed() -> void:
	var available := StoryActions.available_easter_eggs(GameManager.get_state())
	if not available.is_empty():
		GameManager.hear_story(available[0])
	refresh_requested.emit()

func _emit_narrative(body: String) -> void:
	feedback_requested.emit({"kind": &"narrative", "body": body})

func _emit_toast(body: String) -> void:
	feedback_requested.emit({"kind": &"toast", "body": body})
