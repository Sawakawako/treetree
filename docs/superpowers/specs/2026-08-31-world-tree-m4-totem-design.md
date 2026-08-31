# 世界树 里程碑 4 设计文档：图腾线（野民漂移探针）

> **状态**：设计定稿（2026-08-31），待实施计划
> **前置**：主设计规格 `docs/superpowers/specs/2026-08-31-world-tree-design.md`（v2.3）；里程碑 3 完成（82 测试全绿，2026-08-31）
> **范围**：野民图腾线机制化——漂移探针从「唤醒第一信号」升级为「可视化暗线」
> **约束**：**无美术资源，纯代码 + 文本**（文字原型阶段，石壁画用文字承载）

---

## 一、背景与目标

M3 野民唤醒文本（「夜里的眼睛」）已给出探针第一信号——「它们在画你，从第一天就在画你」。本里程碑把这条暗线机制化：

1. **图腾状态**：石壁画随记忆总量（采梦量）渐进浮现 5 幅——玩家能看见自己看不见的变化（暗线六条之五「野民图腾：吞噬者即我」）；
2. **解读**：每幅浮现后可解读一次（零消耗），得领悟值 + 该幅真相文本（吞噬者即我渐进）；
3. **领悟值**：`insight` 状态入存档（spec §13.6 好结局门槛 ≥10 的前置，明选系统后续接入）；
4. 兑现 spec §15 架构 `memories/`（记忆图书馆 / 领悟值）目录的第一块内容。

## 二、范围与边界

### 2.1 包含

- `TotemLibrary`（5 幅图腾数据：threshold/reveal_text/interpret_text）
- `TotemActions`（RefCounted 纯静态：visible_stage/can_interpret/interpret）
- `GameState` 扩展 `totem_interpreted: Array[int]`、`insight: int` + 存档序列化（旧档回退）
- `GameManager` 入口 `interpret_totem` + `totem_interpreted` 信号
- UI：野民面板图腾区（浮现文本 + 解读按钮 + 领悟显示，纯文本）
- 5 幅浮现文本 + 5 段解读文本（文风六则）

### 2.2 边界（不包含，留 M5+）

- 明选系统对领悟值的消费（好结局门槛 ≥10 的完整链路）——M5 明选
- 环形废墟 / 人族说书人故事（领悟值另两条来源）——M5+
- 记忆图书馆（收藏文本回看）——独立候选
- 图腾的「惊扰」代价（野民攻击）——M5 夺梦系统
- 多周目记忆余烬

## 三、架构

### 3.1 TotemLibrary（数据，const 表）

新增 `features/memories/totem_library.gd`，沿用 M2 RelicLibrary const 表模式（纯内容文本，非平衡数值）：

```gdscript
class_name TotemLibrary
extends RefCounted

const TOTEMS: Array[Dictionary] = [
    {"id": 1, "threshold": 0.0,  "reveal_text": "...", "interpret_text": "..."},
    {"id": 2, "threshold": 4.0,  "reveal_text": "...", "interpret_text": "..."},
    {"id": 3, "threshold": 10.0, "reveal_text": "...", "interpret_text": "..."},
    {"id": 4, "threshold": 20.0, "reveal_text": "...", "interpret_text": "..."},
    {"id": 5, "threshold": 35.0, "reveal_text": "...", "interpret_text": "..."},
]

static func all_totems() -> Array[Dictionary]
static func get_totem(id: int) -> Dictionary      # 找不到返回空字典
static func totem_count() -> int
```

阈值语义：`memory >= threshold` 时该幅**浮现**（玩家看到新画）；解读后才知真相。幅 1 阈值 0（野民唤醒即现，呼应 M3 唤醒文本「它们在画你」）。

> 数据驱动形式说明：图腾是**内容文本**（非可调平衡），沿用 RelicLibrary const 表模式；与 M3 种族 .tres 不冲突——种族系数（增长/虔诚）需 Inspector 调平衡故 .tres，图腾文本固定。若未来文本量膨胀（20+ 幅）再迁 .tres。

### 3.2 TotemActions（逻辑，RefCounted 纯静态）

新增 `features/memories/totem_actions.gd`：

```gdscript
class_name TotemActions
extends RefCounted

static func visible_stage(state: GameState) -> int
# 当前浮现的最大幅数：遍历 TOTEMS，memory >= threshold 计为可见；野民未唤醒返回 0

static func can_interpret(state: GameState, totem_id: int) -> bool
# 幅已浮现（visible_stage >= 幅序号）且未解读（id 不在 totem_interpreted）

static func interpret(state: GameState, totem_id: int) -> Dictionary
# 不可解读返回 {"ok": false}
# 可解读：insight += 1、totem_interpreted.append(id)、返回 {"ok": true, "insight": insight, "text": interpret_text}
```

前置：图腾只对已唤醒的野民有意义——`visible_stage` 在野民未唤醒时返回 0（即使记忆达标）。

### 3.3 GameState 扩展与存档

新增字段：

```gdscript
var totem_interpreted: Array[int] = []   # 已解读幅 id
var insight: int = 0                      # 领悟值
```

- `to_dict()`：`"totem_interpreted": totem_interpreted`、`"insight": insight`
- `from_dict()`：`totem_interpreted` 过滤非数字元素（沿 relics_found 防御模式）；`insight = int(d.get("insight", 0))`；缺字段回退默认，M2/M3 旧档不损坏

### 3.4 GameManager 集成

```gdscript
signal totem_interpreted(totem_id: int, interpret_text: String)

func interpret_totem(totem_id: int) -> Dictionary:
    var result := TotemActions.interpret(_state, totem_id)
    if result.get("ok", false):
        totem_interpreted.emit(totem_id, str(result.get("text", "")))
        resources_changed.emit()
    return result
```

UI 靠信号更新（Layer Cake），解读入口由按钮触发。

### 3.5 UI（纯文本，无美术）

- 野民面板图腾区（main.gd `_refresh_race_rows` 扩展或独立 `_refresh_totem`）：
  - 野民未唤醒：图腾区隐藏
  - 已唤醒：显示 `「图腾·第 N 幅」` + 当前浮现幅的 reveal_text（多幅同时可见时显示最新一幅 + 已浮现幅数）
  - 「解读图腾」按钮：`can_interpret` 时可用，点击调 `GameManager.interpret_totem`（当前解读目标 = 最新浮现未解读幅）
  - 总领悟显示：`领悟：N`
- 解读后：事件标签显示 interpret_text + 「领悟 +1」（复用 race_event_label）

## 四、数值模型

### 4.1 阈值（记忆驱动）

| 幅 | 阈值 | 记忆来源对照 |
|---|---|---|
| 1 | 0（野民唤醒即现） | M3 唤醒文本已在画 |
| 2 | 4 | 4 遗迹全探（M2 一次性 +4）后 |
| 3 | 10 | 遗迹 + 人族梦产累积 |
| 4 | 20 | 成树→巨树过渡期 |
| 5 | 35 | 巨树期（真相收束） |

### 4.2 节奏验证

记忆来源：遗迹一次性 +4（M2）+ 人族梦产 `人口 × 0.001`/tick（M3，50 人口 0.05/tick）。人族唤醒后（M3 数值）：约 20 秒 +1 记忆，遗迹 4 记忆约覆盖幅 2。幅 3（10）≈ 遗迹后 +6 ≈ 2 分钟人族梦产；幅 5（35）为长线目标（约 10+ 分钟），图腾是探针而非速通——与「巨树阶段图腾线」的 spec 定位一致。

领悟值上限 +5（5 幅各一次）；spec §13.6 好结局门槛 ≥10 的缺口由 M5 环形废墟/说书人补——本里程碑只落地图腾线部分，不修改好结局逻辑。

## 五、内容交付（文风六则：短句呼吸/意象代替说明/留白不写尽/柔和如风/自然词汇/人称柔软）

**幅 1「证据」（野民唤醒即现）**
> 浮现：石壁上多了一幅画。画的是一棵树——树冠遮天，根须伸进河流。河在变浅。
> 解读：它们在画你。它们从第一天就在画你——你才知道，那不是风景，是证据。

**幅 2「人」（记忆≥4）**
> 浮现：画里多了一行小人。跪在树前，黑黑的一排，像种子。
> 解读：那是人。活过、哭过、把名字刻进石头的人。你仔细看——它们的脸，正对着你。

**幅 3「事实」（记忆≥10）**
> 浮现：树的根须，缠着什么东西。像拥抱，又像收紧。
> 解读：它们不画仇恨。它们只画事实。你吞下去的，不止是梦。

**幅 4「眼睛」（记忆≥20）**
> 浮现：画旁多了一双眼睛。不眨，看着你，已经看了很久。
> 解读：那是野民的眼睛。也是你看自己的眼睛。中间没有隔着河。

**幅 5「同一个」（记忆≥35，吞噬者即我）**
> 浮现：画的角落里，树的倒影里，站着一个人影。树与人影，是同一个。
> 解读：你想起自己醒来时，手里那一点希望。它从来不是火种。是最后的证据——旧世界记得你，你忘了你也是它。

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_totem_actions.gd` | visible_stage 边界（3.99/4.0/35.0）、野民未唤醒返回 0；can_interpret（未浮现/已解读/未解读）；interpret（+1 领悟/标记已解读/幂等不可重复/返回文本） |
| `test_game_state.gd` | totem_interpreted/insight 序列化往返；旧档缺字段回退；totem_interpreted 非数字元素过滤 |
| `test_game_manager.gd` | interpret_totem 集成（解读 → 信号 + 领悟 +1；不可解读返回 ok:false 不发信号） |
| 全量回归 | 既有 82 测试无回归；headless 冒烟无 SCRIPT ERROR |

## 七、决策记录（对主 spec 的细化/偏离）

1. **纯文本承载**：无美术资源约束下，图腾「画」用文字描述（spec 画风规范 §11.2 的"梦与画"在文字原型阶段以文本意象实现）。
2. **记忆驱动**：图腾随记忆总量（采梦量）变化——采梦量是「河变浅」暗线的机制化读数，比信仰/人口更贴探针定位。
3. **每幅一次、零消耗解读**：领悟是知识奖励（spec §13.6「解读图腾 → 领悟值」），与资源交易区分；一次性防止刷领悟。
4. **领悟值边界**：本里程碑只落地状态 + 存档 + 显示（+5 上限）；好结局门槛 ≥10 的完整链路（环形废墟/说书人）留 M5。
5. **const 表 vs .tres**：图腾是内容文本沿用 RelicLibrary const 模式；种族 .tres 是平衡数据（Inspector 可调），两者定位不同，不冲突。
6. **阈值 4/10/20/35**：按记忆来源节奏定（遗迹 4 覆盖幅 2、人族梦产推进 3-5），spec 无先例数值，属本设计定稿，待试玩调优回填。

## 八、M5 衔接

- **明选系统**：领悟值消费（好结局门槛 ≥10；体验机器明选 C「研究 +1 领悟」、忒修斯之树 C 需领悟≥8——spec §13.5）
- **环形废墟 / 说书人**：领悟值另两条来源（spec §13.6）
- **夺梦系统**：图腾「惊扰」代价（野民攻击）机制化
- **记忆图书馆**：收藏文本回看（独立候选）

---

## 附录：存档示例

```jsonc
// M3 旧档（迁移前）：无 totem 字段 → 载入后回退默认
{ "races": {...}, "memory": {...}, ... }
// M4 新档：
{ "totem_interpreted": [1, 2], "insight": 2, "races": {...}, ... }
```
