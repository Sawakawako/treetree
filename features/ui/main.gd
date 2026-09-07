class_name MainShell
extends Control

const TAB_TREE_HEART := &"tree_heart"
const PAGE_FADE_DURATION := 0.16

var _active_tab: StringName = TAB_TREE_HEART
var _pages: Dictionary[StringName, UiPage] = {}
var _page_tween: Tween
var _refresh_scheduled := false

@onready var _return_title_button: Button = %ReturnTitleButton
@onready var _resource_bar: ResourceBar = %ResourceBar
@onready var _navigation: BottomNavigation = %BottomNavigation
@onready var _event_layer: EventLayer = %EventLayer

func _ready() -> void:
	GameManager.enter_run_scene()
	_pages = {
		&"tree_heart": %TreeHeartPage,
		&"beings": %BeingsPage,
		&"lingua": %LinguaPage,
		&"nine_realms": %NineRealmsPage,
	}
	_wire_local_signals()
	_wire_game_manager_signals()
	_refresh_all()
	_resume_pending_choice()
	_resume_pending_ending()
	_enqueue_offline_summary(GameManager.take_offline_summary())

func _wire_local_signals() -> void:
	_return_title_button.pressed.connect(_on_return_title_pressed)
	_navigation.tab_selected.connect(_on_tab_selected)
	for page: UiPage in _pages.values():
		page.refresh_requested.connect(_request_refresh)
		page.feedback_requested.connect(_event_layer.enqueue)
	_event_layer.choice_submitted.connect(_on_choice_submitted)
	_event_layer.return_advance_requested.connect(_on_return_advance_requested)
	_event_layer.ending_action_requested.connect(_on_ending_action_requested)

func _wire_game_manager_signals() -> void:
	GameManager.resources_changed.connect(_request_refresh)
	GameManager.relic_discovered.connect(_on_relic_discovered)
	GameManager.race_awakened.connect(_on_race_awakened)
	GameManager.totem_interpreted.connect(_on_totem_interpreted)
	GameManager.relation_changed.connect(_on_relation_changed)
	GameManager.plunder_done.connect(_on_plunder_done)
	GameManager.intimate_done.connect(_on_intimate_done)
	GameManager.choice_available.connect(_on_choice_available)
	GameManager.choice_resolved.connect(_on_choice_resolved)
	GameManager.soul_changed.connect(_on_soul_changed)
	GameManager.soul_revived.connect(_on_soul_revived)
	GameManager.soul_plundered.connect(_on_soul_plundered)
	GameManager.story_heard.connect(_on_story_heard)
	GameManager.realm_explored.connect(_on_realm_explored)
	GameManager.world_language_changed.connect(_on_world_language_changed)
	GameManager.miracle_performed.connect(_on_miracle_performed)
	GameManager.ending_resolved.connect(_on_ending_resolved)
	GameManager.run_restarted.connect(_on_run_restarted)

func _refresh_all() -> void:
	var state := GameManager.get_state()
	var visible_tabs := BottomNavigation.visible_tabs(state)
	_active_tab = BottomNavigation.normalize_active_tab(_active_tab, visible_tabs)
	_navigation.refresh(visible_tabs, _active_tab)
	_resource_bar.refresh(state, GameManager.get_sap_cap(), _active_tab)
	for tab_id: StringName in _pages:
		_pages[tab_id].visible = tab_id == _active_tab
	_pages[_active_tab].refresh(state)

func _request_refresh() -> void:
	if _refresh_scheduled:
		return
	_refresh_scheduled = true
	call_deferred("_flush_refresh")

func _flush_refresh() -> void:
	_refresh_scheduled = false
	_refresh_all()

func _on_tab_selected(tab_id: StringName) -> void:
	var visible_tabs := BottomNavigation.visible_tabs(GameManager.get_state())
	var normalized := BottomNavigation.normalize_active_tab(tab_id, visible_tabs)
	if normalized == _active_tab:
		return
	_active_tab = normalized
	_resource_bar.collapse()
	_animate_page_in(_pages[_active_tab])
	_request_refresh()
	call_deferred("_focus_active_page")

func _animate_page_in(page: UiPage) -> void:
	if _page_tween != null and _page_tween.is_valid():
		_page_tween.kill()
	for candidate: UiPage in _pages.values():
		candidate.visible = candidate == page
	page.modulate.a = 0.0
	_page_tween = create_tween().bind_node(page)
	_page_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_page_tween.tween_property(page, "modulate:a", 1.0, PAGE_FADE_DURATION)

func _focus_active_page() -> void:
	var page := _pages.get(_active_tab) as UiPage
	if page == null or not page.visible:
		return
	for node: Node in page.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.visible and not button.disabled and button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus()
			return

func _resume_pending_choice() -> void:
	if GameManager._pending_choice == &"":
		return
	var choice := ChoiceLibrary.get_choice(GameManager._pending_choice)
	if choice.is_empty():
		return
	_on_choice_available(GameManager._pending_choice, str(choice.get("title", "")), str(choice.get("intro", "")), choice.get("options", []))

func _resume_pending_ending() -> void:
	var pending := GameManager.get_pending_ending()
	if not pending.is_empty():
		_event_layer.show_pending_ending(pending, GameManager.get_state())

func _on_choice_submitted(choice_id: StringName, option_id: StringName) -> void:
	GameManager.resolve_choice(choice_id, option_id)

func _on_return_advance_requested() -> void:
	var result := GameManager.advance_return_sequence()
	if bool(result.get("ok", false)):
		_resume_pending_ending()
		_request_refresh()

func _on_ending_action_requested(loops: bool) -> void:
	if loops:
		GameManager.restart_run()
	else:
		GameManager.reset_to_title()

func _on_return_title_pressed() -> void:
	GameManager.return_to_title()

func _on_relic_discovered(relic_name: String, dream_text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": relic_name, "body": dream_text})

func _on_race_awakened(_race_id: StringName, race_name: String, awaken_text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": race_name, "body": awaken_text})

func _on_totem_interpreted(totem_id: int, interpret_text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": "图腾·第 %d 幅" % totem_id, "body": interpret_text + "\n（领悟 +1）"})

func _on_relation_changed(_race_id: StringName, _relation: float) -> void:
	_request_refresh()

func _on_plunder_done(_race_id: StringName, text: String, revealed: bool) -> void:
	_event_layer.enqueue({"kind": &"narrative", "body": text})
	if revealed:
		_event_layer.enqueue({"kind": &"toast", "body": "（你忽然意识到什么。）"})

func _on_intimate_done(_race_id: StringName, text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "body": text})

func _on_choice_available(choice_id: StringName, title: String, intro: String, options: Array) -> void:
	_event_layer.enqueue({"kind": &"choice", "choice_id": choice_id, "title": title, "body": intro, "options": options, "state": GameManager.get_state()})

func _on_choice_resolved(_choice_id: StringName, _option_id: StringName, result_text: String, option_text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": "明选·%s" % option_text, "body": result_text})
	_request_refresh()

func _on_soul_changed(_soul_river: int) -> void:
	_request_refresh()

func _on_soul_revived(_race_id: StringName, pop_gain: int) -> void:
	_event_layer.enqueue({"kind": &"narrative", "body": "河水浅了一分。有人醒来了。\n（你从河里，唤回 %d 人。）" % pop_gain})

func _on_soul_plundered(_race_id: StringName, pop_loss: int) -> void:
	_event_layer.enqueue({"kind": &"narrative", "body": "河水满了一分。有人沉默了。\n（你让 %d 人，沉回河底。）" % pop_loss})

func _on_story_heard(_story_id: StringName, title: String, story_text: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": title, "body": story_text})

func _on_realm_explored(_realm_id: StringName, realm_name: String, discovery_text: String, _world_level: int) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": realm_name, "body": discovery_text})

func _on_world_language_changed(_node_id: StringName, node_name: String, effect: String) -> void:
	_event_layer.enqueue({"kind": &"narrative", "title": node_name, "body": effect})

func _on_miracle_performed(_miracle_id: StringName, _target_race_id: StringName, result_text: String, _count: int) -> void:
	_event_layer.enqueue({"kind": &"narrative", "body": result_text})

func _on_ending_resolved(_outcome: StringName, _hope_after: int) -> void:
	_resume_pending_ending()
	_request_refresh()

func _on_run_restarted(run_number: int) -> void:
	_event_layer.clear_events()
	var opening := TreeHeartPage.run_opening_text(run_number)
	_event_layer.enqueue({"kind": &"narrative", "title": "第 %d 个春天" % run_number, "body": opening if not opening.is_empty() else "你在土里醒来。"})
	_request_refresh()

func _enqueue_offline_summary(summary: Dictionary) -> void:
	if not bool(summary.get("applied", false)):
		return
	var gains: Array[String] = []
	for entry: Array in [["daylight", "日光"], ["sap", "树液"], ["growth", "生长"], ["faith", "信仰"], ["memory", "记忆"]]:
		var amount := float(summary.get(entry[0], 0.0))
		if amount > 0.000001:
			gains.append("%s +%s" % [entry[1], Formatter.format_number(BigNum.new(amount))])
	var population: Dictionary = summary.get("population", {})
	for race_id: Variant in population:
		var amount := float(population[race_id])
		if amount <= 0.000001:
			continue
		var race := GameManager.get_race(StringName(str(race_id)))
		var race_name := str(race.display_name) if race != null else str(race_id)
		gains.append("%s人口 +%s" % [race_name, Formatter.format_number(BigNum.new(amount))])
	if gains.is_empty():
		return
	var minutes := maxi(int(summary.get("seconds", 0)) / 60, 1)
	_event_layer.enqueue({"kind": &"narrative", "title": "离开时，根仍听着大地。", "body": "%d 分钟里：%s" % [minutes, " · ".join(gains)]})

func _exit_tree() -> void:
	if _page_tween != null and _page_tween.is_valid():
		_page_tween.kill()
