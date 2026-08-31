# 涓栫晫鏍?MVP 鏂囧瓧鍘熷瀷 Implementation Plan锛圙odot 鐗堬級

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 鐢?Godot 4.7 鎼捣銆婁笘鐣屾爲銆嬫渶灏忓彲鐜╂枃瀛楀師鍨嬶細鐜╁鎵紨涓€妫垫爲锛岀偣鍑昏垝灞曞彾鐗囨敹闆嗘棩鍏夛紝缁忓厜鍚堣浆鍖栦负鏍戞恫锛岃喘涔版枑娉㈤偅濂戞垚鏈殑鍗囩骇锛堝彾搴忚灪鏃?鍒嗘灊搴忥級瀹炵幇鑷姩閲囬泦锛屾爲娑茬疮绉负鏍戦珮锛堢敓闀匡級锛屽甫 `user://` 鑷姩瀛樻。銆?
**Architecture:** 鎸?godot-master Layer Cake 鍒嗗眰锛歚GameState`锛圧efCounted 鏁版嵁瀹瑰櫒锛夈€乣GameLoop`/`GameActions`/`CostCalculator`/`BigNum`/`Formatter`锛圧efCounted 绾€昏緫锛宧eadless 鍙祴锛夈€乣GameManager`锛圓utoload锛氭寔鏈夌姸鎬併€乣_process(delta)` 鎵嬪姩绱姞 tick銆佸彂 `resources_changed` 淇″彿锛夈€乣main.tscn`锛圥resentation 鍙洃鍚俊鍙锋洿鏂?UI锛夈€傛祴璇曠敤 GdUnit4锛宍godot --headless` 杩愯銆?
**Tech Stack:** Godot 4.7.1锛坢ono锛屽凡瑁呬簬 `C:\Users\10990\AppData\Local\Programs\Godot\Godot_v4.7.1-stable_mono_win64\`锛宍godot` 鍛戒护鍦?PATH锛夛紱GDScript锛坱yped锛夛紱GdUnit4 v6.x锛圡IT锛屽厠闅嗗埌 `addons/gdUnit4/`锛夈€傞浂绗笁鏂硅繍琛屾椂渚濊禆銆?
**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-design.md`锛堟湰璁″垝瀹炵幇鍏?搂4 鍏疯薄杞?MVP 閮ㄥ垎 + 搂9 鏂愭尝閭ｅ鍗囩骇缁勪腑鐨勫彾搴忚灪鏃?鍒嗘灊搴忥級

## Global Constraints

- Godot 鐗堟湰锛?.7.x锛堝嬁闄嶇骇锛沵ono 鐗堜害鍙窇 GDScript锛夈€?- 鍏ㄩ儴鏁版嵁涓庨€昏緫浣跨敤 typed GDScript锛沗@export` 璧勬簮鎸夐渶 `duplicate()`锛岄伩鍏嶅叡浜唴瀛樸€?- 璐у竵涓庤祫婧愭暟鍊?*涓€寰嬩娇鐢?`BigNum`**锛堝熬鏁?鎸囨暟锛夛紝绂佹瑁?`float` 瀛樺偍璧勬簮锛堥槻 1e308 INF锛宨dle-clicker NEVER 瑙勫垯锛夈€?- 鏀跺叆涓?tick **鍦?`GameManager._process(delta)` 鐢ㄧ疮鍔犲櫒鎵嬪姩绱姞**锛岀姝?`Timer` 鑺傜偣椹卞姩缁忔祹锛堥槻甯х巼婕傜Щ锛夈€?- UI 鍙€氳繃 `resources_changed` 淇″彿鏇存柊锛岀姝㈠湪 `_process` 閲岀洿鎺ユ敼 Label銆?- 瀛樻。璧?`user://`锛堢姝?`res://` 鍐欏叆锛夛紝淇濆瓨涓?JSON锛汢igNum 搴忓垪鍖栦负 `{"m": mantissa, "e": exponent}`銆?- 鍗囩骇鎴愭湰鎸夋枑娉㈤偅濂戞暟鍒楋細`fib(1)=1, fib(2)=1, fib(3)=2, ..., fib(34)=5702887`锛團鈧?F鈧?1锛夈€?*鍒绘剰鍋忕 idle-clicker 琛屼笟鏍囧噯 1.15 鎸囨暟鏇茬嚎**锛岄噰鐢ㄦ枑娉㈤偅濂戯紙spec 搂9 涓婚璁捐锛氭鐗╃殑鏁板 + 鍓嶆湡瀵嗛泦/涓湡绱у紶/鍚庢湡浠版湜鐨勪綋楠屾洸绾匡級銆?- 鏁板€艰鍒欙紙MVP 瀹氱锛夛細
  - 鐐瑰嚮銆岃垝灞曞彾鐗囥€嶏細`daylight += 1 脳 (1 + 0.25 脳 leafLevel)`
  - 姣?tick 鑷姩閲囬泦锛歚daylight += branchLevel 脳 (1 + 0.25 脳 leafLevel)`
  - 姣?tick 鍏夊悎锛歚sap += daylight 脳 0.1`锛堟棩鍏変笉鍥犺浆鍖栬€屾秷鑰楋級
  - 姣?tick 鐢熼暱锛歚growth += sap 脳 0.01`
  - 鍙跺簭铻烘棆锛坙evel 浠?0 璁★紝鍗囧埌 level+1 鐨勮姳璐癸級锛歚500 脳 fib(level + 1)`
  - 鍒嗘灊搴忥細`1200 脳 fib(level + 1)`
- 寮€灞€鐘舵€侊細`daylight=0, sap=0, growth=0, leafLevel=0, branchLevel=0, tick=0, hope=1`锛坄hope` 鍙欎簨鍏冪礌锛孧VP 鍙樉绀猴級銆?- 鑷姩瀛樻。锛氭瘡 60 tick 淇濆瓨涓€娆★紱鍔犺浇鏃惰妗ｏ紝鏃犳。鍒欐柊寤恒€?- 鍛藉悕涓庢枃妗堬細鑴氭湰/鑺傜偣鐢?snake_case锛涙父鎴忓唴鏂囨绠€浣撲腑鏂囥€?- 娴嬭瘯锛欸dUnit4锛涘懡浠?`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 蹇呴』鍏ㄧ豢锛涙瘡涓?`features/` 閫昏緫妯″潡鏈夊搴?`tests/unit/` 濂椾欢銆?
---

### Task 1: Godot 椤圭洰鑴氭墜鏋?+ GdUnit4 瀹夎 + headless 娴嬭瘯璺戦€?
**Files:**
- Create: `project.godot`
- Create: `icon.svg`
- Create: `autoloads/.gitkeep`
- Create: `features/game/.gitkeep`銆乣features/economy/.gitkeep`銆乣features/ui/.gitkeep`
- Create: `tests/unit/.gitkeep`
- Create: `tests/unit/test_smoke.gd`锛堝啋鐑熸祴璇曪紝楠岃瘉 GdUnit4 鍙敤锛?- Create: `addons/gdUnit4/`锛堝厠闅嗚嚜 https://github.com/MikeSchulze/gdUnit4锛?
**Interfaces:**
- Consumes: 鏃?- Produces: 鍙繍琛岄」鐩鏋讹紱`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 鑳借窇骞舵樉绀?1 涓€氳繃鐢ㄤ緥锛沗godot` 鎵撳紑椤圭洰鏃犳姤閿?
- [ ] **Step 1: 鍒涘缓 project.godot**

```ini
; Engine configuration file.
config_version=5

[application]
config/name="涓栫晫鏍?
run/main_scene="res://features/ui/main.tscn"

[display]
window/size/viewport_width=420
window/size/viewport_height=640

[editor_plugins]
enabled=PackedStringArray("gdUnit4")
```

- [ ] **Step 2: 鍒涘缓 icon.svg锛堟瀬绠€鏍戝舰鍥炬爣锛?*

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="#1a1512"/><path d="M64 20 L96 84 L32 84 Z" fill="#3f7a3f"/><rect x="60" y="84" width="8" height="28" fill="#6b5638"/></svg>
```

- [ ] **Step 3: 瀹夎 GdUnit4 鎻掍欢**

Run:
```bash
mkdir -p addons
git clone --depth 1 https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
```
锛堣嫢 git clone 琚綉缁?reset锛屾敼鐢細涓嬭浇 `https://codeload.github.com/MikeSchulze/gdUnit4/zip/refs/heads/master` 瑙ｅ帇骞跺皢瑙ｅ帇鍑虹殑 `gdUnit4-master` 鐩綍閲嶅懡鍚嶄负 `addons/gdUnit4`銆傦級
Expected: `addons/gdUnit4/plugin.cfg` 瀛樺湪銆?
- [ ] **Step 4: 鍒涘缓鍐掔儫娴嬭瘯**

```gdscript
# tests/unit/test_smoke.gd
extends GdUnitTestSuite

func test_gdunit_works() -> void:
    assert_that(1 + 1).is_equal(2)
```

- [ ] **Step 5: 杩愯鍐掔儫娴嬭瘯楠岃瘉 headless 閾捐矾**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: 杈撳嚭鍖呭惈 test_gdunit_works 閫氳繃锛涢€€鍑虹爜 0
锛堥娆¤繍琛岃嫢鎶?"Plugin not enabled"锛岀‘璁?project.godot `[editor_plugins]` 宸插啓鍏ヤ笖璺緞涓?`res://addons/gdUnit4/plugin.cfg`銆傦級

- [ ] **Step 6: Commit**

```bash
git add project.godot icon.svg autoloads features tests addons/gdUnit4
git commit -m "feat: Godot 4.7 鑴氭墜鏋?+ GdUnit4 鎺ュ叆锛坔eadless 娴嬭瘯璺戦€氾級"
```

---

### Task 2: 澶ф暟妯″潡 big_num.gd

**Files:**
- Create: `features/economy/big_num.gd`
- Test: `tests/unit/test_big_num.gd`

**Interfaces:**
- Produces: `class_name BigNum extends RefCounted`锛屽瓧娈?`mantissa: float`銆乣exponent: int`锛堝€?= mantissa 脳 10^exponent锛宮antissa 鈭?[1,10) 鎴?0锛夈€傛柟娉曪細
  - `_init(v: float = 0.0)`
  - `set_value(v: float) -> void`
  - `add(other: BigNum) -> void`锛堝師鍦板姞锛?  - `sub(other: BigNum) -> void`锛堝師鍦板噺锛?  - `mul_scalar(f: float) -> BigNum`锛堣繑鍥炴柊 BigNum锛?  - `is_greater_or_equal(other: BigNum) -> bool`
  - `to_value() -> float`锛堟祴璇曡緟鍔╋級
  - `to_dict() -> Dictionary`锛坄{"m": mantissa, "e": exponent}`锛?  - `static from_dict(d: Dictionary) -> BigNum`

- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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
    # 鍘熷璞′笉鍙?    assert_that(a.to_value()).is_equal_approx(1234.0, 1e-4)

func test_compare() -> void:
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(998.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(999.0))).is_true()
    assert_that(BigNum.new(999.0).is_greater_or_equal(BigNum.new(1000.0))).is_false()
    # 璺ㄦ寚鏁版瘮杈?    assert_that(BigNum.new(1e9).is_greater_or_equal(BigNum.new(9e8))).is_true()

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

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_big_num.gd`
Expected: FAIL锛堟棤娉曡В鏋?`BigNum` 绫伙級

- [ ] **Step 3: 瀹炵幇 features/economy/big_num.gd**

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
        return mantissa <= other.mantissa
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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_big_num.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/economy/big_num.gd tests/unit/test_big_num.gd
git commit -m "feat: BigNum 澶ф暟妯″潡锛堝熬鏁?鎸囨暟/鍔犲噺涔?姣旇緝/搴忓垪鍖栵級"
```

---

### Task 3: 鏂愭尝閭ｅ鎴愭湰妯″潡 cost_calculator.gd

**Files:**
- Create: `features/economy/cost_calculator.gd`
- Test: `tests/unit/test_cost_calculator.gd`

**Interfaces:**
- Consumes: 鏃?- Produces: `class_name CostCalculator extends RefCounted`锛?  - `static func fib(n: int) -> int`锛團鈧?F鈧?1锛?  - `static func leaf_cost(level: int) -> int`锛?00脳fib(level+1)锛?  - `static func branch_cost(level: int) -> int`锛?200脳fib(level+1)锛?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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
    # 浼︾撼寰蜂箣寰嬪僵铔嬫暟瀛?    assert_that(CostCalculator.fib(34)).is_equal(5702887)

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

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_cost_calculator.gd`
Expected: FAIL锛堟棤娉曡В鏋?`CostCalculator`锛?
- [ ] **Step 3: 瀹炵幇 features/economy/cost_calculator.gd**

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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_cost_calculator.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/economy/cost_calculator.gd tests/unit/test_cost_calculator.gd
git commit -m "feat: 鏂愭尝閭ｅ鎴愭湰妯″潡锛坒ib/鍙跺簭铻烘棆/鍒嗘灊搴忥級"
```

---

### Task 4: 鏁板瓧鏍煎紡鍖栨ā鍧?formatter.gd

**Files:**
- Create: `features/economy/formatter.gd`
- Test: `tests/unit/test_formatter.gd`

**Interfaces:**
- Consumes: `BigNum`锛坆ig_num.gd锛?- Produces: `class_name Formatter extends RefCounted`锛?  - `static func format_number(bn: BigNum) -> String`锛?1000 鏄剧ず鍘熷€硷紙鈮? 浣嶅皬鏁帮級锛涒墺1000 鐢?K/M/B/T 鍚庣紑锛屼繚鐣?2 浣嶅皬鏁板幓灏鹃浂锛?  - `static func format_cost(cost: int) -> String`锛堟暣鏁板崈鍒嗕綅锛?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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

func test_cost_format() -> void:
    assert_that(Formatter.format_cost(500)).is_equal("500")
    assert_that(Formatter.format_cost(5000)).is_equal("5,000")
    assert_that(Formatter.format_cost(5702887)).is_equal("5,702,887")
```

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_formatter.gd`
Expected: FAIL锛堟棤娉曡В鏋?`Formatter`锛?
- [ ] **Step 3: 瀹炵幇 features/economy/formatter.gd**

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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_formatter.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級
娉細鑻?`5702887` 鏍煎紡鍖栫粨鏋滃洜娴偣鍙栨暣鍋忓樊鍑虹幇 `5.7M` 涔嬪鐨勫€硷紙濡?`5.71M`锛夛紝灏嗘祴璇曟柇瑷€鏀逛负瀵瑰簲褰撳墠 `String.num` 鍥涜垗浜斿叆琛屼负锛屾垨鎶?`_trim_zeros(String.num(mant, 2))` 涓?mant 鍏?`floor(mant*100)/100` 鍐嶆牸寮忓寲锛屼繚璇佷笌鏂█涓€鑷粹€斺€斾簩鑰呭彇鍏朵竴骞朵繚鎸佹祴璇?瀹炵幇鍚屾銆?
- [ ] **Step 5: Commit**

```bash
git add features/economy/formatter.gd tests/unit/test_formatter.gd
git commit -m "feat: 鏁板瓧鏍煎紡鍖栨ā鍧楋紙鍚庣紑/鍗冨垎浣嶏級"
```

---

### Task 5: 娓告垙鐘舵€?game_state.gd

**Files:**
- Create: `features/game/game_state.gd`
- Test: `tests/unit/test_game_state.gd`

**Interfaces:**
- Consumes: `BigNum`
- Produces: `class_name GameState extends RefCounted`锛屽瓧娈?`daylight: BigNum`銆乣sap: BigNum`銆乣growth: BigNum`銆乣leaf_level: int = 0`銆乣branch_level: int = 0`銆乣tick: int = 0`銆乣hope: int = 1`銆傛柟娉曪細
  - `_init()`
  - `to_dict() -> Dictionary`
  - `static from_dict(d: Dictionary) -> GameState`锛堝瓧娈电己澶卞洖閫€榛樿锛?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_state.gd`
Expected: FAIL锛堟棤娉曡В鏋?`GameState`锛?
- [ ] **Step 3: 瀹炵幇 features/game/game_state.gd**

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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_state.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/game/game_state.gd tests/unit/test_game_state.gd
git commit -m "feat: 娓告垙鐘舵€佹ā鍧楋紙鍒濆鍊?搴忓垪鍖栵級"
```

---

### Task 6: 鐜╁鍔ㄤ綔妯″潡 actions.gd

**Files:**
- Create: `features/economy/actions.gd`
- Test: `tests/unit/test_actions.gd`

**Interfaces:**
- Consumes: `GameState`銆乣BigNum`銆乣CostCalculator`
- Produces: `class_name GameActions extends RefCounted`锛?  - `static func gather_daylight(state: GameState) -> void`
  - `static func buy_leaf(state: GameState) -> bool`
  - `static func buy_branch(state: GameState) -> bool`

- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_actions.gd`
Expected: FAIL锛堟棤娉曡В鏋?`GameActions`锛?
- [ ] **Step 3: 瀹炵幇 features/economy/actions.gd**

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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_actions.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/economy/actions.gd tests/unit/test_actions.gd
git commit -m "feat: 鐜╁鍔ㄤ綔妯″潡锛堣垝灞曞彾鐗?璐拱鍗囩骇锛?
```

---

### Task 7: 娓告垙寰幆妯″潡 game_loop.gd

**Files:**
- Create: `features/game/game_loop.gd`
- Test: `tests/unit/test_game_loop.gd`

**Interfaces:**
- Consumes: `GameState`銆乣BigNum`
- Produces: `class_name GameLoop extends RefCounted`锛?  - `static func tick(state: GameState) -> void`
  - `static func should_auto_save(state: GameState) -> bool`锛坄state.tick > 0 and state.tick % 60 == 0`锛?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

```gdscript
# tests/unit/test_game_loop.gd
extends GdUnitTestSuite

func test_tick_increments_and_photosynthesis() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(100.0)
    GameLoop.tick(s)
    assert_that(s.tick).is_equal(1)
    assert_that(s.sap.to_value()).is_equal_approx(10.0, 1e-4)  # 100 脳 0.1
    assert_that(s.daylight.to_value()).is_equal_approx(100.0, 1e-4)  # 鏃犲垎鏀椂鏃ュ厜涓嶅彉

func test_tick_auto_collect() -> void:
    var s := GameState.new()
    s.branch_level = 3
    s.daylight = BigNum.new(10.0)
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(13.0, 1e-4)  # 10 + 3脳1

func test_tick_auto_collect_with_leaf_bonus() -> void:
    var s := GameState.new()
    s.branch_level = 2
    s.leaf_level = 2  # 2 脳 1.5 = 3
    GameLoop.tick(s)
    assert_that(s.daylight.to_value()).is_equal_approx(3.0, 1e-4)

func test_tick_growth() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    GameLoop.tick(s)
    assert_that(s.growth.to_value()).is_equal_approx(2.0, 1e-4)  # 200 脳 0.01

func test_should_auto_save() -> void:
    var s := GameState.new()
    s.tick = 60
    assert_that(GameLoop.should_auto_save(s)).is_true()
    s.tick = 61
    assert_that(GameLoop.should_auto_save(s)).is_false()
```

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_loop.gd`
Expected: FAIL锛堟棤娉曡В鏋?`GameLoop`锛?
- [ ] **Step 3: 瀹炵幇 features/game/game_loop.gd**

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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_game_loop.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/game/game_loop.gd tests/unit/test_game_loop.gd
git commit -m "feat: 娓告垙寰幆妯″潡锛堣嚜鍔ㄩ噰闆?鍏夊悎/鐢熼暱/鑷姩瀛樻。鍒ゅ畾锛?
```

---

### Task 8: 瀛樻。妯″潡 save_manager.gd

**Files:**
- Create: `features/game/save_manager.gd`
- Test: `tests/unit/test_save_manager.gd`

**Interfaces:**
- Consumes: `GameState`
- Produces: `class_name SaveManager extends RefCounted`锛?  - `static func save(state: GameState, path: String = "user://save.json") -> void`
  - `static func load_or_create(path: String = "user://save.json") -> GameState`

- [ ] **Step 1: 鍐欏け璐ユ祴璇?*

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

- [ ] **Step 2: 杩愯纭澶辫触**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_save_manager.gd`
Expected: FAIL锛堟棤娉曡В鏋?`SaveManager`锛?
- [ ] **Step 3: 瀹炵幇 features/game/save_manager.gd**

```gdscript
class_name SaveManager
extends RefCounted

const DEFAULT_PATH := "user://save.json"

static func save(state: GameState, path: String = DEFAULT_PATH) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        push_error("鏃犳硶鍐欏叆瀛樻。: %s" % path)
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

- [ ] **Step 4: 杩愯纭閫氳繃**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests --add res://tests/unit/test_save_manager.gd`
Expected: PASS锛? 涓敤渚嬪叏缁匡級

- [ ] **Step 5: Commit**

```bash
git add features/game/save_manager.gd tests/unit/test_save_manager.gd
git commit -m "feat: 瀛樻。妯″潡锛坲ser:// JSON 璇诲啓/缂烘。鍥為€€锛?
```

---

### Task 9: GameManager Autoload + main 鍦烘櫙锛堥泦鎴愶級

**Files:**
- Create: `autoloads/game_manager.gd`
- Create: `features/ui/main.tscn`
- Create: `features/ui/main.gd`
- Modify: `project.godot`锛堟敞鍐?autoload锛?
**Interfaces:**
- Consumes: `GameState`銆乣GameLoop`銆乣GameActions`銆乣SaveManager`銆乣Formatter`銆乣CostCalculator`
- Produces:
  - `GameManager`锛圓utoload锛岃妭鐐瑰悕 `GameManager`锛夛細淇″彿 `resources_changed`锛涙柟娉?`gather()`銆乣buy_leaf() -> bool`銆乣buy_branch() -> bool`銆乣get_state() -> GameState`銆乣get_leaf_cost() -> int`銆乣get_branch_cost() -> int`
  - `features/ui/main.tscn`锛氫富鍦烘櫙锛堟牴 Control锛屽惈鏍囬銆佸笇鏈涜銆侀噰闆嗘寜閽€佽祫婧愭爣绛俱€佸崌绾ф寜閽€佹棩蹇楁爣绛撅級

- [ ] **Step 1: 娉ㄥ唽 Autoload锛堜慨鏀?project.godot锛?*

```ini
[autoload]
GameManager="*res://autoloads/game_manager.gd"
```

- [ ] **Step 2: 瀹炵幇 autoloads/game_manager.gd**

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

- [ ] **Step 3: 瀹炵幇 features/ui/main.gd**

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
        log_label.text = "鍙跺簭铻烘棆鍗囪嚦 %d 绾с€? % GameManager.get_state().leaf_level
    _refresh()

func _on_branch_pressed() -> void:
    if GameManager.buy_branch():
        log_label.text = "鍒嗘灊搴忓崌鑷?%d 绾с€? % GameManager.get_state().branch_level
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

- [ ] **Step 4: 鍒涘缓 features/ui/main.tscn**

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
text = "涓栫晫鏍?

[node name="Hope" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "涓€鐐瑰笇鏈涳紝鍦ㄥ簾澧熶腑闈欓潤鐕冪儳銆?

[node name="GatherButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鑸掑睍鍙剁墖"

[node name="DaylightLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鏃ュ厜锛?"

[node name="SapLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鏍戞恫锛?"

[node name="GrowthLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鏍戦珮锛?"

[node name="LeafButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鍙跺簭铻烘棆锛堟棩鍏夐噰闆?+25%/绾э級"

[node name="LeafCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "浠锋牸锛?00"

[node name="BranchButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "鍒嗘灊搴忥紙鑷姩閲囬泦 +1/绾э級"

[node name="BranchCostLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "浠锋牸锛?200"

[node name="LogLabel" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = ""
```

- [ ] **Step 5: 杩愯鍏ㄩ儴娴嬭瘯纭鏃犲洖褰?*

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: PASS锛堝叏閮ㄦ祴璇曞浠讹紝鍚?smoke锛?
- [ ] **Step 6: 鎵撳紑缂栬緫鍣ㄩ獙璇佸満鏅彲杩愯**

Run: `godot --path .`锛堟垨缂栬緫鍣ㄦ墦寮€锛夛紝杩愯涓诲満鏅?Expected: 鏃犺剼鏈姤閿欙紱鎸夐挳/鏍囩鎸夐鏈熷嚭鐜帮紙鏁板€间负 0锛?
- [ ] **Step 7: Commit**

```bash
git add autoloads/game_manager.gd features/ui/main.tscn features/ui/main.gd project.godot
git commit -m "feat: GameManager Autoload + 涓诲満鏅泦鎴愶紙tick/淇″彿/UI锛?
```

---

### Task 10: 闆嗘垚楠岃瘉涓庢墜娴嬫竻鍗?
**Files:**
- Modify: 鏃狅紙绾獙璇侊級

**Interfaces:**
- Consumes: 鍏ㄩ儴鍓嶅簭浠诲姟浜х墿

- [ ] **Step 1: 鍏ㄩ噺娴嬭瘯**

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: 鍏ㄩ儴 PASS锛岄€€鍑虹爜 0

- [ ] **Step 2: 鎵嬪姩鐜╂硶楠岃瘉锛堝鐓?Global Constraints 鏁板€艰鍒欙級**

鍦?Godot 缂栬緫鍣ㄨ繍琛屼富鍦烘櫙锛屼緷娆￠獙璇侊細
- [ ] 鐣岄潰鏄剧ず"涓€鐐瑰笇鏈涳紝鍦ㄥ簾澧熶腑闈欓潤鐕冪儳"锛坔ope 鍙欎簨鍏冪礌锛?- [ ] 鐐瑰嚮 5 娆°€岃垝灞曞彾鐗囥€嶁啋 鏃ュ厜 = 5
- [ ] 绛夊緟鏍戞恫 鈮?500 鈫?璐拱銆屽彾搴忚灪鏃嬨€嶁啋 鐐瑰嚮閲囬泦鍙樹负 +1.25
- [ ] 璐拱绗?2 绾у彾搴忚灪鏃嬶紙500锛夆啋 閲囬泦 +1.5
- [ ] 璐拱銆屽垎鏋濆簭銆嶁啋 姣?tick 鏃ュ厜鑷姩 +1
- [ ] 60 绉掑悗瑙﹀彂鑷姩瀛樻。锛坄user://save.json` 瀛樺湪锛夛紱閲嶅惎娓告垙鏁板€间繚鐣?
- [ ] **Step 3: 鏈€缁堟彁浜?*

```bash
git add -A
git commit -m "chore: Godot MVP 楠岃瘉閫氳繃"
```

---

## Self-Review 璁板綍

- **Spec 瑕嗙洊**锛毬? 鍏疯薄杞紙鏃ュ厜/鏍戞恫/鐢熼暱锛夆湏锛坓ame_loop/actions锛夛紱搂9 鏂愭尝閭ｅ鍗囩骇缁勫墠涓ら」 鉁擄紙cost_calculator/actions锛夛紱寮€灞€涓€鐐瑰笇鏈?鉁擄紙game_state.hope + main.tscn 鏂囨锛夛紱瀛樻。 鉁擄紙save_manager + GameManager 姣?60 tick锛夈€傚洓鏃?姊﹀/鏄庨€?缁堝眬灞炲悗缁噷绋嬬锛屼笉鍦ㄦ湰璁″垝鑼冨洿锛坰pec 搂12 閲岀▼纰?2-4锛夈€?- **鍗犱綅绗︽壂鎻?*锛氭棤 TBD/TODO锛涙墍鏈夋楠ゅ惈鍏蜂綋 GDScript 涓庡懡浠ゃ€?- **绫诲瀷涓€鑷存€?*锛歚BigNum`锛坄add/sub/mul_scalar/is_greater_or_equal/to_value/to_dict/from_dict`锛夈€乣CostCalculator.fib/leaf_cost/branch_cost`銆乣GameActions.gather_daylight/buy_leaf/buy_branch`銆乣GameLoop.tick/should_auto_save`銆乣SaveManager.save/load_or_create`銆乣GameManager` 淇″彿涓庢柟娉曞湪鍚勪换鍔￠棿绛惧悕涓€鑷达紱main.gd 鐨?`%UniqueName` 涓?main.tscn 鐨?`unique_name_in_owner` 鑺傜偣涓€涓€瀵瑰簲銆?- **閾佸緥閬靛惊**锛氭湰璁″垝鎸夐搧寰?2 鍏堣 godot-master 骞惰矾鐢辫嚦 godot-genre-idle-clicker锛圔igNum/鎵嬪姩绱姞/淇″彿鑺傛祦/UNIX 瀛樻。瑙勫垯锛変笌 godot-testing-patterns锛圙dUnit4 headless锛夈€?