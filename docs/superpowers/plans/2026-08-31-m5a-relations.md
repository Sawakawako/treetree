# 世界树 里程碑 5a（关系值系统）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地四族关系值系统（对称 -3..+3）——关系修正 API（明选后果消费方）+ 四族一次性仪式互动（防刷）+ UI 颜色表达关系温度 + 亲密级接口预留（`is_intimate`，M7 化身填充）。

**Architecture:** 沿用既有模式：`features/relations/` 新增 `RelationEvents`（const 表，4 个仪式互动）与 `RelationActions`（RefCounted 纯静态）；`GameState` 增 `relations`/`relation_events`（沿 races/relics_found 防御模式）；`GameManager` 增 `interact_relation` + `relation_changed` 信号；UI 四族面板加关系温度（文字+字体颜色）与互动按钮。

**Tech Stack:** Godot 4.7.1（mono）+ GDScript（typed）+ GdUnit4 6.2.1（headless）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-m5a-relations-design.md`（本计划唯一权威）；主规格 §13.5/§13.6/§11.1/§11.2；路线图 `docs/world-tree/ROADMAP.md`

## Global Constraints

- **测试命令**（GdUnit4 6.2.1，不是 `--run-tests`）：
  - 全量：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
  - 单文件：同命令加 `--add res://tests/unit/test_xxx.gd`；可加 `-c` 关 fail-fast
  - **新增 class_name 脚本后先跑** `godot --headless --path . --import`
- **`is_equal_approx` 双参签名** `(expected, approx)`——断言统一带容差 `, 1e-4`
- 资源一律 `BigNum`；typed GDScript
- 中文文件一律用 write/edit 工具（禁 PowerShell 默认编码）
- **文风铁律**：四篇互动文本**必须逐字复制**设计文档 §五（含叙事基线：巨树身份/根须周围/无化身/禁止人形暗示）
- 存档兼容：M2-M4 旧档缺 relations 字段回退默认，不得损坏
- `.uid` 文件入库（新增 class_name 脚本后确认 `git status` 含 .uid）
- git master；每任务一个 commit；工作目录 `E:\world tree`

---

### Task 1: RelationEvents 数据模块（4 个仪式互动）

**Files:**
- Create: `features/relations/relation_events.gd`
- Test: `tests/unit/test_relation_events.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name RelationEvents extends RefCounted`：
  - `const EVENTS: Array[Dictionary]`（4 项：race_id: StringName/condition: String/text: String）
  - `static func get_event(race_id: StringName) -> Dictionary`（找不到返回空字典）
  - `static func event_count() -> int`

- [ ] **Step 1: 写失败测试**（test_relation_events.gd）

```gdscript
extends GdUnitTestSuite

func test_event_count() -> void:
	assert_that(RelationEvents.event_count()).is_equal(4)

func test_get_event_fields() -> void:
	var e := RelationEvents.get_event(&"human")
	assert_that(e.has("race_id")).is_true()
	assert_that(e.has("condition")).is_true()
	assert_that(e.has("text")).is_true()
	assert_that(str(e.get("text", "")).length()).is_greater(10)

func test_get_missing_event_returns_empty() -> void:
	assert_that(RelationEvents.get_event(&"nobody").is_empty()).is_true()

func test_events_cover_four_races() -> void:
	var ids: Array = []
	for e in RelationEvents.EVENTS:
		ids.append(e.get("race_id"))
	for expected in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		assert_that(ids.has(expected)).is_true()

func test_conditions_format_valid() -> void:
	for e in RelationEvents.EVENTS:
		var cond := str(e.get("condition", ""))
		var ok := false
		for prefix in ["memory>=", "faith>=", "sap>=", "totem>="]:
			if cond.begins_with(prefix):
				ok = float(cond.get_slice(">=", 1)) >= 0.0
		assert_that(ok).is_true()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 RelationEvents）

- [ ] **Step 3: 实现 relation_events.gd**（文本逐字复制设计文档 §五）

```gdscript
class_name RelationEvents
extends RefCounted

const EVENTS: Array[Dictionary] = [
	{
		"race_id": &"human",
		"condition": "memory>=4",
		"text": "火塘生在你的根须旁边。火苗是她用记忆点的，烧得很小心。\n她说：天裂的那一天，有人把种子藏进了胸口。\n她不知道你在听。但你的根须听得懂。\n你的年轮里，有什么东西，轻轻动了一下。",
	},
	{
		"race_id": &"forestfolk",
		"condition": "faith>=20",
		"text": "他们围着你最老的那条根坐下，像围着一座圣坛。\n开口，先是一声低音，然后整片林子应和。\n歌声顺着根须爬上来，在你身体里走了一圈——\n你听见自己的年轮，也跟着唱了一节。\n唱完，他们不说话，只是把脸贴在树皮上，很久。",
	},
	{
		"race_id": &"stoneborn",
		"condition": "sap>=300",
		"text": "石裔在你南面的根下挖了一条槽，把熔化的石头浇进去。\n他们说，这是给你的地基——树站了太多年，该有人替它站一会儿。\n锤声落下来，一下，一下，像另一种心跳。\n你不确定那是他们的，还是你的。",
	},
	{
		"race_id": &"wildfolk",
		"condition": "totem>=2",
		"text": "夜里，野民在你根旁的石壁上画完第二幅画。\n画的还是那棵树，但树下多了一行脚印。\n脚印从画里伸出来，一直延伸到——你这里。\n他们没有叫你。但他们画的每一步，都像在问：要不要走出来？",
	},
]

static func get_event(race_id: StringName) -> Dictionary:
	for e in EVENTS:
		if e.get("race_id") == race_id:
			return e
	return {}

static func event_count() -> int:
	return EVENTS.size()
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（5 用例）

- [ ] **Step 5: Commit**

```bash
git add features/relations/ tests/unit/test_relation_events.gd tests/unit/test_relation_events.gd.uid
git commit -m "feat: RelationEvents 数据模块（4 族仪式互动）"
```

---

### Task 2: GameState 扩展（relations/relation_events）

**Files:**
- Modify: `features/game/game_state.gd`
- Modify: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: 无新依赖
- Produces: `GameState.relations: Dictionary = {}`（`{race_id: int}`）、`GameState.relation_events: Array[StringName] = []`；`to_dict` 含两者；`from_dict` 回退默认 + relations 非字典防御（沿 races 模式）+ 值 int 归一 + relation_events 过滤非字符串（JSON 载入为 String）

- [ ] **Step 1: 写失败测试**（test_game_state.gd 追加）

```gdscript
func test_relations_roundtrip() -> void:
	var s := GameState.new()
	s.relations["human"] = 2
	s.relations["wildfolk"] = -1
	s.relation_events.assign([&"human", &"wildfolk"])
	var back := GameState.from_dict(s.to_dict())
	assert_that(int(back.relations["human"])).is_equal(2)
	assert_that(int(back.relations["wildfolk"])).is_equal(-1)
	assert_that(back.relation_events).contains(&"human")
	assert_that(back.relation_events).contains(&"wildfolk")

func test_relations_missing_fallback() -> void:
	var back := GameState.from_dict({"tick": 5})
	assert_that(back.relations.is_empty()).is_true()
	assert_that(back.relation_events).is_empty()

func test_from_dict_guards_corrupt_relations() -> void:
	# 损坏存档：relations 非字典 / 值非数字 → 回退或归一，不崩溃
	var back := GameState.from_dict({"relations": "corrupt"})
	assert_that(back.relations.is_empty()).is_true()
	var back2 := GameState.from_dict({"relations": {"human": "x", "wildfolk": 1.5}})
	assert_that(int(back2.relations.get("human", 0))).is_equal(0)
	assert_that(int(back2.relations["wildfolk"])).is_equal(1)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（字段不存在）

- [ ] **Step 3: 扩展 game_state.gd**

```gdscript
# 新字段（insight 附近）：
var relations: Dictionary = {}
var relation_events: Array[StringName] = []

# to_dict() 中追加：
"relations": relations,
"relation_events": relation_events,

# from_dict() 中，insight 之后追加：
var rel: Variant = d.get("relations", {})
if typeof(rel) != TYPE_DICTIONARY:
	rel = {}
s.relations = {}
for rid: Variant in rel:
	var rv: Variant = rel[rid]
	if typeof(rv) == TYPE_INT or typeof(rv) == TYPE_FLOAT:
		s.relations[rid] = int(rv)
var re: Array = d.get("relation_events", [])
var re_cleaned: Array = []
for x in re:
	if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
		re_cleaned.append(StringName(x))
s.relation_events.assign(re_cleaned)
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（3 新用例 + 旧用例无回归）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 扩展（relations/relation_events + 存档回退防御）"
```

---

### Task 3: RelationActions 逻辑

**Files:**
- Create: `features/relations/relation_actions.gd`
- Test: `tests/unit/test_relation_actions.gd`

**Interfaces:**
- Consumes: `RelationEvents`（T1）、`GameState`（relations/relation_events/races/memory/faith/sap，T2）、`TotemActions.visible_stage`（M4）
- Produces: `class_name RelationActions extends RefCounted`：
  - `static func get_relation(state, race_id) -> int`（缺省 0）
  - `static func apply_change(state, race_id, delta) -> int`（clamp -3..+3，返回新值）
  - `static func is_intimate(state, race_id) -> bool`（relation >= +2——亲密级事件位预留）
  - `static func can_interact(state, race_id) -> bool`（该族已唤醒 + 资源条件满足 + 未触发）
  - `static func interact(state, race_id) -> Dictionary`（`{"ok", "text", "relation"}`——+1 关系、标记已触发、返回文本）

- [ ] **Step 1: 写失败测试**（test_relation_actions.gd）

```gdscript
extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
	state.races[id] = {"awakened": true, "population": 50.0}

func test_get_relation_default_zero() -> void:
	var s := GameState.new()
	assert_that(RelationActions.get_relation(s, &"human")).is_equal(0)

func test_apply_change_clamps() -> void:
	var s := GameState.new()
	assert_that(RelationActions.apply_change(s, &"human", 5)).is_equal(3)
	assert_that(RelationActions.apply_change(s, &"human", -8)).is_equal(-3)
	assert_that(RelationActions.apply_change(s, &"human", 1)).is_equal(-2)

func test_is_intimate_boundary() -> void:
	var s := GameState.new()
	s.relations["human"] = 1
	assert_that(RelationActions.is_intimate(s, &"human")).is_false()
	s.relations["human"] = 2
	assert_that(RelationActions.is_intimate(s, &"human")).is_true()

func test_can_interact_requires_awakened() -> void:
	var s := GameState.new()  # 人族未醒
	s.memory = BigNum.new(10.0)
	assert_that(RelationActions.can_interact(s, &"human")).is_false()

func test_can_interact_requires_resource() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(3.99)  # 需记忆>=4
	assert_that(RelationActions.can_interact(s, &"human")).is_false()
	s.memory = BigNum.new(4.0)
	assert_that(RelationActions.can_interact(s, &"human")).is_true()

func test_can_interact_once_only() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	assert_that(RelationActions.interact(s, &"human").get("ok", false)).is_true()
	assert_that(RelationActions.can_interact(s, &"human")).is_false()

func test_interact_gives_relation_and_text() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	var r := RelationActions.interact(s, &"human")
	assert_that(r.get("ok", false)).is_true()
	assert_that(int(r.get("relation", 0))).is_equal(1)
	assert_that(str(r.get("text", "")).length()).is_greater(10)
	assert_that(s.relations["human"]).is_equal(1)
	assert_that(s.relation_events).contains(&"human")

func test_interact_idempotent() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.memory = BigNum.new(4.0)
	RelationActions.interact(s, &"human")
	var again := RelationActions.interact(s, &"human")
	assert_that(again.get("ok", false)).is_false()
	assert_that(s.relations["human"]).is_equal(1)  # 不重复 +1

func test_stoneborn_requires_sap() -> void:
	var s := GameState.new()
	_awaken(s, &"stoneborn")
	s.sap = BigNum.new(299.0)
	assert_that(RelationActions.can_interact(s, &"stoneborn")).is_false()
	s.sap = BigNum.new(300.0)
	assert_that(RelationActions.can_interact(s, &"stoneborn")).is_true()

func test_wildfolk_requires_totem_stage() -> void:
	var s := GameState.new()
	_awaken(s, &"wildfolk")
	s.memory = BigNum.new(4.0)  # totem stage 2 需记忆>=4
	assert_that(RelationActions.can_interact(s, &"wildfolk")).is_true()
	s.memory = BigNum.new(3.99)
	assert_that(RelationActions.can_interact(s, &"wildfolk")).is_false()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 RelationActions）

- [ ] **Step 3: 实现 relation_actions.gd**

```gdscript
class_name RelationActions
extends RefCounted

const RELATION_MIN := -3
const RELATION_MAX := 3

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func get_relation(state: GameState, race_id: StringName) -> int:
	return int(state.relations.get(race_id, 0))

static func apply_change(state: GameState, race_id: StringName, delta: int) -> int:
	if delta == 0:
		return get_relation(state, race_id)
	var new_val := clampi(get_relation(state, race_id) + delta, RELATION_MIN, RELATION_MAX)
	state.relations[race_id] = new_val
	return new_val

static func is_intimate(state: GameState, race_id: StringName) -> bool:
	return get_relation(state, race_id) >= 2

static func _condition_met(state: GameState, race_id: StringName) -> bool:
	var ev := RelationEvents.get_event(race_id)
	if ev.is_empty():
		return false
	var cond := str(ev.get("condition", ""))
	if cond.begins_with("memory>="):
		return state.memory.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("faith>="):
		return state.faith.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("sap>="):
		return state.sap.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("totem>="):
		return TotemActions.visible_stage(state) >= int(float(cond.get_slice(">=", 1)))
	return false

static func can_interact(state: GameState, race_id: StringName) -> bool:
	if not _race_awakened(state, race_id):
		return false
	if state.relation_events.has(race_id):
		return false
	return _condition_met(state, race_id)

static func interact(state: GameState, race_id: StringName) -> Dictionary:
	if not can_interact(state, race_id):
		return {"ok": false}
	var ev := RelationEvents.get_event(race_id)
	apply_change(state, race_id, 1)
	state.relation_events.append(race_id)
	return {"ok": true, "text": str(ev.get("text", "")), "relation": get_relation(state, race_id)}
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（10 用例）

- [ ] **Step 5: Commit**

```bash
git add features/relations/ tests/unit/test_relation_actions.gd tests/unit/test_relation_actions.gd.uid
git commit -m "feat: RelationActions 逻辑（关系修正 clamp/一次性互动/条件解析/亲密级接口）"
```

---

### Task 4: GameManager 集成

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: `RelationActions`（T3）
- Produces: `signal relation_changed(race_id: StringName, relation: int)`；`func interact_relation(race_id: StringName) -> Dictionary`（成功时 emit 信号 + resources_changed）

- [ ] **Step 1: 写失败测试**（test_game_manager.gd 追加）

```gdscript
func test_interact_relation_signal() -> void:
	gm._state = GameState.new()
	gm._state.races["human"] = {"awakened": true, "population": 50.0}
	gm._state.memory = BigNum.new(4.0)
	var got := {"ok": false, "rel": -99}
	gm.relation_changed.connect(func(id: StringName, rel: int) -> void:
		got["ok"] = true
		got["rel"] = rel)
	var result: Dictionary = gm.interact_relation(&"human")
	assert_that(result.get("ok", false)).is_true()
	assert_that(got["ok"]).is_true()
	assert_that(int(got["rel"])).is_equal(1)
	assert_that(gm.get_state().relations["human"]).is_equal(1)

func test_interact_relation_blocked_no_signal() -> void:
	gm._state = GameState.new()  # 人族未醒
	var got := {"ok": false}
	gm.relation_changed.connect(func(id: StringName, rel: int) -> void: got["ok"] = true)
	var result: Dictionary = gm.interact_relation(&"human")
	assert_that(result.get("ok", false)).is_false()
	assert_that(got["ok"]).is_false()
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（interact_relation 不存在）

- [ ] **Step 3: 修改 game_manager.gd**

```gdscript
# 信号区追加：
signal relation_changed(race_id: StringName, relation: int)

# 新增方法（interpret_totem 之后）：
func interact_relation(race_id: StringName) -> Dictionary:
	var result := RelationActions.interact(_state, race_id)
	if result.get("ok", false):
		relation_changed.emit(race_id, int(result.get("relation", 0)))
		resources_changed.emit()
	return result
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . --import` → 单文件测试 → 全量回归
Expected: 单文件 PASS；全量 106 = 102 + 2 + 2（T2 已加 3 个 game_state 用例？——以实际为准，见 Task 2/3 后全量数）

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 集成（interact_relation 入口 + relation_changed 信号）"
```

---

### Task 5: UI 关系温度 + 互动按钮

**Files:**
- Modify: `features/ui/main.tscn`
- Modify: `features/ui/main.gd`

**Interfaces:**
- Consumes: `GameManager.interact_relation`、`GameManager.get_state()`（T4）、`RelationActions.get_relation/can_interact`（T3）
- Produces: 4 个互动按钮（`%InteractHumanButton` 等）；`_refresh_race_rows` 加关系温度（文字+颜色）；`_on_interact_pressed(race_id)`

- [ ] **Step 1: 追加 main.tscn 节点**（四个互动按钮，InsightLabel 之后）

```
[node name="InteractHumanButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与人族围火"

[node name="InteractForestButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与林地民听歌"

[node name="InteractStoneButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与石裔看地基"

[node name="InteractWildButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "与野民看壁画"
```

- [ ] **Step 2: 扩展 main.gd**

```gdscript
# 常量（RACE_ROWS 附近）：
const RELATION_LABELS := {
	-3: "敌意", -2: "敌意", -1: "冷淡", 0: "平常",
	1: "友善", 2: "亲近", 3: "挚友",
}
const RELATION_COLORS := {
	-3: Color("#7a8a99"), -2: Color("#7a8a99"), -1: Color("#9aa5ad"),
	0: Color.WHITE, 1: Color("#c9a25c"), 2: Color("#e6a23c"), 3: Color("#f0b64e"),
}

# @onready 追加：
@onready var interact_human_button: Button = %InteractHumanButton
@onready var interact_forest_button: Button = %InteractForestButton
@onready var interact_stone_button: Button = %InteractStoneButton
@onready var interact_wild_button: Button = %InteractWildButton

# _ready() 中追加：
interact_human_button.pressed.connect(func(): _on_interact_pressed(&"human"))
interact_forest_button.pressed.connect(func(): _on_interact_pressed(&"forestfolk"))
interact_stone_button.pressed.connect(func(): _on_interact_pressed(&"stoneborn"))
interact_wild_button.pressed.connect(func(): _on_interact_pressed(&"wildfolk"))

# _refresh_race_rows() 已唤醒分支改为：
if s.races.has(id) and bool(s.races[id].get("awakened", false)):
	var pop := float(s.races[id].get("population", 0.0))
	var rel := RelationActions.get_relation(s, id)
	label.text = "%s：人口 %d · %s" % [RACE_ROWS[id], int(pop), RELATION_LABELS.get(rel, "平常")]
	label.add_theme_color_override("font_color", RELATION_COLORS.get(rel, Color.WHITE))
else:
	label.text = "%s：%s 时苏醒" % [RACE_ROWS[id], _awaken_hint(data)]
	label.add_theme_color_override("font_color", Color.WHITE)

# _refresh() 末尾追加（_refresh_totem 之后）：
_refresh_interact_buttons()

# 新增方法：
func _refresh_interact_buttons() -> void:
	var s := GameManager.get_state()
	var pairs := [
		[&"human", interact_human_button],
		[&"forestfolk", interact_forest_button],
		[&"stoneborn", interact_stone_button],
		[&"wildfolk", interact_wild_button],
	]
	for p in pairs:
		var rid: StringName = p[0]
		var btn: Button = p[1]
		btn.visible = RelationActions.can_interact(s, rid)

func _on_interact_pressed(race_id: StringName) -> void:
	var result: Dictionary = GameManager.interact_relation(race_id)
	if result.get("ok", false):
		race_event_label.text = str(result.get("text", ""))
		log_label.text = "关系 · 亲近了一分。"
	_refresh()
```

- [ ] **Step 3: 验证**

Run: `godot --headless --path . --import` → 全量测试（无回归）→ `godot --headless --path . --quit-after 5`（无 SCRIPT ERROR）

- [ ] **Step 4: Commit**

```bash
git add features/ui/main.tscn features/ui/main.gd
git commit -m "feat: UI 关系温度（颜色表达）+ 四族互动按钮"
```

---

### Task 6: 集成验证与端到端

**Files:**
- Modify: 无（验证；临时脚本验证后删除）

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全部 PASS、0 failures、退出码 0

- [ ] **Step 2: 端到端玩法验证（临时脚本，验证后删除）**

`_verify_m5a.gd`（`extends SceneTree`）：

```gdscript
extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var s := GameState.new()
	# 1. 四族唤醒 + 资源满足
	s.races["human"] = {"awakened": true, "population": 50.0}
	s.races["forestfolk"] = {"awakened": true, "population": 30.0}
	s.races["stoneborn"] = {"awakened": true, "population": 20.0}
	s.races["wildfolk"] = {"awakened": true, "population": 80.0}
	s.memory = BigNum.new(10.0)   # human>=4, wildfolk totem stage>=2
	s.faith = BigNum.new(30.0)    # forestfolk>=20
	s.sap = BigNum.new(500.0)     # stoneborn>=300
	# 2. 互动 4 次 → 每族 +1
	for rid in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		var r := RelationActions.interact(s, rid)
		if not r.get("ok", false):
			failures.append("interact %s failed" % rid)
	if int(s.relations.get("human", 0)) != 1 or int(s.relations.get("wildfolk", 0)) != 1:
		failures.append("relations not +1 each")
	# 3. 防刷：再互动全失败
	for rid in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		if RelationActions.interact(s, rid).get("ok", false):
			failures.append("interact %s not once-only" % rid)
	# 4. clamp：apply_change 超界
	RelationActions.apply_change(s, &"human", 5)
	if int(s.relations["human"]) != 3:
		failures.append("clamp max failed")
	RelationActions.apply_change(s, &"human", -8)
	if int(s.relations["human"]) != -3:
		failures.append("clamp min failed")
	# 5. 存档往返
	var back := GameState.from_dict(s.to_dict())
	if back.relation_events.size() != 4:
		failures.append("save roundtrip events")
	# 6. M4 旧档回退
	var legacy := GameState.from_dict({"races": {"human": {"awakened": true, "population": 50.0}}})
	if not legacy.relations.is_empty():
		failures.append("legacy fallback")
	if failures.is_empty():
		print("M5A E2E VERIFY PASSED")
		quit(0)
	else:
		print("M5A E2E FAILED: ", failures)
		quit(1)
```

Run: `godot --headless --path . -s res://_verify_m5a.gd`
Expected: 输出 `M5A E2E VERIFY PASSED`、退出码 0

- [ ] **Step 3: 清理 + 提交**

删除 `_verify_m5a.gd`；`git status` 确认工作区干净（含 .uid 检查）；如有修复则提交。

---

## Self-Review 记录（写完计划时自查）

- **设计文档覆盖**：§3.1 GameState ✓（T2）；§3.2 RelationActions ✓（T3）；§3.3 RelationEvents ✓（T1）；§3.4 GameManager ✓（T4）；§3.5 UI ✓（T5）；§4 数值 ✓（T3 条件/T1 数据）；§五 文本 ✓（T1 逐字）；§6 测试矩阵 ✓（T1-T6）。
- **占位符扫描**：无 TBD/TODO；所有测试与实现代码完整给出。
- **类型一致性**：`relations: Dictionary`（值 int）、`relation_events: Array[StringName]` 在 T2/T3/T4/T5/T6 一致；`interact(state, race_id: StringName) -> Dictionary` 返回 `{"ok","text","relation"}` 在 T3/T4 一致；`relation_changed(race_id: StringName, relation: int)` 在 T4/T5 签名一致；`can_interact(state, race_id)` 在 T3/T5/T6 一致。
- **边界核对**：apply_change clamp（-3/+3，T3 test）；interact 幂等（已触发挡，T3 test）；can_interact 三条件（唤醒/资源/未触发，T3 各测试）；wildfolk 条件 `totem>=2` 经 TotemActions.visible_stage（依赖 M4，T3 test 用 memory 4.0/3.99 驱动）；关系值无自然衰减。
- **UI 细节**：颜色 7 档映射与设计 §3.5 一致；温度文字 5 档（敌意/冷淡/平常/友善/亲近/挚友——6 个标签对应 7 值，-2 与 -3 同为"敌意"）；按钮 visible = can_interact；互动文本经 race_event_label。
- **数值**：资源条件（记忆4/信仰20/树液300/图腾stage2）与设计 §4 一致；T6 E2E 用 10/30/500 记忆/信仰/树液 满足全部四族。
- **迁移安全**：M2-M4 旧档缺 relations/relation_events 回退默认（T2 测试 + T6 E2E 第 6 项）。
- **已知行为变更（有意）**：无——纯新增系统；四族行文本从「人口 X」扩展为「人口 X · 温度」（T5）。
- **.uid 提醒**：T1/T3 新增 class_name 后 `git status` 确认 .uid 入库（M4 教训）。
