# 世界树 里程碑 5d（增量深度：升级总表扩展）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 扩展升级总表 5 类可重复升级（叶绿体/木质部/花盘/螺舱/根须等级）——补「赚钱→买升级→赚更多」循环与消耗端；螺舱引入宽裕树液储量上限（初始 10000）。

**Architecture:** 沿用 M1 模式：`CostCalculator` 加 5 类成本（四型曲线）；`GameState` 加 5 个等级字段；`GameActions`（features/economy/actions.gd）加 5 个购买动作；`GameLoop.tick` 光合/生长公式乘系数 + sap clamp；`RaceManager`/`PlunderActions` 产出接入花盘/根须；`GameManager` 入口 + UI 按钮。

**Tech Stack:** Godot 4.7.1（mono）+ GDScript（typed）+ GdUnit4 6.2.1（headless）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-m5d-idle-depth-design.md`（本计划唯一权威）；主规格 §14.1/§14.3

## Global Constraints

- **测试命令**（GdUnit4 6.2.1，不是 `--run-tests`）：
  - 全量：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
  - 单文件：同命令加 `--add res://tests/unit/test_xxx.gd`；可加 `-c` 关 fail-fast
  - **新增 class_name 脚本后先跑** `godot --headless --path . --import`
- **`is_equal_approx` 双参签名** `(expected, approx)`——断言统一带容差 `, 1e-4`
- 资源一律 `BigNum`；typed GDScript
- 中文文件一律用 write/edit 工具（禁 PowerShell 默认编码）
- 存档兼容：M1-M5b 旧档缺等级字段回退 0；旧档 sap 超 cap 时 tick clamp 自动收敛（不破坏存档）
- `.uid` 文件入库（新增 class_name 后确认）
- git master；每任务一个 commit；工作目录 `E:\world tree`

---

### Task 1: CostCalculator 扩展（5 类成本）

**Files:**
- Modify: `features/economy/cost_calculator.gd`
- Modify: `tests/unit/test_cost_calculator.gd`（若不存在则新建）

**Interfaces:**
- Consumes: 无（现有 `fib(n)`）
- Produces: `chloroplast_cost(level) -> int`（800×1.6^L）/ `xylem_cost(level) -> int`（50×(L+1)）/ `sunflower_cost(level) -> int`（2000×fib(L+1)）/ `nautilus_cost(level) -> int`（2000×fib(L+1)）/ `root_eff_cost(level) -> int`（1000×1.8^L）

- [ ] **Step 1: 写失败测试**

```gdscript
extends GdUnitTestSuite

func test_chloroplast_cost_exponential() -> void:
	assert_that(CostCalculator.chloroplast_cost(0)).is_equal(800)
	assert_that(CostCalculator.chloroplast_cost(1)).is_equal(1280)   # 800×1.6
	assert_that(CostCalculator.chloroplast_cost(2)).is_equal(2048)   # 800×1.6²

func test_xylem_cost_linear() -> void:
	assert_that(CostCalculator.xylem_cost(0)).is_equal(50)
	assert_that(CostCalculator.xylem_cost(1)).is_equal(100)
	assert_that(CostCalculator.xylem_cost(2)).is_equal(150)

func test_sunflower_cost_fibonacci() -> void:
	assert_that(CostCalculator.sunflower_cost(0)).is_equal(2000)    # 2000×fib(1)
	assert_that(CostCalculator.sunflower_cost(1)).is_equal(2000)    # 2000×fib(2)
	assert_that(CostCalculator.sunflower_cost(2)).is_equal(4000)    # 2000×fib(3)

func test_nautilus_cost_fibonacci() -> void:
	assert_that(CostCalculator.nautilus_cost(0)).is_equal(2000)
	assert_that(CostCalculator.nautilus_cost(2)).is_equal(4000)

func test_root_eff_cost_exponential() -> void:
	assert_that(CostCalculator.root_eff_cost(0)).is_equal(1000)
	assert_that(CostCalculator.root_eff_cost(1)).is_equal(1800)     # 1000×1.8
	assert_that(CostCalculator.root_eff_cost(2)).is_equal(3240)     # 1000×1.8²
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试（`--add res://tests/unit/test_cost_calculator.gd`）
Expected: FAIL（函数不存在）

- [ ] **Step 3: 扩展 cost_calculator.gd**

```gdscript
static func chloroplast_cost(level: int) -> int:
	return int(800.0 * pow(1.6, float(level)))

static func xylem_cost(level: int) -> int:
	return 50 * (level + 1)

static func sunflower_cost(level: int) -> int:
	return 2000 * fib(level + 1)

static func nautilus_cost(level: int) -> int:
	return 2000 * fib(level + 1)

static func root_eff_cost(level: int) -> int:
	return int(1000.0 * pow(1.8, float(level)))
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（5 用例）

- [ ] **Step 5: Commit**

```bash
git add features/economy/cost_calculator.gd tests/unit/test_cost_calculator.gd
git commit -m "feat: CostCalculator 5 类成本（指数/线性/斐波那契四型曲线）"
```

---

### Task 2: GameState 扩展（5 个等级字段）

**Files:**
- Modify: `features/game/game_state.gd`
- Modify: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: 无
- Produces: `chloroplast_level/xylem_level/sunflower_level/nautilus_level/root_eff_level: int = 0`；序列化 + 缺字段回退 0

- [ ] **Step 1: 写失败测试**（test_game_state.gd 追加）

```gdscript
func test_upgrade_levels_roundtrip() -> void:
	var s := GameState.new()
	s.chloroplast_level = 2
	s.xylem_level = 1
	s.sunflower_level = 3
	s.nautilus_level = 1
	s.root_eff_level = 2
	var back := GameState.from_dict(s.to_dict())
	assert_that(back.chloroplast_level).is_equal(2)
	assert_that(back.xylem_level).is_equal(1)
	assert_that(back.sunflower_level).is_equal(3)
	assert_that(back.nautilus_level).is_equal(1)
	assert_that(back.root_eff_level).is_equal(2)

func test_upgrade_levels_missing_fallback() -> void:
	var back := GameState.from_dict({"tick": 5})
	assert_that(back.chloroplast_level).is_equal(0)
	assert_that(back.xylem_level).is_equal(0)
	assert_that(back.sunflower_level).is_equal(0)
	assert_that(back.nautilus_level).is_equal(0)
	assert_that(back.root_eff_level).is_equal(0)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（字段不存在）

- [ ] **Step 3: 扩展 game_state.gd**

```gdscript
# 新字段（relation_events 附近）：
var chloroplast_level: int = 0
var xylem_level: int = 0
var sunflower_level: int = 0
var nautilus_level: int = 0
var root_eff_level: int = 0

# to_dict() 中追加：
"chloroplast_level": chloroplast_level,
"xylem_level": xylem_level,
"sunflower_level": sunflower_level,
"nautilus_level": nautilus_level,
"root_eff_level": root_eff_level,

# from_dict() 中追加：
s.chloroplast_level = int(d.get("chloroplast_level", 0))
s.xylem_level = int(d.get("xylem_level", 0))
s.sunflower_level = int(d.get("sunflower_level", 0))
s.nautilus_level = int(d.get("nautilus_level", 0))
s.root_eff_level = int(d.get("root_eff_level", 0))
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（2 新用例 + 旧用例无回归）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 5 个升级等级字段（存档回退）"
```

---

### Task 3: GameActions 购买动作（5 类）

**Files:**
- Modify: `features/economy/actions.gd`
- Modify: `tests/unit/test_actions.gd`

**Interfaces:**
- Consumes: `CostCalculator`（T1）、`GameState`（T2）
- Produces: `buy_chloroplast/buy_xylem/buy_sunflower/buy_nautilus/buy_root_eff(state) -> bool`（统一模式：sap ≥ cost → 扣减 + level+1 → true）

- [ ] **Step 1: 写失败测试**（test_actions.gd 追加）

```gdscript
func test_buy_chloroplast_success() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(800.0)
	assert_that(GameActions.buy_chloroplast(s)).is_true()
	assert_that(s.chloroplast_level).is_equal(1)
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_buy_chloroplast_insufficient() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(799.0)
	assert_that(GameActions.buy_chloroplast(s)).is_false()
	assert_that(s.chloroplast_level).is_equal(0)

func test_buy_xylem_sunflower_nautilus_root() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(10000.0)
	assert_that(GameActions.buy_xylem(s)).is_true()
	assert_that(GameActions.buy_sunflower(s)).is_true()
	assert_that(GameActions.buy_nautilus(s)).is_true()
	assert_that(GameActions.buy_root_eff(s)).is_true()
	assert_that(s.xylem_level).is_equal(1)
	assert_that(s.sunflower_level).is_equal(1)
	assert_that(s.nautilus_level).is_equal(1)
	assert_that(s.root_eff_level).is_equal(1)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（buy_* 不存在）

- [ ] **Step 3: 扩展 actions.gd**（沿用 buy_leaf 模式）

```gdscript
static func buy_chloroplast(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.chloroplast_cost(state.chloroplast_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.chloroplast_level += 1
	return true

static func buy_xylem(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.xylem_cost(state.xylem_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.xylem_level += 1
	return true

static func buy_sunflower(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.sunflower_cost(state.sunflower_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.sunflower_level += 1
	return true

static func buy_nautilus(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.nautilus_cost(state.nautilus_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.nautilus_level += 1
	return true

static func buy_root_eff(state: GameState) -> bool:
	var cost := BigNum.new(float(CostCalculator.root_eff_cost(state.root_eff_level)))
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.root_eff_level += 1
	return true
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试
Expected: PASS（3 新用例 + 旧用例无回归）

- [ ] **Step 5: Commit**

```bash
git add features/economy/actions.gd tests/unit/test_actions.gd
git commit -m "feat: GameActions 5 类购买动作"
```

---

### Task 4: GameLoop 公式接入（光合/生长/sap clamp）

**Files:**
- Modify: `features/game/game_loop.gd`
- Modify: `tests/unit/test_game_loop.gd`（若不存在则新建）

**Interfaces:**
- Consumes: `GameState`（chloroplast_level/xylem_level/nautilus_level，T2）
- Produces: `GameLoop.tick` 光合/生长公式乘系数；`static func sap_cap(state: GameState) -> float`（10000 + 5000×nautilus_level）；tick 末尾 sap clamp

- [ ] **Step 1: 写失败测试**

```gdscript
extends GdUnitTestSuite

func test_chloroplast_boosts_photosynthesis() -> void:
	var s := GameState.new()
	s.daylight = BigNum.new(100.0)
	s.chloroplast_level = 2
	GameLoop.tick(s)
	# 光合：100 × (0.1 + 0.01×2) = 12
	assert_that(s.sap.to_value()).is_equal_approx(12.0, 1e-4)

func test_xylem_boosts_growth() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(100.0)
	s.xylem_level = 1
	GameLoop.tick(s)
	# 生长：100 × 0.01 × (1 + 0.05×1) = 1.05
	assert_that(s.growth.to_value()).is_equal_approx(1.05, 1e-4)

func test_sap_clamped_to_cap() -> void:
	var s := GameState.new()
	s.daylight = BigNum.new(200000.0)  # 光合巨大
	s.sap = BigNum.new(99999.0)  # 存量已超默认 cap 10000
	GameLoop.tick(s)
	# clamp：min(99999+光合, 10000) = 10000
	assert_that(s.sap.to_value()).is_equal_approx(10000.0, 1e-4)

func test_nautilus_raises_cap() -> void:
	var s := GameState.new()
	s.nautilus_level = 1
	assert_that(GameLoop.sap_cap(s)).is_equal_approx(15000.0, 1e-4)
	s.nautilus_level = 2
	assert_that(GameLoop.sap_cap(s)).is_equal_approx(20000.0, 1e-4)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（光合/生长公式未变 / sap_cap 不存在）

- [ ] **Step 3: 修改 game_loop.gd**

```gdscript
static func sap_cap(state: GameState) -> float:
	return 10000.0 + 5000.0 * float(state.nautilus_level)

static func tick(state: GameState) -> void:
	state.tick += 1
	var eff := 1.0 + 0.25 * float(state.leaf_level)
	var collected := BigNum.new(float(state.branch_level) * eff)
	state.daylight.add(collected)
	# 光合（树液转化）——叶绿体：0.1 + 0.01×L
	var converted := state.daylight.mul_scalar(0.1 + 0.01 * float(state.chloroplast_level))
	state.sap.add(converted)
	# 生长（树高转化）——木质部：0.01 × (1 + 0.05×L)
	var grown := state.sap.mul_scalar(0.01 * (1.0 + 0.05 * float(state.xylem_level)))
	state.growth.add(grown)
	# 树液 clamp 到储量上限（宽裕版）
	state.sap = BigNum.new(minf(state.sap.to_value(), sap_cap(state)))
```

- [ ] **Step 4: 运行确认通过**

Run: 单文件测试 → 全量回归（注意：GameLoop 公式改变会影响既有测试——`test_game_loop.gd` 旧用例若断言原始 0.1/0.01 值需确认仍成立：chloroplast_level=0 时 0.1 不变，xylem_level=0 时 0.01 不变——旧用例应仍绿）
Expected: 单文件 PASS；全量无回归

- [ ] **Step 5: Commit**

```bash
git add features/game/game_loop.gd tests/unit/test_game_loop.gd
git commit -m "feat: GameLoop 光合/生长公式 + sap 储量上限（宽裕版 clamp）"
```

---

### Task 5: RaceManager 花盘/根须 + Plunder 根须

**Files:**
- Modify: `features/races/race_manager.gd`
- Modify: `features/memories/plunder_actions.gd`
- Modify: `tests/unit/test_race_manager.gd`
- Modify: `tests/unit/test_plunder_actions.gd`

**Interfaces:**
- Consumes: `GameState`（sunflower_level/root_eff_level，T2）
- Produces: `tick_races` 产出阶段追加花盘独立信仰（0.5×L/tick）；人族梦产 × 根须系数（1+0.1×L）；`PlunderActions.plunder` 记忆产出 × 根须系数

- [ ] **Step 1: 写失败测试**

test_race_manager.gd 追加：

```gdscript
func test_sunflower_faith_production() -> void:
	# 花盘独立信仰产出（与人口无关）
	var s := GameState.new()
	s.sunflower_level = 2
	s.sap = BigNum.new(1000.0)
	RaceManager.tick_races(s)
	assert_that(s.faith.to_value()).is_equal_approx(1.0, 1e-4)  # 0.5×2

func test_root_eff_boosts_human_memory() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.root_eff_level = 1
	s.sap = BigNum.new(1000.0)
	RaceManager.tick_races(s)
	# 人族梦产：50×0.001×1.1 = 0.055（增长后 pop 略有变化，用容差区间）
	assert_that(s.memory.to_value()).is_greater(0.05)
	assert_that(s.memory.to_value()).is_less(0.06)
```

test_plunder_actions.gd 追加：

```gdscript
func test_root_eff_boosts_plunder() -> void:
	var s := GameState.new()
	_awaken(s, &"human")
	s.root_eff_level = 1
	var r := PlunderActions.plunder(s, &"human")
	assert_that(float(r.get("memory", 0.0))).is_equal_approx(1.1, 1e-4)  # 1.0×1.1
	assert_that(s.memory.to_value()).is_equal_approx(1.1, 1e-4)
```

- [ ] **Step 2: 运行确认失败**

Run: 两个单文件测试
Expected: FAIL（花盘/根须未接入）

- [ ] **Step 3: 修改 race_manager.gd（tick_races 产出阶段）**

```gdscript
	# 4) 产出
	for race in all_races():
		if not _is_awakened(state, race.id):
			continue
		var pop := float(state.races[race.id]["population"])
		state.faith.add(BigNum.new(pop * race.devotion * FAITH_EFF))
		if race.produce_memory:
			state.memory.add(BigNum.new(pop * MEMORY_EFF * (1.0 + 0.1 * float(state.root_eff_level))))
		if race.craft_sap > 0.0:
			state.sap.add(BigNum.new(pop * race.craft_sap))
	# 花盘：独立信仰产出（与人口无关）
	if state.sunflower_level > 0:
		state.faith.add(BigNum.new(0.5 * float(state.sunflower_level)))
```

修改 plunder_actions.gd（产出记忆处）：

```gdscript
	# 石裔无梦：不涨 counter、无产出
	if yield_mem > 0.0:
		var boosted := yield_mem * (1.0 + 0.1 * float(state.root_eff_level))
		state.memory.add(BigNum.new(boosted))
		state.plundered[race_id] = count(state, race_id) + 1
```

- [ ] **Step 4: 运行确认通过**

Run: 两个单文件测试 → 全量回归
Expected: 单文件 PASS；全量无回归（花盘在 sunflower_level=0 时不产出，旧测试不受影响）

- [ ] **Step 5: Commit**

```bash
git add features/races/race_manager.gd features/memories/plunder_actions.gd tests/unit/test_race_manager.gd tests/unit/test_plunder_actions.gd
git commit -m "feat: 花盘信仰产出 + 根须等级记忆加成（人族梦产/夺梦）"
```

---

### Task 6: GameManager 入口 + UI

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `features/ui/main.tscn`
- Modify: `features/ui/main.gd`
- Modify: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: `GameActions`（T3）、`GameLoop.sap_cap`（T4）
- Produces: `buy_chloroplast/buy_xylem/buy_sunflower/buy_nautilus/buy_root_eff() -> bool`、`get_chloroplast_cost()/... -> int` ×5、`get_sap_cap() -> float`；UI 5 按钮 + 5 成本标签 + sap 显示「X / 上限」

- [ ] **Step 1: 写失败测试**（test_game_manager.gd 追加）

```gdscript
func test_buy_upgrade_entrances() -> void:
	gm._state = GameState.new()
	gm._state.sap = BigNum.new(10000.0)
	assert_that(gm.buy_chloroplast()).is_true()
	assert_that(gm.buy_xylem()).is_true()
	assert_that(gm.buy_sunflower()).is_true()
	assert_that(gm.buy_nautilus()).is_true()
	assert_that(gm.buy_root_eff()).is_true()
	assert_that(gm.get_chloroplast_cost()).is_greater(0)
	assert_that(gm.get_sap_cap()).is_equal_approx(10000.0, 1e-4)

func test_buy_upgrade_insufficient() -> void:
	gm._state = GameState.new()
	gm._state.sap = BigNum.new(1.0)
	assert_that(gm.buy_sunflower()).is_false()
	assert_that(gm.get_state().sunflower_level).is_equal(0)
```

- [ ] **Step 2: 运行确认失败**

Run: 单文件测试
Expected: FAIL（buy_* 入口不存在）

- [ ] **Step 3: 修改 game_manager.gd**

```gdscript
# 新增方法（buy_branch 之后，统一模式）：
func buy_chloroplast() -> bool:
	var ok := GameActions.buy_chloroplast(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_xylem() -> bool:
	var ok := GameActions.buy_xylem(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_sunflower() -> bool:
	var ok := GameActions.buy_sunflower(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_nautilus() -> bool:
	var ok := GameActions.buy_nautilus(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_root_eff() -> bool:
	var ok := GameActions.buy_root_eff(_state)
	if ok:
		resources_changed.emit()
	return ok

func get_chloroplast_cost() -> int:
	return CostCalculator.chloroplast_cost(_state.chloroplast_level)

func get_xylem_cost() -> int:
	return CostCalculator.xylem_cost(_state.xylem_level)

func get_sunflower_cost() -> int:
	return CostCalculator.sunflower_cost(_state.sunflower_level)

func get_nautilus_cost() -> int:
	return CostCalculator.nautilus_cost(_state.nautilus_level)

func get_root_eff_cost() -> int:
	return CostCalculator.root_eff_cost(_state.root_eff_level)

func get_sap_cap() -> float:
	return GameLoop.sap_cap(_state)
```

- [ ] **Step 4: 修改 main.tscn**（LeafCostLabel 之后追加 5 组按钮+成本标签）

```
[node name="ChloroplastButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "叶绿体（光合 +0.01/级）"

[node name="ChloroplastCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：800"

[node name="XylemButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "木质部（生长 +5%/级）"

[node name="XylemCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：50"

[node name="SunflowerButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "花盘（信仰 +0.5/tick/级）"

[node name="SunflowerCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：2000"

[node name="NautilusButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "螺舱（储量 +5000/级）"

[node name="NautilusCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：2000"

[node name="RootEffButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "根须等级（记忆 +10%/级）"

[node name="RootEffCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：1000"
```

- [ ] **Step 5: 修改 main.gd**

```gdscript
# @onready 追加：
@onready var chloroplast_button: Button = %ChloroplastButton
@onready var chloroplast_cost_label: Label = %ChloroplastCostLabel
@onready var xylem_button: Button = %XylemButton
@onready var xylem_cost_label: Label = %XylemCostLabel
@onready var sunflower_button: Button = %SunflowerButton
@onready var sunflower_cost_label: Label = %SunflowerCostLabel
@onready var nautilus_button: Button = %NautilusButton
@onready var nautilus_cost_label: Label = %NautilusCostLabel
@onready var root_eff_button: Button = %RootEffButton
@onready var root_eff_cost_label: Label = %RootEffCostLabel

# _ready() 中追加连接：
chloroplast_button.pressed.connect(_on_chloroplast_pressed)
xylem_button.pressed.connect(_on_xylem_pressed)
sunflower_button.pressed.connect(_on_sunflower_pressed)
nautilus_button.pressed.connect(_on_nautilus_pressed)
root_eff_button.pressed.connect(_on_root_eff_pressed)

# _refresh() 中追加（sap 显示加上限 + 成本/按钮禁用）：
sap_label.text = "树液：%s / %s" % [Formatter.format_number(s.sap), Formatter.format_cost(int(GameManager.get_sap_cap()))]
chloroplast_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_chloroplast_cost())
xylem_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_xylem_cost())
sunflower_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_sunflower_cost())
nautilus_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_nautilus_cost())
root_eff_cost_label.text = "价格：" + Formatter.format_cost(GameManager.get_root_eff_cost())
chloroplast_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_chloroplast_cost())))
xylem_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_xylem_cost())))
sunflower_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_sunflower_cost())))
nautilus_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_nautilus_cost())))
root_eff_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_root_eff_cost())))

# 新增方法（统一模式）：
func _on_chloroplast_pressed() -> void:
	if GameManager.buy_chloroplast():
		log_label.text = "叶绿体升至 %d 级。" % GameManager.get_state().chloroplast_level
	_refresh()
# ...（_on_xylem/_on_sunflower/_on_nautilus/_on_root_eff 同模式）
```

- [ ] **Step 6: 验证**

Run: `godot --headless --path . --import` → 全量测试（无回归）→ `godot --headless --path . --quit-after 5`（无 SCRIPT ERROR）

- [ ] **Step 7: Commit**

```bash
git add autoloads/game_manager.gd features/ui/main.tscn features/ui/main.gd tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 升级入口 + UI（5 按钮/成本/sap 上限显示）"
```

---

### Task 7: 集成验证与端到端

**Files:**
- Modify: 无（验证；临时脚本验证后删除）

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全部 PASS、0 failures、退出码 0

- [ ] **Step 2: 端到端玩法验证（临时脚本，验证后删除）**

`_verify_m5d.gd`（`extends SceneTree`）：

```gdscript
extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var s := GameState.new()
	s.sap = BigNum.new(20000.0)
	# 1. 五类购买
	if not GameActions.buy_chloroplast(s) or not GameActions.buy_xylem(s):
		failures.append("buy chloroplast/xylem failed")
	if not GameActions.buy_sunflower(s) or not GameActions.buy_nautilus(s) or not GameActions.buy_root_eff(s):
		failures.append("buy sunflower/nautilus/root failed")
	if s.chloroplast_level != 1 or s.xylem_level != 1 or s.sunflower_level != 1:
		failures.append("levels not 1")
	# 2. 光合/生长公式（叶绿体 L1：0.11；木质部 L1：×1.05）
	var s2 := GameState.new()
	s2.chloroplast_level = 1
	s2.xylem_level = 1
	s2.daylight = BigNum.new(100.0)
	s2.sap = BigNum.new(100.0)
	GameLoop.tick(s2)
	if s2.sap.to_value() < 10.9 or s2.sap.to_value() > 11.1:
		failures.append("photosynthesis not boosted")
	if s2.growth.to_value() < 1.04 or s2.growth.to_value() > 1.06:
		failures.append("growth not boosted")
	# 3. sap clamp
	var s3 := GameState.new()
	s3.daylight = BigNum.new(1000000.0)
	GameLoop.tick(s3)
	if s3.sap.to_value() != 10000.0:
		failures.append("sap not clamped")
	# 4. 花盘/根须
	var s4 := GameState.new()
	s4.races["human"] = {"awakened": true, "population": 50.0}
	s4.sunflower_level = 1
	s4.root_eff_level = 1
	s4.sap = BigNum.new(1000.0)
	RaceManager.tick_races(s4)
	if s4.faith.to_value() < 0.5:
		failures.append("sunflower not producing")
	var s5 := GameState.new()
	s5.races["human"] = {"awakened": true, "population": 50.0}
	s5.root_eff_level = 1
	var r := PlunderActions.plunder(s5, &"human")
	if float(r.get("memory", 0.0)) != 1.1:
		failures.append("root_eff not boosting plunder")
	# 5. 存档往返 + 旧档回退
	var back := GameState.from_dict(s.to_dict())
	if back.chloroplast_level != 1:
		failures.append("save roundtrip levels")
	var legacy := GameState.from_dict({"tick": 5})
	if legacy.sunflower_level != 0:
		failures.append("legacy fallback")
	if failures.is_empty():
		print("M5D E2E VERIFY PASSED")
		quit(0)
	else:
		print("M5D E2E FAILED: ", failures)
		quit(1)
```

Run: `godot --headless --path . -s res://_verify_m5d.gd`
Expected: 输出 `M5D E2E VERIFY PASSED`、退出码 0

- [ ] **Step 3: 清理 + 提交**

删除 `_verify_m5d.gd`；`git status` 确认工作区干净（含 .uid 检查）；如有修复则提交。

---

## Self-Review 记录（写完计划时自查）

- **设计文档覆盖**：§3.1 GameState ✓（T2）；§3.2 CostCalculator ✓（T1）；§3.3 GameActions ✓（T3）；§3.4 GameLoop ✓（T4）；§3.5 sap_cap ✓（T4）；§3.6 RaceManager ✓（T5）；§3.7 Plunder ✓（T5）；§3.8 GameManager ✓（T6）；§3.9 UI ✓（T6）；§4 数值 ✓（T1-T5）；§5 测试矩阵 ✓（T1-T7）。
- **占位符扫描**：无 TBD/TODO（T6 的 `_on_xylem/_on_sunflower/_on_nautilus/_on_root_eff` 注明"同模式"——实现者按 _on_chloroplast 复制，属明确模式非占位）。
- **类型一致性**：5 个等级字段在 T2/T3/T4/T5/T6/T7 一致；`buy_*(state) -> bool` 在 T3/T6 一致；`sap_cap(state) -> float` 在 T4/T6 一致；成本 getter 在 T6/T7 一致。
- **边界核对**：指数成本 int() 取整（800×1.6=1280 精确；1.6²=2.56×800=2048 精确——断言安全）；斐波那契沿现有 fib（L0=2000×fib(1)=2000）；sap clamp 用 minf（旧档收敛）；chloroplast=0 时 0.1 不变（旧测试安全）；sunflower=0 不产出（旧测试安全）；root_eff=0 时 ×1.0（旧测试安全）。
- **UI 细节**：sap 显示改「X / 上限」；5 按钮禁用逻辑沿用 leaf/branch 模式。
- **数值**：与设计 §4 一致（800×1.6ⁿ / 50×(L+1) / 2000 斐波那契 / 10000+5000L / 1000×1.8ⁿ）；花盘 0.5×L、根须 ×(1+0.1L)。
- **迁移安全**：旧档等级字段回退 0（T2 测试 + T7 E2E）；旧档 sap 超 cap 首个 tick 收敛（T4 测试）。
- **已知行为变更（有意）**：GameLoop 光合/生长公式乘系数（等级 0 时不变）；sap 上限引入（宽裕版 10000）。
- **.uid 提醒**：本计划无新增 class_name 脚本（全部 Modify 现有文件）——无需 .uid 处理。
