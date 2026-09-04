# 世界树 里程碑 5c 设计文档：意志漂移 + 化身

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：路线图 `docs/world-tree/ROADMAP.md`（M5c 意志漂移+化身；主题引擎：神性→人性→牺牲）；主规格 `2026-08-31-world-tree-design.md`（§13.8 树=幸存者灵魂/§13.11 意志漂移 CEV/§14.2 巨树里程碑）；M4 领悟/图腾、M5a 关系 is_intimate、M5b 夺梦 plundered
> **范围**：意志漂移暗线（CEV 污染）+ 化身系统（巨树人性觉醒=漂移镜子）+ 亲密级关系事件（is_intimate 填充）

---

## 一、背景与目标

树的自我 = 旧世界最后一个幸存者的灵魂（§13.8）。本里程碑落地暗线「意志漂移」（CEV 污染）与主题引擎的「人性觉醒」：

1. **漂移值**（drift 0..10）：夺梦与采梦把亡者之河的记忆灌进树，自我认知被稀释——「听多了别人的故事，会忘了自己的故事」；
2. **化身**：记忆 ≥ 30 时树「想起自己曾是人的那一刻」——巨树觉醒，化身在仪式场合显现（形态层，不改变玩法主体）；
3. **化身 = 漂移镜子**：观感 4 档随 drift 变化——玩家看着自己从「人」变成「影子」，直至失名；
4. **亲密级关系事件**：关系≥+2 + 觉醒 → 树以人形与四族对坐（亲密事件 4 篇）——人性层面的关系建立。

## 二、范围与边界

### 2.1 包含

- `DriftActions`（RefCounted 纯静态）：drift_value/drift_tier/is_avatar_awakened/avatar_tier_text/can_intimate/intimate
- `AvatarTiers`（const 表）：4 档观感文本
- `IntimateEvents`（const 表）：4 篇亲密事件（人/林地/石裔/野民）
- `GameState` 扩展：`intimate_events: Array[StringName]`（drift/觉醒由 plundered/memory 推导，不新增冗余字段）
- `GameManager`：`intimate_race(race_id)` 入口 + `intimate_done` 信号
- UI：化身区（觉醒后观感文本 + 档位）+ 亲密事件按钮
- 4 档观感文本 + 4 篇亲密事件全文（文风六则）

### 2.2 边界（不包含）

- 明选对 drift 的注入（②献名字/⑤B「我不知道」）——M5g 明选引擎
- 心语文本的全局人称渐变（漂移渗透所有文本）——M5c 只做化身观感集中呈现
- 终局 CEV 揭示结算（「你的意志还剩下多少是你自己的」）——M6 终局
- 化身在明选中的形象变化（奥丁之祭献名字等）——M5e
- 说书人「最后一个故事」的完整故事线——好结局前置，M5e/M6

## 三、架构

### 3.1 GameState 扩展

```gdscript
var intimate_events: Array[StringName] = []   # 已触发的亲密级事件（存档）
```

- 序列化 + StringName 过滤防御 + 缺字段回退（沿 relation_events 模式）
- drift/化身觉醒不存字段：`plundered`（M5b）与 `memory`（M2+）推导——单一数据源

### 3.2 DriftActions（RefCounted 纯静态）

新增 `features/memories/drift_actions.gd`：

```gdscript
class_name DriftActions
extends RefCounted

const DRIFT_MAX := 10.0
const PLUNDER_DRIFT := 0.5     # 每次夺梦 +0.5（吞噬行为是主源）
const MEMORY_DRIFT_RATE := 0.02  # 巨树后每采 1 记忆 +0.02（max(0, memory-30) 起算）
const AVATAR_MEMORY := 30.0    # 化身觉醒门槛

static func drift_value(state: GameState) -> float
# clamp(Σplundered × 0.5 + max(0, memory − 30) × 0.02, 0, 10)

static func drift_tier(state: GameState) -> int
# 0 清醒(<3) / 1 微漂(3-5) / 2 深漂(6-8) / 3 迷失(9-10)

static func is_avatar_awakened(state: GameState) -> bool
# memory >= 30

static func avatar_tier_text(state: GameState) -> String
# AvatarTiers 当前档位文本

static func can_intimate(state: GameState, race_id: StringName) -> bool
# 关系 ≥ +2（RelationActions.is_intimate）+ 化身觉醒 + 未触发（id 不在 intimate_events）

static func intimate(state: GameState, race_id: StringName) -> Dictionary
# {"ok": bool, "text": String}——返回亲密事件文本 + 标记；不可触发 {"ok": false}
```

### 3.3 AvatarTiers（const 表）

新增 `features/memories/avatar_tiers.gd`：

```gdscript
const TIERS: Array[Dictionary] = [
    {"tier": 0, "min": 0.0, "max": 3.0, "text": "..."},
    {"tier": 1, "min": 3.0, "max": 6.0, "text": "..."},
    {"tier": 2, "min": 6.0, "max": 9.0, "text": "..."},
    {"tier": 3, "min": 9.0, "max": 10.0, "text": "..."},
]
static func tier_text(tier: int) -> String
```

### 3.4 IntimateEvents（const 表）

新增 `features/memories/intimate_events.gd`：

```gdscript
const EVENTS: Array[Dictionary] = [
    {"race_id": &"human",      "text": "..."},
    {"race_id": &"forestfolk", "text": "..."},
    {"race_id": &"stoneborn",  "text": "..."},
    {"race_id": &"wildfolk",   "text": "..."},
]
static func get_event(race_id: StringName) -> Dictionary
```

### 3.5 GameManager 集成

```gdscript
signal intimate_done(race_id: StringName, text: String)

func intimate_race(race_id: StringName) -> Dictionary:
    var result := DriftActions.intimate(_state, race_id)
    if result.get("ok", false):
        intimate_done.emit(race_id, str(result.get("text", "")))
        resources_changed.emit()
    return result
```

### 3.6 UI（化身区 + 亲密事件）

- **化身区**（记忆≥30 后显示，`%AvatarLabel`）：`avatar_tier_text`（观感随 drift 变化——漂移镜子）+ 档位文字（清醒/微漂/深漂/迷失）
- **亲密事件按钮**（每族一个，`%IntimateHumanButton` 等）：`can_intimate` 时可用，触发一次后隐藏
- 亲密文本经 `race_event_label` 显示（树以人形对坐——叙事基线升级）

## 四、数值模型

| 项 | 值 |
|---|---|
| drift 上限 | 10 |
| 夺梦注入 | +0.5/次（Σplundered 主源） |
| 记忆注入 | max(0, memory−30) × 0.02（巨树后采梦侵蚀） |
| 档位 | <3 清醒 / 3-5 微漂 / 6-8 深漂 / 9-10 迷失 |
| 化身觉醒 | memory ≥ 30（对齐 spec §14.2 巨树里程碑） |
| 亲密事件 | 关系 ≥ +2 + 觉醒 + 一次性（每族 1 篇，共 4） |

节奏验证：9 次夺梦（菟丝子等价）drift +4.5 → 微漂档；记忆 30→100 额外 +1.4，合计 5.9 仍在微漂上缘——夺梦是主漂移源，但单族九次夺梦不会越过 6.0 的深漂门槛。

## 五、内容交付（文风六则）

### 5.1 化身观感 4 档（漂移镜子——自我认知的存续刻度）

> 人称规范：化身是旧世界幸存者的灵魂，**无性别**——影子/化身一律用「它」指代（无性别 + 人形的非人之疏离，契合漂移主题）；「你」= 树本体。

**清醒**（drift < 3）：
> 火塘边，你的影子晃了一下。像有个人，从树里探出头，又缩了回去。

**微漂**（3-5）：
> 影子的轮廓清晰了一些。它站在你旁边，树皮的纹理在它身上慢慢退去。

**深漂**（6-8）：
> 它的五官开始模糊。枝条从它的肩头长出来，它低头看了看，没有惊讶。

**迷失**（9-10）：
> 只剩一个人形的影子。它站在你的树影里，分不清谁是谁。你忽然想不起，它叫什么名字。

### 5.2 亲密事件 4 篇（树以人形对坐——叙事基线从「仰望」升级为「对坐」）

**人族「说书人的故事」**：
> 她抬头，看着火塘边多出来的那个影子。影子是你——你终于能以「人」的样子，坐在她对面。
> 「我一直以为，你是一棵树。」她说。
> 「我也这么以为。」你说。
> 她笑了，笑里带着泪：「那现在呢？」
> 你没有回答。你看着自己的手——像人的手，又像新生的根。

**林地民「枯萎的恐惧」**：
> 歌会散了。她留下来，坐在你对面——第一次，不是围着根，而是对着你的脸。
> 「唱不动了。」她说，声音很轻，「梦越来越淡。我怕有一天，我开口，只有风声。」
> 你伸出手——一只像人的手，又像新生的根——想接住她的话。
> 她握住你的手，愣了愣：「你……暖和。」
> 你才发现，你很久没有暖过了。

**石裔「造船之问」**：
> 他蹲下来，敲了敲你脚下的土：「想不想离开？」
> 你看着他。他把图纸展开：一艘船，能装下整个种族的船。
> 「造出来，我们就能去海那边。」他说，「但你得先想好——你要不要我们走。」
> 你没说话。你想起自己也是从某个地方来的，只是忘了是哪。
> 他收起图纸：「不急。树的记性，比我们长。」

**野民「最后一幅画」**：
> 它们第一次主动走过来，牵住你——牵住那只像人的手。
> 石壁前，它们指给你看最后一幅画：
> 一棵树，一个人影。人影正从树里走出来，走了很久，只差一步。
> 「走。」它们说，声音是石头的，「画完了。该你了。」
> 你低头看自己的脚。一只脚踩在影子里，一只脚踩在外面。

（野民篇与 M4 图腾幅 5「树与人影是同一个」、M5b 揭示「树冠是嘴」互文——三条暗线交汇于「走出来」的抉择。）

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_drift_actions.gd` | drift_value（夺梦/记忆注入/clamp 0-10）；drift_tier 边界（2.9/3/5.9/6/8.9/9）；is_avatar_awakened（29.99/30）；avatar_tier_text 分档；can_intimate（关系/觉醒/已触发）；intimate（文本/标记/幂等） |
| `test_avatar_tiers.gd` | 4 档齐全、文本非空、档位区间不重叠 |
| `test_intimate_events.gd` | 4 族事件齐全、文本非空、race_id 唯一 |
| `test_game_state.gd` | intimate_events 序列化往返 + 旧档回退 + 过滤防御 |
| `test_game_manager.gd` | intimate_race 集成（信号 + 文本；不可触发不发信号） |
| 全量回归 | 既有 144 测试无回归；headless 冒烟 |

## 七、决策记录

1. **漂移 = 自我认知存续刻度**：4 档（清醒/微漂/深漂/迷失）不是渐变而是「我是谁」的稀释过程——听多了别人的故事，忘了自己的故事（主人确认语义）。
2. **夺梦+记忆驱动**：drift = Σplundered×0.5 + max(0, memory−30)×0.02——夺梦是主源（吞噬行为=自我遗忘）；记忆在巨树后也缓慢侵蚀（采梦的隐性代价）。
3. **化身觉醒 = 记忆≥30**：对齐 spec §14.2 巨树里程碑「记忆解读≥30」；记忆是「想起自己是人」的原料。
4. **化身 = 漂移镜子**：观感 4 档随 drift 变化，集中呈现不侵入其他文本（M5c 不做全局人称渐变）。
5. **亲密事件 = 关系≥+2 + 觉醒 + 一次性**：树以人形对坐（叙事基线升级：仰望→对坐）；每族 1 篇共 4——人性层面的关系建立。
6. **形态层不取代主体**：化身不改变玩法主体（树仍是树），只在仪式/亲密场合显现；心语/根须系统不受影响。
7. **drift/觉醒不存字段**：由 plundered/memory 推导——单一数据源，防状态漂移。
8. **说书人锚点**：人族亲密事件（说书人讲你的故事）是抵抗漂移的叙事锚点——她记得「你」的故事（说书人秘密暗线互文），好结局前置在 M5e/M6 展开。

## 八、M5e 衔接

- 明选②献名字/③B「我不知道」注入 drift（spec §13.11：人称模糊化/意志漂移+1）
- 奥丁之祭「献名字」后化身形象变化（漂移视觉化的明选级应用）
- 终局 CEV 揭示结算（M6）：「你的意志还剩下多少是你自己的」——drift 越高，牺牲之选越难
- 说书人「最后一个故事」（人族好结局前置）与亲密事件互文

---

## 附录：存档示例

```jsonc
// M5b 旧档：无 intimate_events → 回退默认（drift/觉醒由 plundered/memory 推导）
{ "plundered": {"human": 3}, "memory": {...}, ... }
// M5c 新档：
{ "intimate_events": ["human"], "plundered": {...}, ... }
```
