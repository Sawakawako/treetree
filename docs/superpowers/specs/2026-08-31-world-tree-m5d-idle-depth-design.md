# 世界树 里程碑 5d 设计文档：增量深度（升级总表扩展）

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：路线图 `docs/world-tree/ROADMAP.md`；主规格 `2026-08-31-world-tree-design.md`（§14.1 基础循环/§14.3 升级成本曲线/§16 升级总表）；M1-M5b 全部完成（144 测试全绿）
> **背景**：2026-09-01 项目方向审视——诊断「增量骨架缺扩展段（内容偏多）」，主人拍板先补增量深度
> **范围**：升级总表 5 类可重复升级——补「赚钱→买升级→赚更多」循环与消耗端

---

## 一、背景与目标

增量游戏的内核循环（点击采集 + 升级 + 经济）在 M1/M3 已立，但 M2-M5b 的重心偏向一次性内容事件——主循环缺乏新的可重复购买目标（树液/信仰/记忆攒多了没处花）。本里程碑：

1. 扩展升级总表 5 类（叶绿体/木质部/花盘/螺舱/根须等级），补足可重复循环；
2. 引入**宽裕的树液储量上限**（初始 10000——正常玩法几乎碰不到的「宽墙」，保留长线投资意义）；
3. 各资源找到**消耗端**（树液→叶绿体/木质部/螺舱/根须等级、信仰→花盘）；
4. 按 spec §14.3 四型曲线落地成本（斐波那契/线性/指数）。

## 二、范围与边界

### 2.1 包含

- 5 类新升级：叶绿体/木质部/花盘/螺舱/根须等级（效果、成本、UI、存档）
- sap 储量上限（初始 10000，螺舱 +5000/级）与 clamp——宽裕版（主人拍板：保留螺舱、上限放宽）
- GameLoop/GameActions/CostCalculator/RaceManager 公式接入
- GameState 5 个等级字段 + 序列化回退

### 2.2 边界（不包含）

- 垂直九界探索层（根须层深化）——下一增量里程碑
- 离线进度（UNIX 时间戳）——后续
- 科技树（三主枝）——后续
- 奇迹（信仰消耗端的中期形态）——M5e 明选/奇迹
- 升级总表 90+ 项的完整版数值——本里程碑只落地 5 类核心，其余按需扩展

## 三、架构

### 3.1 GameState 扩展

```gdscript
var chloroplast_level: int = 0   # 叶绿体（光合效率）
var xylem_level: int = 0         # 木质部（生长效率）
var sunflower_level: int = 0     # 花盘（信仰产出）
var nautilus_level: int = 0      # 螺舱（树液储量上限）
var root_eff_level: int = 0      # 根须等级（记忆产出）
```

- 序列化 + 缺字段回退 0（M1-M5b 旧档不损坏）

### 3.2 CostCalculator 扩展（spec §14.3 四型曲线）

```gdscript
static func chloroplast_cost(level: int) -> int  # 800 × 1.6^level（指数）
static func xylem_cost(level: int) -> int        # 50 × (level + 1)（线性）
static func sunflower_cost(level: int) -> int    # 斐波那契 base 2000
static func nautilus_cost(level: int) -> int     # 斐波那契 base 2000
static func root_eff_cost(level: int) -> int     # 1000 × 1.8^level（指数）
```

（斐波那契沿用现有 leaf_cost/branch_cost 的实现模式。）

### 3.3 GameActions 扩展

```gdscript
static func buy_chloroplast(state) -> bool   # 树液扣成本、level+1
static func buy_xylem(state) -> bool
static func buy_sunflower(state) -> bool
static func buy_nautilus(state) -> bool
static func buy_root_eff(state) -> bool
# 统一模式：sap >= cost → sap 扣减 + level+1 → true；否则 false
```
### 3.4 GameLoop 公式接入（spec §14.1）

```gdscript
# tick 内：
# 光合（树液转化）——叶绿体：0.1 + 0.01×L
var converted := state.daylight.mul_scalar(0.1 + 0.01 * float(state.chloroplast_level))
# 生长（树高转化）——木质部：0.01 × (1 + 0.05×L)
var grown := state.sap.mul_scalar(0.01 * (1.0 + 0.05 * float(state.xylem_level)))
# tick 末尾：树液 clamp 到储量上限（宽裕版——正常玩法几乎碰不到）
state.sap = BigNum.new(minf(state.sap.to_value(), sap_cap(state)))
```

### 3.5 储量上限（sap_cap，宽裕版）

```gdscript
static func sap_cap(state) -> float  # 10000 + 5000 × nautilus_level
```

- 引入位置：GameLoop.tick 末尾 clamp（旧档 sap 超 cap 时首个 tick 自动收敛，不破坏存档）
- 探索/供养只减 sap，不涉及 clamp
- **宽裕标准**：初始 10000 树液 ≈ 50 次探索（200/次）或长线供养——正常玩法碰不到，仅防极端挂机与为九界/奇迹蓄水

### 3.6 RaceManager 产出接入

```gdscript
# tick 产出阶段追加：
# 花盘：独立信仰产出（与人口无关）
state.faith.add(BigNum.new(0.5 * float(state.sunflower_level)))
# 人族梦产 × 根须系数：
var mem := pop * MEMORY_EFF * (1.0 + 0.1 * float(state.root_eff_level))
```

### 3.7 夺梦产出接入（根须等级）

`PlunderActions.plunder` 产出记忆 × `(1 + 0.1 × root_eff_level)`——根须加深捞记忆更快。

### 3.8 GameManager 集成

```gdscript
func buy_chloroplast() -> bool  # 等 5 个入口：成功 → resources_changed.emit()
func get_chloroplast_cost() -> int  # 等 5 个成本 getter
func get_sap_cap() -> float
```

### 3.9 UI

- 5 个新按钮（`%ChloroplastButton` 等）+ 成本/效果显示（沿用叶序/分枝模式：按钮 + 成本标签）
- 效果文案：叶绿体「光合 +0.01/级」、木质部「生长 +5%/级」、花盘「信仰 +0.5/tick/级」、螺舱「储量 +5000/级」、根须「记忆 +10%/级」
- sap 显示追加「树液：X / 上限」（上限 10000 起步）

## 四、数值模型（spec §14.3 骨架 + M5 节奏调整）

| 升级 | 效果/级 | 成本曲线 | 基准 | 接入 |
|---|---|---|---|---|
| 叶绿体 | 光合 +0.01 | 指数 1.6ⁿ | 800 | GameLoop |
| 木质部 | 生长 +5% | 线性 | 50×(L+1) | GameLoop |
| 花盘 | 信仰 +0.5/tick | 斐波那契 | 2000 | RaceManager |
| 螺舱 | 储量 +5000 | 斐波那契 | 2000 | GameLoop clamp |
| 根须等级 | 记忆 +10% | 指数 1.8ⁿ | 1000 | RaceManager + Plunder |

节奏验证：
- 叶绿体 L1 成本 800（指数 800×1.6ⁿ：800/1280/2048/...）——M1 分枝 1200 同级，玩家中期可买
- 花盘 L1 成本 2000，产出 +0.5/tick → 回本 4000 tick ≈ 1 小时（长线投资）
- 螺舱 L1 成本 2000，cap 10000→15000——宽裕墙，为九界/奇迹蓄水；正常玩法碰不到
- 根须 L1 成本 1000（1000×1.8ⁿ），记忆 +10%——记忆是稀缺资源，回报显著

**数值偏离记录（回填 spec）**：spec §14.3 花盘 50000/螺舱 200000 为完整版数值（回本 138 小时失衡）；M5 用节奏调整值（2000/500 基准），试玩调优后回填 spec。

## 五、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_cost_calculator.gd` | 5 类成本：叶绿体指数（0→800、1→1280）、木质部线性（0→50、2→150）、花盘/螺舱斐波那契序列、根须指数（1000/1800） |
| `test_game_actions.gd` | 5 类购买：成功（扣 sap + level+1）/失败（树液不足不变） |
| `test_game_loop.gd` | 光合公式（叶绿体 0.01/级）；生长公式（木质部 5%/级）；sap clamp（超 cap 收敛到 cap） |
| `test_race_manager.gd` | 花盘产出（0.5×L/tick）；人族梦产 × 根须系数（L1 记忆 ×1.1） |
| `test_plunder_actions.gd` | 夺梦产出 × 根须系数 |
| `test_game_state.gd` | 5 个等级字段序列化往返 + 旧档回退 0 |
| `test_game_manager.gd` | 5 个购买入口集成（信号/成本 getter/sap_cap） |
| 全量回归 | 既有 144 测试无回归；headless 冒烟 |

## 六、决策记录

1. **先补增量深度**（主人拍板）：项目方向审视——内容偏多、增量骨架缺扩展段；本里程碑补可重复循环与消耗端。
2. **5 类升级选择**：贴 spec §14.1（叶绿体/木质部）+ §14.3（花盘/螺舱）+ 根须等级（记忆效率）——覆盖 光合/生长/信仰/储量/记忆 五条资源线。
3. **根须等级 = 记忆产出**（非探索成本）：4 遗迹一次性挖完后探索成本无意义；记忆效率有实际效果，且为九界探索层铺垫。
4. **螺舱保留、上限放宽裕**（主人拍板）：初始 cap 10000（≈50 次探索）+ 每级 +5000——「宽墙」防极端挂机、为九界/奇迹蓄水，正常玩法碰不到；tick 末尾 clamp 兼容旧档（首个 tick 自动收敛）。
5. **数值偏离（花盘/螺舱成本调低）**：spec 完整版数值（50000/200000）回本失衡，M5 用节奏值（base 2000），试玩调优后回填 spec。
6. **斐波那契/线性/指数四型曲线落地**：spec §14.3 从示例变实现——三类曲线各司其职（主题/教学/功能）。

## 七、路线图衔接

- 下一增量里程碑：垂直九界探索层（根须层深化——可重复探索替代一次性遗迹）+ 离线进度（UNIX 时间戳）
- M5c 意志漂移 + 化身（押后执行，编号不变）
- 奇迹（信仰消耗端中期形态）与明选联动（M5e）

---

## 附录：存档示例

```jsonc
// M5b 旧档：无等级字段 → 回退 0
{ "plundered": {...}, "sap": {...}, ... }
// M5d 新档：
{ "chloroplast_level": 2, "xylem_level": 1, "sunflower_level": 0, "nautilus_level": 3, "root_eff_level": 1, ... }
```
