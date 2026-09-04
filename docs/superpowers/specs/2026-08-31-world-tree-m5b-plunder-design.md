# 世界树 里程碑 5b 设计文档：夺梦系统（延迟代价·暗线机制）

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：路线图 `docs/world-tree/ROADMAP.md`（M5b 夺梦）；主规格 `2026-08-31-world-tree-design.md`（§5 采梦代价/§6 梦境转化/§13.3 夺梦/§13.11 明暗双线）；M5a 关系值（±3/一次性互动）
> **范围**：夺梦的主动日常机制——延迟代价、分级揭示、各族差异化、伪装文案

---

## 一、背景与目标

spec §13.3「奇迹的反面：夺梦（消耗生灵）——主动暗代价」。本里程碑把夺梦做成**主动日常机制**，核心是暗线设计：

1. **延迟代价**：夺梦按钮只显示产出（快而诱人），代价以隐藏计数器累积——玩家不知不觉夺了很多次；
2. **分级揭示**：某族夺梦达 3/6/9 次触发揭示事件（§13.11 手法 6「结算时刻」）——把之前所有微妙信号一次点亮，玩家「豁然开朗 + 后悔」；
3. **各族差异化**（贴 spec §5）：人族伤神/林地民枯萎/野民惊扰/石裔无梦可夺（机制级拷问）；
4. **伪装文案**：按钮不叫「夺梦」而叫「把梦收进年轮」——玩家以为在守护记忆，实为吞噬（明线伪装暗线的按钮级表达）；
5. 为 M5c 意志漂移预留 `plundered` 注入源。

## 二、范围与边界

### 2.1 包含

- `PlunderActions`（RefCounted 纯静态）：can_plunder/plunder/reveal_stage/is_frozen
- `PlunderData`（const 表）：各族产出/信号文本池/3 级揭示文本
- `GameState` 扩展：`plundered: Dictionary`（`{race_id: int}`）、`plunder_reveals: Array[StringName]`（已揭示的族）
- `RaceManager` 增长阶段接入 `is_frozen`（揭示后该族人口冻结）
- `GameManager`：`plunder_race(race_id)` 入口 + 信号
- UI：每族「把梦收进年轮」按钮（伪装文案）+ 信号/揭示文本显示
- 暗线信号池 + 3 级揭示文本全文（人/林地/野民）+ 石裔拷问文本

### 2.2 边界（不包含）

- 菟丝子明选（重夺 -1.5 的明选事件）——M5g 明选引擎
- 意志漂移值（drift）——M5c（本次只积累 plundered 计数器）
- 产出公式的显性衰减（夺梦降信仰产）——M5b 以关系扣减+人口冻结表达代价，不侵入产出公式
- 石裔的夺梦防御/反击机制——无梦即无代价，仅拷问文本

## 三、架构

### 3.1 GameState 扩展

```gdscript
var plundered: Dictionary = {}              # {race_id: int} 夺梦次数（隐藏，存档）
var plunder_reveals: Array[StringName] = [] # 已触发揭示的族（防重复揭示）
```

- 序列化 + 非字典/非 StringName 过滤防御（沿既有模式）+ 缺字段回退

### 3.2 PlunderActions（RefCounted 纯静态）

新增 `features/memories/plunder_actions.gd`：

```gdscript
class_name PlunderActions
extends RefCounted

const REVEAL_THRESHOLDS := [3, 6, 9]

static func count(state, race_id) -> int              # plundered 次数，缺省 0
static func can_plunder(state, race_id) -> bool       # 该族已唤醒（石裔可点但无产出）
static func plunder(state, race_id) -> Dictionary
# 产出记忆（各族 PlunderData.yield）；plundered[id] += 1（石裔不加）
# 返回 {"ok", "memory": int, "text": String}
#   text = 信号文本（正常夺梦）或揭示文本（达新阈值：应用代价 + 标记 plunder_reveals）
static func reveal_stage(state, race_id) -> int       # 0/1/2/3（已揭示的最高级）
static func is_frozen(state, race_id) -> bool         # reveal_stage >= 1（人口增长冻结）
```

**揭示应用代价**（达 3/6/9 时）：
- 关系 -0.5（`RelationActions.apply_change(state, race_id, -0.5)`，三级累计 -1.5）
- 人口增长冻结（`is_frozen` 由 reveal_stage>=1 推导，RaceManager 增长阶段跳过）
- 野民 1 级揭示额外：人口 -20%（一次性，round 取整，防重复——由 plunder_reveals 保证）

### 3.3 PlunderData（const 表，沿 TotemLibrary 模式）

新增 `features/memories/plunder_data.gd`：

```gdscript
const DATA: Array[Dictionary] = [
    {"race_id": &"human",      "yield": 1.0,  "signals": [...], "reveals": [3 级文本]},
    {"race_id": &"forestfolk", "yield": 1.2,  "signals": [...], "reveals": [...]},
    {"race_id": &"wildfolk",   "yield": 2.0,  "signals": [...], "reveals": [...]},
    {"race_id": &"stoneborn",  "yield": 0.0,  "signals": [...], "reveals": []},  # 无梦
]
static func get_data(race_id) -> Dictionary
static func signal_text(state, race_id) -> String   # 从信号池轮换（按 plundered 计数取模）
```

### 3.4 RaceManager 集成（增长冻结）

`tick_races` 增长阶段（步骤 3）追加：

```gdscript
if PlunderActions.is_frozen(state, race.id):
    continue  # 该族人口冻结（夺梦揭示后）
```

### 3.5 GameManager 集成

```gdscript
signal plunder_done(race_id: StringName, text: String, revealed: bool)

func plunder_race(race_id: StringName) -> Dictionary:
    var result := PlunderActions.plunder(_state, race_id)
    if result.get("ok", false):
        plunder_done.emit(race_id, str(result.get("text", "")), bool(result.get("revealed", false)))
        resources_changed.emit()
    return result
```

### 3.6 UI（伪装文案）

- 每族面板追加「**把梦收进年轮**」按钮（`%PlunderHumanButton` 等）——该族已唤醒即可点
- 石裔按钮永远可点：产出 0，每次返回拷问文本「它们没有梦。只有手。」
- 信号文本/揭示文本经 `race_event_label` 显示（揭示文本以「——」断句结算样式）

## 四、数值模型

| 族 | 产出/次 | 揭示阈值 | 关系代价（每级） | 额外代价 |
|---|---|---|---|---|
| 人族 | +1.0 记忆 | 3/6/9 | -0.5（累计 -1.5） | 人口冻结 |
| 林地民 | +1.2 记忆 | 3/6/9 | -0.5（累计 -1.5） | 人口冻结 |
| 野民 | +2.0 记忆 | 3/6/9 | -0.5（累计 -1.5） | 1 级：人口 -20%（惊扰攻击） |
| 石裔 | 0 | — | 无 | 无（夺无可夺） |

- 节奏对照：人族梦产 0.05/tick（50 人口）≈ 20 秒 +1 记忆；夺梦一次 +1（人族）瞬间获得——「快而伤」的诱惑成立
- 9 次日常夺梦与菟丝子明选「继续吸」均累计 -1.5——日常的涓滴之恶积累成明选级之伤

## 五、内容交付（文风六则 + 暗线手法：信号模糊、揭示结算）

> 叙事基线沿用：第二人称「你」= 巨树；互动发生于根须/年轮；无化身。

### 5.1 暗线信号池（夺梦后给一句「哪里不对」，按 plundered 轮换）

**人族**：
1. 「她说故事的时候，停了一下。像在数着什么。」
2. 「火塘的火，比上次小了一些。」
3. 「她看了你一眼。很快移开。」

**林地民**：
1. 「歌会散了之后，有个人回头看了你的根，很久。」
2. 「萤光。好像比昨天暗了一点。」
3. 「有一首歌，他们今天没唱。没有人提起。」

**野民**：
1. 「夜里，石壁前多了一双眼睛。」
2. 「画里那棵树，根须好像粗了一圈。」
3. 「风声里，有一声很轻的，像是叹息。」

**石裔**（每次，唯一文本）：
> 「你伸向它们。它们摊开手——手里是锤子和凿子。『我们没有梦。』它们说。『我们只有手，和接下来要造的东西。』」

### 5.2 揭示事件（3 级 × 3 族，结算时刻点亮所有信号）

**人族 1 级**（3 次）：
> 「你忽然想起来——你已经听了她 3 次梦。故事不是讲到一半停住的。是她每次讲完，都觉得少了什么。」
**人族 2 级**（6 次）：
> 「火塘还亮着。但她讲故事的时候，会用手捂着嘴——像怕梦从嘴里漏出来。」
**人族 3 级**（9 次）：
> 「她不再看你了。她对着火塘讲，讲给没有人听。你才知道，你把她梦里的那个人，一点一点，借走了。」

**林地民 1 级**（3 次）：
> 「歌会照常。但你数了一下——今天的歌，比昨天少了一首。没有人注意到。除了你。」
**林地民 2 级**（6 次）：
> 「有棵树下，坐着一个不唱歌的林地民。她看着自己的手，像在看一件坏掉的乐器。」
**林地民 3 级**（9 次）：
> 「萤光熄了大半。他们还在唱，唱给谁听呢——树不说话。树把它们的歌，都收进了年轮。」

**野民 1 级**（3 次）：
> 「夜里，石壁上的画多了一幅：一棵树，根须伸进河流，河底躺着很多萤火虫。」
**野民 2 级**（6 次）：
> 「野民不再靠近你的根了。他们绕路。画里的树，越长越大，越画越像——一张嘴。」
**野民 3 级**（9 次）：
> 「它们在石壁上画完了最后一幅：树在吞噬。树冠是嘴，根须是舌。你盯着看了很久——忽然认出，那就是你。」

（野民 3 级与 M4 图腾幅 5「树与人影是同一个」互文——吞噬者即我，两条暗线交汇。）

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_plunder_actions.gd` | 产出各族不同（1/1.2/2/0）；石裔不涨 counter 且产出 0；counter 累积；阈值 3/6/9 揭示（reveal_stage 0→1→2→3）；揭示幂等（已揭示不重复应用）；关系扣减（每级 -0.5 累计 -1.5）；is_frozen（揭示后 true）；野民 1 级人口 -20% 一次 |
| `test_plunder_data.gd` | 4 族数据齐全、yield 合法、信号池非空、揭示文本 3 级齐全（石裔除外） |
| `test_game_state.gd` | plundered/plunder_reveals 序列化往返 + 旧档回退 + 过滤防御 |
| `test_race_manager.gd` | tick_races 增长阶段跳过 is_frozen 的族（冻结族人口不变） |
| `test_game_manager.gd` | plunder_race 集成（信号 + 记忆产出 + 揭示标记；不可夺不发信号） |
| 全量回归 | 既有 122 测试无回归；headless 冒烟 |

## 七、决策记录

1. **主动日常机制**（spec §13.3「主动暗代价」）——玩家主动选择快而伤的路径，代价节制而非硬冷却。
2. **延迟代价 + 分级揭示（3/6/9）**：夺梦只显示产出，代价隐藏累积；§13.11 手法 6「结算时刻」在 3/6/9 点亮——「豁然开朗 + 后悔」的节奏（主人拍板）。
3. **伪装文案「把梦收进年轮」**：按钮级明线伪装（主人拍板）——玩家以为在守护记忆，实为吞噬；与 M4「解读图腾」的诚实文案形成善恶不对称。
4. **各族差异化产出**（贴 spec §5）：野民梦最深（+2）但惊扰最重；石裔无梦（0 产出 + 拷问文本——「不采梦也能有信仰」的日常化）。
5. **代价以关系+冻结表达**：不侵入产出公式（M5b 简化）；9 次日常夺梦 ≈ 菟丝子 -1.5 等价。
6. **野民人口 -20%**（1 级）：惊扰攻击的机制表达，一次性防重复。
7. **意志漂移接口预留**：plundered 总量是 M5c drift 的注入源（本次不引入 drift 值）。
8. **暗线信号池轮换**：按 plundered 计数取模，信号模糊不指明因果——玩家无法把信号与夺梦直接关联，直到揭示。

## 八、M5c 衔接

- `plundered` 总量 → 意志漂移注入（夺梦 = 吞噬行为，漂移 = 自我认知的代价）
- 菟丝子明选（重夺 -1.5 事件版）→ M5g 明选引擎，复用 PlunderActions 的代价机制
- 化身的「自我审视」场景：揭示文本与化身觉醒互文（M5c）

---

## 附录：存档示例

```jsonc
// M5a 旧档：无 plundered 字段 → 回退默认
{ "relations": {...}, ... }
// M5b 新档：
{ "plundered": {"human": 3, "wildfolk": 1}, "plunder_reveals": ["human"], ... }
```
