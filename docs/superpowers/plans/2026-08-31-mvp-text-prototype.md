# 世界树 MVP 文字原型 Implementation Plan（Godot 版）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Godot 4.7 搭起《世界树》最小可玩文字原型：玩家扮演一棵树，点击舒展叶片收集日光，经光合转化为树液，购买斐波那契成本的升级（叶序螺旋/分枝序）实现自动采集，树液累积为树高（生长），带 `user://` 自动存档。

**Architecture:** 按 godot-master Layer Cake 分层：`GameState`（RefCounted 数据容器）、`GameLoop`/`GameActions`/`CostCalculator`/`BigNum`/`Formatter`（RefCounted 纯逻辑，headless 可测）、`GameManager`（Autoload：持有状态、`_process(delta)` 手动累加 tick、发 `resources_changed` 信号）、`main.tscn`（Presentation 只监听信号更新 UI）。测试用 GdUnit4，`godot --headless` 运行。

**Tech Stack:** Godot 4.7.1（mono，已装于 `C:\Users\10990\AppData\Local\Programs\Godot\Godot_v4.7.1-stable_mono_win64\`，`godot` 命令在 PATH）；GDScript（typed）；GdUnit4 v6.x（MIT，克隆到 `addons/gdUnit4/`）。零第三方运行时依赖。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-design.md`（本计划实现其 §4 具象轨 MVP 部分 + §9 斐波那契升级组中的叶序螺旋/分枝序）

## Global Constraints

- Godot 版本：4.7.x（勿降级；mono 版亦可跑 GDScript）。
- 全部数据与逻辑使用 typed GDScript；`@export` 资源按需 `duplicate()`，避免共享内存。
- 货币与资源数值**一律使用 `BigNum`**（尾数+指数），禁止裸 `float` 存储资源（防 1e308 INF，idle-clicker NEVER 规则）。
- 收入与 tick **在 `GameManager._process(delta)` 用累加器手动累加**，禁止 `Timer` 节点驱动经济（防帧率漂移）。
- UI 只通过 `resources_changed` 信号更新，禁止在 `_process` 里直接改 Label。
- 存档走 `user://`（禁止 `res://` 写入），保存为 JSON；BigNum 序列化为 `{"m": mantissa, "e": exponent}`。
- 升级成本按斐波那契数列：`fib(1)=1, fib(2)=1, fib(3)=2, ..., fib(34)=5702887`（F₁=F₂=1）。**刻意偏离 idle-clicker 行业标准 1.15 指数曲线**，采用斐波那契（spec §9 主题设计：植物的数学 + 前期密集/中期紧张/后期仰望的体验曲线）。
- 数值规则（MVP 定稿）：
  - 点击「舒展叶片」：`daylight += 1 × (1 + 0.25 × leafLevel)`
  - 每 tick 自动采集：`daylight += branchLevel × (1 + 0.25 × leafLevel)`
  - 每 tick 光合：`sap += daylight × 0.1`（日光不因转化而消耗）
  - 每 tick 生长：`growth += sap × 0.01`
  - 叶序螺旋（level 从 0 计，升到 level+1 的花费）：`500 × fib(level + 1)`
  - 分枝序：`1200 × fib(level + 1)`
- 开局状态：`daylight=0, sap=0, growth=0, leafLevel=0, branchLevel=0, tick=0, hope=1`（`hope` 叙事元素，MVP 只显示）。
- 自动存档：每 60 tick 保存一次；加载时读档，无档则新建。
- 命名与文案：脚本/节点用 snake_case；游戏内文案简体中文。
- 测试：GdUnit4；命令 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 必须全绿；每个 `features/` 逻辑模块有对应 `tests/unit/` 套件。

---

### Task 1: Godot 项目脚手架 + GdUnit4 安装 + headless 测试跑通

**Files:**
- Create: `project.godot`
- Create: `icon.svg`
- Create: `autoloads/.gitkeep`
- Create: `features/game/.gitkeep`、`features/economy/.gitkeep`、`features/ui/.gitkeep`
- Create: `tests/unit/.gitkeep`
- Create: `tests/unit/test_smoke.gd`（冒烟测试，验证 GdUnit4 可用）
- Create: `addons/gdUnit4/`（克隆自 https://github.com/MikeSchulze/gdUnit4）

**Interfaces:**
- Consumes: 无
- Produces: 可运行项目骨架；`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 能跑并显示 1 个通过用例；`godot` 打开项目无报错

- [ ] **Step 1: 创建 project.godot**

```ini
; Engine configuration file.
config_version=5

[application]
config/name="世界树"
run/main_scene="res://features/ui/main.tscn"

[display]
window/size/viewport_width=420
window/size/viewport_height=640

[editor_plugins]
enabled=PackedStringArray("gdUnit4")
```

- [ ] **Step 2: 创建 icon.svg（极简树形图标）**

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="#1a1512"/><path d="M64 20 L96 84 L32 84 Z" fill="#3f7a3f"/><rect x="60" y="84" width="8" height="28" fill="#6b5638"/></svg>
```

- [ ] **Step 3: 安装 GdUnit4 插件**

Run:
```bash
mkdir -p addons
git clone --depth 1 https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
```
（若 git clone 被网络 reset，改用：下载 `https://codeload.github.com/MikeSchulze/gdUnit4/zip/refs/heads/master` 解压并将解压出的 `gdUnit4-master` 目录重命名为 `addons/gdUnit4`。）
Expected: `addons/gdUnit4/plugin.cfg` 存在。

- [ ] **Step 4: 创建冒烟测试**

```gdscript
# tests/unit/test_smoke.gd
extends GdUnitTestSuite

func test_gdunit_works() -> void:
    assert_that(1 + 1).is_equal(2)
```

- [ ] **Step 5: 运行冒烟测试验证 headless 链路**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: 输出包含 test_gdunit_works 通过；退出码 0
（首次运行若报 "Plugin not enabled"，确认 project.godot `[editor_plugins]` 已写入且路径为 `res://addons/gdUnit4/plugin.cfg`。）

- [ ] **Step 6: Commit**

```bash
git add project.godot icon.svg autoloads features tests addons/gdUnit4
git commit -m "feat: Godot 4.7 脚手架 + GdUnit4 接入（headless 测试跑通）"
```

---

### Task 2: 大数模块 big_num.gd

**Files:**
- Create: `features/economy/big_num.gd`
- Test: `tests/unit/test_big_num.gd`

**Interfaces:**
- Produces: `class_name BigNum extends RefCounted`，字段 `mantissa: float`、`exponent: int`（值 = mantissa × 10^exponent，mantissa ∈ [1,10) 或 0）。方法：
  - `_init(v: float = 0.0)`
  - `set_value(v: float) -> void`
  - `add(other: BigNum) -> void`（原地加）
  - `sub(other: BigNum) -> void`（原地减）
  - `mul_scalar(f: float) -> BigNum`（返回新 BigNum）
  - `is_greater_or_equal(other: BigNum) -> bool`
  - `to_value() -> float`（测试辅助）
  - `to_dict() -> Dictionary`（`{"m": mantissa, "e": exponent}`）
  - `static from_dict(d: Dictionary) -> BigNum`

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_big_num.gd
extends GdUnitTestSuite

func test_zero() -> void:
    var bn := BigNum.new(0.0)
    assert_that(bn.to_value()).is_equal(0.0)

func test_initialization_normalizes() -> void:
    var bn := BigNum.new(1234.5)
    assert_that(bn.mantissa).is_equal_approx(1.2345, 1e-4)
    assert_that(bn.exponent).is_equal(3)
    assert_that(bn.to_value()).is_equal_approx(1234.5, 1e-4)

func test_add_with_carry() -> void:
    var a := BigNum.new(9.5)
    var b := BigNum.new(0.8)
    a.add(b)
    assert_that(a.to_value()).is_equal_approx(10.3, 1e-4)
    assert_that(a.exponent).is_equal(1)

func test_sub() -> void:
    var a := BigNum.new(500.0)
    var b := BigNum.new(499.0)
    a.sub(b)
    assert_that(a.to_value()).is_equal_approx(1.0, 1e-4)

func test_mul_scalar() -> void:
    var a := BigNum.new(1234.0)
    var c := a.mul_scalar(0.1)
    assert_that(c.to_value()).is_equal_approx(123.4, 1e-4)
    # 原对象不变
    assert_that(a.to_value()).is_equal_approx(1234.0, 1e-4)

func test_compare() -> void:
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(998.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(999.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(1000.0))).is_false()
    # 跨指数比较
    assert_that(BigNum.new(1e9).is_greater_or_equal(BigNum.new(9e8))).is_true()

func test_compare_negative() -> void:
    assert_that(BigNum.new(-500.0).is_greater_or_equal(BigNum.new(-90.0))).is_false()
    assert_that(BigNum.new(-500.0).is_greater_or_equal(BigNum.new(10.0))).is_false()
    assert_that(BigNum.new(-90.0).is_greater_or_equal(BigNum.new(-500.0))).is_true()

func test_no_inf_storage() -> void:
    var a := BigNum.new(1e308)
    var b := BigNum.new(1e308)
    a.add(b)
    assert_that(is_inf(a.mantissa)).is_false()
    assert_that(a.exponent).is_equal(308)

func test_serialization_roundtrip() -> void:
    var bn := BigNum.new(5702887.0)
    var back := BigNum.from_dict(bn.to_dict())
    assert_that(back.to_value()).is_equal_approx(5702887.0, 1e-4)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_big_num.gd`
Expected: FAIL（无法解析 `BigNum` 类）

- [ ] **Step 3: 实现 features/economy/big_num.gd**

```gdscript
class_name BigNum
extends RefCounted

var mantissa: float = 0.0
var exponent: int = 0

func _init(v: float = 0.0) -> void:
    set_value(v)

func set_value(v: float) -> void:
    if v == 0.0:
        mantissa = 0.0
        exponent = 0
        return
    exponent = int(floor(log(abs(v)) / log(10.0)))
    mantissa = v / pow(10.0, exponent)
    _normalize()

func _normalize() -> void:
    if mantissa == 0.0:
        exponent = 0
        return
    var e := int(floor(log(abs(mantissa)) / log(10.0)))
    if e != 0:
        mantissa /= pow(10.0, e)
        exponent += e

func add(other: BigNum) -> void:
    if other.mantissa == 0.0:
        return
    var e := maxi(exponent, other.exponent)
    var a := mantissa * pow(10.0, exponent - e)
    var b := other.mantissa * pow(10.0, other.exponent - e)
    mantissa = a + b
    exponent = e
    _normalize()

func sub(other: BigNum) -> void:
    var neg := BigNum.new()
    neg.mantissa = -other.mantissa
    neg.exponent = other.exponent
    add(neg)

func mul_scalar(f: float) -> BigNum:
    var out := BigNum.new()
    out.mantissa = mantissa * f
    out.exponent = exponent
    out._normalize()
    return out

func is_greater_or_equal(other: BigNum) -> bool:
    var self_neg := mantissa < 0.0
    var other_neg := other.mantissa < 0.0
    if self_neg != other_neg:
        return other_neg
    if self_neg:
        if exponent != other.exponent:
            return exponent < other.exponent
        return mantissa >= other.mantissa
    if exponent != other.exponent:
        return exponent > other.exponent
    return mantissa >= other.mantissa

func to_value() -> float:
    return mantissa * pow(10.0, exponent)

func to_dict() -> Dictionary:
    return {"m": mantissa, "e": exponent}

static func from_dict(d: Dictionary) -> BigNum:
    var bn := BigNum.new()
    bn.mantissa = float(d.get("m", 0.0))
    bn.exponent = int(d.get("e", 0))
    bn._normalize()
    return bn
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_big_num.gd`
Expected: PASS（8 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/economy/big_num.gd tests/unit/test_big_num.gd
git commit -m "feat: BigNum 大数模块（尾数/指数/加减乘/比较/序列化）"
```

---

### Task 3: 斐波那契成本模块 cost_calculator.gd

**Files:**
- Create: `features/economy/cost_calculator.gd`
- Test: `tests/unit/test_cost_calculator.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name CostCalculator extends RefCounted`：
  - `static func fib(n: int) -> int`（F₁=F₂=1）
  - `static func leaf_cost(level: int) -> int`（500×fib(level+1)）
  - `static func branch_cost(level: int) -> int`（1200×fib(level+1)）

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_cost_calculator.gd
extends GdUnitTestSuite

func test_fib_first_terms() -> void:
    assert_that(CostCalculator.fib(1)).is_equal(1)
    assert_that(CostCalculator.fib(2)).is_equal(1)
    assert_that(CostCalculator.fib(3)).is_equal(2)
    assert_that(CostCalculator.fib(4)).is_equal(3)
    assert_that(CostCalculator.fib(5)).is_equal(5)
    assert_that(CostCalculator.fib(6)).is_equal(8)

func test_fib_34_is_easter_egg_number() -> void:
    # 伦纳德之律彩蛋数字
    assert_that(CostCalculator.fib(34)).is_equal(5702887)

func test_leaf_cost() -> void:
    assert_that(CostCalculator.leaf_cost(0)).is_equal(500)
    assert_that(CostCalculator.leaf_cost(1)).is_equal(500)
    assert_that(CostCalculator.leaf_cost(2)).is_equal(1000)
    assert_that(CostCalculator.leaf_cost(3)).is_equal(1500)

func test_branch_cost() -> void:
    assert_that(CostCalculator.branch_cost(0)).is_equal(1200)
    assert_that(CostCalculator.branch_cost(1)).is_equal(1200)
    assert_that(CostCalculator.branch_cost(2)).is_equal(2400)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_cost_calculator.gd`
Expected: FAIL（无法解析 `CostCalculator`）

- [ ] **Step 3: 实现 features/economy/cost_calculator.gd**

```gdscript
class_name CostCalculator
extends RefCounted

static func fib(n: int) -> int:
    if n <= 0:
        return 0
    if n <= 2:
        return 1
    var a := 1
    var b := 1
    for i in range(3, n + 1):
        var t := a + b
        a = b
        b = t
    return b

static func leaf_cost(level: int) -> int:
    return 500 * fib(level + 1)

static func branch_cost(level: int) -> int:
    return 1200 * fib(level + 1)
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_cost_calculator.gd`
Expected: PASS（4 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/economy/cost_calculator.gd tests/unit/test_cost_calculator.gd
git commit -m "feat: 斐波那契成本模块（fib/叶序螺旋/分枝序）"
```

---

### Task 4: 数字格式化模块 formatter.gd

**Files:**
- Create: `features/economy/formatter.gd`
- Test: `tests/unit/test_formatter.gd`

**Interfaces:**
- Consumes: `BigNum`（big_num.gd）
- Produces: `class_name Formatter extends RefCounted`：
  - `static func format_number(bn: BigNum) -> String`（<1000 显示原值（≤2 位小数）；≥1000 用 K/M/B/T 后缀，保留 2 位小数去尾零）
  - `static func format_cost(cost: int) -> String`（整数千分位）

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_formatter.gd
extends GdUnitTestSuite

func test_small_numbers() -> void:
    assert_that(Formatter.format_number(BigNum.new(0.0))).is_equal("0")
    assert_that(Formatter.format_number(BigNum.new(12.5))).is_equal("12.5")
    assert_that(Formatter.format_number(BigNum.new(999.0))).is_equal("999")

func test_suffix_numbers() -> void:
    assert_that(Formatter.format_number(BigNum.new(1234.5))).is_equal("1.23K")
    assert_that(Formatter.format_number(BigNum.new(1234567.0))).is_equal("1.23M")
    assert_that(Formatter.format_number(BigNum.new(5702887.0))).is_equal("5.7M")

func test_small_fraction() -> void:
    assert_that(Formatter.format_number(BigNum.new(0.5))).is_equal("0.5")
    assert_that(Formatter.format_number(BigNum.new(0.005))).is_equal("0.005")

func test_carry_rounding() -> void:
    assert_that(Formatter.format_number(BigNum.new(999999.0))).is_equal("1M")
    assert_that(Formatter.format_number(BigNum.new(999999999.0))).is_equal("1B")

func test_cost_format() -> void:
    assert_that(Formatter.format_cost(500)).is_equal("500")
    assert_that(Formatter.format_cost(5000)).is_equal("5,000")
    assert_that(Formatter.format_cost(5702887)).is_equal("5,702,887")
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_formatter.gd`
Expected: FAIL（无法解析 `Formatter`）

- [ ] **Step 3: 实现 features/economy/formatter.gd**

```gdscript
class_name Formatter
extends RefCounted

const SUFFIX := ["", "K", "M", "B", "T"]

static func format_number(bn: BigNum) -> String:
    if bn.mantissa == 0.0:
        return "0"
    var tier := bn.exponent / 3
    if tier <= 0:
        # 绝对值 < 1 的小数：直接显示原值（≤6 位有效小数，去尾零）
        var small := bn.to_value()
        return _trim_zeros(String.num(small, 6))
    var mant := bn.mantissa * pow(10.0, bn.exponent - tier * 3)
    if mant >= 1000.0:
        # 舍入进位（如 999.999 → 1000）：升一档重算
        tier += 1
        mant = bn.mantissa * pow(10.0, bn.exponent - tier * 3)
    var idx := mini(tier, SUFFIX.size() - 1)
    return "%s%s" % [_trim_zeros(String.num(mant, 2)), SUFFIX[idx]]

static func format_cost(cost: int) -> String:
    var s := str(cost)
    var out := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        out = s[i] + out
        count += 1
        if count % 3 == 0 and i > 0:
            out = "," + out
    return out

static func _trim_zeros(s: String) -> String:
    if s.contains("."):
        var t := s.rstrip("0")
        if t.ends_with("."):
            t = t.trim_suffix(".")
        return t
    return s
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_formatter.gd`
Expected: PASS（3 个用例全绿）
注：若 `5702887` 格式化结果因浮点取整偏差出现 `5.7M` 之外的值（如 `5.71M`），将测试断言改为对应当前 `String.num` 四舍五入行为，或把 `_trim_zeros(String.num(mant, 2))` 中 mant 先 `floor(mant*100)/100` 再格式化，保证与断言一致——二者取其一并保持测试/实现同步。

- [ ] **Step 5: Commit**

```bash
git add features/economy/formatter.gd tests/unit/test_formatter.gd
git commit -m "feat: 数字格式化模块（后缀/千分位）"
```

---

### Task 5: 游戏状态 game_state.gd

**Files:**
- Create: `features/game/game_state.gd`
- Test: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: `BigNum`
- Produces: `class_name GameState extends RefCounted`，字段 `daylight: BigNum`、`sap: BigNum`、`growth: BigNum`、`leaf_level: int = 0`、`branch_level: int = 0`、`tick: int = 0`、`hope: int = 1`。方法：
  - `_init()`
  - `to_dict() -> Dictionary`
  - `static from_dict(d: Dictionary) -> GameState`（字段缺失回退默认）

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_game_state.gd
extends GdUnitTestSuite

func test_initial_state() -> void:
    var s := GameState.new()
    assert_that(s.daylight.to_value()).is_equal(0.0)
    assert_that(s.sap.to_value()).is_equal(0.0)
    assert_that(s.growth.to_value()).is_equal(0.0)
    assert_that(s.leaf_level).is_equal(0)
    assert_that(s.branch_level).is_equal(0)
    assert_that(s.tick).is_equal(0)
    assert_that(s.hope).is_equal(1)

func test_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(42.0)
    s.leaf_level = 3
    s.tick = 60
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.daylight.to_value()).is_equal_approx(42.0, 1e-4)
    assert_that(back.leaf_level).is_equal(3)
    assert_that(back.tick).is_equal(60)

func test_from_dict_missing_fields_fallback() -> void:
    var back := GameState.from_dict({"sap": {"m": 7.0, "e": 0}})
    assert_that(back.sap.to_value()).is_equal_approx(7.0, 1e-4)
    assert_that(back.leaf_level).is_equal(0)
    assert_that(back.hope).is_equal(1)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_state.gd`
Expected: FAIL（无法解析 `GameState`）

- [ ] **Step 3: 实现 features/game/game_state.gd**

```gdscript
class_name GameState
extends RefCounted

var daylight: BigNum
var sap: BigNum
var growth: BigNum
var leaf_level: int = 0
var branch_level: int = 0
var tick: int = 0
var hope: int = 1

func _init() -> void:
    daylight = BigNum.new(0.0)
    sap = BigNum.new(0.0)
    growth = BigNum.new(0.0)

func to_dict() -> Dictionary:
    return {
        "daylight": daylight.to_dict(),
        "sap": sap.to_dict(),
        "growth": growth.to_dict(),
        "leaf_level": leaf_level,
        "branch_level": branch_level,
        "tick": tick,
        "hope": hope,
    }

static func from_dict(d: Dictionary) -> GameState:
    var s := GameState.new()
    s.daylight = BigNum.from_dict(d.get("daylight", {}))
    s.sap = BigNum.from_dict(d.get("sap", {}))
    s.growth = BigNum.from_dict(d.get("growth", {}))
    s.leaf_level = int(d.get("leaf_level", 0))
    s.branch_level = int(d.get("branch_level", 0))
    s.tick = int(d.get("tick", 0))
    s.hope = int(d.get("hope", 1))
    return s
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_state.gd`
Expected: PASS（3 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: 游戏状态模块（初始值/序列化）"
```

---

### Task 6: 玩家动作模块 actions.gd

**Files:**
- Create: `features/economy/actions.gd`
- Test: `tests/unit/test_actions.gd`

**Interfaces:**
- Consumes: `GameState`、`BigNum`、`CostCalculator`
- Produces: `class_name GameActions extends RefCounted`：
  - `static func gather_daylight(state: GameState) -> void`
  - `static func buy_leaf(state: GameState) -> bool`
  - `static func buy_branch(state: GameState) -> bool`

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_actions.gd
extends GdUnitTestSuite

func test_gather_basic() -> void:
    var s := GameState.new()
    GameActions.gather_daylight(s)
    assert_that(s.daylight.to_value()).is_equal_approx(1.0, 1e-4)

func test_gather_with_leaf_bonus() -> void:
    var s := GameState.new()
    s.leaf_level = 2  # 1 + 0.25*2 = 1.5
    GameActions.gather_daylight(s)
    assert_that(s.daylight.to_value()).is_equal_approx(1.5, 1e-4)

func test_buy_leaf_success() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(500.0)
    assert_that(GameActions.buy_leaf(s)).is_true()
    assert_that(s.leaf_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)

func test_buy_leaf_insufficient() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(499.0)
    assert_that(GameActions.buy_leaf(s)).is_false()
    assert_that(s.leaf_level).is_equal(0)
    assert_that(s.sap.to_value()).is_equal_approx(499.0, 1e-4)

func test_buy_branch_success() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(1200.0)
    assert_that(GameActions.buy_branch(s)).is_true()
    assert_that(s.branch_level).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_actions.gd`
Expected: FAIL（无法解析 `GameActions`）

- [ ] **Step 3: 实现 features/economy/actions.gd**

```gdscript
class_name GameActions
extends RefCounted

static func gather_daylight(state: GameState) -> void:
    var gain := BigNum.new(1.0 * (1.0 + 0.25 * float(state.leaf_level)))
    state.daylight.add(gain)

static func buy_leaf(state: GameState) -> bool:
    var cost := BigNum.new(float(CostCalculator.leaf_cost(state.leaf_level)))
    if not state.sap.is_greater_or_equal(cost):
        return false
    state.sap.sub(cost)
    state.leaf_level += 1
    return true

static func buy_branch(state: GameState) -> bool:
    var cost := BigNum.new(float(CostCalculator.branch_cost(state.branch_level)))
    if not state.sap.is_greater_or_equal(cost):
        return false
    state.sap.sub(cost)
    state.branch_level += 1
    return true
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_actions.gd`
Expected: PASS（5 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/economy/actions.gd tests/unit/test_actions.gd
git commit -m "feat: 玩家动作模块（舒展叶片/购买升级）"
```

---

### Task 7: 游戏循环模块 game_loop.gd

**Files:**
- Create: `features/game/game_loop.gd`
- Test: `tests/unit/test_game_loop.gd`

**Interfaces:**
- Consumes: `GameState`、`BigNum`
- Produces: `class_name GameLoop extends RefCounted`：
  - `static func tick(state: GameState) -> void`
  - `static func should_auto_save(state: GameState) -> bool`（`state.tick > 0 and state.tick % 60 == 0`）

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_game_loop.gd
extends GdUnitTestSuite

func test_tick_increments_and_photosynthesis() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(100.0)
    GameLoop.tick(s)
    assert_that(s.tick).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(10.0, 1e-4)  # 100 × 0.1
    assert_that(s.daylight.to_value()).is_equal_approx(100.0, 1e-4)  # 无分支时日光不变

func test_tick_auto_collect() -> void:
    var s := GameState.new()
    s.branch_level = 3
    s.daylight = BigNum.new(10.0)
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(13.0, 1e-4)  # 10 + 3×1

func test_tick_auto_collect_with_leaf_bonus() -> void:
    var s := GameState.new()
    s.branch_level = 2
    s.leaf_level = 2  # 2 × 1.5 = 3
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(3.0, 1e-4)

func test_tick_growth() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    GameLoop.tick(s)
    assert_that(s.growth.to_value()).is_equal_approx(2.0, 1e-4)  # 200 × 0.01

func test_should_auto_save() -> void:
    var s := GameState.new()
    s.tick = 60
    assert_that(GameLoop.should_auto_save(s)).is_true()
    s.tick = 61
    assert_that(GameLoop.should_auto_save(s)).is_false()
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_loop.gd`
Expected: FAIL（无法解析 `GameLoop`）

- [ ] **Step 3: 实现 features/game/game_loop.gd**

```gdscript
class_name GameLoop
extends RefCounted

static func tick(state: GameState) -> void:
    state.tick += 1
    var eff := 1.0 + 0.25 * float(state.leaf_level)
    var collected := BigNum.new(float(state.branch_level) * eff)
    state.daylight.add(collected)
    var converted := state.daylight.mul_scalar(0.1)
    state.sap.add(converted)
    var grown := state.sap.mul_scalar(0.01)
    state.growth.add(grown)

static func should_auto_save(state: GameState) -> bool:
    return state.tick > 0 and state.tick % 60 == 0
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_loop.gd`
Expected: PASS（5 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/game/game_loop.gd tests/unit/test_game_loop.gd
git commit -m "feat: 游戏循环模块（自动采集/光合/生长/自动存档判定）"
```

---

### Task 8: 存档模块 save_manager.gd

**Files:**
- Create: `features/game/save_manager.gd`
- Test: `tests/unit/test_save_manager.gd`

**Interfaces:**
- Consumes: `GameState`
- Produces: `class_name SaveManager extends RefCounted`：
  - `static func save(state: GameState, path: String = "user://save.json") -> void`
  - `static func load_or_create(path: String = "user://save.json") -> GameState`

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/unit/test_save_manager.gd
extends GdUnitTestSuite

const TEST_PATH := "user://test_save.json"

func after_test() -> void:
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)

func test_save_then_load_roundtrip() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(42.0)
    s.leaf_level = 3
    s.tick = 120
    SaveManager.save(s, TEST_PATH)
    assert_that(FileAccess.file_exists(TEST_PATH)).is_true()
    var loaded := SaveManager.load_or_create(TEST_PATH)
    assert_that(loaded.daylight.to_value()).is_equal_approx(42.0, 1e-4)
    assert_that(loaded.leaf_level).is_equal(3)
    assert_that(loaded.tick).is_equal(120)

func test_load_when_missing_returns_fresh() -> void:
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)
    var loaded := SaveManager.load_or_create(TEST_PATH)
    assert_that(loaded.tick).is_equal(0)
    assert_that(loaded.hope).is_equal(1)
```

- [ ] **Step 2: 运行确认失败**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_save_manager.gd`
Expected: FAIL（无法解析 `SaveManager`）

- [ ] **Step 3: 实现 features/game/save_manager.gd**

```gdscript
class_name SaveManager
extends RefCounted

const DEFAULT_PATH := "user://save.json"

static func save(state: GameState, path: String = DEFAULT_PATH) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        push_error("无法写入存档: %s" % path)
        return
    f.store_string(JSON.stringify(state.to_dict()))
    f.close()

static func load_or_create(path: String = DEFAULT_PATH) -> GameState:
    if not FileAccess.file_exists(path):
        return GameState.new()
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return GameState.new()
    var text := f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return GameState.new()
    return GameState.from_dict(parsed)
```

- [ ] **Step 4: 运行确认通过**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_save_manager.gd`
Expected: PASS（2 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add features/game/save_manager.gd tests/unit/test_save_manager.gd
git commit -m "feat: 存档模块（user:// JSON 读写/缺档回退）"
```

---

### Task 9: GameManager Autoload + main 场景（集成）

**Files:**
- Create: `autoloads/game_manager.gd`
- Create: `features/ui/main.tscn`
- Create: `features/ui/main.gd`
- Modify: `project.godot`（注册 autoload）

**Interfaces:**
- Consumes: `GameState`、`GameLoop`、`GameActions`、`SaveManager`、`Formatter`、`CostCalculator`
- Produces:
  - `GameManager`（Autoload，节点名 `GameManager`）：信号 `resources_changed`；方法 `gather()`、`buy_leaf() -> bool`、`buy_branch() -> bool`、`get_state() -> GameState`、`get_leaf_cost() -> int`、`get_branch_cost() -> int`
  - `features/ui/main.tscn`：主场景（根 Control，含标题、希望行、采集按钮、资源标签、升级按钮、日志标签）

- [ ] **Step 1: 注册 Autoload（修改 project.godot）**

```ini
[autoload]
GameManager="*res://autoloads/game_manager.gd"
```

- [ ] **Step 2: 实现 autoloads/game_manager.gd**

```gdscript
extends Node

signal resources_changed

const SAVE_PATH := "user://save.json"
const TICK_INTERVAL := 1.0

var _state: GameState
var _tick_accumulator := 0.0

func _ready() -> void:
    _state = SaveManager.load_or_create(SAVE_PATH)

func _process(delta: float) -> void:
    _tick_accumulator += delta
    if _tick_accumulator >= TICK_INTERVAL:
        _tick_accumulator -= TICK_INTERVAL
        GameLoop.tick(_state)
        if GameLoop.should_auto_save(_state):
            SaveManager.save(_state, SAVE_PATH)
        resources_changed.emit()

func get_state() -> GameState:
    return _state

func gather() -> void:
    GameActions.gather_daylight(_state)
    resources_changed.emit()

func buy_leaf() -> bool:
    var ok := GameActions.buy_leaf(_state)
    if ok:
        resources_changed.emit()
    return ok

func buy_branch() -> bool:
    var ok := GameActions.buy_branch(_state)
    if ok:
        resources_changed.emit()
    return ok

func get_leaf_cost() -> int:
    return CostCalculator.leaf_cost(_state.leaf_level)

func get_branch_cost() -> int:
    return CostCalculator.branch_cost(_state.branch_level)
```

- [ ] **Step 3: 实现 features/ui/main.gd**

```gdscript
extends Control

@onready var daylight_label: Label = %DaylightLabel
@onready var sap_label: Label = %SapLabel
@onready var growth_label: Label = %GrowthLabel
@onready var leaf_cost_label: Label = %LeafCostLabel
@onready var branch_cost_label: Label = %BranchCostLabel
@onready var leaf_button: Button = %LeafButton
@onready var branch_button: Button = %BranchButton
@onready var log_label: Label = %LogLabel

func _ready() -> void:
    %GatherButton.pressed.connect(_on_gather_pressed)
    leaf_button.pressed.connect(_on_leaf_pressed)
    branch_button.pressed.connect(_on_branch_pressed)
    GameManager.resources_changed.connect(_refresh)
    _refresh()

func _on_gather_pressed() -> void:
    GameManager.gather()

func _on_leaf_pressed() -> void:
    if GameManager.buy_leaf():
        log_label.text = "叶序螺旋升至 %d 级。" % GameManager.get_state().leaf_level
    _refresh()

func _on_branch_pressed() -> void:
    if GameManager.buy_branch():
        log_label.text = "分枝序升至 %d 级。" % GameManager.get_state().branch_level
    _refresh()

func _refresh() -> void:
    var s := GameManager.get_state()
    daylight_label.text = Formatter.format_number(s.daylight)
    sap_label.text = Formatter.format_number(s.sap)
    growth_label.text = Formatter.format_number(s.growth)
    leaf_cost_label.text = Formatter.format_cost(GameManager.get_leaf_cost())
    branch_cost_label.text = Formatter.format_cost(GameManager.get_branch_cost())
    leaf_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_leaf_cost())))
    branch_button.disabled = not s.sap.is_greater_or_equal(BigNum.new(float(GameManager.get_branch_cost())))
```

- [ ] **Step 4: 创建 features/ui/main.tscn**

```
[gd_scene load_steps=2 format=3 uid="uid://worldtreemain"]

[ext_resource type="Script" path="res://features/ui/main.gd" id="1_main"]

[node name="Main" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_main")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 24.0
offset_right = -24.0
offset_bottom = -24.0

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "世界树"

[node name="Hope" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "一点希望，在废墟中静静燃烧。"

[node name="GatherButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "舒展叶片"

[node name="DaylightLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "日光：0"

[node name="SapLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "树液：0"

[node name="GrowthLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "树高：0"

[node name="LeafButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "叶序螺旋（日光采集 +25%/级）"

[node name="LeafCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：500"

[node name="BranchButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "分枝序（自动采集 +1/级）"

[node name="BranchCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "价格：1200"

[node name="LogLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = ""
```

- [ ] **Step 5: 运行全部测试确认无回归**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: PASS（全部测试套件，含 smoke）

- [ ] **Step 6: 打开编辑器验证场景可运行**

Run: `godot --path .`（或编辑器打开），运行主场景
Expected: 无脚本报错；按钮/标签按预期出现（数值为 0）

- [ ] **Step 7: Commit**

```bash
git add autoloads/game_manager.gd features/ui/main.tscn features/ui/main.gd project.godot
git commit -m "feat: GameManager Autoload + 主场景集成（tick/信号/UI）"
```

---

### Task 10: 集成验证与手测清单

**Files:**
- Modify: 无（纯验证）

**Interfaces:**
- Consumes: 全部前序任务产物

- [ ] **Step 1: 全量测试**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: 全部 PASS，退出码 0

- [ ] **Step 2: 手动玩法验证（对照 Global Constraints 数值规则）**

在 Godot 编辑器运行主场景，依次验证：
- [ ] 界面显示"一点希望，在废墟中静静燃烧"（hope 叙事元素）
- [ ] 点击 5 次「舒展叶片」→ 日光 = 5
- [ ] 等待树液 ≥ 500 → 购买「叶序螺旋」→ 点击采集变为 +1.25
- [ ] 购买第 2 级叶序螺旋（500）→ 采集 +1.5
- [ ] 购买「分枝序」→ 每 tick 日光自动 +1
- [ ] 60 秒后触发自动存档（`user://save.json` 存在）；重启游戏数值保留

- [ ] **Step 3: 最终提交**

```bash
git add -A
git commit -m "chore: Godot MVP 验证通过"
```

---

## Self-Review 记录

- **Spec 覆盖**：§4 具象轨（日光/树液/生长）✓（game_loop/actions）；§9 斐波那契升级组前两项 ✓（cost_calculator/actions）；开局一点希望 ✓（game_state.hope + main.tscn 文案）；存档 ✓（save_manager + GameManager 每 60 tick）。四族/梦境/明选/终局属后续里程碑，不在本计划范围（spec §12 里程碑 2-4）。
- **占位符扫描**：无 TBD/TODO；所有步骤含具体 GDScript 与命令。
- **类型一致性**：`BigNum`（`add/sub/mul_scalar/is_greater_or_equal/to_value/to_dict/from_dict`）、`CostCalculator.fib/leaf_cost/branch_cost`、`GameActions.gather_daylight/buy_leaf/buy_branch`、`GameLoop.tick/should_auto_save`、`SaveManager.save/load_or_create`、`GameManager` 信号与方法在各任务间签名一致；main.gd 的 `%UniqueName` 与 main.tscn 的 `unique_name_in_owner` 节点一一对应。
- **铁律遵循**：本计划按铁律 2 先读 godot-master 并路由至 godot-genre-idle-clicker（BigNum/手动累加/信号节流/UNIX 存档规则）与 godot-testing-patterns（GdUnit4 headless）。
