# 世界树 里程碑 2（记忆/信仰/人族/遗迹梦境）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 MVP 具象轨之上加入抽象轨：记忆（梦珀）资源、根须探索遗迹系统、信仰资源、人族（说书人）唤醒与献梦，以及梦境碎片文本——完成"双轨资源 + 第一族 + 梦境"的 MVP-2 里程碑。

**Architecture:** 沿用 Layer Cake 与既有模块风格：`GameState` 扩展（memory/faith/root_depth/relics 等字段 + 序列化）；新增 `features/dreams/`（遗迹数据 RelicLibrary + 梦境逻辑）、`features/races/`（人族 RaceManager）；逻辑类保持 RefCounted 纯函数可 headless 测；`GameManager` 增加动作入口与信号；`main.gd`/`main.tscn` 扩展 UI（记忆/信仰/根须/遗迹按钮 + 梦境文本弹层）。所有新增游戏内文本遵循文风铁律（spec §11.1 诗歌化·柔和）。

**Tech Stack:** Godot 4.7.1（mono）+ GDScript（typed）+ GdUnit4 6.2.1（headless）。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-design.md`（§4.2 抽象轨、§5.1 人族、§6 梦境、§13.1 根须探索、§14 数值骨架）

## Global Constraints

- **测试命令**（GdUnit4 6.2.1，不是 `--run-tests`）：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`；**新增 class_name 脚本后先跑** `godot --headless --path . --import`。
- **`is_equal_approx` 双参签名** `(expected, approx)`——测试统一带容差 `, 1e-4`。
- 资源一律 `BigNum`（禁裸 float 存资源）；typed GDScript；中文文件用 edit 工具或 .NET UTF-8 读写（禁 PowerShell 默认编码）。
- **文风铁律**：所有游戏内文本（遗迹梦境碎片、唤醒事件、心语）遵循 spec §11.1 诗歌化·柔和六则（短句呼吸/意象代替说明/留白不写尽/柔和如风/自然词汇/人称柔软）。
- 数值规则（MVP-2 定稿）：
  - 根须探索：每级根须解锁 1 个遗迹；探索消耗树液 200；每遗迹一次性 +1 记忆（BigNum）并触发梦境碎片文本。
  - 人族唤醒：记忆 ≥ 2 触发（`human_awakened` 置 true，一次性事件文本）。
  - 信仰：人族献梦——每 10 tick 自动 +1 信仰（可设 `faith_rate` 系数）；人族存在时人族梦产：每 20 tick 记忆 +1（人族是记忆引擎）。
  - 遗迹总量：MVP-2 定义 4 个遗迹（城市废墟/陵墓/梦田/命运之泉），后续里程碑扩展。
- 存档：`GameState.to_dict/from_dict` 需包含新增字段（旧档缺失回退默认，不得损坏旧档）。
- 工作目录：`E:\world tree`；git master。

---

### Task 1: GameState 扩展（记忆/信仰/根须/人族状态）

**Files:**
- Modify: `features/game/game_state.gd`（加字段 + 序列化）
- Modify: `tests/unit/test_game_state.gd`（补新字段测试）

**Interfaces:**
- Consumes: `BigNum`
- Produces: 新增字段：
  - `memory: BigNum`（初始 0）
  - `faith: BigNum`（初始 0）
  - `root_depth: int = 0`（根须深度，0=未探索）
  - `human_awakened: bool = false`
  - `relics_found: Array[int] = []`（已发现的遗迹 id 列表）
  - `tick` 已有
- 序列化：`to_dict`/`from_dict` 含全部新字段，缺失回退默认。

- [ ] **Step 1: 补失败测试**（test_game_state.gd 追加）

```gdscript
func test_new_fields_initial() -> void:
    var s := GameState.new()
    assert_that(s.memory.to_value()).is_equal(0.0)
    assert_that(s.faith.to_value()).is_equal(0.0)
    assert_that(s.root_depth).is_equal(0)
    assert_that(s.human_awakened).is_false()
    assert_that(s.relics_found).is_empty()

func test_new_fields_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(3.0)
    s.faith = BigNum.new(7.0)
    s.root_depth = 2
    s.human_awakened = true
    s.relics_found = [1, 2]
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.memory.to_value()).is_equal_approx(3.0, 1e-4)
    assert_that(back.faith.to_value()).is_equal_approx(7.0, 1e-4)
    assert_that(back.root_depth).is_equal(2)
    assert_that(back.human_awakened).is_true()
    assert_that(back.relics_found).contains(1)

func test_old_save_fallback() -> void:
    # 旧档无新字段——from_dict 应回退默认不损坏
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.memory.to_value()).is_equal(0.0)
    assert_that(back.faith.to_value()).is_equal(0.0)
    assert_that(back.root_depth).is_equal(0)
    assert_that(back.human_awakened).is_false()
    assert_that(back.relics_found).is_empty()
    assert_that(back.tick).is_equal(5)
```

- [ ] **Step 2: 运行确认失败**

先 `godot --headless --path . --import`，再 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_game_state.gd`
Expected: FAIL（新字段不存在）

- [ ] **Step 3: 扩展 features/game/game_state.gd**

```gdscript
var memory: BigNum
var faith: BigNum
var root_depth: int = 0
var human_awakened: bool = false
var relics_found: Array[int] = []

# _init 中追加：
memory = BigNum.new(0.0)
faith = BigNum.new(0.0)

# to_dict 中追加：
"memory": memory.to_dict(),
"faith": faith.to_dict(),
"root_depth": root_depth,
"human_awakened": human_awakened,
"relics_found": relics_found,

# from_dict 中追加：
s.memory = BigNum.from_dict(d.get("memory", {}))
s.faith = BigNum.from_dict(d.get("faith", {}))
s.root_depth = int(d.get("root_depth", 0))
s.human_awakened = bool(d.get("human_awakened", false))
var rf: Array = d.get("relics_found", [])
s.relics_found = rf.map(func(x): return int(x))
```

- [ ] **Step 4: 运行确认通过**

Run: 同 Step 2 命令（或 `-a res://tests/unit` 全量）
Expected: PASS（新 3 用例 + 旧用例无回归）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState 扩展（记忆/信仰/根须/人族状态 + 序列化回退）"
```

---

### Task 2: 遗迹数据模块 RelicLibrary

**Files:**
- Create: `features/dreams/relic_library.gd`
- Test: `tests/unit/test_relic_library.gd`

**Interfaces:**
- Consumes: 无（数据模块）
- Produces: `class_name RelicLibrary extends RefCounted`：
  - `const RELICS: Array[Dictionary]`（4 个遗迹：id/name/dream_text/reward_memory）
  - `static func all_relics() -> Array[Dictionary]`
  - `static func get_relic(id: int) -> Dictionary`（找不到返回空字典）
  - `static func relic_count() -> int`

**文风铁律**：`dream_text` 必须遵循诗歌化·柔和六则（见 spec §11.1）。

- [ ] **Step 1: 写失败测试**（test_relic_library.gd）

```gdscript
extends GdUnitTestSuite

func test_relic_count() -> void:
    assert_that(RelicLibrary.relic_count()).is_equal(4)

func test_get_relic() -> void:
    var r := RelicLibrary.get_relic(1)
    assert_that(r.get("id", 0)).is_equal(1)
    assert_that(r.has("name")).is_true()
    assert_that(r.has("dream_text")).is_true()
    assert_that(r.has("reward_memory")).is_true()

func test_get_missing_relic_returns_empty() -> void:
    var r := RelicLibrary.get_relic(99)
    assert_that(r.is_empty()).is_true()

func test_all_relics_have_unique_ids() -> void:
    var ids: Array = []
    for r in RelicLibrary.all_relics():
        var id: int = r.get("id", 0)
        assert_that(ids.contains(id)).is_false()
        ids.append(id)
```

- [ ] **Step 2: 运行确认失败**

`godot --headless --path . --import` 后跑 `--add res://tests/unit/test_relic_library.gd`
Expected: FAIL（无法解析 RelicLibrary）

- [ ] **Step 3: 实现 features/dreams/relic_library.gd**

```gdscript
class_name RelicLibrary
extends RefCounted

const RELICS: Array[Dictionary] = [
    {
        "id": 1,
        "name": "城市废墟",
        "dream_text": "你触到一块刻字的石板。\n字你不认得。\n但你的根须认得——\n它在土里埋了太久，连石头都开始忘记。\n\n你在梦里看见一座会发光的城市。\n人们走在街上。\n没有人抬头看天。",
        "reward_memory": 1.0,
    },
    {
        "id": 2,
        "name": "陵墓",
        "dream_text": "石板下有棺。\n棺里有骨。\n骨上有指纹——\n是有人把手按在泥土上留下的。\n\n你第一次意识到：\n这些"它"，曾经是"他们"。",
        "reward_memory": 1.0,
    },
    {
        "id": 3,
        "name": "梦田",
        "dream_text": "这里的土是甜的。\n旧世界的梦沉得太深，化成了肥料。\n\n你吸了一口。\n尝到了许多人的一生。",
        "reward_memory": 1.0,
    },
    {
        "id": 4,
        "name": "命运之泉",
        "dream_text": "泉已经干了。\n但泉底还有一圈湿痕——\n圆的，像什么曾经在这里坐了很久。\n\n你想起自己醒来时，\n手里那一点希望。\n\n它的形状，和这圈湿痕一样。",
        "reward_memory": 1.0,
    },
]

static func all_relics() -> Array[Dictionary]:
    return RELICS

static func get_relic(id: int) -> Dictionary:
    for r in RELICS:
        if r.get("id", 0) == id:
            return r
    return {}

static func relic_count() -> int:
    return RELICS.size()
```

- [ ] **Step 4: 运行确认通过**

Expected: PASS（4 用例）

- [ ] **Step 5: Commit**

```bash
git add features/dreams/relic_library.gd tests/unit/test_relic_library.gd
git commit -m "feat: 遗迹数据模块（4 遗迹梦境文本）"
```

---

### Task 3: 根须探索与梦境逻辑 RootActions

**Files:**
- Create: `features/dreams/root_actions.gd`
- Test: `tests/unit/test_root_actions.gd`

**Interfaces:**
- Consumes: `GameState`、`BigNum`、`RelicLibrary`
- Produces: `class_name RootActions extends RefCounted`：
  - `static func can_explore(state: GameState) -> bool`（`state.root_depth < RelicLibrary.relic_count() and state.sap.is_greater_or_equal(BigNum.new(200.0))`）
  - `static func explore(state: GameState) -> Dictionary`（返回 `{"relic": Dictionary, "text": String, "ok": bool}`；探索：消耗 200 树液、root_depth+1、memory+1、标记 relics_found；不可探索返回 `{"ok": false}`）

- [ ] **Step 1: 写失败测试**（test_root_actions.gd）

```gdscript
extends GdUnitTestSuite

func test_explore_first_relic() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    var result := RootActions.explore(s)
    assert_that(result.get("ok", false)).is_true()
    assert_that(s.root_depth).is_equal(1)
    assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)
    assert_that(s.relics_found.size()).is_equal(1)

func test_explore_insufficient_sap() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(199.0)
    var result := RootActions.explore(s)
    assert_that(result.get("ok", false)).is_false()
    assert_that(s.root_depth).is_equal(0)

func test_explore_all_relics_then_blocked() -> void:
    var s := GameState.new()
    for i in RelicLibrary.relic_count():
        s.sap = BigNum.new(200.0)
        var result := RootActions.explore(s)
        assert_that(result.get("ok", false)).is_true()
    # 第 5 次应被阻止（遗迹耗尽）
    s.sap = BigNum.new(200.0)
    var blocked := RootActions.explore(s)
    assert_that(blocked.get("ok", false)).is_false()
    assert_that(s.root_depth).is_equal(RelicLibrary.relic_count())

func test_can_explore() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    assert_that(RootActions.can_explore(s)).is_true()
    s.sap = BigNum.new(199.0)
    assert_that(RootActions.can_explore(s)).is_false()
```

- [ ] **Step 2: 运行确认失败**

`godot --headless --path . --import` 后跑 `--add res://tests/unit/test_root_actions.gd`
Expected: FAIL（无法解析 RootActions）

- [ ] **Step 3: 实现 features/dreams/root_actions.gd**

```gdscript
class_name RootActions
extends RefCounted

const EXPLORE_COST := 200.0

static func can_explore(state: GameState) -> bool:
    if state.root_depth >= RelicLibrary.relic_count():
        return false
    return state.sap.is_greater_or_equal(BigNum.new(EXPLORE_COST))

static func explore(state: GameState) -> Dictionary:
    if not can_explore(state):
        return {"ok": false}
    var relic := RelicLibrary.get_relic(state.root_depth + 1)
    state.sap.sub(BigNum.new(EXPLORE_COST))
    state.root_depth += 1
    state.memory.add(BigNum.new(float(relic.get("reward_memory", 1.0))))
    state.relics_found.append(int(relic.get("id", 0)))
    return {"ok": true, "relic": relic, "text": str(relic.get("dream_text", ""))}
```

- [ ] **Step 4: 运行确认通过**

Expected: PASS（4 用例）

- [ ] **Step 5: Commit**

```bash
git add features/dreams/root_actions.gd tests/unit/test_root_actions.gd
git commit -m "feat: 根须探索逻辑（遗迹解锁/树液消耗/记忆奖励）"
```

---

### Task 4: 人族系统 RaceManager（唤醒/献梦/梦产）

**Files:**
- Create: `features/races/human_manager.gd`
- Test: `tests/unit/test_human_manager.gd`

**Interfaces:**
- Consumes: `GameState`、`BigNum`
- Produces: `class_name HumanManager extends RefCounted`：
  - `const HUMAN_AWAKEN_MEMORY := 2.0`
  - `static func check_awaken(state: GameState) -> bool`（`not state.human_awakened and state.memory.is_greater_or_equal(BigNum.new(HUMAN_AWAKEN_MEMORY))` 时置 true 返回 true；否则 false）
  - `static func tick_human(state: GameState) -> void`（人族已唤醒时：每 10 tick 信仰 +1（`state.tick % 10 == 0`）、每 20 tick 记忆 +1（`state.tick % 20 == 0`）——人族是记忆引擎）

- [ ] **Step 1: 写失败测试**（test_human_manager.gd）

```gdscript
extends GdUnitTestSuite

func test_awaken_when_memory_enough() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(2.0)
    assert_that(HumanManager.check_awaken(s)).is_true()
    assert_that(s.human_awakened).is_true()
    # 不重复触发
    assert_that(HumanManager.check_awaken(s)).is_false()

func test_no_awaken_before_threshold() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(1.99)
    assert_that(HumanManager.check_awaken(s)).is_false()
    assert_that(s.human_awakened).is_false()

func test_faith_production_on_tick() -> void:
    var s := GameState.new()
    s.human_awakened = true
    s.tick = 10
    HumanManager.tick_human(s)
    assert_that(s.faith.to_value()).is_equal_approx(1.0, 1e-4)

func test_memory_production_on_tick_20() -> void:
    var s := GameState.new()
    s.human_awakened = true
    s.tick = 20
    HumanManager.tick_human(s)
    assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)

func test_no_production_before_awaken() -> void:
    var s := GameState.new()
    s.tick = 20
    HumanManager.tick_human(s)
    assert_that(s.faith.to_value()).is_equal(0.0)
    assert_that(s.memory.to_value()).is_equal(0.0)
```

- [ ] **Step 2: 运行确认失败**

`godot --headless --path . --import` 后跑 `--add res://tests/unit/test_human_manager.gd`
Expected: FAIL（无法解析 HumanManager）

- [ ] **Step 3: 实现 features/races/human_manager.gd**

```gdscript
class_name HumanManager
extends RefCounted

const HUMAN_AWAKEN_MEMORY := 2.0
const FAITH_PER_10_TICKS := 1.0
const MEMORY_PER_20_TICKS := 1.0

static func check_awaken(state: GameState) -> bool:
    if state.human_awakened:
        return false
    if not state.memory.is_greater_or_equal(BigNum.new(HUMAN_AWAKEN_MEMORY)):
        return false
    state.human_awakened = true
    return true

static func tick_human(state: GameState) -> void:
    if not state.human_awakened:
        return
    if state.tick % 10 == 0:
        state.faith.add(BigNum.new(FAITH_PER_10_TICKS))
    if state.tick % 20 == 0:
        state.memory.add(BigNum.new(MEMORY_PER_20_TICKS))
```

- [ ] **Step 4: 运行确认通过**

Expected: PASS（5 用例）

- [ ] **Step 5: Commit**

```bash
git add features/races/human_manager.gd tests/unit/test_human_manager.gd
git commit -m "feat: 人族系统（记忆唤醒/献梦产信仰/梦产记忆）"
```

---

### Task 5: GameManager 集成（动作入口 + 信号）

**Files:**
- Modify: `autoloads/game_manager.gd`
- Test: `tests/unit/test_game_manager.gd`（新文件——GameManager 是 autoload Node，用 GdUnit4 场景/实例测试）

**Interfaces:**
- Consumes: `RootActions`、`HumanManager`、`GameState`
- Produces:
  - `func explore_relic() -> Dictionary`（调 RootActions.explore + emit `relic_discovered` 信号 + `resources_changed`）
  - `func get_memory() -> BigNum`、`func get_faith() -> BigNum`、`func get_root_depth() -> int`、`func is_human_awakened() -> bool`
  - 信号新增：`signal relic_discovered(relic_name: String, dream_text: String)`
  - `_process` 中调 `HumanManager.tick_human(_state)`（在人族唤醒判定后）
  - `_ready` 后调 `HumanManager.check_awaken(_state)`（读档后恢复唤醒状态）

- [ ] **Step 1: 写失败测试**（test_game_manager.gd）

```gdscript
extends GdUnitTestSuite

var gm: Node

func before_test() -> void:
    gm = GameManager.new()

func after_test() -> void:
    gm.free()

func test_explore_relic_signal() -> void:
    gm._state = GameState.new()
    gm._state.sap = BigNum.new(200.0)
    var got_relic := false
    var got_text := ""
    gm.relic_discovered.connect(func(name: String, text: String) -> void:
        got_relic = true
        got_text = text)
    var result := gm.explore_relic()
    assert_that(result.get("ok", false)).is_true()
    assert_that(got_relic).is_true()
    assert_that(got_text.length()).is_greater(10)

func test_getters() -> void:
    gm._state = GameState.new()
    gm._state.memory = BigNum.new(5.0)
    gm._state.faith = BigNum.new(3.0)
    gm._state.root_depth = 2
    gm._state.human_awakened = true
    assert_that(gm.get_memory().to_value()).is_equal_approx(5.0, 1e-4)
    assert_that(gm.get_faith().to_value()).is_equal_approx(3.0, 1e-4)
    assert_that(gm.get_root_depth()).is_equal(2)
    assert_that(gm.is_human_awakened()).is_true()
```

- [ ] **Step 2: 运行确认失败**

`godot --headless --path . --import` 后跑 `--add res://tests/unit/test_game_manager.gd`
Expected: FAIL（explore_relic 等方法不存在；注意 GameManager 是 autoload，`GameManager.new()` 创建独立实例可测）

- [ ] **Step 3: 修改 autoloads/game_manager.gd**

```gdscript
signal resources_changed
signal relic_discovered(relic_name: String, dream_text: String)

# _ready 追加：读档后恢复唤醒状态
HumanManager.check_awaken(_state)

# _process 的 tick 分支内追加：
HumanManager.tick_human(_state)

# 新增方法：
func explore_relic() -> Dictionary:
    var result := RootActions.explore(_state)
    if result.get("ok", false):
        var relic: Dictionary = result.get("relic", {})
        relic_discovered.emit(str(relic.get("name", "")), str(relic.get("dream_text", "")))
        resources_changed.emit()
    return result

func get_memory() -> BigNum:
    return _state.memory

func get_faith() -> BigNum:
    return _state.faith

func get_root_depth() -> int:
    return _state.root_depth

func is_human_awakened() -> bool:
    return _state.human_awakened
```

- [ ] **Step 4: 运行确认通过**

Expected: PASS（2 用例）

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/unit/test_game_manager.gd
git commit -m "feat: GameManager 集成（根须探索入口/人族 tick/信号）"
```

---

### Task 6: UI 扩展（记忆/信仰/根须/遗迹 + 梦境弹层 + 人族事件）

**Files:**
- Modify: `features/ui/main.tscn`（加：记忆/信仰显示、根须探索按钮、梦境文本标签、人族唤醒文本）
- Modify: `features/ui/main.gd`（接信号、刷新新 UI）

**Interfaces:**
- Consumes: `GameManager`（新接口）、`Formatter`、`RelicLibrary`
- Produces: UI 元素（`%UniqueName`）：
  - `MemoryLabel`（记忆：显示）
  - `FaithLabel`（信仰：显示）
  - `RootExploreButton`（根须探索）
  - `DreamPanel` / `DreamTextLabel`（梦境文本展示，探索后显示 3-5 秒或常驻）
  - `HumanEventLabel`（人族唤醒事件文本，一次性）

- [ ] **Step 1: 扩展 main.tscn**（在 `%GrowthLabel` 后追加）

```
[node name="MemoryLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "记忆：0"

[node name="FaithLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "信仰：0"

[node name="RootExploreButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "根须探索（200 树液）"

[node name="DreamPanel" type="PanelContainer" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2

[node name="DreamTextLabel" type="Label" parent="VBox/DreamPanel"]
unique_name_in_owner = true
layout_mode = 2
text = ""
autowrap_mode = 3

[node name="HumanEventLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = ""
```

- [ ] **Step 2: 扩展 main.gd**

```gdscript
@onready var memory_label: Label = %MemoryLabel
@onready var faith_label: Label = %FaithLabel
@onready var root_button: Button = %RootExploreButton
@onready var dream_text_label: Label = %DreamTextLabel
@onready var human_event_label: Label = %HumanEventLabel

# _ready 追加：
root_button.pressed.connect(_on_root_pressed)
GameManager.relic_discovered.connect(_on_relic_discovered)

func _on_root_pressed() -> void:
    var result := GameManager.explore_relic()
    if not result.get("ok", false):
        human_event_label.text = "树液不够。或者……地下已经空了。"

func _on_relic_discovered(relic_name: String, dream_text: String) -> void:
    dream_text_label.text = dream_text
    human_event_label.text = "你在「%s」找到了一段记忆。" % relic_name

func _refresh() -> void:
    # 现有刷新后追加：
    memory_label.text = Formatter.format_number(GameManager.get_memory())
    faith_label.text = Formatter.format_number(GameManager.get_faith())
    root_button.disabled = not RootActions.can_explore(GameManager.get_state())
    # 人族唤醒事件（一次性）
    if GameManager.is_human_awakened() and not _human_announced:
        _human_announced = true
        human_event_label.text = "土里传来一个苍老的声音：\n「你在听吗？……我是最后一个说梦的人。我梦见你很多年了。」"
```

（main.gd 顶部加 `var _human_announced := false`）

- [ ] **Step 3: 验证**

`godot --headless --path . --import`（无 ERROR）→ 全量测试（无回归）→ `godot --headless --path . --quit-after 5`（无脚本报错）

- [ ] **Step 4: Commit**

```bash
git add features/ui/main.tscn features/ui/main.gd
git commit -m "feat: UI 扩展（记忆/信仰/根须探索/梦境文本/人族事件）"
```

---

### Task 7: 集成验证与端到端

**Files:**
- Modify: 无（验证）

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: 全部 PASS、0 failures、退出码 0

- [ ] **Step 2: 端到端玩法验证（临时脚本，验证后删除）**

脚本（`extends SceneTree`）验证：点击采集 → 攒树液 → 探索 4 遗迹（记忆 4）→ 人族唤醒 → tick 产信仰/记忆 → 存档往返含新字段。Expected: 输出 `M2 E2E VERIFY PASSED`。

- [ ] **Step 3: 清理 + 提交**

临时脚本删除、`user://` 无残留、工作区干净；如有修复则提交。

---

## Self-Review 记录（写完计划时自查）

- **Spec 覆盖**：§4.2 抽象轨（记忆/信仰）✓（T1/T4）、§5.1 人族 ✓（T4）、§6 梦境 ✓（T2/T3）、§13.1 根须探索 ✓（T3）、§14 数值（记忆≥2 唤醒、遗迹一次性）✓。林地民/石裔/野民、人口、图书馆、明选按范围草案留里程碑 3+。
- **文风铁律**：T2 遗迹文本 + T6 唤醒文本按诗歌化六则撰写 ✓。
- **接口一致性**：`GameState` 新字段（memory/faith/root_depth/human_awakened/relics_found）在 T1 定义，T3-T6 消费；`RootActions.explore` 返回 `{"ok", "relic", "text"}`，T5 消费；`HumanManager` 方法签名 T5 引用一致；`%UniqueName` 节点 ↔ main.gd 引用一一对应（T6）。
- **兼容性**：GameState 序列化缺字段回退（T1 test_old_save_fallback）——旧档不损坏。
- **数值**：探索消耗 200 树液、记忆≥2 唤醒、信仰每 10 tick +1、记忆每 20 tick +1——与 spec §14 骨架一致（spec 数值为 v1 骨架，实施中如有手感问题记录偏离并回填 spec）。
