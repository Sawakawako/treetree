# M6 终局 + 多周目 + 真结局 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 M6 主闭环——终局状态机（世界之轴明选⑦ + 四结局判定 + 归还序列 7 步）+ 多周目（周目门控/切换/六新关系事件/三周目快进）+ 真结局循环终止。

**Architecture:** 沿项目既有 Layer Cake：纯静态 RefCounted 逻辑类（`features/ending/`）+ GameState 序列化扩展（`run_number`/`ending_seen`）+ GameManager 入口发信号 + UI 只监听信号 + GdUnit4 headless 测试。明选⑦ 复用 ChoiceLibrary/ChoiceActions JSON 外置机制但后果走 EndingStateMachine（选项只设 intent flag）；二周目六事件扩展 RelationEvents 为多事件结构（event_id + 周目门控）。

**Tech Stack:** Godot 4.7.1 mono（GDScript）/ GdUnit4 6.2.1 / BigNum 经济 / JSON 文本外置。

**Spec:** `docs/superpowers/specs/2026-09-05-world-tree-m6-ending-multirun-design.md`（设计权威）→ 主 spec `docs/superpowers/specs/2026-08-31-world-tree-design.md` §8（终局/结局/归还/真/多周目）

## Global Constraints

- 引擎 Godot **4.7.1** mono；测试用 GdUnit4 6.2.1：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`（退出码 0=全绿，100=有失败；RED 验证加 `-c` 看全部预期失败）。
- 新增 class_name 脚本后必须先跑 `godot --headless --path . --import`（否则类未注册）；新 `.uid` 文件要入库。
- 新增 class_name 脚本 `.uid` 确认入库（chore commit 补）。
- 文件一律 UTF-8（edit/write 工具或 .NET 显式编码，禁 PowerShell 默认编码）。
- git：每任务一 commit，风格 `feat: 模块名（要点）`。
- 游戏内文本遵循文风六则（短句呼吸/意象代替说明/留白不写尽/柔和如风/自然词汇/人称柔软）；写作任务完成过 humanize-ai 自检。
- 关系值 float，最小步长 0.5，clamp -3.0..+3.0；好结局关系总值 ≥12（四族各 +3）。
- 领悟跨周目保留（同知识只奖一次）；关系/事件标记每周目清零。
- 希望点：1 开局 → 好结局 +1 → 真结局耗 2（跨周目唯一货币）。
- 真结局 = 结束循环回标题（无自由模式）；记忆余烬 = 仅保留知识/领悟/希望/解锁。
- 环形废墟 = relic id 9，flag `circular_ruins_revealed`；世界之轴成型 = 环形废墟 + 四族醒 + 明选①—⑥完成 + 说书人⑥听完 + growth ≥ 1000。

---

### Task 1: GameState 扩展（run_number / ending_seen + 周目重置工厂）

**Files:**
- Modify: `features/game/game_state.gd`
- Test: `tests/unit/test_game_state.gd`（追加减量）

**Interfaces:**
- Consumes: 既有 GameState 字段全量（见文件）。
- Produces: `GameState.run_number: int`（缺省 1）；`GameState.ending_seen: Array[StringName]`（缺省 []）；`GameState.new_run_preserved() -> GameState`（周目重置工厂：拷贝保留字段回新实例，清零字段归默认，run_number+1）。

- [ ] **Step 1: 在 test_game_state.gd 追加字段序列化测试**

```gdscript
func test_m6_run_number_default_and_roundtrip() -> void:
	var s := GameState.new()
	assert_that(s.run_number).is_equal(1)
	assert_that(s.ending_seen).is_empty()
	s.run_number = 2
	s.ending_seen.append(&"good")
	var s2 := GameState.from_dict(s.to_dict())
	assert_that(s2.run_number).is_equal(2)
	assert_that(s2.ending_seen).contains(&"good")

func test_m6_old_save_defaults() -> void:
	# 无 run_number/ending_seen 的旧档 → 缺省回退
	var s := GameState.from_dict({"hope": 1})
	assert_that(s.run_number).is_equal(1)
	assert_that(s.ending_seen).is_empty()
```

- [ ] **Step 2: 跑测试确认失败（类未定义字段 → 解析错）**

Run: `godot --headless --path . --import` 然后 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_game_state.gd -c`
Expected: FAIL（`run_number` 不存在）

- [ ] **Step 3: 实现字段 + 序列化**

在 `features/game/game_state.gd` 顶部字段区（`soul_river` 后）追加：

```gdscript
var run_number: int = 1                # 当前周目（M6，1 起始；周目门控/文本层叠依据）
var ending_seen: Array[StringName] = []  # 已达成结局 id（bad/normal/good/true，M6）
```

`to_dict()` 加 `"run_number": run_number,` `"ending_seen": ending_seen,`；`from_dict()` 加：

```gdscript
s.run_number = int(d.get("run_number", 1))
var es: Array = d.get("ending_seen", [])
var es_cleaned: Array = []
for x in es:
    if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
        es_cleaned.append(StringName(x))
s.ending_seen.assign(es_cleaned)
```

- [ ] **Step 4: 跑测试确认通过**

Run: 同 Step 2（去掉 `-c`）
Expected: PASS（test_game_state 全绿）

- [ ] **Step 5: 实现周目重置工厂**

在 `game_state.gd` 末尾加（`from_dict` 后）：

```gdscript
# M6 周目重置：新建一局的 GameState，仅拷贝跨周目保留字段（记忆余烬）
static func new_run_preserved(prev: GameState) -> GameState:
	var s := GameState.new()
	# 保留：希望 / 领悟 / 真相 / 知识解锁标记
	s.hope = prev.hope
	s.insight = prev.insight
	s.truth = prev.truth
	s.run_number = prev.run_number + 1
	s.ending_seen.assign(prev.ending_seen)
	s.choice_flags.assign(prev.choice_flags)          # 知识型 flag 保留
	s.totem_interpreted.assign(prev.totem_interpreted)
	s.storyteller_stories.assign(prev.storyteller_stories)
	return s
```

- [ ] **Step 6: 追加周目重置测试**

```gdscript
func test_m6_new_run_preserves_only_knowledge() -> void:
	var s := GameState.new()
	s.hope = 2
	s.insight = 11
	s.truth = 6
	s.run_number = 1
	s.choice_flags.append(&"theseus_remembered")
	s.storyteller_stories.append(&"story_6")
	s.relations[&"human"] = 3.0
	s.memory = BigNum.new(99.0)
	s.growth = BigNum.new(5000.0)
	s.leaf_level = 5
	s.races[&"human"] = {"awakened": true, "population": 50.0}
	s.soul_river = 80
	var s2 := GameState.new_run_preserved(s)
	assert_that(s2.run_number).is_equal(2)
	assert_that(s2.hope).is_equal(2)
	assert_that(s2.insight).is_equal(11)
	assert_that(s2.truth).is_equal(6)
	assert_that(s2.choice_flags).contains(&"theseus_remembered")
	assert_that(s2.storyteller_stories).contains(&"story_6")
	assert_that(s2.relations).is_empty()
	assert_that(s2.relation_events).is_empty()
	assert_that(float(s2.memory.to_value())).is_equal_approx(0.0, 1e-4)
	assert_that(float(s2.growth.to_value())).is_equal_approx(0.0, 1e-4)
	assert_that(s2.leaf_level).is_equal(0)
	assert_that(s2.races).is_empty()
	assert_that(s2.soul_river).is_equal(100)
```

- [ ] **Step 7: 跑测试确认通过 + commit**

Run: 同 Step 2（全量 test_game_state，去 `-c`）
Expected: PASS
```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd tests/unit/test_game_state.gd.uid
git commit -m "feat: GameState 周目字段（run_number/ending_seen）+ 周目重置工厂"
```

---

### Task 2: EndingStateMachine（终局状态机：成型判定/明选⑦分流/结局判定/希望结算）

**Files:**
- Create: `features/ending/ending_state_machine.gd`
- Create: `features/ending/ending_state_machine.gd.uid`（import 生成后入库）
- Test: `tests/unit/test_ending_state_machine.gd`
- Test: `tests/unit/test_ending_state_machine.gd.uid`

**Interfaces:**
- Consumes: `GameState.run_number/ending_seen/hope/insight/truth/relations/choice_flags/storyteller_stories/choices_done/relics_found/races/growth`；`RelationActions`；`ChoiceLibrary`。
- Produces:
  - `EndingStateMachine.INSIGHT_GOOD := 10`（好结局领悟门槛）
  - `EndingStateMachine.GROWTH_AXIS := 1000.0`（世界之轴树高阈值，估值可调）
  - `EndingStateMachine.axis_ready(state: GameState) -> bool`（成型判定）
  - `EndingStateMachine.resolve_ending(state: GameState, intent: StringName) -> Dictionary`（消费明选⑦ intent: `&"condense"`/`&"refuse"`/`&"return"`/`&"self"` → `{"ok": true, "outcome": "bad"|"normal"|"good"|"true", "hope_before": int, "hope_after": int}`；写 `ending_seen`，结算 hope）
  - `EndingStateMachine.outcome_of(state, intent) -> StringName`（纯判定，供测试/UI 预显）

- [ ] **Step 1: 写失败测试（成型判定 + 判定矩阵 + 希望结算）**

`tests/unit/test_ending_state_machine.gd`：

```gdscript
extends GdUnitTestSuite

func _state_axis_ready() -> GameState:
	var s := GameState.new()
	s.growth = BigNum.new(1000.0)
	s.relics_found.append(9)
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.races[rid] = {"awakened": true, "population": 10.0}
	# 明选①—⑥ 完成（8 卡除 world_axis 外全做）
	for c in ChoiceLibrary.load_all():
		var cid := StringName(str(c.get("id", "")))
		if cid != &"world_axis":
			s.choices_done.append(cid)
	s.storyteller_stories.append(&"story_6")
	return s

func test_axis_not_ready_missing_relic() -> void:
	var s := _state_axis_ready()
	s.relics_found = []
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_not_ready_low_growth() -> void:
	var s := _state_axis_ready()
	s.growth = BigNum.new(999.0)
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_not_ready_missing_choice() -> void:
	var s := _state_axis_ready()
	s.choices_done.remove_at(0)
	assert_that(EndingStateMachine.axis_ready(s)).is_false()

func test_axis_ready_when_all_met() -> void:
	var s := _state_axis_ready()
	assert_that(EndingStateMachine.axis_ready(s)).is_true()

func test_bad_when_no_insight_no_bonds() -> void:
	var s := _state_axis_ready()  # insight 0, relations 空
	var r := EndingStateMachine.resolve_ending(s, &"condense")
	assert_that(str(r.get("outcome", ""))).is_equal("bad")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)
	assert_that(s.ending_seen).contains(&"bad")

func test_normal_when_insight_no_bonds() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	var r := EndingStateMachine.resolve_ending(s, &"condense")
	assert_that(str(r.get("outcome", ""))).is_equal("normal")

func test_bonds_require_all_three() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0
	s.relations[&"forestfolk"] = 3.0
	s.relations[&"stoneborn"] = 3.0
	s.relations[&"wildfolk"] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"return")
	assert_that(str(r.get("outcome", ""))).is_equal("good")
	assert_that(int(r.get("hope_after", 0))).is_equal(2)
	assert_that(s.ending_seen).contains(&"good")

func test_return_without_full_bonds_is_normal() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0  # 只一族满
	var r := EndingStateMachine.resolve_ending(s, &"return")
	assert_that(str(r.get("outcome", ""))).is_equal("normal")
	assert_that(int(r.get("hope_after", 0))).is_equal(1)

func test_refuse_is_bad() -> void:
	var s := _state_axis_ready()
	s.insight = 10
	s.relations[&"human"] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"refuse")
	assert_that(str(r.get("outcome", ""))).is_equal("bad")

func test_true_requires_run3_full_hope2() -> void:
	var s := _state_axis_ready()
	s.run_number = 3
	s.hope = 2
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"self")
	assert_that(str(r.get("outcome", ""))).is_equal("true")
	assert_that(s.ending_seen).contains(&"true")

func test_self_blocked_below_run3() -> void:
	var s := _state_axis_ready()
	s.run_number = 2
	s.hope = 2
	s.insight = 10
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		s.relations[rid] = 3.0
	var r := EndingStateMachine.resolve_ending(s, &"self")
	assert_that(r.get("ok", false)).is_false()  # 三周目前 d 不亮不可选
```

- [ ] **Step 2: 跑测试确认失败**

Run: `godot --headless --path . --import` 然后单测 `--add res://tests/unit/test_ending_state_machine.gd -c`
Expected: FAIL（EndingStateMachine 未定义）

- [ ] **Step 3: 实现 EndingStateMachine**

`features/ending/ending_state_machine.gd`：

```gdscript
class_name EndingStateMachine
extends RefCounted

const INSIGHT_GOOD := 10
const GROWTH_AXIS := 1000.0
const HOPE_GOOD_GAIN := 1

static func _race_awakened(state: GameState, race_id: StringName) -> bool:
	return state.races.has(race_id) and bool(state.races[race_id].get("awakened", false))

static func _choices_before_axis_done(state: GameState) -> bool:
	for c in ChoiceLibrary.load_all():
		var cid := StringName(str(c.get("id", "")))
		if cid == &"world_axis":
			continue
		if not state.choices_done.has(cid):
			return false
	return true

static func _all_races_awakened(state: GameState) -> bool:
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		if not _race_awakened(state, rid):
			return false
	return true

static func axis_ready(state: GameState) -> bool:
	if not state.relics_found.has(9):
		return false
	if not _all_races_awakened(state):
		return false
	if not _choices_before_axis_done(state):
		return false
	if not state.storyteller_stories.has(&"story_6"):
		return false
	if not state.growth.is_greater_or_equal(BigNum.new(GROWTH_AXIS)):
		return false
	return true

static func _bonds_full(state: GameState) -> bool:
	for rid: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		if RelationActions.get_relation(state, rid) < 3.0:
			return false
	return true

static func _can_true(state: GameState) -> bool:
	return state.run_number >= 3 and state.hope >= 2 \
		and state.insight >= INSIGHT_GOOD and _bonds_full(state)

static func outcome_of(state: GameState, intent: StringName) -> StringName:
	match intent:
		&"refuse":
			return &"bad"
		&"self":
			return &"true" if _can_true(state) else &""
		&"return":
			if state.insight >= INSIGHT_GOOD and _bonds_full(state):
				return &"good"
			return &"normal"
		&"condense":
			return &"good" if state.insight >= INSIGHT_GOOD and _bonds_full(state) else (&"normal" if state.insight >= INSIGHT_GOOD else &"bad")
		_:
			return &""

static func resolve_ending(state: GameState, intent: StringName) -> Dictionary:
	var outcome := outcome_of(state, intent)
	if outcome == &"":
		return {"ok": false}
	var hope_before := state.hope
	if outcome == &"good":
		state.hope += HOPE_GOOD_GAIN
	if outcome == &"true":
		state.hope = 0  # 用在自己身上，圆满了
	if not state.ending_seen.has(outcome):
		state.ending_seen.append(outcome)
	return {"ok": true, "outcome": outcome, "hope_before": hope_before, "hope_after": state.hope}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `--add res://tests/unit/test_ending_state_machine.gd`（去 `-c`）
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add features/ending/ending_state_machine.gd features/ending/ending_state_machine.gd.uid tests/unit/test_ending_state_machine.gd tests/unit/test_ending_state_machine.gd.uid
git commit -m "feat: 终局状态机（世界之轴成型/四结局判定/希望结算）"
```

---

### Task 3: ReturnSequence（归还序列 7 步状态机 + 周目差分文本取用）

**Files:**
- Create: `features/ending/return_sequence.gd`
- Create: `features/ending/return_sequence.gd.uid`
- Test: `tests/unit/test_return_sequence.gd`
- Test: `tests/unit/test_return_sequence.gd.uid`

**Interfaces:**
- Consumes: `GameState.run_number`；`EndingStateMachine` outcome（`&"good"` 满 7 步 / `&"normal"`、`&"bad"` 拆 4-5 步停）。
- Produces:
  - `ReturnSequence.STEPS := 7`
  - `ReturnSequence.MAX_PARTIAL_STEP := 4`（普通/坏拆到第 4 步停）
  - `ReturnSequence.texts: Dictionary`（`{run: {step: String}}`，3 周目 × 7 步 = 21 段，文风六则；Task 4 填全文，本任务先填最小可测占位 + 一周目锚点权威文本）
  - `ReturnSequence.text_for(run: int, step: int) -> String`
  - `ReturnSequence.max_step_for(outcome: StringName) -> int`（good → 7；normal/bad → 4）
  - `ReturnSequence.halt_text(run: int) -> String`（普通/坏「拆到一半舍不得」停步文本，周目差分）

- [ ] **Step 1: 写失败测试**

`tests/unit/test_return_sequence.gd`：

```gdscript
extends GdUnitTestSuite

func test_good_goes_full_seven_steps() -> void:
	assert_that(ReturnSequence.max_step_for(&"good")).is_equal(7)

func test_normal_and_bad_stop_at_four() -> void:
	assert_that(ReturnSequence.max_step_for(&"normal")).is_equal(4)
	assert_that(ReturnSequence.max_step_for(&"bad")).is_equal(4)

func test_text_per_run_and_step_nonempty() -> void:
	for run: int in [1, 2, 3]:
		for step: int in range(1, 8):
			assert_that(str(ReturnSequence.text_for(run, step)).length()).is_greater(10)

func test_run_differs() -> void:
	# 每周目 7 步全套差分 → run1 step1 ≠ run2 step1
	assert_that(ReturnSequence.text_for(1, 1)).is_not_equal(ReturnSequence.text_for(2, 1))

func test_halt_text_nonempty() -> void:
	for run: int in [1, 2, 3]:
		assert_that(str(ReturnSequence.halt_text(run)).length()).is_greater(10)
```

- [ ] **Step 2: 跑测试确认失败**

Run: `--import` 然后 `--add res://tests/unit/test_return_sequence.gd -c`
Expected: FAIL（ReturnSequence 未定义）

- [ ] **Step 3: 实现 ReturnSequence（框架 + 一周目锚点权威文本，二/三周目占位待 Task 4 填）**

`features/ending/return_sequence.gd`：

```gdscript
class_name ReturnSequence
extends RefCounted

const STEPS := 7
const MAX_PARTIAL_STEP := 4
const PARTIAL_HALT_AFTER := 4  # normal/bad 拆到第 4 步后停

# 周目 × 步 → 文本。3 周目 × 7 步（全套差分）。文风六则。
const TEXTS := {
	1: {
		1: "你把叶子和光一起放下。树冠低了，天空重了一点。",
		2: "你拆下每一根枝。它们落进土里，变成别的树的骨架。",
		3: "你把根须一根一根从河里拔出来。河面泛起细小的涟漪——像告别。",
		4: "年轮一圈一圈松开。每一圈，都是你活过的一年。",
		5: "你把捞起的灵魂轻轻放回河底。它们下沉的时候，没有挣扎。",
		6: "最后，你低头看那点希望。你没有凝成什么——你把它种进了土壤。",
		7: "你看着自己。你不再是树了。你是一颗种子。一颗什么都不记得，但什么都愿意再试一次的种子。",
	},
	2: {
		1: "TASK4_RUN2_STEP1",
		2: "TASK4_RUN2_STEP2",
		3: "TASK4_RUN2_STEP3",
		4: "TASK4_RUN2_STEP4",
		5: "TASK4_RUN2_STEP5",
		6: "TASK4_RUN2_STEP6",
		7: "TASK4_RUN2_STEP7",
	},
	3: {
		1: "TASK4_RUN3_STEP1",
		2: "TASK4_RUN3_STEP2",
		3: "TASK4_RUN3_STEP3",
		4: "TASK4_RUN3_STEP4",
		5: "TASK4_RUN3_STEP5",
		6: "TASK4_RUN3_STEP6",
		7: "TASK4_RUN3_STEP7",
	},
}

# 普通/坏「拆到一半，忽然舍不得」停步文本（周目差分）
const HALT_TEXTS := {
	1: "你拆到一半，忽然舍不得了。你把剩下的部分拢了拢，凝成一点希望。",
	2: "TASK4_HALT_RUN2",
	3: "TASK4_HALT_RUN3",
}

static func text_for(run: int, step: int) -> String:
	var run_map: Dictionary = TEXTS.get(run, {})
	return str(run_map.get(step, ""))

static func halt_text(run: int) -> String:
	return str(HALT_TEXTS.get(run, ""))

static func max_step_for(outcome: StringName) -> int:
	if outcome == &"good" or outcome == &"true":
		return STEPS
	return MAX_PARTIAL_STEP
```

> ⚠️ `TASK4_*` 占位符**不是可交付内容**——Task 4 会替换为文风六则全文并跑 humanize-ai。本任务测试只断言非空与 run 间不同（占位已满足），Task 4 换全文后测试仍绿。

- [ ] **Step 4: 跑测试确认通过**

Run: `--add res://tests/unit/test_return_sequence.gd`（去 `-c`）
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add features/ending/return_sequence.gd features/ending/return_sequence.gd.uid tests/unit/test_return_sequence.gd tests/unit/test_return_sequence.gd.uid
git commit -m "feat: 归还序列 7 步状态机（周目差分文本框架 + 权威锚点）"
```

---

### Task 4: 归还序列 21 段周目差分全文（写作任务）

**Files:**
- Modify: `features/ending/return_sequence.gd`（替换 `TASK4_*` 占位）
- 写作产物归档：`docs/world-tree/narrative/11-ending-return.md`（新建，narrative 归档惯例）

**Interfaces:**
- Consumes: Task 3 的 `TEXTS` 结构（3 周目 × 7 步）+ `HALT_TEXTS`（3 段）。
- Produces: 完整 21 段归还文本 + 3 段停步文本，替换占位符。

- [ ] **Step 1: 读写作 skill（铁律 1）**

先读 `webnovel-writing` 或 `cw-prose-writing` 的写作规范 + `humanize-ai`（去 AI 味）——按 AGENTS.md 铁律 1 与文风六则执行。项目文风锚点见设计文档 §7.2 与 spec §8.3。

- [ ] **Step 2: 写 21 段差分文本**

三周目心境线：**一周目** = 茫然的第一次拆解（权威锚点文本，已含）；**二周目** = 记得的归还（「你记得这缕光」——你知道自己在重复，还得更清醒）；**三周目** = 带希望归还（呼应「一点半」——这一次，你是为了把希望种进土壤才还的）。

每段遵循文风六则：短句呼吸（每行 2-4 短句）/ 意象代替说明 / 留白不写尽 / 柔和如风 / 自然词汇（露光土风河火灰种子）/ 人称柔软。写入 `TEXTS[2]`、`TEXTS[3]` 与 `HALT_TEXTS[2]`、`HALT_TEXTS[3]`，替换所有 `TASK4_*` 占位。同步把全文归档到 `docs/world-tree/narrative/11-ending-return.md`。

- [ ] **Step 3: humanize-ai 自检**

用 humanize-ai 检查 21 段 + 3 段停步文本，消除 AI 味（句式整齐/总结陈词/套话），确保读起来像树的低语而非说明文。

- [ ] **Step 4: 跑测试确认全绿**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_return_sequence.gd`
Expected: PASS（占位符替换后非空与差分断言仍绿；若某段触发长度断言注意 >10）

- [ ] **Step 5: Commit**

```bash
git add features/ending/return_sequence.gd docs/world-tree/narrative/11-ending-return.md
git commit -m "feat: 归还序列 21 段周目差分全文（文风六则 + 归档）"
```

---

### Task 5: 二周目六事件（石裔 3 + 野民 3，多事件结构 + 周目门控）

**Files:**
- Modify: `features/relations/relation_events.gd`（加多事件支持 + 6 事件数据）
- Modify: `features/relations/relation_actions.gd`（interact 支持 event_id + run 门控）
- Test: `tests/unit/test_relation_actions.gd`（追加）
- Test: `tests/unit/test_relation_events.gd`（追加，若存在）

**Interfaces:**
- Consumes: `GameState.run_number`/`relation_events`（改为存 event_id，兼容旧 race_id）；`RelationEvents`。
- Produces:
  - `RelationEvents.EVENTS` 每族 1 事件保持（race_id 即 event_id 向后兼容），新增 `RelationEvents.EXTRA_EVENTS: Array[Dictionary]`（6 个：`{"event_id": &"stoneborn_run2_a", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=X", "text": ...}`）。
  - `RelationActions.can_interact_event(state, event_id) -> bool`；`RelationActions.interact_event(state, event_id) -> Dictionary`（+0.5，标记 event_id，幂等）。既有 `interact(race_id)` 保持（内部委托到 race 主事件）。

- [ ] **Step 1: 写失败测试**

`tests/unit/test_relation_actions.gd` 追加：

```gdscript
func _awaken_run(state: GameState, id: StringName, run: int) -> void:
	state.races[id] = {"awakened": true, "population": 10.0}
	state.run_number = run

func test_run2_events_hidden_in_run1() -> void:
	for ev in RelationEvents.extra_events():
		var s := GameState.new()
		_awaken_run(s, StringName(str(ev.get("race_id", &""))), 1)
		s.sap = BigNum.new(9999.0)
		assert_that(RelationActions.can_interact_event(s, StringName(str(ev.get("event_id", &""))))).is_false()

func test_run2_events_available_in_run2() -> void:
	for ev in RelationEvents.extra_events():
		var s := GameState.new()
		_awaken_run(s, StringName(str(ev.get("race_id", &""))), 2)
		s.sap = BigNum.new(9999.0)
		s.memory = BigNum.new(9999.0)
		assert_that(RelationActions.can_interact_event(s, StringName(str(ev.get("event_id", &""))))).is_true()

func test_run2_event_gives_half_and_once() -> void:
	var s := GameState.new()
	_awaken_run(s, &"stoneborn", 2)
	s.sap = BigNum.new(9999.0)
	var first_ev := RelationEvents.extra_events()[0]
	var eid := StringName(str(first_ev.get("event_id", &"")))
	var r := RelationActions.interact_event(s, eid)
	assert_that(r.get("ok", false)).is_true()
	assert_that(float(r.get("relation", 0.0))).is_equal_approx(0.5, 1e-4)
	assert_that(s.relation_events).contains(eid)
	assert_that(RelationActions.can_interact_event(s, eid)).is_false()  # 一次性

func test_extra_events_count_six() -> void:
	assert_that(RelationEvents.extra_events().size()).is_equal(6)

func test_extra_events_only_stoneborn_wildfolk() -> void:
	for ev in RelationEvents.extra_events():
		var race := StringName(str(ev.get("race_id", &"")))
		assert_that(race == &"stoneborn" or race == &"wildfolk").is_true()
```

- [ ] **Step 2: 跑测试确认失败**

Run: `--add res://tests/unit/test_relation_actions.gd -c`
Expected: FAIL（extra_events/interact_event 未定义）

- [ ] **Step 3: 扩展 RelationEvents（加 6 事件数据）**

`features/relations/relation_events.gd` 追加（注意 `condition` 沿既有字符串解析：`memory>=X`/`faith>=X`/`sap>=X`/`totem>=X`）：

```gdscript
# M6 二周目新增事件（run_gte=2；每族 3 个各 +0.5，补足两族到 +3 → 12/12）
const EXTRA_EVENTS: Array[Dictionary] = [
	# 石裔 ×3 —— 二周目「你记得」主题
	{"event_id": &"stoneborn_r2a", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=300",
		"text": "TASK5_SB_A"},
	{"event_id": &"stoneborn_r2b", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=600",
		"text": "TASK5_SB_B"},
	{"event_id": &"stoneborn_r2c", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=900",
		"text": "TASK5_SB_C"},
	# 野民 ×3
	{"event_id": &"wildfolk_r2a", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=2",
		"text": "TASK5_WF_A"},
	{"event_id": &"wildfolk_r2b", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=4",
		"text": "TASK5_WF_B"},
	{"event_id": &"wildfolk_r2c", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=5",
		"text": "TASK5_WF_C"},
]

static func extra_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in EXTRA_EVENTS:
		out.append(e.duplicate(true))
	return out

static func get_extra_event(event_id: StringName) -> Dictionary:
	for e in EXTRA_EVENTS:
		if e.get("event_id") == event_id:
			return e.duplicate(true)
	return {}
```

> ⚠️ `TASK5_*` 占位——Task 6 填全文。本任务测试不读文本内容（只查 ok/relation/幂等/计数），占位可过。

- [ ] **Step 4: 扩展 RelationActions（event 级 interact + run 门控）**

`features/relations/relation_actions.gd` 追加：

```gdscript
static func _condition_met_for(state: GameState, ev: Dictionary) -> bool:
	var cond := str(ev.get("condition", ""))
	if cond.is_empty():
		return true
	if cond.begins_with("memory>="):
		return state.memory.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("faith>="):
		return state.faith.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("sap>="):
		return state.sap.is_greater_or_equal(BigNum.new(float(cond.get_slice(">=", 1))))
	if cond.begins_with("totem>="):
		return TotemActions.visible_stage(state) >= int(float(cond.get_slice(">=", 1)))
	return false

static func can_interact_event(state: GameState, event_id: StringName) -> bool:
	var ev := RelationEvents.get_extra_event(event_id)
	if ev.is_empty():
		return false
	if state.run_number < int(ev.get("run_gte", 1)):
		return false
	var race_id := StringName(str(ev.get("race_id", &"")))
	if not _race_awakened(state, race_id):
		return false
	if state.relation_events.has(event_id):
		return false
	return _condition_met_for(state, ev)

static func interact_event(state: GameState, event_id: StringName) -> Dictionary:
	if not can_interact_event(state, event_id):
		return {"ok": false}
	var ev := RelationEvents.get_extra_event(event_id)
	var race_id := StringName(str(ev.get("race_id", &"")))
	apply_change(state, race_id, INTERACTION_GAIN)
	state.relation_events.append(event_id)
	return {"ok": true, "text": str(ev.get("text", "")), "relation": get_relation(state, race_id)}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `--add res://tests/unit/test_relation_actions.gd`
Expected: PASS（含既有用例回归）

- [ ] **Step 6: Commit**

```bash
git add features/relations/relation_events.gd features/relations/relation_actions.gd tests/unit/test_relation_actions.gd tests/unit/test_relation_actions.gd.uid
git commit -m "feat: 二周目六关系事件（石裔3+野民3，event 级多事件 + run 门控）"
```

---

### Task 6: 六事件文本全文（写作任务）

**Files:**
- Modify: `features/relations/relation_events.gd`（替换 `TASK5_*` 占位）
- 归档：`docs/world-tree/narrative/05-relations.md`（追加 M6 六事件段）

**Interfaces:**
- Consumes: Task 5 的 EXTRA_EVENTS 结构。
- Produces: 六事件完整文本。

- [ ] **Step 1: 写作 skill 检查（铁律 1）+ 文风六则**

内容方向（设计文档 §4.4）：
- 石裔 3：① 石裔梦见上一轮的刻痕（它们记得你的形状）；② 石裔献上「你上次折断的根须」做的碑；③ 石裔问「母树，你这次还会走吗？」
- 野民 3：① 野民画「上一轮的树」；② 首领说「图腾上的眼睛，见过你两次」；③ 野民把「你还给河的记忆」编进歌。
- 二周目主题 = 「你记得」——四族隐隐觉得这棵树回来过。

- [ ] **Step 2: 写 6 段文本替换占位**

沿既有 EVENTS 文本风格（2-4 行短句、意象、柔和），写入 `EXTRA_EVENTS` 的 text 字段。同步归档到 `docs/world-tree/narrative/05-relations.md`。

- [ ] **Step 3: humanize-ai 自检**

- [ ] **Step 4: 跑测试确认全绿**

Run: 全量 relation 测试套件
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add features/relations/relation_events.gd docs/world-tree/narrative/05-relations.md
git commit -m "feat: 二周目六事件全文（文风六则 + 归档）"
```

---

### Task 7: 明选⑦ 世界之轴卡片（JSON 外置 + d 选项 unlock）

**Files:**
- Modify: `features/choices/data/choices.json`（加 `world_axis` 卡）
- Modify: `features/choices/choice_actions.gd`（加 run_number/ending 相关 trigger 键支持）
- Modify: `autoloads/game_manager.gd`（终局入口 + 信号）
- Test: `tests/unit/test_choice_actions.gd`（追加）

**Interfaces:**
- Consumes: `ChoiceLibrary` JSON；`EndingStateMachine.axis_ready/outcome_of/resolve_ending`；`GameState`。
- Produces:
  - `choices.json` 新增 `world_axis` 卡（四选项 a/b/c/d，d 带 unlock `run_gte/insight_gte/relations_full/hope_gte`——但 unlock 键引擎现有只支持数值/关系——见 Step 1 设计约束）。
  - `ChoiceActions._trigger_met` 支持 `run_gte`、`relations_all_gte`；`option_unlocked` 同。
  - `GameManager` 新入口 `try_start_world_axis() -> bool`（axis_ready 时设 `_pending_choice = &"world_axis"` 发 `choice_available`）；`resolve_ending_choice(intent)` 走 EndingStateMachine 发 `ending_resolved`。

- [ ] **Step 1: 先写 trigger/unlock 键扩展的失败测试**

`tests/unit/test_choice_actions.gd` 追加：

```gdscript
func test_trigger_run_gte() -> void:
	var s := GameState.new()
	s.run_number = 1
	assert_that(ChoiceActions._trigger_met(s, {"run_gte": 2})).is_false()
	s.run_number = 2
	assert_that(ChoiceActions._trigger_met(s, {"run_gte": 2})).is_true()

func test_trigger_relations_all_gte() -> void:
	var s := GameState.new()
	s.relations[&"human"] = 3.0
	s.relations[&"forestfolk"] = 3.0
	s.relations[&"stoneborn"] = 3.0
	s.relations[&"wildfolk"] = 3.0
	assert_that(ChoiceActions._trigger_met(s, {"relations_all_gte": 3.0})).is_true()
	s.relations[&"wildfolk"] = 2.9
	assert_that(ChoiceActions._trigger_met(s, {"relations_all_gte": 3.0})).is_false()
```

- [ ] **Step 2: 跑测试确认失败**

Run: `--add res://tests/unit/test_choice_actions.gd -c`
Expected: FAIL

- [ ] **Step 3: 实现 trigger 键扩展**

`choice_actions.gd` `_trigger_met` 内（`soul_river_gte` 分支后）加：

```gdscript
	if trigger.has("run_gte"):
		if state.run_number < int(trigger["run_gte"]):
			return false
	if trigger.has("relations_all_gte"):
		var need_all := float(trigger["relations_all_gte"])
		for rid_all: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
			if RelationActions.get_relation(state, rid_all) < need_all:
				return false
```

- [ ] **Step 4: 跑测试确认通过**

Run: `--add res://tests/unit/test_choice_actions.gd`
Expected: PASS

- [ ] **Step 5: 加 world_axis 卡片到 choices.json**

```json
{
  "id": "world_axis",
  "title": "世界之轴",
  "stage_hint": "世界之轴·终局",
  "intro": "根须扎进冥河，树冠刺破天界。\n你第一次看清自己有多高。\n也看清，自己是用什么长成这样的。",
  "trigger": {},  # 注：world_axis 不走 tick 轮询，此 trigger 无效；真实闸门是 EndingStateMachine.axis_ready（try_start_world_axis 内部判定）
  "options": [
    {
      "id": "a",
      "text": "凝记忆为希望",
      "effects": { "ending_intent": "condense" },
      "result_text": "你把一生的记忆拢成一团，像拢一簇火。\n……然后，把它交给下一个自己。"
    },
    {
      "id": "b",
      "text": "拒绝",
      "effects": { "ending_intent": "refuse" },
      "result_text": "你不凝，也不还。\n你就站在那里。风穿过你。\n什么也没有发生——除了你还在。"
    },
    {
      "id": "c",
      "text": "把记忆还给河",
      "effects": { "ending_intent": "return" },
      "result_text": "你把记忆一颗一颗还给亡者之河。\n不是交还——是偿还。是归还一笔欠了太久的债。"
    },
    {
      "id": "d",
      "text": "……",
      "unlock": { "run_gte": 3, "relations_all_gte": 3.0, "insight_gte": 10, "hope_gte": 2 },
      "effects": { "ending_intent": "self" },
      "result_text": "你还有一点多余的希望。\n这世间还有一个人需要它。\n——你自己。"
    }
  ]
}
```

> `ending_intent` 是 ChoiceActions 不识别的新 effects 键——**必须**在 `_apply_effects` 加忽略守卫（见 Step 6），否则 resolve 会静默漏掉 intent。真实后果由 GameManager.resolve_ending_choice 消费。

- [ ] **Step 6: ChoiceActions 支持 ending_intent + hope_gte unlock**

`_apply_effects` 末尾加：

```gdscript
	if effects.has("ending_intent"):
		state.choice_flags.append(StringName("world_axis_intent_" + str(effects["ending_intent"])))
```

> 用 flag 记录玩家意图（`world_axis_intent_condense` 等），GameManager 消费 flag 而非直接调 EndingStateMachine（保持 ChoiceActions 纯数据，避免循环依赖）。

`_trigger_met` 加 `hope_gte` 支持（与 run_gte 同处）：

```gdscript
	if trigger.has("hope_gte"):
		if state.hope < int(trigger["hope_gte"]):
			return false
```

**关键：world_axis 卡不应走 `choices_done` 防重入的普通 resolve**——终局是停顿点后进状态机的特殊流程。resolve 普通分支会把它当一次性明选做完即消失。M6 需要它**可选多次吗**？不——选完进结局即周目结束/循环终止，无需再选。故 `resolve()` 仍会 append choices_done，但走 GameManager 的特殊入口（Step 7）在 resolve 后立即结算结局，UI 不再回主循环。

- [ ] **Step 7: GameManager 终局入口 + 信号 + available 排除守卫**

`choice_actions.gd` `available()` 加排除（world_axis 只走主动入口，防 tick 轮询条件不一致）：

```gdscript
static func available(state: GameState) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in ChoiceLibrary.load_all():
		var id := StringName(str(c.get("id", "")))
		if state.choices_done.has(id):
			continue
		if id == &"world_axis":
			continue  # 终局由 EndingStateMachine.axis_ready 主动门控，不进 tick 轮询
		if _trigger_met(state, c.get("trigger", {})):
			out.append(id)
	return out
```

`game_manager.gd` 加信号与入口：

```gdscript
signal ending_resolved(outcome: StringName, hope_after: int)
signal run_restarted(run_number: int)

func try_start_world_axis() -> bool:
	if _pending_choice != &"":
		return false
	if not EndingStateMachine.axis_ready(_state):
		return false
	_pending_choice = &"world_axis"
	var c := ChoiceLibrary.get_choice(&"world_axis")
	if c.is_empty():
		_pending_choice = &""
		return false
	choice_available.emit(&"world_axis", str(c.get("title", "")), str(c.get("intro", "")), c.get("options", []))
	return true
```

> ⚠️ **关键设计决策**：world_axis 卡**不进 `_check_choice_trigger` tick 轮询**——它由玩家主动入口 `try_start_world_axis()` 触发（内部用 `EndingStateMachine.axis_ready` 完整判定：环形废墟 + 四族醒 + 明选①—⑥完成 + 说书人⑥ + growth≥1000）。若让 JSON trigger 决定轮询，会出现 growth≥1000 + relic9 就弹、但四族未醒/卡未做完的不一致。**实现**：`ChoiceActions.available()` 需排除 world_axis（见 Step 7 守卫），world_axis 只走主动入口。

修改 `_check_choice_trigger` 无需改动（world_axis 被 available 排除后不进轮询）。resolve_choice 需在 resolve 后检查 ending_intent flag：

```gdscript
func resolve_choice(choice_id: StringName, option_id: StringName) -> Dictionary:
	# ...既有逻辑...
	var result := ChoiceActions.resolve(_state, choice_id, option_id)
	if not result.get("ok", false):
		return result
	_pending_choice = &""
	# M6：world_axis 结算 → 终局状态机
	if choice_id == &"world_axis":
		return _settle_world_axis(option_id, result)
	# ...既有 emit/resource_changed...
	return result

func _settle_world_axis(option_id: StringName, result: Dictionary) -> Dictionary:
	var intent := &"condense"
	match option_id:
		&"a": intent = &"condense"
		&"b": intent = &"refuse"
		&"c": intent = &"return"
		&"d": intent = &"self"
	var er := EndingStateMachine.resolve_ending(_state, intent)
	if not er.get("ok", false):
		return {"ok": false, "reason": "ending_blocked"}
	ending_resolved.emit(StringName(str(er.get("outcome", &""))), int(er.get("hope_after", 0)))
	SaveManager.save(_state, SAVE_PATH)
	return er
```

- [ ] **Step 8: 跑测试确认通过**

Run: 全量 test_choice_actions + test_game_manager
Expected: PASS（新增用例 + 既有回归）

- [ ] **Step 9: Commit**

```bash
git add features/choices/data/choices.json features/choices/choice_actions.gd autoloads/game_manager.gd tests/unit/test_choice_actions.gd tests/unit/test_game_manager.gd
git commit -m "feat: 明选⑦世界之轴卡 + 终局结算入口（ending_intent flag 通路）"
```

---

### Task 8: GameManager.restart_run（周目切换）

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `features/game/save_manager.gd`（若需强制落盘）
- Test: `tests/unit/test_game_manager.gd`（追加）

**Interfaces:**
- Consumes: `GameState.new_run_preserved`（Task 1）；`SaveManager`。
- Produces: `GameManager.restart_run() -> Dictionary`（周目重置：`_state = GameState.new_run_preserved(_state)`，保存，发 `run_restarted`，返回新 run_number）。

- [ ] **Step 1: 写失败测试**

`tests/unit/test_game_manager.gd` 追加（沿既有 GM 测试模式——const preload + new）：

```gdscript
# ⚠️ M2 教训 #4：autoload 单例不可 GameManager.new()。需 const GM := preload("res://autoloads/game_manager.gd") 再 .new()（纯逻辑测试）——实施时先读既有 test_game_manager.gd 顶部确认其构造模式并照抄。
func test_restart_run_preserves_and_increments() -> void:
	var gm := GM.new()
	var st := gm.get_state()
	st.hope = 2
	st.insight = 11
	st.relations[&"human"] = 3.0
	var r := gm.restart_run()
	assert_that(r.get("ok", false)).is_true()
	assert_that(int(r.get("run_number", 0))).is_equal(2)
	var st2 := gm.get_state()
	assert_that(st2.hope).is_equal(2)
	assert_that(st2.insight).is_equal(11)
	assert_that(st2.relations).is_empty()
```

> ⚠️ 需先读既有 `test_game_manager.gd` 确认 GM 构造/存档隔离模式（可能用 `SaveManager` mock 或临时 user 路径）再落地测试体。实施时按该文件既有模式对齐。

- [ ] **Step 2: 跑测试确认失败**

Run: `--add res://tests/unit/test_game_manager.gd -c`
Expected: FAIL（restart_run 未定义）

- [ ] **Step 3: 实现 restart_run**

`game_manager.gd` 加：

```gdscript
func restart_run() -> Dictionary:
	_state = GameState.new_run_preserved(_state)
	_pending_choice = &""
	SaveManager.save(_state, SAVE_PATH)
	run_restarted.emit(int(_state.run_number))
	return {"ok": true, "run_number": int(_state.run_number)}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `--add res://tests/unit/test_game_manager.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/unit/test_game_manager.gd tests/unit/test_game_manager.gd.uid
git commit -m "feat: 周目切换 restart_run（余烬保留 + 存档 + run_restarted 信号）"
```

---

### Task 9: 三周目快进（浓缩快进周目开局赠予）

**Files:**
- Create: `features/ending/run_boost.gd`
- Create: `features/ending/run_boost.gd.uid`
- Test: `tests/unit/test_run_boost.gd`
- Test: `tests/unit/test_run_boost.gd.uid`

**Interfaces:**
- Consumes: `GameState.run_number`；BigNum。
- Produces: `RunBoost.apply_boost(state: GameState) -> void`（run≥3 时赠予起步资源/解锁；run<3 无操作）。

- [ ] **Step 1: 写失败测试**

`tests/unit/test_run_boost.gd`：

```gdscript
extends GdUnitTestSuite

func test_no_boost_below_run3() -> void:
	var s := GameState.new()
	s.run_number = 2
	RunBoost.apply_boost(s)
	assert_that(float(s.sap.to_value())).is_equal_approx(0.0, 1e-4)
	assert_that(s.lingua_life_level).is_equal(0)

func test_boost_run3_gives_headstart() -> void:
	var s := GameState.new()
	s.run_number = 3
	RunBoost.apply_boost(s)
	assert_that(s.sap.to_value()).is_greater(0.0)
	assert_that(s.memory.to_value()).is_greater(0.0)
	assert_that(s.faith.to_value()).is_greater(0.0)
	assert_that(s.growth.to_value()).is_greater(0.0)
```

- [ ] **Step 2: 跑测试确认失败**

Run: `--import` 后 `--add res://tests/unit/test_run_boost.gd -c`
Expected: FAIL（RunBoost 未定义）

- [ ] **Step 3: 实现 RunBoost（数值估值，试玩可调）**

`features/ending/run_boost.gd`：

```gdscript
class_name RunBoost
extends RefCounted

# 三周目浓缩快进（spec §8.6）：开局赠予，直扑终局。数值估值待试玩调优。
const BOOST_SAP := 5000.0
const BOOST_MEMORY := 80.0
const BOOST_FAITH := 200.0
const BOOST_GROWTH := 600.0
const BOOST_LEAF := 3
const BOOST_ROOT := 3
const BOOST_LIFE_LV := 2
const BOOST_FLAGS: Array[StringName] = [&"tree_canopy", &"root_resonance", &"cloud_crown", &"grace"]

static func apply_boost(state: GameState) -> void:
	if state.run_number < 3:
		return
	state.sap.add(BigNum.new(BOOST_SAP))
	state.memory.add(BigNum.new(BOOST_MEMORY))
	state.faith.add(BigNum.new(BOOST_FAITH))
	state.growth.add(BigNum.new(BOOST_GROWTH))
	state.leaf_level = maxi(state.leaf_level, BOOST_LEAF)
	state.root_depth = maxi(state.root_depth, BOOST_ROOT)
	state.lingua_life_level = maxi(state.lingua_life_level, BOOST_LIFE_LV)
	for f in BOOST_FLAGS:
		if not state.choice_flags.has(f):
			state.choice_flags.append(f)
	# 明选全开：已完成卡保留（跨周目知识 flag），本局可触发卡正常轮询
```

- [ ] **Step 4: 跑测试确认通过**

Run: `--add res://tests/unit/test_run_boost.gd`
Expected: PASS

- [ ] **Step 5: 接入 restart_run（run3 开局调用）**

`game_manager.gd` `restart_run()` 里 `SaveManager.save` 前加：

```gdscript
	if _state.run_number >= 3:
		RunBoost.apply_boost(_state)
```

（restart_run 测试断言不受影响：run1→2 不触发 boost。）

- [ ] **Step 6: 全量回归 + commit**

Run: 全量单测
Expected: PASS
```bash
git add features/ending/run_boost.gd features/ending/run_boost.gd.uid tests/unit/test_run_boost.gd tests/unit/test_run_boost.gd.uid autoloads/game_manager.gd
git commit -m "feat: 三周目浓缩快进（开局赠予直扑终局）"
```

---

### Task 10: UI 接入（世界之轴入口 / 归还序列面板 / 结算画面 / 周目开局层叠）

**Files:**
- Modify: `features/ui/main.gd`
- Modify: `features/ui/main.tscn`
- Test: `tests/unit/test_main_ui.gd`（追加，若存在 UI 测试模式）

**Interfaces:**
- Consumes: GameManager 全部新信号（`ending_resolved`/`run_restarted`）+ `try_start_world_axis`/`restart_run`；EndingStateMachine/ReturnSequence/RunBoost 只读查询。
- Produces: UI 呈现（世界之轴按钮、归还序列逐点、结算、周目文本层叠）。

- [ ] **Step 1: 读 main.gd/main.tscn 现状定位挂载点**

读 `features/ui/main.gd` 找：明选弹层处理（`choice_available`/`resolve_choice` 按钮）、`race_event_label` 播报位、资源区布局、420×640 滚动容器。读 `main.tscn` 找按钮/弹层节点结构（M6 按钮加在哪、VBox/Scroll 层级）。

- [ ] **Step 2: UI 加世界之轴按钮 + 归还/结算弹层（main.gd）**

在 main.gd 依 main.tscn 既有模式：
- 世界之轴按钮：`axis_ready` 时 visible；`pressed` → `try_start_world_axis()`。
- 明选弹层已通用（world_axis 卡自动走 choice_available/resolve_choice）。resolve 后若 option 是 world_axis → 显示归还序列面板（`ReturnSequence` 逐点）或结局画面。
- `ending_resolved` 信号 → 结算画面（结局文案 + 希望变化 + 「再次醒来」按钮 → `restart_run()`；真结局无再醒按钮，改「回到标题」）。
- `run_restarted` → 开局文本层叠（按 run_number 显示 spec §8.6 层叠句）+ `RunBoost` 已由 GameManager 应用。

> 具体节点名/信号连接以 main.tscn 实际结构为准；本任务 UI 测试若项目无 UI 单测模式则降级为 headless 冒烟验证（见 Step 4）。

- [ ] **Step 3: 追加 UI 测试（若有既有模式）或写冒烟脚本**

查 `tests/unit/` 是否有 main UI 测试（M5h 加了 `test_main_ui.gd`）。若有：追加「世界之轴按钮 visible 门控」「ending_resolved 触发结算层」断言。若测试基建无法覆盖 UI 节点可见性，改为临时 E2E 脚本验证（验证后删除，沿项目惯例）。

- [ ] **Step 4: 验证**

Run: 全量单测全绿 + `godot --headless --path . --quit-after 5`（无 SCRIPT ERROR 即通过）
Expected: PASS + 冒烟无错

- [ ] **Step 5: Commit**

```bash
git add features/ui/main.gd features/ui/main.tscn tests/unit/test_main_ui.gd tests/unit/test_main_ui.gd.uid
git commit -m "feat: UI 终局入口/归还序列/结算画面/周目层叠"
```

---

### Task 11: 全量回归 + 文档同步 + M6 封板记录

**Files:**
- Modify: `docs/world-tree/CONTINUE.md`（M6 状态表）
- Modify: `docs/world-tree/ROADMAP.md`（M6 完成）
- Modify: `AGENTS.md`（交接基线节）
- 可能：`docs/superpowers/plans/2026-09-05-m6-ending-multirun.md`（勾选 ✅）

- [ ] **Step 1: 全量测试回归**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全绿（基线 366 + 新增；无 orphan 报错）

- [ ] **Step 2: headless 冒烟**

Run: `godot --headless --path . --quit-after 5`
Expected: 无 SCRIPT ERROR

- [ ] **Step 3: 补 E2E 真实链路（一次性脚本，验证后删）**

写临时 E2E：人族唤醒 → 攒到 growth 1000 + relic 9 + 六卡 + story6 → `try_start_world_axis` true → resolve c → outcome normal/good 按关系 → `restart_run` → run_number 2 → 六事件可达 →（run3 合成 hope2/关系满/领悟满）→ resolve d → true → 循环终止。验证后删除脚本。

- [ ] **Step 4: 同步文档**

CONTINUE.md 状态表加 M6 行（✅ 完成 + 测试数）；ROADMAP.md 加 M6 完成注；AGENTS.md 交接基线更新为「M6 已封板，下一步 M6-D 九界/世界之语/奇迹」；计划文档勾选 ✅。

- [ ] **Step 5: Commit**

```bash
git add docs/world-tree/CONTINUE.md docs/world-tree/ROADMAP.md AGENTS.md docs/superpowers/plans/2026-09-05-m6-ending-multirun.md
git commit -m "docs: M6 终局+多周目封板记录 + 路线图同步"
```

---

## Self-Review 记录

**Spec 覆盖核对：**
- §1 终局触发（里程碑门）→ Task 2 axis_ready + Task 7 world_axis 卡 + Task 10 UI 入口 ✓
- §2 明选⑦ 四路径 → Task 7 ✓
- §3 四结局判定 + 希望结算 → Task 2 ✓
- §4 周目门控 + 六事件 → Task 5/6 ✓
- §5 周目切换/重置 → Task 1 new_run_preserved + Task 8 ✓
- §6 真结局（run3 + 隐藏选项 d + 循环终止）→ Task 2 _can_true + Task 7 d unlock ✓
- §7 归还序列 7 步 + 周目差分 → Task 3/4 ✓
- §8 架构（features/ending/ + run_number/ending_seen）→ Task 1/2/3/9 ✓
- §9 测试 → 各 Task 内嵌 ✓
- 三周目快进 → Task 9 ✓
- UI → Task 10 ✓

**遗留风险（已知，非阻塞）：**
1. Task 8 的 GameManager 测试需先读既有 test_game_manager.gd 确认构造/存档隔离模式（M2 教训 #4：autoload 单例不可 new，需 const preload）。实施时对齐。
2. Task 10 UI 节点名依赖 main.tscn 实际结构，计划只给了挂载原则，实施时读文件定位。
3. Task 4/6 是写作任务，占位符替换需保证测试长度断言（>10 字）满足。
4. `resolve_choice` 改造（Task 7 Step 7）影响既有 choice 流程——实施时确保非 world_axis 卡行为不变（新增分支只在 choice_id==world_axis 触发）。
5. world_axis 卡会进 `_check_choice_trigger` tick 轮询（growth≥1000 + relic9 满足即自动弹）——设计上「里程碑门 + 明选常驻」两路径并存可接受；若主人不想要 tick 自动弹，可后续把 world_axis 从 available() 排除、只走 try_start_world_axis（一行守卫，实施时确认）。

---

## 首轮 Code Review 修复记录（2026-09-06）

- [x] 二周目六个关系事件接入 `GameManager.interact_relation()` 和 UI 可用性判定，并验证同族三事件顺序推进。
- [x] `GameState` 新增持久化 `pending_ending`；世界之轴结算与归还步进即时保存，启动后可恢复，兼容迁移已锁死的旧存档。
- [x] `EndingStateMachine` 的归还分支补领悟门槛：领悟不足判为坏结局。
- [x] 忒修斯/体验机器的知识奖励增加稳定 `knowledge_id`，领悟与真相只在首次掌握时发放。
- [x] 归还序列增加 `树留存度 ↓ / 世界复苏度 ↑` 的互补进度，UI 同步显示并保证合计 100%。
- [x] 交接文档分支名统一为 `main`。

**验证结果**：37 套件 / 435 测试全绿（0 失败、0 flaky、0 skipped、0 orphan）；隔离 `user://` 的 headless 主场景启动与存档写入成功，无 SCRIPT ERROR。沙箱内仍会记录 Windows 根证书库不可读，不影响离线 GDScript 游戏逻辑。
