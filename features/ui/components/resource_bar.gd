class_name ResourceBar
extends VBoxContainer

signal expanded_changed(expanded: bool)

const VALUE_FLASH_DURATION := 0.16

var _expanded := false
var _last_values: Dictionary = {}
var _value_tweens: Dictionary = {}

@onready var _summary_labels: Dictionary = {
	&"sap": %SummarySap,
	&"growth": %SummaryGrowth,
	&"memory": %SummaryMemory,
	&"faith": %SummaryFaith,
}
@onready var _expanded_labels: Dictionary = {
	&"daylight": %DaylightValueLabel,
	&"sap": %SapValueLabel,
	&"growth": %GrowthValueLabel,
	&"memory": %MemoryValueLabel,
	&"faith": %FaithValueLabel,
	&"soul": %SoulValueLabel,
	&"insight": %InsightValueLabel,
	&"hope": %HopeValueLabel,
}

func _ready() -> void:
	%ExpandButton.pressed.connect(_on_expand_pressed)
	%ExpandedPanel.visible = _expanded

static func build_view(state: GameState, sap_cap: float, active_tab: StringName) -> Dictionary:
	var all_items: Array[Dictionary] = [
		{"id": &"daylight", "label": "日光", "value": Formatter.format_number(state.daylight)},
		{"id": &"sap", "label": "树液", "value": "%s / %s" % [Formatter.format_number(state.sap), Formatter.format_cost(int(sap_cap))]},
		{"id": &"growth", "label": "生长", "value": Formatter.format_number(state.growth)},
		{"id": &"memory", "label": "记忆", "value": Formatter.format_number(state.memory)},
		{"id": &"faith", "label": "信仰", "value": Formatter.format_number(state.faith)},
		{"id": &"soul", "label": "灵魂", "value": "%d / %d" % [state.soul_river, SoulActions.RIVER_TOTAL]},
		{"id": &"insight", "label": "领悟", "value": str(state.insight)},
		{"id": &"hope", "label": "希望", "value": str(state.hope)},
	]
	var summary_ids: Array[StringName] = [&"sap", &"growth", &"memory", &"faith"]
	var context: Array[StringName] = []
	if active_tab == &"beings":
		context.assign([&"soul", &"insight"])
	elif active_tab == &"lingua":
		context.assign([&"insight"])
	elif active_tab == &"nine_realms":
		context.assign([&"hope"])
	return {"summary": _select_items(all_items, summary_ids), "expanded": all_items, "context": context}

static func _select_items(items: Array[Dictionary], ids: Array[StringName]) -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for item: Dictionary in items:
		by_id[StringName(str(item.get("id", &"")))] = item
	var selected: Array[Dictionary] = []
	for id: StringName in ids:
		if by_id.has(id):
			selected.append(by_id[id])
	return selected

func refresh(state: GameState, sap_cap: float, active_tab: StringName) -> void:
	var view := build_view(state, sap_cap, active_tab)
	for item: Dictionary in view.get("summary", []):
		_set_label_value(_summary_labels, item)
	for item: Dictionary in view.get("expanded", []):
		_set_label_value(_expanded_labels, item)
	var current_values := _resource_values(state)
	if not _last_values.is_empty():
		for item_id: StringName in current_values:
			if current_values[item_id] > _last_values.get(item_id, current_values[item_id]):
				_flash_item(item_id)
	_last_values = current_values

func collapse() -> void:
	if not _expanded:
		return
	_expanded = false
	%ExpandedPanel.visible = false
	expanded_changed.emit(false)

func _set_label_value(labels: Dictionary, item: Dictionary) -> void:
	var item_id := StringName(str(item.get("id", &"")))
	var label := labels.get(item_id) as Label
	if label != null:
		label.text = str(item.get("value", ""))

func _resource_values(state: GameState) -> Dictionary:
	return {
		&"daylight": state.daylight.to_value(),
		&"sap": state.sap.to_value(),
		&"growth": state.growth.to_value(),
		&"memory": state.memory.to_value(),
		&"faith": state.faith.to_value(),
		&"soul": state.soul_river,
		&"insight": state.insight,
		&"hope": state.hope,
	}

func _on_expand_pressed() -> void:
	_expanded = not _expanded
	%ExpandedPanel.visible = _expanded
	expanded_changed.emit(_expanded)

func _flash_item(item_id: StringName) -> void:
	for labels: Dictionary in [_summary_labels, _expanded_labels]:
		var label := labels.get(item_id) as Label
		if label != null:
			_flash_label(label)

func _flash_label(label: Label) -> void:
	if _value_tweens.has(label):
		var previous := _value_tweens[label] as Tween
		if previous != null and previous.is_valid():
			previous.kill()
	if not is_inside_tree():
		return
	var start := label.modulate
	start.a = 0.45
	label.modulate = start
	var target := label.modulate
	target.a = 1.0
	var tween := create_tween().bind_node(label)
	tween.tween_property(label, "modulate", target, VALUE_FLASH_DURATION)
	_value_tweens[label] = tween

func _exit_tree() -> void:
	for tween: Tween in _value_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_value_tweens.clear()
