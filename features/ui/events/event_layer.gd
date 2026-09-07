class_name EventLayer
extends Control

const QueueScript := preload("res://features/ui/events/ui_event_queue.gd")

signal choice_submitted(choice_id: StringName, option_id: StringName)
signal return_advance_requested
signal ending_action_requested(loops: bool)
signal event_dismissed

var _queue := QueueScript.new()
var _current_event: Dictionary = {}
var _pump_scheduled := false
var _focus_before_event: Control
var _choice_id: StringName = &""
var _choice_option_ids: Array[StringName] = [&"", &"", &"", &""]
var _ending_loops := true
var _toast_tween: Tween
var _narrative_tween: Tween
var _narrative_rest_position := Vector2.ZERO

@onready var _toast_layer: MarginContainer = %ToastLayer
@onready var _toast_label: Label = %ToastLabel
@onready var _narrative_scrim: ColorRect = %NarrativeScrim
@onready var _narrative_card: PanelContainer = %NarrativeCard
@onready var _narrative_title_label: Label = %NarrativeTitleLabel
@onready var _narrative_body_label: RichTextLabel = %NarrativeBodyLabel
@onready var _narrative_close_button: Button = %NarrativeCloseButton
@onready var _blocking_overlay: Control = %BlockingOverlay
@onready var _choice_panel: PanelContainer = %ChoicePanel
@onready var _choice_title_label: Label = %ChoiceTitleLabel
@onready var _choice_intro_label: RichTextLabel = %ChoiceIntroLabel
@onready var _return_panel: PanelContainer = %ReturnPanel
@onready var _return_title_label: Label = %ReturnTitleLabel
@onready var _return_text_label: RichTextLabel = %ReturnTextLabel
@onready var _return_progress_label: Label = %ReturnProgressLabel
@onready var _return_advance_button: Button = %ReturnAdvanceButton
@onready var _ending_panel: PanelContainer = %EndingPanel
@onready var _ending_title_label: Label = %EndingTitleLabel
@onready var _ending_body_label: RichTextLabel = %EndingBodyLabel
@onready var _ending_hope_label: Label = %EndingHopeLabel
@onready var _ending_action_button: Button = %EndingActionButton

var _choice_buttons: Array[Button] = []

func _ready() -> void:
	_choice_buttons.assign([
		%ChoiceOptionAButton, %ChoiceOptionBButton, %ChoiceOptionCButton, %ChoiceOptionDButton,
	])
	_narrative_close_button.pressed.connect(_on_narrative_close_pressed)
	_return_advance_button.pressed.connect(_on_return_advance_pressed)
	_ending_action_button.pressed.connect(_on_ending_action_pressed)
	for index in _choice_buttons.size():
		_choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	_narrative_rest_position = _narrative_card.position
	_hide_active_layers()

static func settlement_view(outcome: StringName, hope_before: int, hope_after: int) -> Dictionary:
	return EndingArchive.settlement_view(outcome, hope_before, hope_after)

func enqueue(event: Dictionary) -> void:
	if event.is_empty():
		return
	if _current_event.is_empty() and _queue.is_empty():
		_capture_focus()
	_queue.enqueue(event)
	if not _current_event.is_empty() and _is_non_blocking(_current_event) and _queue.peek_priority() >= 2:
		_queue.requeue_front(_current_event)
		_current_event = {}
		_hide_active_layers()
	_schedule_pump()

func show_pending_ending(pending: Dictionary, state: GameState) -> void:
	if pending.is_empty():
		return
	var phase := StringName(str(pending.get("phase", &"settlement")))
	var event := pending.duplicate(true)
	event["kind"] = &"return" if phase == &"return" else &"ending"
	event["state"] = state
	if not _current_event.is_empty() and _is_blocking(_current_event):
		_current_event = {}
		_hide_active_layers()
	enqueue(event)

func clear_events() -> void:
	_queue.clear()
	_current_event = {}
	_pump_scheduled = false
	_hide_active_layers()

func _schedule_pump() -> void:
	if _pump_scheduled:
		return
	_pump_scheduled = true
	call_deferred("_pump")

func _pump() -> void:
	_pump_scheduled = false
	if not _current_event.is_empty() or _queue.is_empty():
		return
	_current_event = _queue.pop_next()
	match StringName(str(_current_event.get("kind", &"toast"))):
		&"narrative":
			_show_narrative(_current_event)
		&"choice":
			_show_choice(_current_event)
		&"return":
			_show_return(_current_event)
		&"ending":
			_show_ending(_current_event)
		_:
			_show_toast(_current_event)

func _show_toast(event: Dictionary) -> void:
	_toast_label.text = _display_text(event)
	_toast_layer.visible = true
	_toast_layer.modulate.a = 0.0
	_kill_tween(_toast_tween)
	_toast_tween = create_tween().bind_node(self)
	_toast_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_toast_tween.tween_property(_toast_layer, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast_layer, "modulate:a", 0.0, 0.12)
	_toast_tween.tween_callback(_on_toast_timeout)

func _show_narrative(event: Dictionary) -> void:
	_narrative_title_label.text = str(event.get("title", ""))
	_narrative_body_label.text = str(event.get("body", event.get("result_text", "")))
	_narrative_scrim.visible = true
	_narrative_card.visible = true
	_narrative_card.position = _narrative_rest_position + Vector2(0.0, 24.0)
	_narrative_card.modulate.a = 0.0
	_kill_tween(_narrative_tween)
	_narrative_tween = create_tween().bind_node(self)
	_narrative_tween.set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_narrative_tween.tween_property(_narrative_card, "position", _narrative_rest_position, 0.18)
	_narrative_tween.tween_property(_narrative_card, "modulate:a", 1.0, 0.18)
	_narrative_close_button.grab_focus()

func _show_choice(event: Dictionary) -> void:
	_show_blocking_panel(_choice_panel)
	_choice_id = StringName(str(event.get("choice_id", &"")))
	_choice_title_label.text = str(event.get("title", ""))
	_choice_intro_label.text = str(event.get("body", event.get("intro", "")))
	var state := event.get("state") as GameState
	if state == null:
		state = GameManager.get_state()
	var options: Array = event.get("options", [])
	for index in _choice_buttons.size():
		var button := _choice_buttons[index]
		if index >= options.size() or typeof(options[index]) != TYPE_DICTIONARY:
			button.visible = false
			button.disabled = true
			_choice_option_ids[index] = &""
			continue
		var option: Dictionary = options[index]
		var option_id := StringName(str(option.get("id", &"")))
		_choice_option_ids[index] = option_id
		button.visible = true
		button.text = str(option.get("text", ""))
		button.disabled = not ChoiceActions.option_unlocked(state, _choice_id, option_id)
	_focus_first_enabled(_choice_buttons)

func _show_return(event: Dictionary) -> void:
	_show_blocking_panel(_return_panel)
	var state := event.get("state") as GameState
	if state == null:
		state = GameManager.get_state()
	var outcome := StringName(str(event.get("outcome", &"normal")))
	var step := clampi(int(event.get("return_step", 1)), 1, ReturnSequence.STEPS)
	var halted := bool(event.get("return_halted", false))
	var max_step := ReturnSequence.max_step_for(outcome)
	_return_title_label.text = "归还序列 · 周目 %d" % state.run_number
	_return_text_label.text = ReturnSequence.halt_text(state.run_number) if halted else ReturnSequence.text_for(state.run_number, step)
	var progress := ReturnSequence.progress_for(step)
	_return_progress_label.text = "树的余形 %d%% · 世界复苏 %d%%" % [
		int(progress.get("tree_remaining", 100)), int(progress.get("world_restored", 0)),
	]
	if halted or outcome == &"good" and step >= max_step:
		_return_advance_button.text = "完成归还"
	elif step >= max_step:
		_return_advance_button.text = "停在这里"
	else:
		_return_advance_button.text = "继续归还"
	_return_advance_button.grab_focus()

func _show_ending(event: Dictionary) -> void:
	_show_blocking_panel(_ending_panel)
	var state := event.get("state") as GameState
	if state == null:
		state = GameManager.get_state()
	var view := settlement_view(
		StringName(str(event.get("outcome", &"normal"))),
		int(event.get("hope_before", state.hope)),
		state.hope,
	)
	_ending_title_label.text = str(view.get("title", ""))
	_ending_body_label.text = str(view.get("body", ""))
	_ending_hope_label.text = str(view.get("hope_line", ""))
	_ending_action_button.text = str(view.get("action_text", "再次醒来"))
	_ending_loops = bool(view.get("loops", true))
	_ending_action_button.grab_focus()

func _show_blocking_panel(panel: Control) -> void:
	_blocking_overlay.visible = true
	_blocking_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_panel.visible = panel == _choice_panel
	_return_panel.visible = panel == _return_panel
	_ending_panel.visible = panel == _ending_panel

func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= _choice_buttons.size():
		return
	var button := _choice_buttons[index]
	var option_id := _choice_option_ids[index]
	if not button.visible or button.disabled or option_id == &"":
		return
	choice_submitted.emit(_choice_id, option_id)
	_finish_current()

func _on_return_advance_pressed() -> void:
	return_advance_requested.emit()

func _on_ending_action_pressed() -> void:
	ending_action_requested.emit(_ending_loops)
	_finish_current()

func _on_narrative_close_pressed() -> void:
	_finish_current()

func _on_toast_timeout() -> void:
	if StringName(str(_current_event.get("kind", &""))) == &"toast":
		_finish_current()

func _finish_current() -> void:
	if _current_event.is_empty():
		return
	_current_event = {}
	_hide_active_layers()
	event_dismissed.emit()
	if _queue.is_empty():
		call_deferred("_restore_focus")
	else:
		_schedule_pump()

func _hide_active_layers() -> void:
	_kill_tween(_toast_tween)
	_kill_tween(_narrative_tween)
	_toast_layer.visible = false
	_toast_layer.modulate.a = 1.0
	_narrative_scrim.visible = false
	_narrative_card.visible = false
	_narrative_card.modulate.a = 1.0
	_blocking_overlay.visible = false
	_blocking_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_panel.visible = false
	_return_panel.visible = false
	_ending_panel.visible = false

func _capture_focus() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	_focus_before_event = owner if owner is Control else null

func _restore_focus() -> void:
	if is_instance_valid(_focus_before_event) and _focus_before_event.visible and _focus_before_event.focus_mode != Control.FOCUS_NONE:
		_focus_before_event.grab_focus()
	_focus_before_event = null

func _focus_first_enabled(buttons: Array[Button]) -> void:
	for button: Button in buttons:
		if button.visible and not button.disabled:
			button.grab_focus()
			return

func _display_text(event: Dictionary) -> String:
	var body := str(event.get("body", event.get("result_text", "")))
	return body if not body.is_empty() else str(event.get("title", ""))

func _is_non_blocking(event: Dictionary) -> bool:
	var kind := StringName(str(event.get("kind", &"toast")))
	return kind == &"toast" or kind == &"narrative"

func _is_blocking(event: Dictionary) -> bool:
	return not _is_non_blocking(event)

func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

func _exit_tree() -> void:
	_kill_tween(_toast_tween)
	_kill_tween(_narrative_tween)
