extends Control

@onready var continue_button: Button = %ContinueButton
@onready var new_run_button: Button = %NewRunButton
@onready var library_button: Button = %LibraryButton
@onready var status_label: Label = %StatusLabel
@onready var confirm_scrim: ColorRect = %ConfirmScrim
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var confirm_new_run_button: Button = %ConfirmNewRunButton
@onready var cancel_new_run_button: Button = %CancelNewRunButton

static func status_view(has_save: bool, run_number: int, archive: MemoryArchiveState) -> Dictionary:
	var summary := MemoryArchive.summary(archive)
	var run_text := "土里的一粒种子，尚未发芽。"
	if has_save:
		run_text = "%s个春天，还在等你。" % _ordinal(run_number)
	var library_text := "年轮里收着 %d/%d 页。" % [summary.get("unlocked", 0), summary.get("total", 0)]
	if archive.library_complete:
		library_text = "年轮已经读完。每个名字都还在。"
	return {"continue_enabled": has_save, "library_enabled": int(summary.get("unlocked", 0)) > 0,
		"run_text": run_text, "library_text": library_text}

static func _ordinal(run_number: int) -> String:
	match run_number:
		1: return "第一"
		2: return "第二"
		3: return "第三"
		_: return "第%d" % maxi(run_number, 1)

func _ready() -> void:
	GameManager.enter_title_scene()
	continue_button.pressed.connect(_on_continue_pressed)
	new_run_button.pressed.connect(_on_new_run_pressed)
	library_button.pressed.connect(_on_library_pressed)
	confirm_new_run_button.pressed.connect(_on_confirm_new_run_pressed)
	cancel_new_run_button.pressed.connect(_on_cancel_new_run_pressed)
	_refresh()
	if continue_button.disabled:
		new_run_button.grab_focus()
	else:
		continue_button.grab_focus()

func _refresh() -> void:
	var has_save := GameManager.has_current_run()
	var view := status_view(has_save, GameManager.get_state().run_number, GameManager.get_memory_archive())
	continue_button.disabled = not bool(view.get("continue_enabled", false))
	library_button.disabled = not bool(view.get("library_enabled", false))
	status_label.text = "%s\n%s" % [view.get("run_text", ""), view.get("library_text", "")]
	_set_confirm_visible(false)

func _on_continue_pressed() -> void:
	GameManager.continue_run()

func _on_new_run_pressed() -> void:
	if GameManager.has_current_run():
		_set_confirm_visible(true)
		confirm_new_run_button.grab_focus()
	else:
		GameManager.start_new_run()

func _on_library_pressed() -> void:
	GameManager.open_memory_library()

func _on_confirm_new_run_pressed() -> void:
	_set_confirm_visible(false)
	GameManager.start_new_run()

func _on_cancel_new_run_pressed() -> void:
	_set_confirm_visible(false)
	new_run_button.grab_focus()

func _set_confirm_visible(is_visible: bool) -> void:
	confirm_scrim.visible = is_visible
	confirm_panel.visible = is_visible
