# Task 2 审查报告：大数模块 big_num.gd

**审查者**：任务审查代理
**审查对象**：`features/economy/big_num.gd` + `tests/unit/test_big_num.gd`（commit `8221293`）
**审查方式**：独立复现（不信任报告结论）——逐行 diff、源码核对 GdUnit4 API、实测重跑测试、探针脚本验证数学行为。

---

## 审查结论

| 判定 | 结果 | 一句话依据 |
|---|---|---|
| **Spec 合规** | **✅** | 实现与 brief 逐字一致（已逐行核对）；8/8 用例实测全绿、退出码 0；已 commit；接口/typed/测试命令全部满足 |
| **任务质量** | **需修改** | `is_greater_or_equal` 存在**已实测复现**的负数比较错误（3/3 全错），且该模块是全局约束点名的"后续资源地基"——需修复并补回归测试后合入 |

**问题计数**：Critical 0 · Important 1 · Minor 4 · Info 2（共 7）

---

## 一、Spec 合规判定：✅（逐条依据）

### 1.1 实现与 brief 逐字一致——**已核实，属实**

`features/economy/big_num.gd`（67 行）与 brief Step 3 代码块逐行比对**零差异**（含缩进、注释缺失、空行）。实施者声明"big_num.gd 与 brief 逐字一致、未改动"**确认无误**。

### 1.2 接口完整性——全部满足

| brief 接口 | 实现 | 状态 |
|---|---|---|
| `class_name BigNum extends RefCounted` | ✓ | 字段 `mantissa: float`、`exponent: int`（值 = m×10^e） |
| `_init(v: float = 0.0) -> void` | ✓ | |
| `set_value(v: float) -> void` | ✓ | |
| `add(other) -> void`（原地） | ✓ | |
| `sub(other) -> void`（原地） | ✓ | |
| `mul_scalar(f: float) -> BigNum`（返回新对象） | ✓ | 实测不修改原对象 |
| `is_greater_or_equal(other) -> bool` | ✓ 存在但**负数语义有缺陷**（见 Important #1） | |
| `to_value() -> float`、`to_dict() -> Dictionary` | ✓ | `{"m","e"}` 与 brief 一致 |
| `static from_dict(d) -> BigNum` | ✓ | |

### 1.3 Global Constraints——满足

- **BigNum 存储、禁裸 float 存资源**：本任务即资源存储层本身，字段为 `float mantissa + int exponent` 结构，符合防 1e308 INF 的全局约束（实测 `1e308+1e308` 存储层为 `m=2.0, e=308`，不产生 INF，见 3.2）。✓
- **typed GDScript**：所有参数/返回值/字段全类型标注。✓
- **测试命令**：与 brief 逐字一致（`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`），实测可跑通。✓

### 1.4 验收标准——全部满足（含独立复现）

- [x] `features/economy/big_num.gd` 实现完整（typed GDScript）——与 brief 逐字一致
- [x] **8 个用例全绿、退出码 0——审查者独立重跑实测：`Overall Summary: 8 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED`，`EXIT=0`**（7 = test_big_num 的 7 个用例 + 1 = Task 1 遗留的 test_smoke，与报告口径一致）
- [x] 已 commit：`8221293` 存在，stat 与 review 包完全一致（4 文件 / 113 insertions）；`.uid` 跟随 Task 1 约定提交（`test_smoke.gd.uid` 确已被跟踪）；工作区仅剩 `.superpowers/` 未跟踪（`.godot/`、`/reports/` 均在 .gitignore）

### 1.5 实施者 2 处测试调整——评估结论：**均合理，且第一处为必需**

1. **`--import` 先注册 class_name**：合理且必要。Godot 的 `-s` 脚本模式不扫描新脚本刷新 `global_script_class_cache.cfg`，这是引擎已知行为；实测当前缓存 `.godot/global_script_class_cache.cfg` 中已含 `BigNum` 条目，佐证 `--import` 生效。`.godot/` 被 gitignore，无污染。**注意**：此调整是"运行流程"层面的，未改动 brief 的测试命令本身。✓
2. **`is_equal_approx(x, 1e-4)` 补容差**：合理且必需。已核对本仓库 GdUnit4 6.2.1 源码 `addons/gdUnit4/src/asserts/GdUnitFloatAssertImpl.gd:75`：`func is_equal_approx(expected :float, approx :float)` 为双参数签名，实现为 `is_between(expected-approx, expected+approx)`——brief 的单参数写法在本版本**必然** Runtime Error（报告中间态"5 errors"与此吻合：7 用例中仅 `test_zero`（用 `is_equal` 精确断言）与 `test_compare`（用布尔断言）无 approx 调用，恰为 2 个非 error 用例）。容差 1e-4 不会掩盖真实 bug：double 运算误差 ~1e-15 量级，1e-4 绝对容差在断言值 1~5.7e6 区间相对误差 ≤1.75e-11；且 `test_initialization_normalizes`/`test_add_with_carry` 对 `exponent` 用**精确 int 断言**锁死归一化结构，approx 仅用于数值面。✓

---

## 二、质量判定：需修改（依据）

实现本身数学正确性总体扎实（_normalize 稳定、进位正确、sub 经取反复用 add、序列化容错好——见下），但**一处已实测复现的比较原语错误**使本任务不能直接 Approved：

- `is_greater_or_equal` 对**负数跨指数**与**异号**比较给出错误答案（Important #1，实测 3/3 全错）。该模块是全局约束点名的"后续资源的地基"，`sub()` 接口本身即允许表示负值，比较原语对可表示值静默说谎，会在下游扣费/判定逻辑中静默传播。
- 缺陷**源头是 brief 自带代码**（Step 3 逐字实现，实施者无偏离）。故：Spec 合规不扣分；修复须**走 brief 修订回流**（planner 修订 brief → 实施者按 TDD 补失败测试再修），不应归咎实施者。
- 需修改的最小范围：仅 `is_greater_or_equal` 一个函数 + 补 2~3 个负数回归用例（含 1 条防 INF 存储回归，可选）。其余代码无需改动。

---

## 三、问题列表（分级）

### 🔴 Critical：无

### 🟠 Important（1）

**#1 `is_greater_or_equal` 负数比较错误（实测复现）**

- **证据**（探针脚本实测输出）：
  ```
  [-500 >= -90] expect=false  actual=true    ← 错
  [-500 >= 10]  expect=false  actual=true     ← 错
  [-90 >= -500] expect=true   actual=false    ← 错
  ```
- **根因**：`if exponent != other.exponent: return exponent > other.exponent` 仅在**两操作数均非负**时成立（非负时指数大 ⇔ 值大）。对负数：指数越大值越小（-5e2 < -9e1）；异号时更与指数无关（任何非负数 ≥ 任何负数）。零的表示 `(0.0, 0)` 不受影响。
- **影响**：若任何下游流程出现负值（`sub()` 透支、负增量）并参与比较（如 `balance.is_greater_or_equal(cost)`），判定静默反转。MVP 若严格保证资源非负则不触发，但 brief 未声明该不变式。
- **建议**（TDD 路径：先加负数失败用例，再改实现）：
  ```gdscript
  func is_greater_or_equal(other: BigNum) -> bool:
      var self_neg := mantissa < 0.0
      var other_neg := other.mantissa < 0.0
      if self_neg != other_neg:
          return other_neg
      if self_neg:
          if exponent != other.exponent:
              return exponent < other.exponent
          return mantissa <= other.mantissa
      if exponent != other.exponent:
          return exponent > other.exponent
      return mantissa >= other.mantissa
  ```
  （审查者已手算全部符号/零/同号/异号组合，含 `-50 >= -90`、`0 >= -5`、`999 >= 1000` 等，修复逻辑正确。）备选：若产品明确资源非负，可在 brief 层声明"非负不变式"并在比较入口断言——但推荐直接修复，成本极低且使原语全函数化。

### 🟡 Minor（4）

**#2 测试未覆盖负数**（8 用例全为非负）——若 brief 自带测试含 1 条负数用例即可当场暴露 #1。建议随 #1 修复一并补：负负跨指数、负正异号、sub 结果为负。

**#3 防 INF 存储无回归测试**——报告已如实承认。审查者实测 `1e308+1e308` 存储层安全（`m=2.0, e=308`，不 INF；`to_value()` 返回 inf 属测试辅助函数正常溢出，存储层不受影响）。建议补断言 `not is_inf(mantissa)` 且 `exponent == 308` 的用例，把全局约束锁进测试。

**#4 `set_value(INF)` / `mul_scalar` 溢出产生损坏状态（实测）**——探针输出：`set_value(INF)` → `m=inf, e=0`；`mul_scalar(1e308*1e308)` → `m=inf, e=-9223372036854775501`（int 转换垃圾值）。可达性极低（mul_scalar 溢出需标量 f ≳ 1.8e307；INF 输入需上游 float 已溢出，恰是 BigNum 要防的场景），但作为地基模块建议在 `set_value`/`_normalize` 入口对 `is_inf`/`is_nan` 防御性早退。

**#5 跨数量级加法小项丢失**（如 1e300 + 1e-10）——报告已如实披露，属 mantissa 表示的 float 语义，MVP 增量场景可接受；建议在后续离线收益任务补精度测试或文档化。非缺陷，记录备查。

### ⚪ Info（2）

**#6 brief 措辞"8 个用例"实为 7 个测试函数 + Task 1 的 test_smoke**——报告口径（"含 test_smoke 共 8/8"）准确；建议 brief 修订时澄清计数来源。

**#7 "1e-4 与 GdUnit4 旧版默认一致"出处无法在本 checkout 验证**——当前源码实现是 `is_between(x±approx)`；容差取值本身合理（见 1.5），但"旧版默认一致"的历史出处无本地证据，建议删除该句或注明出处。

---

## 四、⚠️ 无法从 diff 验证项

1. **RED → `--import` → GREEN 完整序列的 before/after**：未重放（重放需改动仓库状态）。旁证充分：`RETURN_ERROR_SCRIPT_ERRORS_DETECTED = 105` 已在 `addons/gdUnit4/src/core/runners/GdUnitTestSessionRunner.gd:23` 确认，与 RED 实录"Abnormal exit with 105"完全吻合；class cache 现含 `BigNum` 佐证 `--import` 生效。
2. **RED 阶段"共 24 条同类 Parse Error"的完整文本**与**中间态退出码 100**：未重放。自洽性已核：中间态"7 用例 | 5 errors"与"仅 2 个用例无 approx 断言"精确吻合。
3. **报告所称"测试文件先逐字写入、后 7 处补容差"的中间态测试版本**：git 历史中不存在中间态（一次性 commit），不可复原；但与源码签名一致，可信。
4. **`is_equal_approx` 单参数写法在"旧版/其他语言习惯"下的行为**：本仓库无旧版 GdUnit4 可对照，不适用。

---

## 五、审查者独立验证清单（证据留痕）

| 验证项 | 方式 | 结果 |
|---|---|---|
| big_num.gd 与 brief 逐字一致 | 实际文件逐行比对 | ✅ 零差异 |
| 测试命令可跑通 | 独立重跑完整命令 | ✅ 8/8 PASSED，EXIT=0 |
| is_equal_approx 双参数签名 | GdUnit4 源码核对 | ✅ `(expected, approx)` → is_between |
| 退出码 105 语义 | GdUnit4 源码核对 | ✅ 脚本错误常量 |
| class_name 已注册 | class cache 检查 | ✅ 含 BigNum |
| commit 与 review 包一致 | git show + ls-files | ✅ 4 文件/113 行；.uid 约定一致；工作区干净 |
| 负数比较 | 探针脚本实测 | ❌ 3/3 错误（#1） |
| 1e308+1e308 存储 | 探针脚本实测 | ✅ m=2.0 e=308 不 INF |
| 0.01 / 9.99+0.02 归一化/进位 | 探针脚本实测 | ✅ m=1.0 e=-2 / m=1.001 e=1 |
| from_dict 容错（垃圾串/空字典） | 探针脚本实测 | ✅ 回落 0/0，无崩溃 |
| INF 输入健壮性 | 探针脚本实测 | ⚠️ 损坏状态（#4，低可达性） |

---

## 六、结论

- **Spec 合规：✅**——实现逐字对齐 brief，测试全部通过（独立复现），commit 完整，Global Constraints 满足；2 处测试调整均合理且经源码证实为必需，非投机性改动。
- **任务质量：需修改**——仅因 `is_greater_or_equal` 的负数比较缺陷（Important #1，实测复现）。缺陷源头在 brief 自带代码，修复应经 **brief 修订回流 + TDD**（先补负数失败用例，再最小改动修复），不构成对实施者的归咎。
- **建议下一步**：① planner 修订 brief（补负数用例 + 澄清"8 用例"计数 + 可选的防 INF 回归用例）；② 实施者按 TDD 修复 #1 后复跑全绿；③ 复核通过后合入。
