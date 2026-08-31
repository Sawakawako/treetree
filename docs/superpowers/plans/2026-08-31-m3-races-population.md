# 世界树 里程碑 3（四族 + 人口 S 曲线）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 HumanManager 泛化为数据驱动的 RaceManager，加入林地民/石裔/野民三族，落地人口 S 曲线（逻辑斯蒂增长、供养负担、虔诚加权信仰、树高驱动承载）——完成"四族归位 + 人口经济学"。

**Architecture:** 沿用 Layer Cake 与 M2 模式：`RaceData`（Resource，`.tres` 数据驱动，spec §15）定义四族数据；`RaceManager`（RefCounted 纯静态）取代 `HumanManager`（注册表 + 唤醒判定 + 每 tick 经济）；`GameState` 增 `races` 字典（旧档 `human_awakened` 迁移兼容）；`GameManager` 每 tick 调 `tick_races` 并转发 `race_awakened` 信号；UI 只监听信号 + `_refresh`。

**Tech Stack:** Godot 4.7.1（mono）+ GDScript（typed）+ GdUnit4 6.2.1（headless）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-m3-races-population-design.md`（本计划唯一权威，argue from spec）；主规格 `docs/superpowers/specs/2026-08-31-world-tree-design.md`（§5/§13.9/§14.4/§14.5/§15）

## Global Constraints

- **测试命令**（GdUnit4 6.2.1，不是 `--run-tests`）：
  - 全量：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
  - 单文件：同命令加 `--add res://tests/unit/test_xxx.gd`
  - **新增 class_name 脚本或 .tres 后先跑** `godot --headless --path . --import`（否则类未注册/资源未导入）
- **`is_equal_approx` 双参签名** `(expected, approx)`——断言统一带容差 `, 1e-4`
- 资源一律 `BigNum`（禁裸 float 存资源）；typed GDScript
- 中文文件一律用 edit/write 工具（禁 PowerShell 默认编码——曾致乱码事故）
- **文风铁律**：唤醒事件文本**必须逐字复制**设计文档 §5.1（已按诗歌化·柔和六则定稿），不得重写；人族唤醒文本沿用 M2 版
- 存档兼容：M2 旧档（含 `human_awakened` 字段）载入后迁移进 `races`，不得损坏
- `.tres` 与 `.uid` 文件一并入库（Godot 4.4+ 自动生成）
- git master；每任务一个 commit
- 工作目录：`E:\world tree`

---

### Task 1: RaceData 框架 + 四族 `.tres` 数据

**Files:**
- Create: `features/races/race_data.gd`
- Create: `features/races/data/human.tres`、`forestfolk.tres`、`stoneborn.tres`、`wildfolk.tres`
- Test: `tests/unit/test_race_data.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name RaceData extends Resource`，字段：`id: StringName`、`display_name: String`、`awaken_condition: String`（`"memory>=2"` 或 `"faith>=N"`）、`awaken_pop: float`、`growth_rate: float`、`support_cost: float`、`devotion: float`、`produce_memory: bool`、`craft_sap: float`（献工系数，非石裔为 0.0）、`awaken_text: String`。后续任务通过 `load("res://features/races/data/<id>.tres")` 取用。

- [ ] **Step 1: 写失败测试**（test_race_data.gd）

```gdscript
extends GdUnitTestSuite

func _load(id: String) -> RaceData:
	return load("res://features/races/data/%s.tres" % id) as RaceData

func test_all_four_races_load() -> void:
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		assert_that(_load(id)).is_not_null()

func test_human_fields() -> void:
	var d := _load("human")
	assert_that(d.id).is_equal(&"human")
	assert_that(d.awaken_condition).is_equal("memory>=2")
	assert_that(d.awaken_pop).is_equal_approx(50.0, 1e-4)
	assert_that(d.produce_memory).is_true()
	assert_that(d.awaken_text.length()).is_greater(10)

func test_forestfolk_fields() -> void:
	var d := _load("forestfolk")
	assert_that(d.awaken_condition).is_equal("faith>=30")
	assert_that(d.devotion).is_equal_approx(1.8, 1e-4)
	assert_that(d.produce_memory).is_false()

func test_stoneborn_craft_sap() -> void:
	var d := _load("stoneborn")
	assert_that(d.awaken_condition).is_equal("faith>=60")
	assert_that(d.craft_sap).is_equal_approx(0.01, 1e-4)

func test_wildfolk_fields() -> void:
	var d := _load("wildfolk")
	assert_that(d.awaken_condition).is_equal("faith>=100")
	assert_that(d.devotion).is_equal_approx(0.3, 1e-4)
	assert_that(d.growth_rate).is_equal_approx(0.02, 1e-4)

func test_all_conditions_format_valid() -> void:
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		var cond := _load(id).awaken_condition
		var ok := cond == "memory>=2" or cond.begins_with("faith>=")
		assert_that(ok).is_true()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_race_data.gd`
Expected: FAIL（无法解析 RaceData / .tres 不存在）

- [ ] **Step 3: 实现 race_data.gd**

```gdscript
class_name RaceData
extends Resource

@export var id: StringName
@export var display_name: String
@export var awaken_condition: String
@export var awaken_pop: float = 0.0
@export var growth_rate: float = 0.0
@export var support_cost: float = 0.0
@export var devotion: float = 0.0
@export var produce_memory: bool = false
@export var craft_sap: float = 0.0
@export var awaken_text: String
```

- [ ] **Step 4: 写四个 .tres**（文本逐字复制设计文档 §5.1；人族文本沿用 M2 版）

`features/races/data/human.tres`：

```
[gd_resource type="Resource" script_class="RaceData" load_steps=2 format=3]

[ext_resource type="Script" path="res://features/races/race_data.gd" id="1_race"]

[resource]
script = ExtResource("1_race")
id = &"human"
display_name = "人族"
awaken_condition = "memory>=2"
awaken_pop = 50.0
growth_rate = 0.01
support_cost = 0.002
devotion = 1.0
produce_memory = true
craft_sap = 0.0
awaken_text = "土里传来一个苍老的声音：\n「你在听吗？……我是最后一个说梦的人。我梦见你很多年了。」"
```

`features/races/data/forestfolk.tres`：

```
[gd_resource type="Resource" script_class="RaceData" load_steps=2 format=3]

[ext_resource type="Script" path="res://features/races/race_data.gd" id="1_race"]

[resource]
script = ExtResource("1_race")
id = &"forestfolk"
display_name = "林地民"
awaken_condition = "faith>=30"
awaken_pop = 30.0
growth_rate = 0.006
support_cost = 0.001
devotion = 1.8
produce_memory = false
craft_sap = 0.0
awaken_text = "林子深处，先有一声。\n不是鸟。\n不是风。\n是很多年以前，有人把歌种进土里，如今发了芽。\n\n他们从树根上醒来，浑身是苔，指尖是叶脉。\n看见你，他们先是一愣，然后笑了——\n开口，就是一整座森林的合唱。\n\n「母树。我们梦见你很久了。\n我们唱歌，你就不孤单。」"
```

`features/races/data/stoneborn.tres`：

```
[gd_resource type="Resource" script_class="RaceData" load_steps=2 format=3]

[ext_resource type="Script" path="res://features/races/race_data.gd" id="1_race"]

[resource]
script = ExtResource("1_race")
id = &"stoneborn"
display_name = "石裔"
awaken_condition = "faith>=60"
awaken_pop = 20.0
growth_rate = 0.005
support_cost = 0.003
devotion = 0.6
produce_memory = false
craft_sap = 0.01
awaken_text = "你听见地底传来闷响。\n一下，一下，有节奏。\n不是心跳。\n是锤。\n\n他们从岩层里起身，指节粗大如卵石，眼睛像淬火的炭。\n不唱歌，不祈祷。\n打量你的年轮，像打量一块料。\n\n「树。」\n他们没有再说第二句。\n锤声落进土里，把地夯实。\n他们不献梦。\n他们献的是——手，和接下来的日子。"
```

`features/races/data/wildfolk.tres`：

```
[gd_resource type="Resource" script_class="RaceData" load_steps=2 format=3]

[ext_resource type="Script" path="res://features/races/race_data.gd" id="1_race"]

[resource]
script = ExtResource("1_race")
id = &"wildfolk"
display_name = "野民"
awaken_condition = "faith>=100"
awaken_pop = 80.0
growth_rate = 0.02
support_cost = 0.001
devotion = 0.3
produce_memory = false
craft_sap = 0.0
awaken_text = "夜里，石壁前多了一圈眼睛。\n半蹲在月光与阴影之间，毛发覆体，兽瞳发亮。\n不靠近，也不离开。\n只是在看。\n\n你忽然发现，石壁上多了一幅画。\n线条很旧，像画了很久。\n画的是一棵树——\n树冠遮天，根须伸进河流。\n河在变浅。\n\n它们在画你。\n它们从第一天就在画你。"
```

- [ ] **Step 5: 运行确认通过**

Run: `godot --headless --path . --import`（导入 .tres/生成 .uid）→ 单文件测试
Expected: PASS（6 用例）；随后 `git add features/races/ tests/unit/test_race_data.gd tests/unit/test_race_data.gd.uid`（.uid 一并入库）

- [ ] **Step 6: Commit**

```bash
git add -A features/races tests/unit/test_race_data.gd tests/unit/test_race_data.gd.uid
git commit -m "feat: RaceData 数据驱动框架 + 四族 .tres（含唤醒事件文本）"
```

---

### Task 2: GameState 扩展 `races` + 旧档迁移

**Files:**
- Modify: `features/game/game_state.gd`
- Modify: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: 无新依赖
- Produces: `GameState.races: Dictionary`（`{id: {"awakened": bool, "population": float}}`）；`to_dict()` 含 `"races"`（`human_awakened` 字段**暂保留**，T6 删）；`from_dict()` 对 M2 旧档（有 `human_awakened` 无 `races`）迁移人族状态，缺字段回退默认。`_init` 时 `races = {}`。

- [ ] **Step 1: 写失败测试**（test_game_state.gd 追加）

```gdscript
func test_races_serialization_roundtrip() -> void:
	var s := GameState.new()
	s.races["human"] = {"awakened": true, "population": 58.5}
	s.races["forestfolk"] = {"awakened": false, "population": 0.0}
	var back := GameState.from_dict(s.to_dict())
	assert_that(back.races.has("human")).is_true()
	assert_that(back.races["human"]["awakened"]).is_true()
	assert_that(float(back.races["human"]["population"])).is_equal_approx(58.5, 1e-4)
	assert_that(back.races["forestfolk"]["awakened"]).is_false()

func test_old_save_human_awakened_migrates() -> void:
	# M2 旧档：无 races 但有 human_awakened —— 迁移人族状态
	var back := GameState.from_dict({"human_awakened": true, "tick": 5})
	assert_that(back.races.has("human")).is_true()
	assert_that(back.races["human"]["awakened"]).is_true()
	assert_that(float(back.races["human"]["population"])).is_equal_approx(50.0, 1e-4)

func test_races_missing_fallback() -> void:
	var back := GameState.from_dict({"tick": 1})
	assert_that(back.races.is_empty()).is_true()

func test_races_partial_entry_fallback() -> void:
	# races 条目缺 population —— 回退默认 0 不损坏
	var back := GameState.from_dict({"races": {"human": {"awakened": true}}})
	assert_that(float(back.races["human"]["population"])).is_equal_approx(0.0, 1e-4)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_game_state.gd`
Expected: FAIL（`races` 不存在）

- [ ] **Step 3: 扩展 game_state.gd**

```gdscript
# 新字段（_init 附近）：
var races: Dictionary = {}

# to_dict() 中追加：
"races": races,
# （human_awakened 行保留到 T6）

# from_dict() 中，human_awakened 行之后追加：
var rd: Dictionary = d.get("races", {})
if rd.is_empty() and d.has("human_awakened"):
	rd = {"human": {"awakened": bool(d.get("human_awakened", false)),
			"population": 50.0 if bool(d.get("human_awakened", false)) else 0.0}}
s.races = {}
for race_id: Variant in rd:
	var entry: Dictionary = rd[race_id]
	s.races[race_id] = {
		"awakened": bool(entry.get("awakened", false)),
		"population": float(entry.get("population", 0.0)),
	}
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（4 新用例 + 旧用例无回归；`human_awakened` 相关旧断言仍绿——字段保留）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 扩展 races 字典 + M2 旧档迁移"
```

---

### Task 3: RaceManager 注册表 + 唤醒判定

**Files:**
- Create: `features/races/race_manager.gd`
- Test: `tests/unit/test_race_manager.gd`

**Interfaces:**
- Consumes: `RaceData`（T1，load `.tres`）、`GameState.races`（T2）
- Produces: `class_name RaceManager extends RefCounted`：
  - `static func get_race(id: StringName) -> RaceData`
  - `static func all_races() -> Array[RaceData]`
  - `static func check_awaken(state: GameState, race: RaceData) -> bool`（条件满足且未唤醒时：置 `races[id] = {"awakened": true, "population": race.awaken_pop}` 返回 true；已唤醒返回 false——幂等）
  - 唤醒条件解析：`"memory>=2"` → `state.memory >= 2`；`"faith>=N"` → `state.faith >= N`

- [ ] **Step 1: 写失败测试**（test_race_manager.gd）

```gdscript
extends GdUnitTestSuite

func test_registry_four_races() -> void:
	assert_that(RaceManager.all_races().size()).is_equal(4)
	assert_that(RaceManager.get_race(&"human")).is_not_null()
	assert_that(RaceManager.get_race(&"wildfolk")).is_not_null()

func test_human_awaken_at_memory_2() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(2.0)
	var race := RaceManager.get_race(&"human")
	assert_that(RaceManager.check_awaken(s, race)).is_true()
	assert_that(s.races["human"]["awakened"]).is_true()
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.0, 1e-4)
	# 幂等：已唤醒不再触发
	assert_that(RaceManager.check_awaken(s, race)).is_false()

func test_human_not_awaken_below_2() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(1.99)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"human"))).is_false()

func test_forestfolk_awaken_at_faith_30() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(30.0)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"forestfolk"))).is_true()
	assert_that(float(s.races["forestfolk"]["population"])).is_equal_approx(30.0, 1e-4)

func test_forestfolk_not_awaken_below_30() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(29.9)
	assert_that(RaceManager.check_awaken(s, RaceManager.get_race(&"forestfolk"))).is_false()

func test_stoneborn_wildfolk_thresholds() -> void:
	var s1 := GameState.new()
	s1.faith = BigNum.new(60.0)
	assert_that(RaceManager.check_awaken(s1, RaceManager.get_race(&"stoneborn"))).is_true()
	var s2 := GameState.new()
	s2.faith = BigNum.new(100.0)
	assert_that(RaceManager.check_awaken(s2, RaceManager.get_race(&"wildfolk"))).is_true()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . --import` 后单文件测试
Expected: FAIL（无法解析 RaceManager）

- [ ] **Step 3: 实现 race_manager.gd**（第一部分）

```gdscript
class_name RaceManager
extends RefCounted

const FAITH_EFF := 0.002
const MEMORY_EFF := 0.001

static var _registry: Dictionary = {}
static var _registry_loaded := false

static func _ensure_registry() -> void:
	if _registry_loaded:
		return
	_registry_loaded = true
	_registry.clear()
	for id in ["human", "forestfolk", "stoneborn", "wildfolk"]:
		var data := load("res://features/races/data/%s.tres" % id) as RaceData
		if data != null:
			_registry[data.id] = data

static func get_race(id: StringName) -> RaceData:
	_ensure_registry()
	return _registry.get(id)

static func all_races() -> Array[RaceData]:
	_ensure_registry()
	return _registry.values()

static func _is_awakened(state: GameState, id: StringName) -> bool:
	return state.races.has(id) and bool(state.races[id].get("awakened", false))

static func check_awaken(state: GameState, race: RaceData) -> bool:
	if _is_awakened(state, race.id):
		return false
	var ok := false
	if race.awaken_condition == "memory>=2":
		ok = state.memory.is_greater_or_equal(BigNum.new(2.0))
	elif race.awaken_condition.begins_with("faith>="):
		var threshold := float(race.awaken_condition.get_slice(">=", 1))
		ok = state.faith.is_greater_or_equal(BigNum.new(threshold))
	if ok:
		state.races[race.id] = {"awakened": true, "population": race.awaken_pop}
	return ok
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（6 用例）

- [ ] **Step 5: Commit**

```bash
git add features/races/race_manager.gd tests/unit/test_race_manager.gd tests/unit/test_race_manager.gd.uid
git commit -m "feat: RaceManager 注册表 + 四族唤醒判定（数据驱动条件）"
```

---

### Task 4: RaceManager 人口与经济（供养/增长/产出/承载）

**Files:**
- Modify: `features/races/race_manager.gd`（追加）
- Modify: `tests/unit/test_race_manager.gd`（追加）

**Interfaces:**
- Consumes: `RaceManager.check_awaken`（T3）、`GameState`（sap/growth/faith/memory/races）
- Produces:
  - `static func tick_races(state: GameState) -> Array[Dictionary]`（每 tick 顺序：唤醒判定 → 供养扣除（clamp≥0）→ 人口逻辑斯蒂增长（sap>0 才增长，clamp≤capacity）→ 产出（信仰/记忆/献工树液）；返回本次唤醒事件 `[{"race_id", "race_name", "awaken_text"}, ...]`）
  - `static func capacity(state: GameState) -> float`（`100 × (1 + 树繁茂)`；繁茂 = growth≥300→2、≥100→1、否则 0）

- [ ] **Step 1: 写失败测试**（test_race_manager.gd 追加）

```gdscript
func _awaken(state: GameState, id: StringName) -> void:
	RaceManager.check_awaken(state, RaceManager.get_race(id))

func test_support_deducted() -> void:
	var s := GameState.new()
	_awaken(s, &"human")  # pop 50 × 0.002 = 0.1
	s.sap = BigNum.new(10.0)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(9.9, 1e-4)

func test_support_clamps_at_zero() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.sap = BigNum.new(0.05)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_logistic_growth() -> void:
	var s := GameState.new()
	_awaken(s, &"human")  # pop 50, rate 0.01, cap 100
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	# 50 + 50×0.01×(1−50/100) = 50.25
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.25, 1e-4)

func test_growth_frozen_when_sap_zero() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.sap = BigNum.new(0.0)
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_equal_approx(50.0, 1e-4)

func test_growth_capped_at_capacity() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.growth = BigNum.new(100.0)  # cap 200
	s.sap = BigNum.new(1000.0)
	s.races["human"]["population"] = 199.0
	RaceManager.tick_races(s)
	assert_that(float(s.races["human"]["population"])).is_less_equal(200.0)

func test_faith_production() -> void:
	var s := GameState.new()
	_awaken(s, &"human")      # 增长后 pop 50.25 → 50.25×1.0×0.002 = 0.1005
	_awaken(s, &"forestfolk") # 增长后 pop 30.126 → 30.126×1.8×0.002 = 0.1084536
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	assert_that(s.faith.to_value()).is_equal_approx(0.2089536, 1e-4)

func test_memory_production_human_only() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	_awaken(s, &"forestfolk")
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	# 人族增长后 50.25 × 0.001 = 0.05025；林地民不产记忆
	assert_that(s.memory.to_value()).is_equal_approx(0.05025, 1e-4)

func test_stoneborn_craft_sap() -> void:
	var s := GameState.new()
	_awaken(s, &"stoneborn")  # pop 20 → 增长后 20.08；供养 0.06；献工 20.08×0.01=0.2008
	s.sap = BigNum.new(100.0)
	RaceManager.tick_races(s)
	assert_that(s.sap.to_value()).is_equal_approx(100.1408, 1e-4)  # 100 − 0.06 + 0.2008

func test_capacity_growth_mapping() -> void:
	var s := GameState.new()
	s.growth = BigNum.new(99.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(100.0, 1e-4)
	s.growth = BigNum.new(100.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(200.0, 1e-4)
	s.growth = BigNum.new(300.0)
	assert_that(RaceManager.capacity(s)).is_equal_approx(300.0, 1e-4)

func test_tick_returns_awaken_events() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(100.0)
	s.sap = BigNum.new(1000.0)
	var events: Array[Dictionary] = RaceManager.tick_races(s)
	assert_that(events.size()).is_equal(3)  # 林地民/石裔/野民同 tick 苏醒
	assert_that(events[0].has("race_name")).is_true()
	assert_that(str(events[0]["awaken_text"]).length()).is_greater(10)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（`tick_races` / `capacity` 不存在）

- [ ] **Step 3: 实现 tick_races + capacity**（race_manager.gd 追加）

```gdscript
static func capacity(state: GameState) -> float:
	var boom := 0
	if state.growth.to_value() >= 300.0:
		boom = 2
	elif state.growth.to_value() >= 100.0:
		boom = 1
	return 100.0 * (1.0 + float(boom))

static func tick_races(state: GameState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	# 1) 唤醒判定
	for race in all_races():
		if check_awaken(state, race):
			events.append({
				"race_id": race.id, "race_name": race.display_name,
				"awaken_text": race.awaken_text,
			})
	# 2) 供养
	var support := 0.0
	for race in all_races():
		if _is_awakened(state, race.id):
			support += float(state.races[race.id]["population"]) * race.support_cost
	state.sap.sub(BigNum.new(support))
	if state.sap.to_value() < 0.0:
		state.sap = BigNum.new(0.0)
	# 3) 人口增长（供养后 sap > 0 才增长）
	if state.sap.to_value() > 0.0:
		var cap := capacity(state)
		for race in all_races():
			if not _is_awakened(state, race.id):
				continue
			var pop := float(state.races[race.id]["population"])
			var growth := pop * race.growth_rate * (1.0 - pop / cap)
			state.races[race.id]["population"] = minf(pop + growth, cap)
	# 4) 产出
	for race in all_races():
		if not _is_awakened(state, race.id):
			continue
		var pop := float(state.races[race.id]["population"])
		state.faith.add(BigNum.new(pop * race.devotion * FAITH_EFF))
		if race.produce_memory:
			state.memory.add(BigNum.new(pop * MEMORY_EFF))
		if race.craft_sap > 0.0:
			state.sap.add(BigNum.new(pop * race.craft_sap))
	return events
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（9 新用例 + 前 6 用例无回归，共 15）

- [ ] **Step 5: Commit**

```bash
git add features/races/race_manager.gd tests/unit/test_race_manager.gd
git commit -m "feat: RaceManager 经济（供养/逻辑斯蒂人口/虔诚信仰/记忆引擎/石裔献工/树高承载）"
```

---

### Task 5: GameManager 集成 + `race_awakened` 信号（含 main.gd 同步）

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `features/ui/main.gd`（信号连接 + 唤醒播报 + `HumanEventLabel` 改名 `RaceEventLabel`）
- Modify: `features/ui/main.tscn`（HumanEventLabel → RaceEventLabel）
- Modify: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: `RaceManager.tick_races`（T4）、`GameState.races`（T2）
- Produces:
  - `signal race_awakened(race_id: StringName, race_name: String, awaken_text: String)`（取代 `human_awakened`）
  - `_process` tick 分支：`GameLoop.tick` → `RaceManager.tick_races` → 逐事件 emit `race_awakened` → 存档 → `resources_changed`
  - `is_human_awakened() -> bool`（改读 `races["human"]`）
  - `get_race(id: StringName) -> RaceData`（UI 兜底播报用）
  - 删除 `_try_awaken` 与所有 `HumanManager` 调用

- [ ] **Step 1: 更新测试**（test_game_manager.gd——预期行为变化：M2 平铺 `tick=10 信仰+1.0` → M3 公式 `+0.1`；信号改名）

```gdscript
func test_getters() -> void:
	gm._state = GameState.new()
	gm._state.memory = BigNum.new(5.0)
	gm._state.faith = BigNum.new(3.0)
	gm._state.root_depth = 2
	gm._state.races["human"] = {"awakened": true, "population": 50.0}
	assert_that(gm.get_memory().to_value()).is_equal_approx(5.0, 1e-4)
	assert_that(gm.get_faith().to_value()).is_equal_approx(3.0, 1e-4)
	assert_that(gm.get_root_depth()).is_equal(2)
	assert_that(gm.is_human_awakened()).is_true()

func test_human_awakens_during_play() -> void:
	# C1 回归（M3 语义）：游戏中记忆≥2 后，tick 链路必须触发唤醒
	gm._state = GameState.new()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	assert_that(gm.get_memory().to_value()).is_equal_approx(2.0, 1e-4)
	assert_that(gm.is_human_awakened()).is_false()
	gm._process(1.0)
	assert_that(gm.is_human_awakened()).is_true()

func test_race_awakened_signal_emitted() -> void:
	# I4 回归（M3）：唤醒时发出 race_awakened（含种族名与文本）
	gm._state = GameState.new()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	var got := {"awakened": false, "name": ""}
	gm.race_awakened.connect(func(id: StringName, name: String, text: String) -> void:
		got["awakened"] = true
		got["name"] = name)
	gm._process(1.0)
	assert_that(got["awakened"]).is_true()
	assert_that(got["name"]).is_equal("人族")

func test_human_produces_faith_after_awaken() -> void:
	# M3 公式：唤醒后每 tick 产 50×1.0×0.002 = 0.1 信仰（原 M2 平铺 +1.0 已废弃）
	gm._state = GameState.new()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	gm._state.sap = BigNum.new(200.0)
	gm.explore_relic()
	gm._state.tick = 9
	gm._process(1.0)
	assert_that(gm.is_human_awakened()).is_true()
	assert_that(gm.get_faith().to_value()).is_equal_approx(0.1, 1e-4)
```

（`test_explore_relic_signal` 不变。）

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（`race_awakened` 不存在 / 信仰断言 0.1 未达 / `races` 读法未实现）

- [ ] **Step 3: 改 game_manager.gd**

```gdscript
# 信号区：
signal resources_changed
signal relic_discovered(relic_name: String, dream_text: String)
signal race_awakened(race_id: StringName, race_name: String, awaken_text: String)
# 删除 signal human_awakened

# _ready：
func _ready() -> void:
	_state = SaveManager.load_or_create(SAVE_PATH)

# _process 的 tick 分支：
func _process(delta: float) -> void:
	_tick_accumulator += delta
	if _tick_accumulator >= TICK_INTERVAL:
		_tick_accumulator -= TICK_INTERVAL
		GameLoop.tick(_state)
		var events: Array[Dictionary] = RaceManager.tick_races(_state)
		for ev in events:
			race_awakened.emit(ev["race_id"], ev["race_name"], ev["awaken_text"])
		if GameLoop.should_auto_save(_state):
			SaveManager.save(_state, SAVE_PATH)
		resources_changed.emit()

# 删除 _try_awaken；新增/改写：
func is_human_awakened() -> bool:
	return _state.races.has(&"human") and bool(_state.races[&"human"].get("awakened", false))

func get_race(id: StringName) -> RaceData:
	return RaceManager.get_race(id)
```

- [ ] **Step 4: 改 main.gd / main.tscn**

main.gd：

```gdscript
# @onready 中：human_event_label → race_event_label（%RaceEventLabel）

# _ready 中：
GameManager.race_awakened.connect(_on_race_awakened)
if GameManager.is_human_awakened():
	var human := GameManager.get_race(&"human")
	_on_race_awakened(human.id, human.display_name, human.awaken_text)

func _on_race_awakened(race_id: StringName, race_name: String, awaken_text: String) -> void:
	race_event_label.text = awaken_text
```

main.tscn：`[node name="HumanEventLabel" ...]` → `[node name="RaceEventLabel" ...]`（其余属性不变）

- [ ] **Step 5: 运行确认通过**

Run: `godot --headless --path . --import` → 单文件（test_game_manager）→ 全量
Expected: 单文件 PASS；全量测试其余套件无回归

- [ ] **Step 6: Commit**

```bash
git add autoloads/game_manager.gd features/ui/main.gd features/ui/main.tscn tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 切换 RaceManager（tick_races/race_awakened 信号）"
```

---

### Task 6: 清理 HumanManager / `human_awakened` 字段

**Files:**
- Delete: `features/races/human_manager.gd`、`features/races/human_manager.gd.uid`
- Delete: `tests/unit/test_human_manager.gd`、`tests/unit/test_human_manager.gd.uid`
- Modify: `features/game/game_state.gd`（删 `human_awakened` 字段与 to_dict/from_dict 对应行；**from_dict 的旧档迁移逻辑保留**）
- Modify: `tests/unit/test_game_state.gd`（`human_awakened` 断言改 `races`）

**Interfaces:**
- Consumes: T5 完成后 `HumanManager` 已无引用
- Produces: 无（纯清理）

- [ ] **Step 1: 更新 test_game_state.gd 断言**

```gdscript
func test_new_fields_initial() -> void:
	var s := GameState.new()
	assert_that(s.memory.to_value()).is_equal(0.0)
	assert_that(s.faith.to_value()).is_equal(0.0)
	assert_that(s.root_depth).is_equal(0)
	assert_that(s.races.is_empty()).is_true()
	assert_that(s.relics_found).is_empty()

func test_new_fields_serialization_roundtrip() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(3.0)
	s.faith = BigNum.new(7.0)
	s.root_depth = 2
	s.races["human"] = {"awakened": true, "population": 50.0}
	s.relics_found.assign([1, 2])
	var back := GameState.from_dict(s.to_dict())
	assert_that(back.memory.to_value()).is_equal_approx(3.0, 1e-4)
	assert_that(back.faith.to_value()).is_equal_approx(7.0, 1e-4)
	assert_that(back.root_depth).is_equal(2)
	assert_that(back.races["human"]["awakened"]).is_true()
	assert_that(back.relics_found).contains(1)

func test_old_save_fallback() -> void:
	var back := GameState.from_dict({"tick": 5})
	assert_that(back.memory.to_value()).is_equal(0.0)
	assert_that(back.faith.to_value()).is_equal(0.0)
	assert_that(back.root_depth).is_equal(0)
	assert_that(back.races.is_empty()).is_true()
	assert_that(back.relics_found).is_empty()
	assert_that(back.tick).is_equal(5)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（`human_awakened` 断言仍指向旧字段——先删字段再跑绿，本步先确认测试已改）

- [ ] **Step 3: 清理 game_state.gd + 删除文件**

game_state.gd：删除 `var human_awakened: bool = false`、to_dict 的 `"human_awakened": human_awakened,` 行、from_dict 的 `s.human_awakened = bool(d.get("human_awakened", false))` 行（**保留** `if rd.is_empty() and d.has("human_awakened")` 迁移块——读旧档仍需它）。
删除 `features/races/human_manager.gd(.uid)`、`tests/unit/test_human_manager.gd(.uid)`。

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . --import` → 全量测试
Expected: 全量 PASS（原 61 − 5 人族平铺用例 + 已增 M3 用例；HumanManager 无引用错误）

- [ ] **Step 5: Commit**

```bash
git rm features/races/human_manager.gd features/races/human_manager.gd.uid tests/unit/test_human_manager.gd tests/unit/test_human_manager.gd.uid
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "refactor: 移除 HumanManager 与 human_awakened 字段（人族并入 RaceManager）"
```

---

### Task 7: UI 四族面板

**Files:**
- Modify: `features/ui/main.tscn`（VBox 追加四族面板）
- Modify: `features/ui/main.gd`（`_refresh` 更新四族行）

**Interfaces:**
- Consumes: `GameManager.get_state()`、`GameManager.get_race(id)`（T5）、`GameState.races`
- Produces: `%RaceHumanLabel` / `%RaceForestLabel` / `%RaceStoneLabel` / `%RaceWildLabel`（每行显示 名称 + 状态）

- [ ] **Step 1: 追加 main.tscn 节点**（`HumanEventLabel` 之后）

```
[node name="RaceHumanLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "人族：未苏醒（记忆 2）"

[node name="RaceForestLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "林地民：未苏醒（信仰 30）"

[node name="RaceStoneLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "石裔：未苏醒（信仰 60）"

[node name="RaceWildLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "野民：未苏醒（信仰 100）"
```

- [ ] **Step 2: 扩展 main.gd**

```gdscript
# @onready 追加：
@onready var race_human_label: Label = %RaceHumanLabel
@onready var race_forest_label: Label = %RaceForestLabel
@onready var race_stone_label: Label = %RaceStoneLabel
@onready var race_wild_label: Label = %RaceWildLabel

# 常量（文件顶部）：
const RACE_ROWS := {
	&"human": "人族",
	&"forestfolk": "林地民",
	&"stoneborn": "石裔",
	&"wildfolk": "野民",
}

# _refresh() 末尾追加：
_refresh_race_rows()

func _refresh_race_rows() -> void:
	var s := GameManager.get_state()
	for id: StringName in RACE_ROWS:
		var data := GameManager.get_race(id)
		var label: Label = null
		match id:
			&"human": label = race_human_label
			&"forestfolk": label = race_forest_label
			&"stoneborn": label = race_stone_label
			&"wildfolk": label = race_wild_label
		if label == null:
			continue
		if s.races.has(id) and bool(s.races[id].get("awakened", false)):
			var pop := float(s.races[id].get("population", 0.0))
			label.text = "%s：人口 %d" % [RACE_ROWS[id], int(pop)]
		else:
			label.text = "%s：未苏醒" % RACE_ROWS[id]
```

- [ ] **Step 3: 验证**

Run: `godot --headless --path . --import` → 全量测试（无回归）→ `godot --headless --path . --quit-after 5`（无 SCRIPT ERROR）

- [ ] **Step 4: Commit**

```bash
git add features/ui/main.tscn features/ui/main.gd
git commit -m "feat: UI 四族面板（状态/人口显示）"
```

---

### Task 8: 集成验证与端到端

**Files:**
- Modify: 无（验证；临时脚本验证后删除）

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全部 PASS、0 failures、退出码 0

- [ ] **Step 2: 端到端玩法验证（临时脚本，验证后删除）**

`_verify_m3.gd`（`extends SceneTree`，模拟：人族唤醒 → 三族陆续唤醒 → 人口增长 → 供养/产出 → 存档往返 → M2 旧档迁移 → 输出 `M3 E2E VERIFY PASSED` 或逐项 PASS/FAIL）：

```gdscript
extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	# 1. 人族唤醒链路（M2 C1 回归）
	var s := GameState.new()
	s.sap = BigNum.new(1000.0)
	s.memory = BigNum.new(2.0)
	var events: Array[Dictionary] = RaceManager.tick_races(s)
	if not (s.races.has(&"human") and bool(s.races[&"human"]["awakened"])):
		failures.append("human awaken")
	# 2. 三族陆续唤醒（faith 100 → 3 事件）
	var s2 := GameState.new()
	s2.faith = BigNum.new(100.0)
	s2.sap = BigNum.new(1000.0)
	var ev2: Array[Dictionary] = RaceManager.tick_races(s2)
	if ev2.size() != 3:
		failures.append("three races awaken: got %d" % ev2.size())
	# 3. 人口增长 + 供养 + 产出 30 tick
	var s3 := GameState.new()
	s3.memory = BigNum.new(2.0)
	s3.faith = BigNum.new(100.0)
	s3.sap = BigNum.new(1000.0)
	s3.growth = BigNum.new(100.0)  # cap 200
	for i in 30:
		RaceManager.tick_races(s3)
	var total_pop := 0.0
	for id in RaceManager.all_races():
		if s3.races.has(id.id) and bool(s3.races[id.id]["awakened"]):
			total_pop += float(s3.races[id.id]["population"])
	if total_pop <= 0.0:
		failures.append("population not growing")
	if s3.faith.to_value() <= 0.0:
		failures.append("faith not produced")
	# 4. 存档往返含 races
	var back := GameState.from_dict(s3.to_dict())
	if not back.races.has(&"human"):
		failures.append("save roundtrip races")
	# 5. M2 旧档迁移
	var legacy := GameState.from_dict({"human_awakened": true, "tick": 5})
	if not (legacy.races.has(&"human") and bool(legacy.races[&"human"]["awakened"])):
		failures.append("legacy migration")
	if failures.is_empty():
		print("M3 E2E VERIFY PASSED")
		quit(0)
	else:
		print("M3 E2E FAILED: ", failures)
		quit(1)
```

Run: `godot --headless --path . -s res://_verify_m3.gd`
Expected: 输出 `M3 E2E VERIFY PASSED`、退出码 0

- [ ] **Step 3: 清理 + 提交**

删除 `_verify_m3.gd`；`git status` 确认工作区干净；如有修复则提交。

---

## Self-Review 记录（写完计划时自查）

- **设计文档覆盖**：§3.1 RaceData ✓（T1）；§3.2 RaceManager ✓（T3/T4）；§3.3 GameState+迁移 ✓（T2/T6）；§3.4 GameManager ✓（T5）；§3.5 UI ✓（T5 信号 + T7 面板）；§4 数值 ✓（T4 全部公式与系数）；§5.1 唤醒文本 ✓（T1 .tres 逐字）；§5.2 四族面板 ✓（T7）；§6 测试矩阵 ✓（T1/T2/T3/T4/T5/T8）；§7 决策记录 ✓（T6 清理 + T8 E2E 验证迁移）。
- **占位符扫描**：无 TBD/TODO；所有测试与实现代码完整给出。
- **类型一致性**：`RaceData.id: StringName` 与 `StringName` 字面量 `&"human"` 一致；`check_awaken(state, race: RaceData)`、`tick_races(state) -> Array[Dictionary]`、`capacity(state) -> float` 在 T3/T4/T5 引用一致；`race_awakened(race_id: StringName, race_name: String, awaken_text: String)` 在 T5 的 GameManager/main.gd/test 三处签名一致；`races[id] = {"awakened", "population"}` 结构在 T2（序列化）、T3（写入）、T4（读取）、T5（is_human_awakened）、T7（UI）一致。
- **已知行为变更（有意）**：M2「每 10/20 tick 平铺」→ M3 §14.5 公式——`test_human_produces_faith_after_awaken` 预期 1.0 → 0.1（T5 更新）；`human_awakened` 信号 → `race_awakened`（T5）；`HumanManager`/`human_awakened` 字段删除（T6）。
- **迁移安全**：M2 旧档 `human_awakened: true` → `races["human"].awakened=true, population=50`（T2 测试 + T8 E2E 第 5 项）；`to_dict` 幂等（T2 roundtrip 测试）。
