# Task 3 Brief: 斐波那契成本模块 cost_calculator.gd

**Files:**
- Create: `features/economy/cost_calculator.gd`
- Test: `tests/unit/test_cost_calculator.gd`

**Interfaces:**
- Consumes: 无（独立数学模块）
- Produces: `class_name CostCalculator extends RefCounted`：
  - `static func fib(n: int) -> int`（F₁=F₂=1，`fib(1)=1, fib(2)=1, fib(34)=5702887`）
  - `static func leaf_cost(level: int) -> int`（500×fib(level+1)）
  - `static func branch_cost(level: int) -> int`（1200×fib(level+1)）

## Global Constraints（本任务相关）

- 升级成本按斐波那契数列（刻意偏离 idle 行业 1.15 指数，spec 主题设计）。
- typed GDScript。
- 测试命令（GdUnit4 6.2.1）：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
- 工作目录：`E:\world tree`。

## Steps

### Step 1: 写失败测试（tests/unit/test_cost_calculator.gd）

```gdscript
extends GdUnitTestSuite

func test_fib_first_terms() -> void:
    assert_that(CostCalculator.fib(1)).is_equal(1)
    assert_that(CostCalculator.fib(2)).is_equal(1)
    assert_that(CostCalculator.fib(3)).is_equal(2)
    assert_that(CostCalculator.fib(4)).is_equal(3)
    assert_that(CostCalculator.fib(5)).is_equal(5)
    assert_that(CostCalculator.fib(6)).is_equal(8)

func test_fib_34_is_easter_egg_number() -> void:
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

### Step 2: 运行确认失败

先注册类缓存（新增 class_name 脚本后的必需步骤）：
Run: `godot --headless --path . --import`
Expected: 退出码 0（注册 CostCalculator 类）

然后：
Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_cost_calculator.gd`
Expected: FAIL（无法解析 `CostCalculator`）

### Step 3: 实现 features/economy/cost_calculator.gd

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

### Step 4: 运行确认通过

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_cost_calculator.gd`
Expected: PASS（4 个用例全绿，0 failures）
注：若新增脚本后测试仍报类未声明，先跑 `godot --headless --path . --import` 再测。

### Step 5: Commit

```bash
git add features/economy/cost_calculator.gd tests/unit/test_cost_calculator.gd
git commit -m "feat: 斐波那契成本模块（fib/叶序螺旋/分枝序）"
```

## 验收标准

- [ ] features/economy/cost_calculator.gd 实现完整（typed GDScript，static 方法）
- [ ] tests/unit/test_cost_calculator.gd 4 个用例全绿（headless 退出码 0）
- [ ] 已 commit
