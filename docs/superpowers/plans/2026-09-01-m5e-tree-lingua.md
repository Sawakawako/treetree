# 里程碑 M5e 树语科技 + 资源分层 实施计划（批 1）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地三层资源架构（点击式兑换 + 二级引擎）+ 树语科技框架（生命之语 Lv1-2 + 初阶/中阶节点）——玩家从「点击产出」进阶到「点击转换」，树语成为能力解锁层。

**Architecture:** GameState 增引擎/树语字段 + GameActions 兑换与引擎购买（纯静态，仿 M5d 五类）+ GameLoop/RaceManager tick 产出引擎与乘数节点 + LinguaActions（树语等级/节点解锁，RefCounted 纯静态）+ LinguaData 数据驱动节点表 + UI 树语区（兑换/引擎/树语面板）。聚落之心节点留能力位（M5d2 设施系统依赖，主人裁决后置）。

**Tech Stack:** Godot 4.7.1 mono / GDScript / GdUnit4 6.2.1（headless CLI）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-m5e-economy-tree-design.md`（权威，§三兑换/§四引擎/§五树语框架）；主线 `docs/superpowers/specs/2026-08-31-world-tree-design.md` §13.10/§14.6（字段/公式已回填）。

## Global Constraints

- 资源一律 BigNum（禁裸 float 存资源）；平衡系数如 rate/devotion 除外
- 逻辑类 RefCounted 纯函数可 headless 测；UI 只通过信号更新，不直改数据（Layer Cake）
- 新增 class_name 脚本后必须先 `godot --headless --path . --import`；`.uid` 确认入库
- 测试命令：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_xxx.gd -c`；全量去掉 `--add`；退出码 0 = 全绿
- 冒烟：`godot --headless --path . --quit-after 5`（无 SCRIPT ERROR 即通过）
- `is_equal_approx` 双参 `(expected, approx)`；`Array.has()` 非 `contains()`；Array 赋值用 `.assign()`；lambda 按值捕获局部变量（Dictionary 包装）
- 中文文件用 edit/write 工具（UTF-8，禁 PowerShell 默认编码写中文）
- 存档兼容：新字段缺省回退；旧档（M5g 及更早）→ faith_engine_level=0/memory_engine_level=0/lingua_life_level=0/lingua_nodes=[]
- 每任务一个 commit，风格 `feat: 模块名（要点）`
- **基线测试数：248**（M5g 后全绿）；每任务后全量回归确认无回退
- 数值公式严格照抄设计文档（§三 100:1 / 500:1；§四 200×fib(L+1) / 500×fib(L+1)；§5.1 生命之语 Lv2=200、Lv3=800；§5.3 节点消耗 初阶 3000/中阶 8000）
- **聚落之心（叶枝·初阶）本批不实现**——依赖 M5d2 四族设施（未实施，主人裁决后置）；节点表数据中不注册该节点（或注册但 can_unlock 恒 false 并注明能力位），实施选前者更干净

---

### Task 1: GameState 扩展（引擎/树语字段 + 序列化回退）

**Files:**
- Modify: `features/game/game_state.gd`
- Test: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: 无
- Produces: `faith_engine_level: int = 0` / `memory_engine_level: int = 0` / `lingua_life_level: int = 0` / `lingua_memory_level: int = 0`（本批只升 life，字段预置供批 2）/ `lingua_nodes: Array[StringName] = []`——全部 to_dict/from_dict + 缺省回退 + 类型防御

- [ ] **Step 1: 写失败测试**——`tests/unit/test_game_state.gd` 末尾追加（仿 M5g 五账本测试模式）：

```gdscript
func test_m5e_fields_roundtrip() -> void:
	var s := GameState.new()
	s.faith_engine_level = 2
	s.memory_engine_level = 1
	s.lingua_life_level = 2
	s.lingua_memory_level = 0
	s.lingua_nodes.assign([&"tree_canopy", &"ring_memory"])
	var back := GameState.from_dict(s.to_dict())
	assert_that(back.faith_engine_level).is_equal(2)
	assert_that(back.memory_engine_level).is_equal(1)
	assert_that(back.lingua_life_level).is_equal(2)
	assert_that(back.lingua_memory_level).is_equal(0)
	assert_that(back.lingua_nodes).contains(&"tree_canopy")
	assert_that(back.lingua_nodes).contains(&"ring_memory")

func test_m5e_fields_missing_fallback() -> void:
	var back := GameState.from_dict({"tick": 5})
	assert_that(back.faith_engine_level).is_equal(0)
	assert_that(back.memory_engine_level).is_equal(0)
	assert_that(back.lingua_life_level).is_equal(0)
	assert_that(back.lingua_memory_level).is_equal(0)
	assert_that(back.lingua_nodes).is_empty()

func test_m5e_fields_corrupt_fallback() -> void:
	var back := GameState.from_dict({"faith_engine_level": "corrupt", "lingua_nodes": [1, {"a": 1}]})
	assert_that(back.faith_engine_level).is_equal(0)
	assert_that(back.lingua_nodes.size()).is_equal(0)
```

- [ ] **Step 2: 跑测试验证失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_game_state.gd -c`
Expected: FAIL（`Invalid access to property 'faith_engine_level'` 等）

- [ ] **Step 3: 最小实现**——`features/game/game_state.gd` 三处：

① 字段区（`var choice_flags` 后）：
```gdscript
var faith_engine_level: int = 0     # 信仰引擎（M5e）
var memory_engine_level: int = 0    # 记忆引擎（M5e）
var lingua_life_level: int = 0      # 生命之语等级（M5e）
var lingua_memory_level: int = 0    # 记忆之语等级（M5e，批 2 升）
var lingua_nodes: Array[StringName] = []  # 已购树语节点（M5e）
```

② `to_dict()` 加 5 键（`"choice_flags": choice_flags,` 后）：
```gdscript
        "faith_engine_level": faith_engine_level,
        "memory_engine_level": memory_engine_level,
        "lingua_life_level": lingua_life_level,
        "lingua_memory_level": lingua_memory_level,
        "lingua_nodes": lingua_nodes,
```

③ `from_dict()` 末尾追加（防损坏 + 集合过滤，仿 M5g）：
```gdscript
    var fel: Variant = d.get("faith_engine_level", 0)
    s.faith_engine_level = int(fel) if typeof(fel) == TYPE_INT or typeof(fel) == TYPE_FLOAT else 0
    var mel: Variant = d.get("memory_engine_level", 0)
    s.memory_engine_level = int(mel) if typeof(mel) == TYPE_INT or typeof(mel) == TYPE_FLOAT else 0
    var lll: Variant = d.get("lingua_life_level", 0)
    s.lingua_life_level = int(lll) if typeof(lll) == TYPE_INT or typeof(lll) == TYPE_FLOAT else 0
    var lml: Variant = d.get("lingua_memory_level", 0)
    s.lingua_memory_level = int(lml) if typeof(lml) == TYPE_INT or typeof(lml) == TYPE_FLOAT else 0
    var ln: Array = d.get("lingua_nodes", [])
    var ln_cleaned: Array = []
    for x in ln:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            ln_cleaned.append(StringName(x))
    s.lingua_nodes.assign(ln_cleaned)
```

- [ ] **Step 4: 跑测试验证通过**

Run: 同 Step 2
Expected: PASS（3 新用例绿；既有无回归）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 扩展（引擎/树语字段 + 序列化回退防御）"
```

---

### Task 2: LinguaData 节点表 + LinguaActions 等级/节点逻辑

**Files:**
- Create: `features/lingua/lingua_data.gd`（新目录）
- Create: `features/lingua/lingua_actions.gd`
- Test: `tests/unit/test_lingua_data.gd`、`tests/unit/test_lingua_actions.gd`（新文件）

**Interfaces:**
- Consumes: Task 1 的 lingua_life_level/lingua_nodes
- Produces: `LinguaData`：`LINGUA_LIFE_COSTS = {1: 0, 2: 200, 3: 800}`（Lv1 免费激活，Lv2=200/Lv3=800 信仰）；`NODES: Array[Dictionary]`（本批注册节点，字段 id/name/branch/层/tier 数值 1 初阶 2 中阶/requirement 树语等级/effects 描述/sap_cost）；`LinguaActions`：`life_cost(state) -> int`/`can_upgrade_life(state) -> bool`/`upgrade_life(state) -> Dictionary`/`can_unlock_node(state, node_id) -> bool`/`unlock_node(state, node_id) -> Dictionary`/`has_node(state, node_id) -> bool`/`life_unlocks_engine...`（能力查询函数统一在 Task 3/4 消费）

- [ ] **Step 1: 写失败测试**——新文件 `tests/unit/test_lingua_data.gd`：

```gdscript
extends GdUnitTestSuite

func test_life_costs_table() -> void:
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[1])).is_equal(0)   # Lv1 免费激活
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[2])).is_equal(200) # 设计 §5.1
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[3])).is_equal(800)

func test_nodes_registered() -> void:
	var nodes := LinguaData.all_nodes()
	# 批 1 注册：根枝 2 + 干枝 3 + 叶枝 2（聚落之心不注册）
	var ids: Array[StringName] = []
	for n in nodes:
		ids.append(StringName(str(n.get("id", ""))))
	assert_that(ids).contains(&"root_echo")     # 遗迹回声
	assert_that(ids).contains(&"root_resonance") # 根须共鸣
	assert_that(ids).contains(&"deep_root")     # 深层根须
	assert_that(ids).contains(&"tree_canopy")   # 树冠舒展
	assert_that(ids).contains(&"ring_memory")   # 年轮记忆
	assert_that(ids).contains(&"cloud_crown")   # 云冠
	assert_that(ids).contains(&"wood_heart")    # 木质强化
	assert_that(ids).contains(&"song_resonance")# 歌之共鸣
	assert_that(ids).contains(&"grace")         # 恩泽
	assert_that(ids).contains(&"altar")         # 圣坛
	assert_that(ids).contains(&"village_heart").is_false()  # 聚落之心不注册（M5d2 后置）
```

> ⚠️ 上面最后一行 `assert_that(...).contains(...).is_false()` 是链式误写——应为 `assert_that(ids).contains(&"village_heart")).is_false()`。实施时写对（GdUnit 断言：`assert_that(ids.contains(&"village_heart")).is_false()`）。

新文件 `tests/unit/test_lingua_actions.gd`：

```gdscript
extends GdUnitTestSuite

func _fresh() -> GameState:
	var s := GameState.new()
	s.faith = BigNum.new(0.0)
	return s

func test_life_lv1_free_activate() -> void:
	var s := _fresh()
	assert_that(LinguaActions.can_upgrade_life(s)).is_true()   # Lv0→1 免费
	var r := LinguaActions.upgrade_life(s)
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(1)
	assert_that(s.faith.to_value()).is_equal_approx(0.0, 1e-4)  # 不扣信仰

func test_life_lv2_costs_200() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.faith = BigNum.new(199.0)
	assert_that(LinguaActions.can_upgrade_life(s)).is_false()   # 信仰不足
	s.faith = BigNum.new(200.0)
	assert_that(LinguaActions.can_upgrade_life(s)).is_true()
	var r := LinguaActions.upgrade_life(s)
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(2)
	assert_that(s.faith.to_value()).is_equal_approx(0.0, 1e-4)

func test_life_lv3_costs_800() -> void:
	var s := _fresh()
	s.lingua_life_level = 2
	s.faith = BigNum.new(800.0)
	assert_that(LinguaActions.upgrade_life(s).get("ok", false)).is_true()
	assert_that(s.lingua_life_level).is_equal(3)

func test_unlock_node_requires_level_and_sap() -> void:
	var s := _fresh()
	s.sap = BigNum.new(3000.0)
	assert_that(LinguaActions.can_unlock_node(s, &"tree_canopy")).is_false()  # 生命之语 Lv0
	s.lingua_life_level = 1
	assert_that(LinguaActions.can_unlock_node(s, &"tree_canopy")).is_true()
	var r := LinguaActions.unlock_node(s, &"tree_canopy")
	assert_that(r.get("ok", false)).is_true()
	assert_that(s.lingua_nodes).contains(&"tree_canopy")
	assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)  # 3000-3000

func test_unlock_node_idempotent() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.sap = BigNum.new(3000.0)
	LinguaActions.unlock_node(s, &"tree_canopy")
	assert_that(LinguaActions.unlock_node(s, &"tree_canopy").get("ok", false)).is_false()  # 已购
	assert_that(s.lingua_nodes.size()).is_equal(1)

func test_mid_tier_requires_lv2_and_8000_sap() -> void:
	var s := _fresh()
	s.lingua_life_level = 1
	s.sap = BigNum.new(8000.0)
	assert_that(LinguaActions.can_unlock_node(s, &"cloud_crown")).is_false()  # 需 Lv2
	s.lingua_life_level = 2
	assert_that(LinguaActions.can_unlock_node(s, &"cloud_crown")).is_true()
```

- [ ] **Step 2: 跑测试验证失败**

Run: `godot --headless --path . --import` + 两个新测试文件 `-c`
Expected: FAIL（`Identifier "LinguaActions" not declared`）

- [ ] **Step 3: 最小实现**——`features/lingua/lingua_data.gd`：

```gdscript
class_name LinguaData
extends RefCounted

# 生命之语升级消耗（信仰）；Lv1 免费激活（设计 §5.1：Lv2=200/Lv3=800）
const LINGUA_LIFE_COSTS := {1: 0, 2: 200, 3: 800}
const LIFE_MAX_LEVEL := 3

# 节点表（设计 §5.2 批 1 注册；tier: 1 初阶 2 中阶；聚落之心不注册——M5d2 设施依赖后置）
const NODES: Array[Dictionary] = [
	{"id": &"root_echo", "name": "遗迹回声", "branch": "root", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "遗迹文本回看"},
	{"id": &"root_resonance", "name": "根须共鸣", "branch": "root", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "解锁树液→记忆兑换"},
	{"id": &"deep_root", "name": "深层根须", "branch": "root", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "根须探索成本 -50%"},
	{"id": &"tree_canopy", "name": "树冠舒展", "branch": "trunk", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "解锁树液→信仰兑换"},
	{"id": &"ring_memory", "name": "年轮记忆", "branch": "trunk", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "生长 +20%"},
	{"id": &"cloud_crown", "name": "云冠", "branch": "trunk", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "解锁信仰引擎"},
	{"id": &"wood_heart", "name": "木质强化", "branch": "trunk", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "sap 上限 +50%"},
	{"id": &"song_resonance", "name": "歌之共鸣", "branch": "leaf", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "信仰产出 +10%"},
	{"id": &"grace", "name": "恩泽", "branch": "leaf", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "解锁记忆引擎"},
	{"id": &"altar", "name": "圣坛", "branch": "leaf", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "信仰引擎效果 ×2"},
]

static func all_nodes() -> Array[Dictionary]:
	return NODES

static func get_node(id: StringName) -> Dictionary:
	for n in NODES:
		if StringName(str(n.get("id", ""))) == id:
			return n
	return {}

static func life_cost(level: int) -> int:
	# level = 当前等级 → 升到 level+1 的成本
	if level >= LIFE_MAX_LEVEL:
		return -1
	return int(LINGUA_LIFE_COSTS.get(level + 1, 0))
```

`features/lingua/lingua_actions.gd`：

```gdscript
class_name LinguaActions
extends RefCounted

static func has_node(state: GameState, node_id: StringName) -> bool:
	return state.lingua_nodes.has(node_id)

static func life_cost(state: GameState) -> int:
	return LinguaData.life_cost(state.lingua_life_level)

static func can_upgrade_life(state: GameState) -> bool:
	var cost := LinguaData.life_cost(state.lingua_life_level)
	if cost < 0:
		return false  # 满级
	return state.faith.is_greater_or_equal(BigNum.new(float(cost)))

static func upgrade_life(state: GameState) -> Dictionary:
	if not can_upgrade_life(state):
		return {"ok": false}
	var cost := LinguaData.life_cost(state.lingua_life_level)
	if cost > 0:
		state.faith.sub(BigNum.new(float(cost)))
	state.lingua_life_level += 1
	return {"ok": true, "level": state.lingua_life_level}

static func can_unlock_node(state: GameState, node_id: StringName) -> bool:
	if state.lingua_nodes.has(node_id):
		return false
	var node := LinguaData.get_node(node_id)
	if node.is_empty():
		return false
	if state.lingua_life_level < int(node.get("requirement", 99)):
		return false
	return state.sap.is_greater_or_equal(BigNum.new(float(node.get("sap_cost", 0))))

static func unlock_node(state: GameState, node_id: StringName) -> Dictionary:
	if not can_unlock_node(state, node_id):
		return {"ok": false}
	var node := LinguaData.get_node(node_id)
	state.sap.sub(BigNum.new(float(node.get("sap_cost", 0))))
	state.lingua_nodes.append(node_id)
	return {"ok": true, "node_id": node_id}
```

- [ ] **Step 4: 跑测试验证通过**

Run: `godot --headless --path . --import` + 测试命令
Expected: PASS（两套件全绿）

- [ ] **Step 5: Commit**（含 .uid）

```bash
git add features/lingua/ tests/unit/test_lingua_data.gd tests/unit/test_lingua_actions.gd
git status   # .uid 确认
git commit -m "feat: Lingua 树语框架（生命之语等级/节点解锁，数据驱动节点表）"
```

---

### Task 3: 兑换（树液→信仰/记忆）+ 节点解锁门

**Files:**
- Modify: `features/economy/actions.gd`（追加兑换函数）
- Create: `features/economy/conversion_actions.gd`（或并入 actions.gd——选并入 actions.gd 更贴既有模式，见下）
- Test: `tests/unit/test_actions.gd`、`tests/unit/test_conversion.gd`

> 实现裁决：兑换函数放 `features/economy/actions.gd`（GameActions 既有静态库，同文件追加）——项目惯例动作都在这；`ConversionActions` 独立类反而散。但测试建议独立套件 `test_conversion.gd`（设计 §八 命名）——测试文件可独立，类不必。

**Interfaces:**
- Consumes: Task 1 lingua_nodes（节点门）、Task 2 LinguaActions.has_node
- Produces: `GameActions.convert_sap_to_faith(state) -> bool`（需节点 tree_canopy + sap≥100 → faith+1、sap-100）/ `convert_sap_to_memory(state) -> bool`（需节点 root_resonance + sap≥500 → memory+1、sap-500）

- [ ] **Step 1: 写失败测试**——新文件 `tests/unit/test_conversion.gd`：

```gdscript
extends GdUnitTestSuite

func _ready_state() -> GameState:
	var s := GameState.new()
	s.lingua_nodes.assign([&"tree_canopy", &"root_resonance"])
	return s

func test_convert_sap_to_faith() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(250.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_true()
	assert_that(s.faith.to_value()).is_equal_approx(1.0, 1e-4)   # 100→1
	assert_that(s.sap.to_value()).is_equal_approx(150.0, 1e-4)

func test_convert_faith_repeatable() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(1000.0)
	GameActions.convert_sap_to_faith(s)
	GameActions.convert_sap_to_faith(s)
	assert_that(s.faith.to_value()).is_equal_approx(2.0, 1e-4)   # 可重复
	assert_that(s.sap.to_value()).is_equal_approx(800.0, 1e-4)

func test_convert_faith_requires_node() -> void:
	var s := GameState.new()  # 无 tree_canopy
	s.sap = BigNum.new(500.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_false()

func test_convert_faith_insufficient_sap() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(99.0)
	assert_that(GameActions.convert_sap_to_faith(s)).is_false()

func test_convert_sap_to_memory() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(1000.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_true()
	assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)  # 500→1
	assert_that(s.sap.to_value()).is_equal_approx(500.0, 1e-4)

func test_convert_memory_requires_node_strict() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(1000.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_false()  # 无 root_resonance

func test_convert_memory_insufficient() -> void:
	var s := _ready_state()
	s.sap = BigNum.new(499.0)
	assert_that(GameActions.convert_sap_to_memory(s)).is_false()
```

- [ ] **Step 2: 跑测试验证失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_conversion.gd -c`
Expected: FAIL（`Nonexistent function 'convert_sap_to_faith'`）

- [ ] **Step 3: 最小实现**——`features/economy/actions.gd` 末尾追加：

```gdscript
static func convert_sap_to_faith(state: GameState) -> bool:
	if not LinguaActions.has_node(state, &"tree_canopy"):
		return false  # 树冠舒展解锁
	var cost := BigNum.new(100.0)
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.faith.add(BigNum.new(1.0))
	return true

static func convert_sap_to_memory(state: GameState) -> bool:
	if not LinguaActions.has_node(state, &"root_resonance"):
		return false  # 根须共鸣解锁
	var cost := BigNum.new(500.0)
	if not state.sap.is_greater_or_equal(cost):
		return false
	state.sap.sub(cost)
	state.memory.add(BigNum.new(1.0))
	return true
```

- [ ] **Step 4: 跑测试验证通过**

Run: 同 Step 2
Expected: PASS（7 用例全绿；test_actions.gd 既有无回归）

- [ ] **Step 5: Commit**

```bash
git add features/economy/actions.gd tests/unit/test_conversion.gd
git commit -m "feat: 点击式兑换（树液→信仰 100:1 / 树液→记忆 500:1，节点解锁门）"
```

---

### Task 4: 二级引擎（信仰/记忆引擎购买 + tick 产出）

**Files:**
- Modify: `features/economy/actions.gd`（引擎购买）
- Modify: `features/races/race_manager.gd`（引擎 tick 产出 + 乘数节点：song_resonance/altar）
- Modify: `features/economy/cost_calculator.gd`（引擎成本）
- Test: `tests/unit/test_engines.gd`、`tests/unit/test_race_manager.gd`、`tests/unit/test_cost_calculator.gd`

**Interfaces:**
- Consumes: Task 1 字段、Task 2 LinguaActions
- Produces: `CostCalculator.faith_engine_cost(level) -> int` = `200 * fib(level+1)`；`memory_engine_cost(level) -> int` = `500 * fib(level+1)`；`GameActions.buy_faith_engine(state) -> bool`（需节点 cloud_crown + 信仰够）/ `buy_memory_engine(state) -> bool`（需节点 grace + 记忆够）；RaceManager tick：信仰引擎产出 `faith_engine_level × (2 if altar else 1)`；记忆引擎产出 `memory_engine_level × 0.1`；song_resonance → 四族信仰产出 ×1.1

- [ ] **Step 1: 写失败测试**——新文件 `tests/unit/test_engines.gd`：

```gdscript
extends GdUnitTestSuite

func test_faith_engine_cost_formula() -> void:
	assert_that(CostCalculator.faith_engine_cost(0)).is_equal(200)   # 200×fib(1)=200×1
	assert_that(CostCalculator.faith_engine_cost(1)).is_equal(200)   # 200×fib(2)=200×1
	assert_that(CostCalculator.faith_engine_cost(2)).is_equal(400)   # 200×fib(3)=200×2

func test_memory_engine_cost_formula() -> void:
	assert_that(CostCalculator.memory_engine_cost(0)).is_equal(500)
	assert_that(CostCalculator.memory_engine_cost(1)).is_equal(500)
	assert_that(CostCalculator.memory_engine_cost(2)).is_equal(1000)

func test_buy_faith_engine_requires_cloud_crown() -> void:
	var s := GameState.new()
	s.faith = BigNum.new(2000.0)
	assert_that(GameActions.buy_faith_engine(s)).is_false()  # 无云冠节点
	s.lingua_nodes.assign([&"cloud_crown"])
	assert_that(GameActions.buy_faith_engine(s)).is_true()
	assert_that(s.faith_engine_level).is_equal(1)
	assert_that(s.faith.to_value()).is_equal_approx(1800.0, 1e-4)  # 2000-200

func test_buy_faith_engine_insufficient() -> void:
	var s := GameState.new()
	s.lingua_nodes.assign([&"cloud_crown"])
	s.faith = BigNum.new(199.0)
	assert_that(GameActions.buy_faith_engine(s)).is_false()
	assert_that(s.faith_engine_level).is_equal(0)

func test_buy_memory_engine_requires_grace() -> void:
	var s := GameState.new()
	s.memory = BigNum.new(5000.0)
	assert_that(GameActions.buy_memory_engine(s)).is_false()
	s.lingua_nodes.assign([&"grace"])
	assert_that(GameActions.buy_memory_engine(s)).is_true()
	assert_that(s.memory_engine_level).is_equal(1)
	assert_that(s.memory.to_value()).is_equal_approx(4500.0, 1e-4)  # 5000-500
```

`tests/unit/test_race_manager.gd` 追加（引擎产出——仿 M5d 花盘测试）：

```gdscript
func test_faith_engine_produces_per_tick() -> void:
	var s := GameState.new()
	s.faith_engine_level = 2
	s.sap = BigNum.new(0.0)  # 无供养，纯引擎
	RaceManager.tick_races(s)
	assert_that(s.faith.to_value()).is_equal_approx(2.0, 1e-4)  # 2×1

func test_altar_doubles_faith_engine() -> void:
	var s := GameState.new()
	s.faith_engine_level = 2
	s.lingua_nodes.assign([&"altar"])
	s.sap = BigNum.new(0.0)
	RaceManager.tick_races(s)
	assert_that(s.faith.to_value()).is_equal_approx(4.0, 1e-4)  # 2×(1×2)

func test_memory_engine_produces_per_tick() -> void:
	var s := GameState.new()
	s.memory_engine_level = 1
	RaceManager.tick_races(s)
	assert_that(s.memory.to_value()).is_equal_approx(0.1, 1e-4)

func test_song_resonance_boosts_race_faith() -> void:
	var s := GameState.new()
	s.races["human"] = {"awakened": true, "population": 50.0}
	s.lingua_nodes.assign([&"song_resonance"])
	s.sap = BigNum.new(500.0)
	RaceManager.tick_races(s)
	# 原 50×1.0×0.002=0.1 → ×1.1 = 0.11
	assert_that(s.faith.to_value()).is_equal_approx(0.11, 1e-4)
```

> ⚠️ 注意 song_resonance 测试：tick_races 顺序=供养→增长→产出。人族 pop 50 sap 500>0 会先增长（pop 50→50.25 见 M5g 教训）再产出 → 实际 50.25×1.0×0.002×1.1 = 0.11055。**断言用增长后精确值 0.11055**（沿用 M5g Ruling）。同上 altar/memory_engine 测试无人口（sap=0 不增长、无唤醒族）→ 纯引擎产出精确。

- [ ] **Step 2: 跑测试验证失败**

Run: 三个测试文件 `-c`
Expected: FAIL（`Nonexistent function 'buy_faith_engine'` / `faith_engine_cost` 等）

- [ ] **Step 3: 最小实现**——三文件：

`features/economy/cost_calculator.gd` 末尾：
```gdscript
static func faith_engine_cost(level: int) -> int:
	return 200 * fib(level + 1)

static func memory_engine_cost(level: int) -> int:
	return 500 * fib(level + 1)
```

`features/economy/actions.gd` 末尾：
```gdscript
static func buy_faith_engine(state: GameState) -> bool:
	if not LinguaActions.has_node(state, &"cloud_crown"):
		return false
	var cost := BigNum.new(float(CostCalculator.faith_engine_cost(state.faith_engine_level)))
	if not state.faith.is_greater_or_equal(cost):
		return false
	state.faith.sub(cost)
	state.faith_engine_level += 1
	return true

static func buy_memory_engine(state: GameState) -> bool:
	if not LinguaActions.has_node(state, &"grace"):
		return false
	var cost := BigNum.new(float(CostCalculator.memory_engine_cost(state.memory_engine_level)))
	if not state.memory.is_greater_or_equal(cost):
		return false
	state.memory.sub(cost)
	state.memory_engine_level += 1
	return true
```

`features/races/race_manager.gd` 第 4 步产出区（花盘块前）追加引擎产出，且四族信仰产出乘 song 系数：

第 4 步信仰产出行改造（`state.faith.add(BigNum.new(pop * race.devotion * FAITH_EFF))`）：
```gdscript
		var song_mult := 1.1 if state.lingua_nodes.has(&"song_resonance") else 1.0
		state.faith.add(BigNum.new(pop * race.devotion * FAITH_EFF * song_mult))
```

花盘块后追加引擎产出：
```gdscript
	# 二级引擎（云冠/恩泽解锁后购买，独立产出）
	if state.faith_engine_level > 0:
		var altar_mult := 2.0 if state.lingua_nodes.has(&"altar") else 1.0
		state.faith.add(BigNum.new(float(state.faith_engine_level) * altar_mult))
	if state.memory_engine_level > 0:
		state.memory.add(BigNum.new(float(state.memory_engine_level) * 0.1))
```

- [ ] **Step 4: 跑测试验证通过**

Run: 三个测试文件
Expected: PASS（song_resonance 用 0.11055）

- [ ] **Step 5: Commit**

```bash
git add features/economy/cost_calculator.gd features/economy/actions.gd features/races/race_manager.gd tests/unit/test_engines.gd tests/unit/test_race_manager.gd tests/unit/test_cost_calculator.gd
git commit -m "feat: 二级引擎（信仰/记忆引擎购买+tick 产出）+ 乘数节点（圣坛/歌之共鸣）"
```

---

### Task 5: 乘数节点接入（年轮记忆/木质强化/深层根须）+ 引擎产出修正

**Files:**
- Modify: `features/game/game_loop.gd`（sap_cap ×wood_heart；生长 ×ring_memory）
- Modify: `features/dreams/root_actions.gd`（探索成本 -50% deep_root）
- Modify: `features/economy/cost_calculator.gd`（若 sap_cap 涉及——实际 sap_cap 在 GameLoop）
- Test: `tests/unit/test_game_loop.gd`、`tests/unit/test_root_actions.gd`

**Interfaces:**
- Consumes: Task 1-2（lingua_nodes + LinguaActions.has_node）
- Produces: 能力查询函数 `LinguaActions.has_node` 被 GameLoop/RootActions 消费：
  - `GameLoop.sap_cap(state)`：有 wood_heart → `(10000+5000×nautilus) × 1.5`
  - `GameLoop.tick` 生长：有 ring_memory → grown × 1.2
  - `RootActions.EXPLORE_COST`：有 deep_root → 100（半价）

- [ ] **Step 1: 写失败测试**：

`tests/unit/test_game_loop.gd` 追加：
```gdscript
func test_wood_heart_raises_sap_cap() -> void:
	var s := GameState.new()
	assert_that(GameLoop.sap_cap(s)).is_equal_approx(10000.0, 1e-4)
	s.lingua_nodes.assign([&"wood_heart"])
	assert_that(GameLoop.sap_cap(s)).is_equal_approx(15000.0, 1e-4)  # ×1.5

func test_ring_memory_boosts_growth() -> void:
	var s := GameState.new()
	s.daylight = BigNum.new(0.0)
	s.sap = BigNum.new(10000.0)
	s.lingua_nodes.assign([&"ring_memory"])
	GameLoop.tick(s)
	# 生长 = sap×0.01×1.2（ring_memory）；sap 被 clamp 会扣？——验证生长公式含 1.2
	# 直接断言 growth 增量：sap 10000 先转 0.01×(1+0)×1.2=120？不对——看实现，sap clamp 上限 15000>10000 不扣
	# grown = 10000×0.01×1.2 = 120
	assert_that(s.growth.to_value()).is_equal_approx(120.0, 1e-4)
```

> ⚠️ 上面 ring_memory 测试假设 sap 10000 不被 clamp——正确（cap 10000+；wood_heart 无则 cap=10000，sap=10000 恰在 cap 不扣）。tick 内先 grown 后 clamp，grown=10000×0.01×1.2=120。若 ring 实现放 grown 公式则此断言成立；实现注意 tick 顺序。

`tests/unit/test_root_actions.gd` 追加：
```gdscript
func test_deep_root_halves_explore_cost() -> void:
	var s := GameState.new()
	s.sap = BigNum.new(150.0)
	assert_that(RootActions.can_explore(s)).is_false()  # 无节点 200 不够
	s.sap = BigNum.new(250.0)
	assert_that(RootActions.can_explore(s)).is_true()
	# 有 deep_root：100 即可
	var s2 := GameState.new()
	s2.lingua_nodes.assign([&"deep_root"])
	s2.sap = BigNum.new(100.0)
	assert_that(RootActions.can_explore(s2)).is_true()
	var r := RootActions.explore(s2)
	assert_that(r.get("ok", false)).is_true()
	assert_that(s2.sap.to_value()).is_equal_approx(0.0, 1e-4)  # 100-100 半价
```

- [ ] **Step 2: 跑测试验证失败**

Run: 两文件 `-c`
Expected: FAIL（wood_heart/ring_memory/deep_root 未接入）

- [ ] **Step 3: 最小实现**——三文件：

`features/game/game_loop.gd`：
```gdscript
static func sap_cap(state: GameState) -> float:
	var base := 10000.0 + 5000.0 * float(state.nautilus_level)
	if state.lingua_nodes.has(&"wood_heart"):
		base *= 1.5
	return base
```
tick 生长行（`var grown := ...`）：
```gdscript
	var ring_mult := 1.2 if state.lingua_nodes.has(&"ring_memory") else 1.0
	var grown := state.sap.mul_scalar(0.01 * (1.0 + 0.05 * float(state.xylem_level)) * ring_mult)
```

`features/dreams/root_actions.gd`：
```gdscript
static func explore_cost(state: GameState) -> float:
	if state.lingua_nodes.has(&"deep_root"):
		return EXPLORE_COST * 0.5
	return EXPLORE_COST
```
can_explore/explore 用 `explore_cost(state)` 替换 `EXPLORE_COST` 两处（`BigNum.new(explore_cost(state))`）。

- [ ] **Step 4: 跑测试验证通过**

Run: 同 Step 2 + 全量
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add features/game/game_loop.gd features/dreams/root_actions.gd tests/unit/test_game_loop.gd tests/unit/test_root_actions.gd
git commit -m "feat: 乘数节点接入（木质强化 sap 上限/年轮记忆生长/深层根须探索半价）"
```

---

### Task 6: GameManager 集成（兑换/引擎/树语入口 + 信号）

**Files:**
- Modify: `autoloads/game_manager.gd`
- Test: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: Task 2-5 全部动作
- Produces: `convert_faith() -> bool` / `convert_memory() -> bool` / `buy_faith_engine() -> bool` / `buy_memory_engine() -> bool` / `upgrade_life() -> bool` / `unlock_node(node_id) -> bool`（各成功→resources_changed.emit()；upgrade/unlock 成功后另发 lingua_changed 信号——本批 UI 刷新靠 resources_changed 即可，为批 2 预留 lingua 信号可不加，YAGNI 选择：只发 resources_changed，不新增信号）

- [ ] **Step 1: 写失败测试**——`tests/unit/test_game_manager.gd` 追加：

```gdscript
func test_convert_entrances() -> void:
	gm._state = GameState.new()
	gm._state.lingua_nodes.assign([&"tree_canopy", &"root_resonance"])
	gm._state.sap = BigNum.new(600.0)
	assert_that(gm.convert_faith()).is_true()
	assert_that(gm.get_state().faith.to_value()).is_equal_approx(1.0, 1e-4)
	assert_that(gm.convert_memory()).is_true()
	assert_that(gm.get_state().memory.to_value()).is_equal_approx(1.0, 1e-4)
	assert_that(gm.get_state().sap.to_value()).is_equal_approx(0.0, 1e-4)  # 600-100-500

func test_convert_blocked() -> void:
	gm._state = GameState.new()  # 无节点
	gm._state.sap = BigNum.new(1000.0)
	assert_that(gm.convert_faith()).is_false()
	assert_that(gm.convert_memory()).is_false()

func test_engine_entrances() -> void:
	gm._state = GameState.new()
	gm._state.lingua_nodes.assign([&"cloud_crown", &"grace"])
	gm._state.faith = BigNum.new(1000.0)
	gm._state.memory = BigNum.new(1000.0)
	assert_that(gm.buy_faith_engine()).is_true()
	assert_that(gm.buy_memory_engine()).is_true()
	assert_that(gm.get_state().faith_engine_level).is_equal(1)
	assert_that(gm.get_state().memory_engine_level).is_equal(1)

func test_lingua_entrances() -> void:
	gm._state = GameState.new()
	gm._state.faith = BigNum.new(1000.0)
	assert_that(gm.upgrade_life()).is_true()  # Lv0→1 免费
	assert_that(gm.upgrade_life()).is_true()  # Lv1→2 扣 200
	assert_that(gm.get_state().lingua_life_level).is_equal(2)
	gm._state.sap = BigNum.new(3000.0)
	assert_that(gm.unlock_node(&"tree_canopy")).is_true()
	assert_that(gm.get_state().lingua_nodes).contains(&"tree_canopy")

func test_unlock_blocked() -> void:
	gm._state = GameState.new()
	gm._state.faith = BigNum.new(1000.0)
	gm.upgrade_life()  # Lv1
	gm._state.sap = BigNum.new(3000.0)
	assert_that(gm.unlock_node(&"root_resonance")).is_true()
	assert_that(gm.unlock_node(&"cloud_crown")).is_false()  # 需 Lv2
```

- [ ] **Step 2: 跑测试验证失败**

Run: `--add tests/unit/test_game_manager.gd -c`
Expected: FAIL（`Nonexistent function 'convert_faith'` 等）

- [ ] **Step 3: 最小实现**——`autoloads/game_manager.gd` 末尾追加（仿既有入口模式）：

```gdscript
func convert_faith() -> bool:
	var ok := GameActions.convert_sap_to_faith(_state)
	if ok:
		resources_changed.emit()
	return ok

func convert_memory() -> bool:
	var ok := GameActions.convert_sap_to_memory(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_faith_engine() -> bool:
	var ok := GameActions.buy_faith_engine(_state)
	if ok:
		resources_changed.emit()
	return ok

func buy_memory_engine() -> bool:
	var ok := GameActions.buy_memory_engine(_state)
	if ok:
		resources_changed.emit()
	return ok

func upgrade_life() -> bool:
	var ok := LinguaActions.upgrade_life(_state)
	if ok.get("ok", false):
		resources_changed.emit()
		return true
	return false

func unlock_node(node_id: StringName) -> bool:
	var ok := LinguaActions.unlock_node(_state, node_id)
	if ok.get("ok", false):
		resources_changed.emit()
		return true
	return false
```

> ⚠️ 上面 upgrade_life/unlock_node 用了 `ok.get` 但 upgrade_life 返回 Dictionary——`var ok := LinguaActions.upgrade_life(_state)` 得 Dictionary，`.get("ok", false)` 正确；但 `if ok:` 语义在 GDScript Dictionary 恒真——必须用 `.get("ok", false)`。已写对。

- [ ] **Step 4: 跑测试验证通过**

Run: 同 Step 2 + 全量
Expected: PASS（5 新用例绿）

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 集成（兑换/引擎/树语六入口 + resources_changed）"
```

---

### Task 7: UI 树语区（兑换按钮/引擎按钮/树语面板）

**Files:**
- Modify: `features/ui/main.tscn`
- Modify: `features/ui/main.gd`
- Test: headless 冒烟 + 全量回归（UI 无单测惯例）

**Interfaces:**
- Consumes: Task 6 六入口 + LinguaActions 查询（can_ 函数 + 成本查询）
- Produces: `%FaithConvertButton`（献祭 100:1）/ `%MemoryConvertButton`（挖梦 500:1）/ `%FaithEngineButton` + 成本 Label / `%MemoryEngineButton` + 成本 Label / `%LifeUpgradeButton` + 成本 Label / 节点按钮区（根枝/干枝/叶枝 三组，10 节点按钮 visible 条件）+ `_refresh_lingua()` / `_on_convert_faith/memory` / `_on_engine_faith/memory` / `_on_life_upgrade` / `_on_node_unlock(node_id)`

- [ ] **Step 1: 改 main.tscn**——VBox 内 ChoicePanel 后追加（节点按钮用三组 VBox 或直接平铺——平铺 10 按钮 + visible 控制最简）：

```text
[node name="FaithConvertButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "献祭（100 树液 → 信仰 +1）"

[node name="MemoryConvertButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "挖梦（500 树液 → 记忆 +1）"

[node name="LifeUpgradeButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "生命之语 · 升级"

[node name="LifeCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = ""

[node name="FaithEngineButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "信仰引擎 · 升级"

[node name="FaithEngineCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = ""

[node name="MemoryEngineButton" type="Button" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = "记忆引擎 · 升级"

[node name="MemoryEngineCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
visible = false
layout_mode = 2
text = ""

[node name="RootEchoButton" type="Button" parent="VBox"]...
[node name="RootResonanceButton" type="Button" parent="VBox"]...
[node name="DeepRootButton" type="Button" parent="VBox"]...
[node name="TreeCanopyButton" type="Button" parent="VBox"]...
[node name="RingMemoryButton" type="Button" parent="VBox"]...
[node name="CloudCrownButton" type="Button" parent="VBox"]...
[node name="WoodHeartButton" type="Button" parent="VBox"]...
[node name="SongResonanceButton" type="Button" parent="VBox"]...
[node name="GraceButton" type="Button" parent="VBox"]...
[node name="AltarButton" type="Button" parent="VBox"]...
```

> ⚠️ 10 个节点按钮完整 tscn 段落在实施时逐一展开（text=节点名 + 效果，visible=false 默认）。此计划省略逐节点 text 以控篇幅——实施者按 LinguaData.NODES 的 name/effect 生成按钮文字（如「遗迹回声：遗迹文本回看」），unique_name 命名 = 节点 id PascalCase + Button（root_echo → %RootEchoButton）。

- [ ] **Step 2: 改 main.gd**——四处改动：

① `@onready` 区追加全部按钮引用（含 10 节点）
② `_ready()` 连接（兑换/引擎/树语/节点各自 pressed → 处理函数）
③ `_refresh()` 末尾调 `_refresh_lingua()`
④ 新方法：
```gdscript
func _refresh_lingua() -> void:
	var s := GameManager.get_state()
	# 兑换按钮：节点已购才显示
	%FaithConvertButton.visible = LinguaActions.has_node(s, &"tree_canopy")
	%MemoryConvertButton.visible = LinguaActions.has_node(s, &"root_resonance")
	# 生命之语：Lv≥1 后可见（免费激活后常显），未激活前隐藏（避免开局刷脸）
	%LifeUpgradeButton.visible = s.lingua_life_level > 0 or s.faith.is_greater_or_equal(BigNum.new(1.0))
	%LifeCostLabel.visible = s.lingua_life_level > 0
	var lc := LinguaActions.life_cost(s)
	%LifeCostLabel.text = "生命之语 Lv%d → %s" % [s.lingua_life_level, ("免费" if lc == 0 else ("%d 信仰" % lc)) if lc >= 0 else "已满级"]
	%LifeUpgradeButton.disabled = not LinguaActions.can_upgrade_life(s)
	# 引擎按钮：节点已购才显示
	%FaithEngineButton.visible = LinguaActions.has_node(s, &"cloud_crown")
	%MemoryEngineButton.visible = LinguaActions.has_node(s, &"grace")
	...
```

> ⚠️ UI 数值格式用 Formatter 惯例；节点按钮可见性 = 可解锁（未购 + 等级满足 + sap 够？——显示门槛：未购且生命之语达到 requirement 即可见，disabled 由 sap 决定）——实施细节按此意图落地，测试冒烟兜底。

- [ ] **Step 3: 冒烟 + 全量回归**

Run: `godot --headless --path . --quit-after 5` + 全量
Expected: 冒烟 0、全量全绿

- [ ] **Step 4: Commit**

```bash
git add features/ui/main.tscn features/ui/main.gd
git commit -m "feat: UI 树语区（兑换/引擎/生命之语/节点按钮，visible+disabled 动态）"
```

---

### Task 8: 临时 E2E + 文档同步

**Files:**
- Create: `tests/e2e_m5e.gd`（临时，跑完删）
- Modify: `docs/world-tree/CONTINUE.md`、`docs/world-tree/ROADMAP.md`

- [ ] **Step 1: 写 E2E 脚本**（extends SceneTree，链路：信仰引擎路线全程验证）：

```gdscript
extends SceneTree

var _checks := 0
var _fails := 0

func _check(name: String, cond: bool) -> void:
	_checks += 1
	if cond:
		print("PASS  ", name)
	else:
		_fails += 1
		print("FAIL  ", name)

func _init() -> void:
	var gm = load("res://autoloads/game_manager.gd").new()
	gm._state = GameState.new()
	var s := gm.get_state()
	# 1) 免费激活生命之语 → Lv1
	_check("生命之语免费激活", gm.upgrade_life())
	_check("Lv1", s.lingua_life_level == 1)
	# 2) 攒 sap → 树冠舒展 + 根须共鸣（初阶 3000 各）
	s.sap = BigNum.new(6000.0)
	_check("解锁树冠舒展", gm.unlock_node(&"tree_canopy"))
	_check("解锁根须共鸣", gm.unlock_node(&"root_resonance"))
	# 3) 兑换信仰 + 记忆
	s.sap = BigNum.new(1000.0)
	_check("献祭 100→1", gm.convert_faith())
	_check("挖梦 500→1", gm.convert_memory())
	_check("兑换后 sap 400", s.sap.to_value() == 400.0)
	# 4) 信仰引擎链：升 Lv2（200 信仰）→ 云冠 → 信仰引擎
	s.faith = BigNum.new(500.0)
	_check("生命之语 Lv2", gm.upgrade_life())
	s.sap = BigNum.new(8000.0)
	_check("解锁云冠", gm.unlock_node(&"cloud_crown"))
	_check("买信仰引擎", gm.buy_faith_engine())
	_check("引擎 Lv1", s.faith_engine_level == 1)
	# 5) tick 产出信仰
	gm._process(1.0)
	_check("信仰引擎每 tick +1", s.faith.to_value() >= 1.0)
	# 6) 存档往返 + 旧档回退
	var d := s.to_dict()
	var back := GameState.from_dict(d)
	_check("存档往返引擎/树语", back.faith_engine_level == s.faith_engine_level and back.lingua_life_level == s.lingua_life_level)
	var old := GameState.from_dict({"tick": 5})
	_check("旧档回退", old.faith_engine_level == 0 and old.lingua_nodes.is_empty())
	gm.free()
	print("E2E 结果: %d 检查, %d 失败" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)
```

> ⚠️ 注意：`_process(1.0)` 会跑 RaceManager.tick_races——人族未唤醒则无产出，但 sap 供养无、无唤醒族 → 引擎产出精确 +1。若 s 里有唤醒族需差值断言（沿用 M5g 教训）。此 E2E 人族未唤醒 → 精确安全。

- [ ] **Step 2: 运行 E2E**

Run: `godot --headless --path . -s res://tests/e2e_m5e.gd`
Expected: 全 PASS，退出码 0

- [ ] **Step 3: 全量回归 + 冒烟**

Run: 全量 + 冒烟
Expected: 全绿 + 0

- [ ] **Step 4: 删 E2E + Commit**

```bash
Remove-Item tests/e2e_m5e.gd
git add -A
git commit -m "feat: M5e 批 1 完整（E2E 全链路 PASS 后删临时脚本）"
```

- [ ] **Step 5: 文档同步**——CONTINUE.md（状态表 M5e 行 + 六·十四 完成记录）+ ROADMAP.md（若路线图含 M5e 则标 ✅）。要点：三层架构（兑换/引擎）/树语 Lv1-2/10 节点；聚落之心留位注明（M5d2 依赖）；测试数 248+N。

```bash
git add docs/world-tree/CONTINUE.md docs/world-tree/ROADMAP.md
git commit -m "docs: M5e 批 1 完成记录 + 路线图同步"
```

---

## Self-Review（writing-plans 自检）

**1. Spec 覆盖：**
- §三 兑换（100:1/500:1）✅ T3；§四 引擎（200×fib/500×fib、+1/tick、+0.1/tick）✅ T4；§五 树语框架（5.1 等级成本 200/800 + Lv1 免费激活裁决；5.2 批 1 节点 10 个）✅ T2/T4/T5；5.3 解锁（树液 3000/8000 + 等级 + 幂等）✅ T2
- §七 批 1 范围：三层架构 ✅ T3/T4、树语框架 ✅ T2、生命之语 Lv1-2 ✅ T2、初阶/中阶节点 ✅ T2/T5（聚落之心不注册 = 决策记录 #7 实施偏差，已报主人裁决后置）
- §八 测试策略套件全部 ✅（test_conversion T3/test_engines T4/test_lingua T2/test_game_state T1/test_game_manager T6）
- 能力位：地脉感应（离线）/天光（离线效率）不注册（批 2 实现时随离线一起）；奇迹之语/冥河之触不注册（批 2 记忆之语系）——与设计 §五「批 1 除大解锁」一致

**2. Placeholder 扫描：** 全部步骤含代码/命令；唯一省略 = Task 7 十个节点按钮的逐段 tscn（已注明实施方式按 LinguaData 生成）；Task 2 测试有一处链式误写已 ⚠️ 注明修正。无 TBD。

**3. 类型一致性：**
- `faith_engine_level`/`memory_engine_level`/`lingua_life_level` int 全线一致（GameState↔GameActions↔RaceManager↔GM 入口）✅
- `lingua_nodes: Array[StringName]` + `has_node` 查询 ↔ 兑换/引擎/乘数节点消费一致 ✅
- CostCalculator.fib 复用（M5d 已有）✅
- GameActions 既有静态模式（buy_leaf 等）——新函数同构 ✅
- node_id StringName 常量（&"tree_canopy" 等）在 LinguaData NODES / LinguaActions / UI / 测试 / E2E 五处一致 ✅