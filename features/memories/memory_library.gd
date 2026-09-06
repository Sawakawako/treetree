extends Control

@onready var summary_label: Label = %SummaryLabel
@onready var category_option: OptionButton = %CategoryOption
@onready var entry_list: VBoxContainer = %EntryList
@onready var detail_title_label: Label = %DetailTitleLabel
@onready var detail_text: RichTextLabel = %DetailText
@onready var back_button: Button = %BackButton

var _archive: MemoryArchiveState
var _entries: Array[Dictionary] = []

static func entry_button_text(entry: Dictionary, index: int) -> String:
	return "%02d · %s" % [index, entry.get("title", "尚未落进年轮")]

func _ready() -> void:
	GameManager.enter_title_scene()
	_archive = GameManager.get_memory_archive()
	category_option.item_selected.connect(_on_category_selected)
	back_button.pressed.connect(_on_back_pressed)
	for category: Dictionary in MemoryArchive.CATEGORIES:
		category_option.add_item(str(category.get("title", "")))
		category_option.set_item_metadata(category_option.item_count - 1, category.get("id", &""))
	_refresh_summary()
	if category_option.item_count > 0:
		_on_category_selected(0)
	back_button.grab_focus()

func _refresh_summary() -> void:
	var summary := MemoryArchive.summary(_archive)
	if _archive.library_complete:
		summary_label.text = "书页 %d/%d · 你记得每一个名字" % [summary.get("unlocked", 0), summary.get("total", 0)]
	else:
		summary_label.text = "书页 %d/%d · 还有风从空格里经过" % [summary.get("unlocked", 0), summary.get("total", 0)]

func _on_category_selected(index: int) -> void:
	var category_id := StringName(str(category_option.get_item_metadata(index)))
	_entries = MemoryArchive.entries_for(_archive, category_id)
	for child: Node in entry_list.get_children():
		entry_list.remove_child(child)
		child.queue_free()
	for entry_index: int in range(_entries.size()):
		var entry := _entries[entry_index]
		var button := Button.new()
		button.custom_minimum_size.y = 42.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = entry_button_text(entry, entry_index + 1)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not bool(entry.get("unlocked", false))
		button.pressed.connect(_on_entry_pressed.bind(entry_index))
		entry_list.add_child(button)
	detail_title_label.text = MemoryArchive.category_title(category_id)
	detail_text.text = "选一页。\n让它在光里慢慢展开。"

func _on_entry_pressed(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry := _entries[index]
	if not bool(entry.get("unlocked", false)):
		return
	detail_title_label.text = str(entry.get("title", ""))
	detail_text.text = str(entry.get("body", ""))

func _on_back_pressed() -> void:
	GameManager.open_title()

