# 世界树 里程碑 5c（意志漂移 + 化身）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地意志漂移暗线（CEV 污染，drift 0-10）+ 化身系统（记忆≥30 人性觉醒，化身=漂移镜子观感 4 档）+ 亲密级关系事件（关系≥+2 + 觉醒，树以人形对坐）。

**Architecture:** 沿用既有模式：`features/memories/` 新增 `AvatarTiers`（4 档观感文本）、`IntimateEvents`（4 篇亲密事件）、`DriftActions`（RefCounted 纯静态：drift_value/drift_tier/is_avatar_awakened/avatar_tier_text/can_intimate/intimate）；`GameState` 增 `intimate_events`（drift/觉醒由 plundered/memory 推导，不存冗余字段）；`GameManager` 增 `intimate_race` + 信号；UI 化身区 + 亲密事件按钮。

**Tech Stack:** Godot 4.7.1（mono）+ GDScript（typed）+ GdUnit4 6.2.1（headless）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-m5c-drift-avatar-design.md`（本计划唯一权威，含化身人称修正「它」）；主规格 §13.8/§13.11/§14.2

## Global Constraints

- **测试命令**（GdUnit4 6.2.1，不是 `--run-tests`）：
  - 全量：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
  - 单文件：同命令加 `--add res://tests/unit/test_xxx.gd`；可加 `-c` 关 fail-fast
  - **新增 class_name 脚本后先跑** `godot --headless --path . --import`
- **`is_equal_approx` 双参签名** `(expected, approx)`——断言统一带容差 `, 1e-4`
- 资源一律 `BigNum`；typed GDScript
- 中文文件一律用 write/edit 工具（禁 PowerShell 默认编码）
- **文风铁律**：4 档观感与 4 篇亲密事件文本**必须逐字复制**设计文档 §五（含人称规范：化身用「它」无性别）
- 存档兼容：M1-M5d2 旧档缺 intimate_events 回退默认
- `.uid` 文件入库（新增 class_name 后确认）
- git master；每任务一个 commit；工作目录 `E:\world tree`

---

### Task 1: AvatarTiers 数据模块（4 档观感）

**Files:**
- Create: `features/memories/avatar_tiers.gd`
- Test: `tests/unit/test_avatar_tiers.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name AvatarTiers extends RefCounted`：`const TIERS: Array[Dictionary]`（4 档：tier/min/max/text）；`static func tier_text(tier: int) -> String`

- [ ] **Step 1: 写失败测试**（test_avatar_tiers.gd）

```gdscript
extends GdUnitTestSuite

func test_four_tiers() -> void:
	assert_that(AvatarTiers.TIERS.size()).is_equal(4)

func test_tiers_cover_drift_range() -> void:
	# 档位区间连续覆盖 0-10 且不重叠
	var prev_max := 0.0
	for t in AvatarTiers.TIERS:
		var min_v := float(t.get("min", -1.0))
		var max_v := float(t.get("max", -1.0))
		assert_that(min_v).is_equal_approx(prev_max, 1e-4)
		prev_max = max_v
	assert_that(prev_max).is_equal_approx(10.0, 1e-4)

func test_tier_text_returns_text() -> void:
	for i in 4:
		assert_that(str(AvatarTiers.tier_text(i)).length()).is_greater(5)

func test_tier_text_out_of_range_empty() -> void:
	assert_that(AvatarTiers.tier_text(9)).is_equal("")
	assert_that(AvatarTiers.tier_text(-1)).is_equal("")
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 AvatarTiers）

- [ ] **Step 3: 实现 avatar_tiers.gd**（文本逐字复制设计文档 §5.1）

```gdscript
class_name AvatarTiers
extends RefCounted

const TIERS: Array[Dictionary] = [
	{"tier": 0, "min": 0.0, "max": 3.0, "text": "火塘边，你的影子晃了一下。像有个人，从树里探出头，又缩了回去。"},
	{"tier": 1, "min": 3.0, "max": 6.0, "text": "影子的轮廓清晰了一些。它站在你旁边，树皮的纹理在它身上慢慢退去。"},
	{"tier": 2, "min": 6.0, "max": 9.0, "text": "它的五官开始模糊。枝条从它的肩头长出来，它低头看了看，没有惊讶。"},
	{"tier": 3, "min": 9.0, "max": 10.0, "text": "只剩一个人形的影子。它站在你的树影里，分不清谁是谁。你忽然想不起，它叫什么名字。"},
]

static func tier_text(tier: int) -> String:
	for t in TIERS:
		if int(t.get("tier", -1)) == tier:
			return str(t.get("text", ""))
	return ""
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（4 用例）

- [ ] **Step 5: Commit**

```bash
git add features/memories/ tests/unit/test_avatar_tiers.gd tests/unit/test_avatar_tiers.gd.uid
git commit -m "feat: AvatarTiers 数据模块（化身观感 4 档：漂移镜子）"
```

---

### Task 2: IntimateEvents 数据模块（4 篇亲密事件）

**Files:**
- Create: `features/memories/intimate_events.gd`
- Test: `tests/unit/test_intimate_events.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name IntimateEvents extends RefCounted`：`const EVENTS: Array[Dictionary]`（4 族：race_id/text）；`static func get_event(race_id: StringName) -> Dictionary`

- [ ] **Step 1: 写失败测试**（test_intimate_events.gd）

```gdscript
extends GdUnitTestSuite

func test_events_cover_four_races() -> void:
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(IntimateEvents.get_event(expected).is_empty()).is_false()

func test_event_text_nonempty() -> void:
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(str(IntimateEvents.get_event(expected).get("text", "")).length()).is_greater(20)

func test_get_missing_returns_empty() -> void:
	assert_that(IntimateEvents.get_event(&"nobody").is_empty()).is_true()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 IntimateEvents）

- [ ] **Step 3: 实现 intimate_events.gd**（文本逐字复制设计文档 §5.2）

```gdscript
class_name IntimateEvents
extends RefCounted

const EVENTS: Array[Dictionary] = [
	{
		"race_id": &"human",
		"text": "她抬头，看着火塘边多出来的那个影子。影子是你——你终于能以「人」的样子，坐在她对面。\n「我一直以为，你是一棵树。」她说。\n「我也这么以为。」你说。\n她笑了，笑里带着泪：「那现在呢？」\n你没有回答。你看着自己的手——像人的手，又像新生的根。",
	},
	{
		"race_id": &"forestfolk",
		"text": "歌会散了。她留下来，坐在你对面——第一次，不是围着根，而是对着你的脸。\n「唱不动了。」她说，声音很轻，「梦越来越淡。我怕有一天，我开口，只有风声。」\n你伸出手——一只像人的手，又像新生的根——想接住她的话。\n她握住你的手，愣了愣：「你……暖和。」\n你才发现，你很久没有暖过了。",
	},
	{
		"race_id": &"stoneborn",
		"text": "他蹲下来，敲了敲你脚下的土：「想不想离开？」\n你看着他。他把图纸展开：一艘船，能装下整个种族的船。\n「造出来，我们就能去海那边。」他说，「但你得先想好——你要不要我们走。」\n你没说话。你想起自己也是从某个地方来的，只是忘了是哪。\n他收起图纸：「不急。树的记性，比我们长。」",
	},
	{
		"race_id": &"wildfolk",
		"text": "它们第一次主动走过来，牵住你——牵住那只像人的手。\n石壁前，它们指给你看最后一幅画：\n一棵树，一个人影。人影正从树里走出来，走了很久，只差一步。\n「走。」它们说，声音是石头的，「画完了。该你了。」\n你低头看自己的脚。一只脚踩在影子里，一只脚踩在外面。",
	},
]

static func get_event(race_id: StringName) -> Dictionary:
	for e in EVENTS:
		if e.get("race_id") == race_id:
			return e
	return {}
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（3 用例）

- [ ] **Step 5: Commit**

```bash
git add features/memories/ tests/unit/test_intimate_events.gd tests/unit/test_intimate_events.gd.uid
git commit -m "feat: IntimateEvents 数据模块（4 族亲密事件：树以人形对坐）"
```

---

### Task 3: GameState 扩展（intimate_events）

**Files:**
- Modify: `features/game/game_state.gd`
- Modify: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: 无
- Produces: `GameState.intimate_events: Array[StringName] = []`；序列化 + StringName 过滤防御 + 缺字段回退（沿 relation_events 模式）

- [ ] **Step 1: 写失败测试**（test_game_state.gd 追加）

```gdscript
func test_intimate_events_roundtrip() -> void:
	var s := GameState.new()
	s.intimate_events.assign([&"human", &"wildfolk"])
	var back := GameState.from_dict(s.to_dict())
	assert_that(back.intimate_events).contains(&"human")
	assert_that(back.intimate_events).contains(&"wildfolk")

func test_intimate_events_missing_fallback() -> void:
	var back := GameState.from_dict({"tick": 5})
	assert_that(back.intimate_events).is_empty()

func test_from_dict_filters_invalid_intimate_events() -> void:
	var back := GameState.from_dict({"intimate_events": ["human", 1, {"a": 1}]})
	assert_that(back.intimate_events.size()).is_equal(1)
	assert_that(back.intimate_events).contains(&"human")
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（字段不存在）

- [ ] **Step 3: 扩展 game_state.gd**

```gdscript
# 新字段（plunder_reveals 附近）：
var intimate_events: Array[StringName] = []

# to_dict() 中追加：
"intimate_events": intimate_events,

# from_dict() 中追加（沿 relation_events 模式）：
var ie: Array = d.get("intimate_events", [])
var ie_cleaned: Array = []
for x in ie:
	if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
		ie_cleaned.append(StringName(x))
s.intimate_events.assign(ie_cleaned)
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（3 新用例 + 旧用例无回归）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 扩展（intimate_events + 存档回退防御）"
```

---

### Task 4: DriftActions 逻辑

**Files:**
- Create: `features/memories/drift_actions.gd`
- Test: `tests/unit/test_drift_actions.gd`

**Interfaces:**
- Consumes: `AvatarTiers`（T1）、`IntimateEvents`（T2）、`GameState`（plundered/memory/relations/races/intimate_events，T3）、`RelationActions.is_intimate`（M5a）
- Produces: `class_name DriftActions extends RefCounted`：
  - `const DRIFT_MAX := 10.0`、`PLUNDER_DRIFT := 0.5`、`MEMORY_DRIFT_RATE := 0.02`、`AVATAR_MEMORY := 30.0`
  - `static func drift_value(state) -> float`（clamp(Σplundered×0.5 + max(0, memory−30)×0.02, 0, 10)）
  - `static func drift_tier(state) -> int`（0/1/2/3）
  - `static func is_avatar_awakened(state) -> bool`（memory >= 30）
  - `static func avatar_tier_text(state) -> String`
  - `static func can_intimate(state, race_id) -> bool`（关系≥+2 + 觉醒 + 未触发）
  - `static func intimate(state, race_id) -> Dictionary`（`{"ok", "text"}`——标记已触发 + 返回文本）

- [ ] **Step 1: 写失败测试**（test_drift_actions.gd）

```gdscript
extends GdUnitTestSuite

func test_drift_zero_by_default() -> void:
	var s := GameState.new()
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.0, 1e-4)

func test_drift_from_plunder() -> void:
	var s := GameState.new()
	s.plundered["human"] = 3
	s.plundered["wildfolk"] = 1
	# 4 × 0.5 = 2.0（memory 0 无记忆加成）
	assert_that(DriftActions.drift_value(s)).is_equal_approx(2.0, 1e-4)

func test_drift_from_memory_after_30() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(50.0)
	# (50-30) × 0.02 = 0.4
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.4, 1e-4)
	s.memory = BigNum.new(20.0)
	assert_that(DriftActions.drift_value(s)).is_equal_approx(0.0, 1e-4)  # 30 以下不计

func test_drift_clamped() -> void:
	var s := GameState.new()
	s.plundered["human"] = 100
	assert_that(DriftActions.drift_value(s)).is_equal_approx(10.0, 1e-4)

func test_drift_tier_boundaries() -> void:
	var s := GameState.new()
	s.plundered["human"] = 5   # 2.5 → tier 0
	assert_that(DriftActions.drift_tier(s)).is_equal(0)
	s.plundered["human"] = 6   # 3.0 → tier 1
	assert_that(DriftActions.drift_tier(s)).is_equal(1)
	s.plundered["human"] = 12  # 6.0 → tier 2
	assert_that(DriftActions.drift_tier(s)).is_equal(2)
	s.plundered["human"] = 18  # 9.0 → tier 3
	assert_that(DriftActions.drift_tier(s)).is_equal(3)

func test_is_avatar_awakened_boundary() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(29.99)
	assert_that(DriftActions.is_avatar_awakened(s)).is_false()
	s.memory = BigNum.new(30.0)
	assert_that(DriftActions.is_avatar_awakened(s)).is_true()

func test_avatar_tier_text_matches_tier() -> void:
	var s := GameState.new()
	s.plundered["human"] = 18  # tier 3
	assert_that(DriftActions.avatar_tier_text(s)).is_equal(AvatarTiers.tier_text(3))

func test_can_intimate_requires_relation_and_awaken() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(40.0)
	s.relations["human"] = 1
	assert_that(DriftActions.can_intimate(s, &"human")).is_false()  # 关系不足
	s.relations["human"] = 2
	assert_that(DriftActions.can_intimate(s, &"human")).is_true()
	s.memory = BigNum.new(20.0)  # 未觉醒
	assert_that(DriftActions.can_intimate(s, &"human")).is_false()

func test_intimate_once_only() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(40.0)
	s.relations["human"] = 2
	var r := DriftActions.intimate(s, &"human")
	assert_that(r.get("ok", false)).is_true()
	assert_that(str(r.get("text", "")).length()).is_greater(20)
	assert_that(s.intimate_events).contains(&"human")
	var again := DriftActions.intimate(s, &"human")
	assert_that(again.get("ok", false)).is_false()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 DriftActions）

- [ ] **Step 3: 实现 drift_actions.gd**

```gdscript
class_name DriftActions
extends RefCounted

const DRIFT_MAX := 10.0
const PLUNDER_DRIFT := 0.5
const MEMORY_DRIFT_RATE := 0.02
const AVATAR_MEMORY := 30.0

static func drift_value(state: GameState) -> float:
	var total_plundered := 0
	for race_id in state.plundered:
		total_plundered += int(state.plundered[race_id])
	var memory_drift := 0.0
	if state.memory.to_value() > AVATAR_MEMORY:
		memory_drift = (state.memory.to_value() - AVATAR_MEMORY) * MEMORY_DRIFT_RATE
	return clampf(float(total_plundered) * PLUNDER_DRIFT + memory_drift, 0.0, DRIFT_MAX)

static func drift_tier(state: GameState) -> int:
	var v := drift_value(state)
	if v >= 9.0:
		return 3
	if v >= 6.0:
		return 2
	if v >= 3.0:
		return 1
	return 0

static func is_avatar_awakened(state: GameState) -> bool:
	return state.memory.is_greater_or_equal(BigNum.new(AVATAR_MEMORY))

static func avatar_tier_text(state: GameState) -> String:
	return AvatarTiers.tier_text(drift_tier(state))

static func can_intimate(state: GameState, race_id: StringName) -> bool:
	if not is_avatar_awakened(state):
		return false
	if not RelationActions.is_intimate(state, race_id):
		return false
	return not state.intimate_events.has(race_id)

static func intimate(state: GameState, race_id: StringName) -> Dictionary:
	if not can_intimate(state, race_id):
		return {"ok": false}
	var ev := IntimateEvents.get_event(race_id)
	state.intimate_events.append(race_id)
	return {"ok": true, "text": str(ev.get("text", ""))}
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（9 用例）

- [ ] **Step 5: Commit**

```bash
git add features/memories/ tests/unit/test_drift_actions.gd tests/unit/test_drift_actions.gd.uid
git commit -m "feat: DriftActions 逻辑（漂移值/档位/化身觉醒/亲密事件）"
```

---

### Task 5: GameManager 集成

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: `DriftActions`（T4）
- Produces: `signal intimate_done(race_id: StringName, text: String)`；`func intimate_race(race_id: StringName) -> Dictionary`

- [ ] **Step 1: 写失败测试**（test_game_manager.gd 追加）

```gdscript
func test_intimate_race_signal() -> void:
	gm._state = GameState.new()
	gm._state.memory = BigNum.new(40.0)
	gm._state.relations["human"] = 2
	var got := {"ok": false, "text": ""}
	gm.intimate_done.connect(func(id: StringName, text: String) -> void:
		got["ok"] = true
		got["text"] = text)
	var result: Dictionary = gm.intimate_race(&"human")
	assert_that(result.get("ok", false)).is_true()
	assert_that(got["ok"]).is_true()
	assert_that(str(got["text"]).length()).is_greater(20)
	assert_that(gm.get_state().intimate_events).contains(&"human")

func test_intimate_race_blocked_no_signal() -> void:
	gm._state = GameState.new()  # 未觉醒
	var got := {"ok": false}
	gm.intimate_done.connect(func(id: StringName, text: String) -> void: got["ok"] = true)
	var result: Dictionary = gm.intimate_race(&"human")
	assert_that(result.get("ok", false)).is_false()
	assert_that(got["ok"]).is_false()
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（intimate_race 不存在）

- [ ] **Step 3: 修改 game_manager.gd**

```gdscript
# 信号区追加：
signal intimate_done(race_id: StringName, text: String)

# 新增方法（plunder_race 之后）：
func intimate_race(race_id: StringName) -> Dictionary:
	var result := DriftActions.intimate(_state, race_id)
	if result.get("ok", false):
		intimate_done.emit(race_id, str(result.get("text", "")))
		resources_changed.emit()
	return result
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . --import` → 单文件测试 → 全量回归
Expected: 单文件 PASS；全量无回归

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 集成（intimate_race 入口 + intimate_done 信号）"
```

---

### Task 6: UI 化身区 + 亲密事件按钮

**Files:**
- Modify: `features/ui/main.tscn`
- Modify: `features/ui/main.gd`

**Interfaces:**
- Consumes: `GameManager.intimate_race`、`GameManager.get_state()`（T5）、`DriftActions`（T4）
- Produces: `%AvatarPanel`（含 `%AvatarLabel`）——记忆≥30 后显示观感文本 + 档位；4 个亲密按钮（`%IntimateHumanButton` 等）——can_intimate 时可用

- [ ] **Step 1: 追加 main.tscn 节点**（InsightLabel 之后）

```
[node name="AvatarPanel" type="PanelContainer" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2

[node name="AvatarLabel" type="Label" parent="VBox/AvatarPanel"]
unique_name_in_owner = true
layout_mode = 2
text = ""
autowrap_mode = 3

[node name="IntimateHumanButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与她促膝"

[node name="IntimateForestButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与她对坐"

[node name="IntimateStoneButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与他谈船"

[node name="IntimateWildButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "随它们看画"
```

- [ ] **Step 2: 扩展 main.gd**

```gdscript
# @onready 追加：
@onready var avatar_panel: PanelContainer = %AvatarPanel
@onready var avatar_label: Label = %AvatarLabel
@onready var intimate_human_button: Button = %IntimateHumanButton
@onready var intimate_forest_button: Button = %IntimateForestButton
@onready var intimate_stone_button: Button = %IntimateStoneButton
@onready var intimate_wild_button: Button = %IntimateWildButton

# _ready() 中追加：
intimate_human_button.pressed.connect(func(): _on_intimate_pressed(&"human"))
intimate_forest_button.pressed.connect(func(): _on_intimate_pressed(&"forestfolk"))
intimate_stone_button.pressed.connect(func(): _on_intimate_pressed(&"stoneborn"))
intimate_wild_button.pressed.connect(func(): _on_intimate_pressed(&"wildfolk"))
GameManager.intimate_done.connect(_on_intimate_done)

# _refresh() 末尾追加（_refresh_plunder_buttons 之后）：
_refresh_avatar()
_refresh_intimate_buttons()

# 新增方法：
func _refresh_avatar() -> void:
	var s := GameManager.get_state()
	if not DriftActions.is_avatar_awakened(s):
		avatar_panel.visible = false
		return
	avatar_panel.visible = true
	var tier := DriftActions.drift_tier(s)
	var tier_names := ["清醒", "微漂", "深漂", "迷失"]
	avatar_label.text = "化身 · %s\n%s" % [tier_names[tier], DriftActions.avatar_tier_text(s)]

func _refresh_intimate_buttons() -> void:
	var s := GameManager.get_state()
	var pairs := [
		[&"human", intimate_human_button],
		[&"forestfolk", intimate_forest_button],
		[&"stoneborn", intimate_stone_button],
		[&"wildfolk", intimate_wild_button],
	]
	for p in pairs:
		var rid: StringName = p[0]
		var btn: Button = p[1]
		btn.visible = DriftActions.can_intimate(s, rid)

func _on_intimate_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.intimate_race(race_id)
	if not result.get("ok", false):
		log_label.text = "它还不想说。"
	# 成功显示由 _on_intimate_done 处理

func _on_intimate_done(race_id: StringName, text: String) -> void:
	race_event_label.text = text
	log_label.text = "（你以「人」的样子，坐在了它身边。）"
```

- [ ] **Step 3: 验证**

Run: `godot --headless --path . --import` → 全量测试（无回归）→ `godot --headless --path . --quit-after 5`（无 SCRIPT ERROR）

- [ ] **Step 4: Commit**

```bash
git add features/ui/main.tscn features/ui/main.gd
git commit -m "feat: UI 化身区（漂移镜子观感）+ 亲密事件按钮（对坐）"
```

---

### Task 7: 集成验证与端到端

**Files:**
- Modify: 无（验证；临时脚本验证后删除）

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全部 PASS、0 failures、退出码 0

- [ ] **Step 2: 端到端玩法验证（临时脚本，验证后删除）**

`_verify_m5c.gd`（`extends SceneTree`）：

```gdscript
extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	# 1. drift 计算（夺梦 + 记忆）
	var s := GameState.new()
	s.plundered["human"] = 4
	s.memory = BigNum.new(50.0)
	var d := DriftActions.drift_value(s)
	if absf(d - 2.4) > 0.01:  # 4×0.5 + 20×0.02 = 2.4
		failures.append("drift calc: %f" % d)
	# 2. 觉醒边界
	var s2 := GameState.new()
	s2.memory = BigNum.new(30.0)
	if not DriftActions.is_avatar_awakened(s2):
		failures.append("avatar not awakened at 30")
	# 3. 亲密事件（关系 2 + 觉醒 + 未触发）
	s2.relations["human"] = 2
	s2.relations["wildfolk"] = 3
	if not DriftActions.can_intimate(s2, &"human"):
		failures.append("cannot intimate human")
	DriftActions.intimate(s2, &"human")
	DriftActions.intimate(s2, &"wildfolk")
	if s2.intimate_events.size() != 2:
		failures.append("intimate events not 2")
	# 4. 幂等
	if DriftActions.intimate(s2, &"human").get("ok", false):
		failures.append("intimate not idempotent")
	# 5. 存档往返 + 旧档回退
	var back := GameState.from_dict(s2.to_dict())
	if back.intimate_events.size() != 2:
		failures.append("save roundtrip")
	var legacy := GameState.from_dict({"tick": 5})
	if not legacy.intimate_events.is_empty():
		failures.append("legacy fallback")
	# 6. 漂移镜子文本（drift 9+ → 迷失档）
	var s3 := GameState.new()
	s3.plundered["human"] = 18
	if not str(DriftActions.avatar_tier_text(s3)).contains("影子"):
		failures.append("avatar tier text")
	if failures.is_empty():
		print("M5C E2E VERIFY PASSED")
		quit(0)
	else:
		print("M5C E2E FAILED: ", failures)
		quit(1)
```

Run: `godot --headless --path . -s res://_verify_m5c.gd`
Expected: 输出 `M5C E2E VERIFY PASSED`、退出码 0

- [ ] **Step 3: 清理 + 提交**

删除 `_verify_m5c.gd`；`git status` 确认工作区干净（含 .uid 检查）；如有修复则提交。

---

## Self-Review 记录（写完计划时自查）

- **设计文档覆盖**：§3.1 GameState ✓（T3）；§3.2 DriftActions ✓（T4）；§3.3 AvatarTiers ✓（T1）；§3.4 IntimateEvents ✓（T2）；§3.5 GameManager ✓（T5）；§3.6 UI ✓（T6）；§4 数值 ✓（T4）；§五 文本 ✓（T1/T2 逐字，含「它」人称）；§6 测试矩阵 ✓（T1-T7）。
- **占位符扫描**：无 TBD/TODO；所有测试与实现代码完整给出。
- **类型一致性**：`drift_value -> float`、`drift_tier -> int`、`is_avatar_awakened -> bool`、`avatar_tier_text -> String`、`can_intimate -> bool`、`intimate -> Dictionary` 在 T4/T5/T6/T7 一致；`intimate_events: Array[StringName]` 在 T3/T4/T5/T7 一致；`intimate_done(race_id: StringName, text: String)` 在 T5/T6 签名一致。
- **边界核对**：drift_tier 边界 2.5/3.0/6.0/9.0（T4 test 用 plundered 5/6/12/18 → 2.5/3.0/6.0/9.0）；觉醒 29.99/30（T4 test）；can_intimate 三条件（关系/觉醒/未触发，T4 test）；intimate 幂等（T4 test）；AvatarTiers 档位区间连续 0-10（T1 test）。
- **UI 细节**：化身区觉醒后显示（档位名 + 观感文本）；亲密按钮 can_intimate 控制可见；T6 文案「它」符合人称规范。
- **数值**：drift 公式（Σplundered×0.5 + max(0, memory−30)×0.02，clamp 0-10）与设计 §4 一致；T7 E2E 用 4 夺梦 + 记忆 50 → 2.4。
- **迁移安全**：旧档缺 intimate_events 回退（T3 测试 + T7 E2E）。
- **已知行为变更（有意）**：无——纯新增系统。
- **.uid 提醒**：T1/T2/T4 新增 class_name 后 `git status` 确认 .uid 入库。
