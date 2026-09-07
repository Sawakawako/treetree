extends GdUnitTestSuite

const EventLayerScene := preload("res://features/ui/events/event_layer.tscn")
const EventLayerScript := preload("res://features/ui/events/event_layer.gd")

func test_scene_has_three_feedback_levels_and_safe_mouse_filters() -> void:
	var root := EventLayerScene.instantiate() as EventLayer
	assert_that(root.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(_control(root, "ToastLayer").mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(_control(root, "NarrativeScrim").mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(_control(root, "BlockingOverlay").mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	for panel_name: String in ["ChoicePanel", "ReturnPanel", "EndingPanel"]:
		assert_that(root.find_child(panel_name, true, false)).is_not_null()
	for button_name: String in [
		"NarrativeCloseButton", "ChoiceOptionAButton", "ChoiceOptionBButton",
		"ChoiceOptionCButton", "ChoiceOptionDButton", "ReturnAdvanceButton", "EndingActionButton",
	]:
		assert_that(_button(root, button_name).custom_minimum_size.y).is_greater_equal(44.0)
	assert_that(root.find_child("NarrativeScroll", true, false) is ScrollContainer).is_true()
	assert_that(_rich_label(root, "NarrativeBodyLabel").autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	assert_that(_rich_label(root, "EndingBodyLabel").autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	root.free()

func test_same_frame_events_defer_and_show_highest_priority_first() -> void:
	var root := _layer()
	var choice := ChoiceLibrary.get_choice(&"human_nightmare")
	root.enqueue({"kind": &"narrative", "title": "later", "body": "n"})
	root.enqueue(_choice_event(&"human_nightmare", choice, GameState.new()))
	assert_that(_control(root, "BlockingOverlay").visible).is_false()
	await get_tree().process_frame
	assert_that(_control(root, "BlockingOverlay").visible).is_true()
	assert_that(_control(root, "BlockingOverlay").mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_that(_control(root, "ChoicePanel").visible).is_true()
	assert_that(_control(root, "NarrativeCard").visible).is_false()
	_button(root, "ChoiceOptionAButton").emit_signal("pressed")
	await get_tree().process_frame
	assert_that(_control(root, "BlockingOverlay").visible).is_false()
	assert_that(_control(root, "NarrativeCard").visible).is_true()
	root.free()

func test_blocking_event_interrupts_visible_narrative_then_resumes_it() -> void:
	var root := _layer()
	root.enqueue({"kind": &"narrative", "title": "first", "body": "still here"})
	await get_tree().process_frame
	assert_that(_control(root, "NarrativeCard").visible).is_true()
	var choice := ChoiceLibrary.get_choice(&"human_nightmare")
	root.enqueue(_choice_event(&"human_nightmare", choice, GameState.new()))
	await get_tree().process_frame
	assert_that(_control(root, "NarrativeCard").visible).is_false()
	assert_that(_control(root, "ChoicePanel").visible).is_true()
	_button(root, "ChoiceOptionAButton").emit_signal("pressed")
	await get_tree().process_frame
	assert_that(_control(root, "NarrativeCard").visible).is_true()
	assert_that(_label(root, "NarrativeTitleLabel").text).is_equal("first")
	root.free()

func test_narrative_close_restores_trigger_focus() -> void:
	var trigger := Button.new()
	trigger.focus_mode = Control.FOCUS_ALL
	add_child(trigger)
	var root := _layer()
	trigger.grab_focus()
	await get_tree().process_frame
	root.enqueue({"kind": &"narrative", "title": "一阵风", "body": "从根边经过。"})
	await get_tree().process_frame
	assert_that(_button(root, "NarrativeCloseButton").has_focus()).is_true()
	_button(root, "NarrativeCloseButton").emit_signal("pressed")
	await get_tree().process_frame
	assert_that(trigger.has_focus()).is_true()
	root.free()
	trigger.free()

func test_choice_uses_four_original_options_and_unlock_gate() -> void:
	var root := _layer()
	var choice := ChoiceLibrary.get_choice(&"world_axis")
	root.enqueue(_choice_event(&"world_axis", choice, GameState.new()))
	await get_tree().process_frame
	for suffix: String in ["A", "B", "C", "D"]:
		assert_that(_button(root, "ChoiceOption%sButton" % suffix).visible).is_true()
	assert_that(_button(root, "ChoiceOptionAButton").disabled).is_false()
	assert_that(_button(root, "ChoiceOptionDButton").disabled).is_true()
	root.free()

func test_choice_button_emits_exact_choice_and_option_ids() -> void:
	var root := _layer()
	var submitted: Array[Array] = []
	root.choice_submitted.connect(func(choice_id: StringName, option_id: StringName) -> void:
		submitted.append([choice_id, option_id])
	)
	var choice := ChoiceLibrary.get_choice(&"human_nightmare")
	root.enqueue(_choice_event(&"human_nightmare", choice, GameState.new()))
	await get_tree().process_frame
	_button(root, "ChoiceOptionBButton").emit_signal("pressed")
	assert_that(submitted).is_equal([[&"human_nightmare", &"b"]])
	root.free()

func test_missing_narrative_body_keeps_available_title() -> void:
	var root := _layer()
	root.enqueue({"kind": &"narrative", "title": "只剩名字"})
	await get_tree().process_frame
	assert_that(_label(root, "NarrativeTitleLabel").text).is_equal("只剩名字")
	assert_that(_rich_label(root, "NarrativeBodyLabel").text).is_equal("")
	root.free()

func test_show_pending_ending_restores_return_phase() -> void:
	var root := _layer()
	var state := GameState.new()
	state.run_number = 2
	root.show_pending_ending({
		"outcome": &"good", "phase": &"return", "return_step": 3,
		"return_halted": false, "hope_before": 1,
	}, state)
	await get_tree().process_frame
	assert_that(_control(root, "ReturnPanel").visible).is_true()
	assert_that(_label(root, "ReturnTitleLabel").text).contains("周目 2")
	assert_that(_rich_label(root, "ReturnTextLabel").text).is_equal(ReturnSequence.text_for(2, 3))
	assert_that(_label(root, "ReturnProgressLabel").text).contains("43%")
	root.free()

func test_show_pending_ending_restores_settlement_phase() -> void:
	var root := _layer()
	var state := GameState.new()
	state.hope = 2
	root.show_pending_ending({"outcome": &"good", "phase": &"settlement", "hope_before": 1}, state)
	await get_tree().process_frame
	assert_that(_control(root, "EndingPanel").visible).is_true()
	assert_that(_label(root, "EndingTitleLabel").text).is_equal("好结局")
	assert_that(_label(root, "EndingHopeLabel").text).contains("1 → 2")
	assert_that(_button(root, "EndingActionButton").text).is_equal("再次醒来")
	root.free()

func test_return_and_ending_actions_emit_existing_lifecycle_intent() -> void:
	var return_root := _layer()
	var return_requests: Array[bool] = []
	return_root.return_advance_requested.connect(func() -> void: return_requests.append(true))
	return_root.show_pending_ending({"outcome": &"good", "phase": &"return", "return_step": 1}, GameState.new())
	await get_tree().process_frame
	_button(return_root, "ReturnAdvanceButton").emit_signal("pressed")
	assert_that(return_requests).has_size(1)
	return_root.free()

	var ending_root := _layer()
	var ending_requests: Array[bool] = []
	ending_root.ending_action_requested.connect(func(loops: bool) -> void: ending_requests.append(loops))
	ending_root.show_pending_ending({"outcome": &"true", "phase": &"settlement", "hope_before": 2}, GameState.new())
	await get_tree().process_frame
	_button(ending_root, "EndingActionButton").emit_signal("pressed")
	assert_that(ending_requests).is_equal([false])
	ending_root.free()

func test_settlement_view_loop_outcomes() -> void:
	var good: Dictionary = EventLayerScript.settlement_view(&"good", 1, 2)
	assert_that(str(good.get("title", ""))).is_equal("好结局")
	assert_that(str(good.get("hope_line", ""))).contains("1 → 2")
	assert_that(str(good.get("action_text", ""))).is_equal("再次醒来")
	assert_that(bool(good.get("loops", true))).is_true()
	var bad: Dictionary = EventLayerScript.settlement_view(&"bad", 1, 1)
	assert_that(str(bad.get("title", ""))).is_equal("坏结局")
	assert_that(str(bad.get("action_text", ""))).is_equal("再次醒来")
	var normal: Dictionary = EventLayerScript.settlement_view(&"normal", 1, 1)
	assert_that(str(normal.get("title", ""))).is_equal("普通结局")

func test_settlement_view_true_ends_loop() -> void:
	var view: Dictionary = EventLayerScript.settlement_view(&"true", 2, 0)
	assert_that(str(view.get("title", ""))).is_equal("真结局")
	assert_that(str(view.get("action_text", ""))).is_equal("回到标题")
	assert_that(bool(view.get("loops", true))).is_false()
	assert_that(str(view.get("body", "")).length()).is_greater(10)

func _choice_event(choice_id: StringName, choice: Dictionary, state: GameState) -> Dictionary:
	return {
		"kind": &"choice", "choice_id": choice_id, "title": choice.get("title", ""),
		"body": choice.get("intro", ""), "options": choice.get("options", []), "state": state,
	}

func _layer() -> EventLayer:
	var root := EventLayerScene.instantiate() as EventLayer
	add_child(root)
	return root

func _control(root: Node, node_name: String) -> Control:
	return root.find_child(node_name, true, false) as Control

func _button(root: Node, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button

func _label(root: Node, node_name: String) -> Label:
	return root.find_child(node_name, true, false) as Label

func _rich_label(root: Node, node_name: String) -> RichTextLabel:
	return root.find_child(node_name, true, false) as RichTextLabel
