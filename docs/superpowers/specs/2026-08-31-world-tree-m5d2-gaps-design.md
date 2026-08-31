# 世界树 里程碑 5d2 设计文档：增量缺口补齐（教学链/一次性大额/四族设施）

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：M5d 增量深度（升级总表 5 类）；主规格 `2026-08-31-world-tree-design.md`（§14.2 种子阶段/§14.3 一次性成本/§16 升级总表/line 284-287 一次性与可重复设施）；M5a 关系互动（区分设施与事件）
> **背景**：升级表盘点——当前可重复 7 个 vs spec 目标 90+；主人拍板「继续补缺口」，全缺口落地
> **范围**：嫩叶教学链 + 一次性大额（深根梦/风语膜）+ 四族可重复设施 4 个

---

## 一、背景与目标

M5d 补了 5 类核心升级，但 spec 升级表的明显缺口仍在：种子阶段教学链（嫩叶Ⅰ-Ⅲ）、一次性大额购买（深根梦/风语膜）、四族可重复设施（spec line 287 的 6 个里只做了花盘/螺舱）。本里程碑：

1. **嫩叶教学链**：种子阶段的线性教学升级（3 级封顶）——新手引导闭环；
2. **一次性大额**：花大钱买爆发（记忆/信仰一次性收益）+ 一次性叙事文本——spec §14.3「一次性」类型落地；
3. **四族可重复设施**：各族资源放大器（火塘/歌之环/铸根坊/图腾柱）——spec line 287 可重复设施清单补齐（6/6）。

## 二、范围与边界

### 2.1 包含

- 嫩叶教学链（seedling_level，3 级封顶，点击 +1/级）
- 一次性大额：深根梦（3000 树液 → 记忆+15）、风语膜（2500 树液 → 信仰+30）+ 2 篇一次性叙事文本
- 四族可重复设施：火塘/歌之环/铸根坊/图腾柱（各族唤醒解锁，独立产出）
- GameState 扩展、CostCalculator 成本、GameActions 购买、GameLoop/RaceManager 公式接入、UI

### 2.2 边界（不包含）

- 升级总表 90+ 的其余项（科技树/九界/离线进度）——后续增量里程碑
- 四族设施的「关系」效果（设施升级加关系）——本里程碑只做资源产出
- 一次性大额的更多项（spec 未列效果的）——只做深根梦/风语膜两项
- 嫩叶之外的线性教学链扩展

## 三、架构

### 3.1 GameState 扩展

```gdscript
var seedling_level: int = 0      # 嫩叶（点击采集 +1/级，3 级封顶）
var firepit_level: int = 0       # 说书人火塘（人族设施，记忆 +0.1/tick/级）
var ring_level: int = 0          # 歌之环（林地民设施，信仰 +0.3/tick/级）
var forge_level: int = 0         # 铸根坊（石裔设施，树液 +0.5/tick/级）
var totem_pole_level: int = 0    # 图腾柱（野民设施，记忆 +0.1/tick/级）
var deep_dream: bool = false     # 深根梦已购（一次性）
var wind_veil: bool = false      # 风语膜已购（一次性）
```

- 序列化 + 缺字段回退默认（M1-M5d 旧档不损坏）

### 3.2 CostCalculator 扩展

```gdscript
static func seedling_cost(level: int) -> int    # 10 × (level + 1)（线性教学，3 级封顶由 GameActions 守卫）
static func firepit_cost(level: int) -> int     # 1000 × fib(level + 1)（斐波那契）
static func ring_cost(level: int) -> int        # 1000 × fib(level + 1)
static func forge_cost(level: int) -> int       # 1000 × fib(level + 1)
static func totem_pole_cost(level: int) -> int  # 1000 × fib(level + 1)
```

### 3.3 GameActions 扩展

```gdscript
static func buy_seedling(state) -> bool    # 3 级封顶：level >= 3 → false
static func buy_firepit(state) -> bool     # 人族已唤醒才可买
static func buy_ring(state) -> bool        # 林地民已唤醒
static func buy_forge(state) -> bool       # 石裔已唤醒
static func buy_totem_pole(state) -> bool  # 野民已唤醒
static func buy_deep_dream(state) -> bool  # 未购 + 3000 树液 → 记忆+15 + deep_dream=true
static func buy_wind_veil(state) -> bool   # 未购 + 2500 树液 → 信仰+30 + wind_veil=true
```

### 3.4 GameLoop 点击公式（嫩叶）

```gdscript
# GameActions.gather_daylight：点击采集 + 嫩叶加成
var gain := BigNum.new(1.0 * (1.0 + 0.25 * float(state.leaf_level)) + float(state.seedling_level))
```

### 3.5 RaceManager 独立产出（四族设施）

`tick_races` 产出阶段追加（与人口无关的设施产出）：

```gdscript
# 四族设施（各族唤醒解锁后购买，独立产出）
state.memory.add(BigNum.new(0.1 * float(state.firepit_level) + 0.1 * float(state.totem_pole_level)))
state.faith.add(BigNum.new(0.3 * float(state.ring_level)))
state.sap.add(BigNum.new(0.5 * float(state.forge_level)))
```

### 3.6 GameManager 集成

```gdscript
func buy_seedling() -> bool  # 等 7 个入口（成功 → resources_changed.emit()）
func get_seedling_cost() -> int  # 等 7 个成本 getter
```

### 3.7 UI

- 嫩叶按钮（3 级后隐藏/禁用）——种子阶段教学
- 深根梦/风语膜按钮（购买后消失）——一次性
- 四族设施按钮（该族唤醒后显示）——各族面板旁
- 一次性叙事文本经 `race_event_label` 显示

## 四、数值模型

| 项 | 成本 | 效果 | 解锁 |
|---|---|---|---|
| 嫩叶 | 线性 10×(L+1)（10/20/30） | 点击 +1/级（3 级封顶） | 始终 |
| 深根梦 | 3000 树液（一次性） | 记忆 +15 | 始终 |
| 风语膜 | 2500 树液（一次性） | 信仰 +30 | 始终 |
| 火塘 | 斐波那契 1000 | 记忆 +0.1/tick/级 | 人族唤醒 |
| 歌之环 | 斐波那契 1000 | 信仰 +0.3/tick/级 | 林地民唤醒 |
| 铸根坊 | 斐波那契 1000 | 树液 +0.5/tick/级 | 石裔唤醒 |
| 图腾柱 | 斐波那契 1000 | 记忆 +0.1/tick/级 | 野民唤醒 |

节奏验证：
- 嫩叶 3 级共 60 树液——种子阶段几分钟内完成教学
- 深根梦 +15 记忆 ≈ 300 tick 人族梦产（一次性爆发，3000 树液回收）；记忆是稀缺资源，奖励显著
- 四族设施 1000 斐波那契 vs 独立产出（火塘 0.1 记忆/tick 回本 10000 tick ≈ 2.7 小时——长线投资，为挂机期服务）

## 五、内容交付（文风六则）

**深根梦**（一次性，记忆+15）：
> 你把根须往更深处送。泥下的梦，比河里的更老——老到分不清是记忆，还是地质层。
> 你梦见一棵树。不是你自己。是很多年前，一棵真正的、普通的树。
> 它不知道什么叫世界。它只知道向上，向光。
> 醒来时，你的根须里多了一点暖意。像有什么东西，在你身体里扎了根。

**风语膜**（一次性，信仰+30）：
> 风从旧世界的方向吹来。你在风里，听见很远的说话声——
> 有人在河边洗衣服。有孩子在追一只蜻蜓。有人在天裂之前，最后看了一眼太阳。
> 声音很轻，像隔着水面。
> 你听了一整个下午。风停的时候，你发现自己记下了它们的声音——像记下了某种信仰。

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_cost_calculator.gd` | 嫩叶线性（0→10、2→30）；四族设施斐波那契（0→1000、2→2000） |
| `test_game_actions.gd` | 嫩叶购买（成功/3 级封顶）；深根梦/风语膜（一次性幂等/记忆+15/信仰+30）；四族设施（唤醒解锁/未醒不可买/成功扣 sap） |
| `test_game_loop.gd` | 点击采集 + 嫩叶加成（gather_daylight seedling L1 +1） |
| `test_race_manager.gd` | 四族设施独立产出（火塘/图腾柱记忆、歌之环信仰、铸根坊树液） |
| `test_game_state.gd` | 7 个新字段序列化往返 + 旧档回退 |
| `test_game_manager.gd` | 7 个入口集成（信号/成本 getter） |
| 全量回归 | 既有 163 测试无回归；headless 冒烟 |

## 七、决策记录

1. **全缺口补齐**（主人拍板）：嫩叶教学链 + 一次性大额 + 四族设施——spec line 287 可重复设施 6/6 达成，升级表可重复 7 → 11 + 一次性 2。
2. **嫩叶 3 级封顶**：教学链线性（10/20/30）——引导新手理解「点击→攒资源→买升级」循环，封顶防通胀。
3. **一次性大额奖励量**（深根梦 +15 记忆 / 风语膜 +30 信仰）：对应 3000/2500 树液成本——记忆稀缺奖励显著，信仰中量；spec 未定义效果，本设计定稿。
4. **四族设施独立产出**：不与现有系数（根须记忆加成/花盘信仰/石裔献工）叠加冲突——设施是「各族资源放大器」的新增独立源。
5. **设施解锁 = 该族唤醒**：与 M5a 仪式互动区分（设施=可重复购买升级，互动=一次性关系事件）。
6. **长线投资定位**：设施回本 2.7 小时——为挂机期服务（增量游戏的核心时段）。

## 八、衔接

- 升级表可重复 11 + 一次性 2 + 解锁型 13（遗迹/图腾/互动）——离 90+ 目标仍有大空间（科技树/九界/离线）
- M5c 意志漂移+化身（押后）不受影响
- 四族设施后续可加「关系」联动（设施升级影响关系温度）——可选扩展

---

## 附录：存档示例

```jsonc
// M5d 旧档：无新字段 → 回退默认
{ "chloroplast_level": 2, ... }
// M5d2 新档：
{ "seedling_level": 3, "firepit_level": 2, "ring_level": 0, "forge_level": 1, "totem_pole_level": 0, "deep_dream": true, "wind_veil": false, ... }
```
