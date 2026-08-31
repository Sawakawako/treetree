# Task 2 Brief: 大数模块 big_num.gd

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

## Global Constraints（本任务相关）

- 资源数值一律使用 `BigNum`，禁止裸 `float` 存储资源（防 1e308 INF）。
- typed GDScript。
- 测试命令（GdUnit4 6.2.1，注意：不是 `--run-tests`）：
  `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
- 工作目录：`E:\world tree`。

## Steps

### Step 1: 写失败测试（tests/unit/test_big_num.gd）

```gdscript
extends GdUnitTestSuite

func test_zero() -> void:
    var bn := BigNum.new(0.0)
    assert_that(bn.to_value()).is_equal(0.0)

func test_initialization_normalizes() -> void:
    var bn := BigNum.new(1234.5)
    assert_that(bn.mantissa).is_equal_approx(1.2345)
    assert_that(bn.exponent).is_equal(3)
    assert_that(bn.to_value()).is_equal_approx(1234.5)

func test_add_with_carry() -> void:
    var a := BigNum.new(9.5)
    var b := BigNum.new(0.8)
    a.add(b)
    assert_that(a.to_value()).is_equal_approx(10.3)
    assert_that(a.exponent).is_equal(1)

func test_sub() -> void:
    var a := BigNum.new(500.0)
    var b := BigNum.new(499.0)
    a.sub(b)
    assert_that(a.to_value()).is_equal_approx(1.0)

func test_mul_scalar() -> void:
    var a := BigNum.new(1234.0)
    var c := a.mul_scalar(0.1)
    assert_that(c.to_value()).is_equal_approx(123.4)
    assert_that(a.to_value()).is_equal_approx(1234.0)

func test_compare() -> void:
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(998.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(999.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(1000.0))).is_false()
    assert_that(BigNum.new(1e9).is_greater_or_equal(BigNum.new(9e8))).is_true()

func test_serialization_roundtrip() -> void:
    var bn := BigNum.new(5702887.0)
    var back := BigNum.from_dict(bn.to_dict())
    assert_that(back.to_value()).is_equal_approx(5702887.0)
```

### Step 2: 运行确认失败

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: FAIL（无法解析 `BigNum` 类；具体为编译/解析错误）

### Step 3: 实现 features/economy/big_num.gd

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

### Step 4: 运行确认通过

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`
Expected: PASS（8 个用例全绿，0 failures；也可只跑本文件 `--add res://tests/unit/test_big_num.gd`）

### Step 5: Commit

```bash
git add features/economy/big_num.gd tests/unit/test_big_num.gd
git commit -m "feat: BigNum 大数模块（尾数/指数/加减乘/比较/序列化）"
```

## 验收标准

- [ ] features/economy/big_num.gd 实现完整（typed GDScript）
- [ ] tests/unit/test_big_num.gd 8 个用例全绿（headless 命令退出码 0）
- [ ] 已 commit
