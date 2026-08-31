# Task 4 Brief: 数字格式化模块 formatter.gd

**Files:**
- Create: `features/economy/formatter.gd`
- Test: `tests/unit/test_formatter.gd`

**Interfaces:**
- Consumes: `BigNum`（features/economy/big_num.gd，Task 2 已实现：`mantissa`/`exponent` 字段、`to_value()`）
- Produces: `class_name Formatter extends RefCounted`：
  - `static func format_number(bn: BigNum) -> String`（<1000 显示原值（≤2 位小数）；≥1000 用 K/M/B/T 后缀，保留 2 位小数去尾零）
  - `static func format_cost(cost: int) -> String`（整数千分位）

## Global Constraints（本任务相关）

- typed GDScript。
- 测试命令（GdUnit4 6.2.1）：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`（新增 class_name 脚本后先跑 `godot --headless --path . --import`）
- **注意：GdUnit4 6.2.1 的 `is_equal_approx` 是双参数签名 `(expected, approx)`**，测试代码统一带容差。
- 工作目录：`E:\world tree`。

## Steps

### Step 1: 写失败测试（tests/unit/test_formatter.gd）

```gdscript
extends GdUnitTestSuite

func test_small_numbers() -> void:
    assert_that(Formatter.format_number(BigNum.new(0.0))).is_equal("0")
    assert_that(Formatter.format_number(BigNum.new(12.5))).is_equal("12.5")
    assert_that(Formatter.format_number(BigNum.new(999.0))).is_equal("999")

func test_suffix_numbers() -> void:
    assert_that(Formatter.format_number(BigNum.new(1234.5))).is_equal("1.23K")
    assert_that(Formatter.format_number(BigNum.new(1234567.0))).is_equal("1.23M")
    assert_that(Formatter.format_number(BigNum.new(5702887.0))).is_equal("5.7M")

func test_cost_format() -> void:
    assert_that(Formatter.format_cost(500)).is_equal("500")
    assert_that(Formatter.format_cost(5000)).is_equal("5,000")
    assert_that(Formatter.format_cost(5702887)).is_equal("5,702,887")
```

### Step 2: 运行确认失败

先注册类缓存：Run: `godot --headless --path . --import`（退出码 0）
然后：Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_formatter.gd`
Expected: FAIL（无法解析 `Formatter`）

### Step 3: 实现 features/economy/formatter.gd

```gdscript
class_name Formatter
extends RefCounted

const SUFFIX := ["", "K", "M", "B", "T"]

static func format_number(bn: BigNum) -> String:
    if bn.mantissa == 0.0:
        return "0"
    var tier := bn.exponent / 3
    if tier == 0:
        var small := bn.to_value()
        var rounded := floor(small * 100.0) / 100.0
        return _trim_zeros(String.num(rounded, 2))
    var mant := bn.mantissa * pow(10.0, bn.exponent - tier * 3)
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

### Step 4: 运行确认通过

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_formatter.gd`
Expected: PASS（3 个用例全绿，0 failures）
**注意**：若 `5702887.0` 格式化结果因浮点取整偏差出现 `5.7M` 之外的值（如 `5.71M`），调整实现使结果与测试断言一致——优先在 `_trim_zeros` 前对 mant 做 `floor(mant*100)/100`（实现已含），并保持测试/实现同步。测试是权威，实现向测试对齐。

### Step 5: Commit

```bash
git add features/economy/formatter.gd tests/unit/test_formatter.gd
git commit -m "feat: 数字格式化模块（后缀/千分位）"
```

## 验收标准

- [ ] features/economy/formatter.gd 实现完整（typed GDScript，static 方法）
- [ ] tests/unit/test_formatter.gd 3 个用例全绿（headless 退出码 0）
- [ ] 已 commit
