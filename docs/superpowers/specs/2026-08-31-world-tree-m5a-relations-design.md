# 世界树 里程碑 5a 设计文档：关系值系统

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：路线图 `docs/world-tree/ROADMAP.md`（主题引擎：神性→人性→牺牲弧线）；主规格 `docs/superpowers/specs/2026-08-31-world-tree-design.md`（§13.5 明选后果/§13.6 关系值/§11.1 文风/§11.2 画风）
> **范围**：明选/终局地基的第一步——四族关系值系统 + 四族一次性仪式互动 + 亲密级接口预留（化身解锁的深度事件位，本次不落地内容）

---

## 一、背景与目标

关系值是七张明选卡片的后果载体（spec §13.5：半点制，常用 ±0.5/±1/±1.5；好结局要求四族各 +3）与终局告别差分的温度计。本里程碑：

1. 落地**四族关系状态**（对称 -3..+3，0 中性）——好结局「四族各 3」的数值地基；
2. 提供**关系修正 API**（apply_change，clamp）——明选卡片后续消费；
3. 落地**四族一次性仪式互动**（人族火塘/林地民歌会/石裔铸根坊/野民壁画）——系统立即可玩、防刷；
4. **预留亲密级接口**——关系≥+2 时该族解锁「亲密级事件位」（化身场合，M5c 化身系统落地后填充内容）；
5. UI 用**字体颜色区分关系好坏**（敌意冷色 → 中性默认 → 亲近暖金 `#e6a23c`）。

## 二、范围与边界

### 2.1 包含

- `GameState` 扩展：`relations: Dictionary`（`{race_id: float}`）、`relation_events: Array[StringName]`（已触发互动 id）+ 序列化/旧档回退
- `RelationActions`（RefCounted 纯静态）：get_relation / apply_change / can_interact / interact / is_intimate（预留）
- `RelationEvents`（const 表）：4 个仪式互动（race_id/condition/文本）
- `GameManager`：`interact_relation(race_id)` 入口 + `relation_changed` 信号
- UI：四族面板关系温度显示（文字 + 颜色）+ 每族互动按钮
- 4 篇仪式互动文本（文风六则 + 巨树叙事基线）

### 2.2 边界（不包含）

- 明选卡片（关系值的消费方）——路线图第 5 步
- 化身系统与亲密级事件内容——M5c（本次只留 `is_intimate` 接口与事件位）
- 关系值的自然衰减/漂移——不引入（关系只由明选后果与一次性互动改变）
- 夺梦/惊扰对关系的影响——M5b 夺梦系统

## 三、架构

### 3.1 GameState 扩展

```gdscript
var relations: Dictionary = {}                # {race_id: float}，-3.0..+3.0，缺省 0.0
var relation_events: Array[StringName] = []   # 已触发的一次性互动 id
```

- `to_dict()`：`"relations"`/`"relation_events"` 追加
- `from_dict()`：relations 逐键 `float()` 归一并 clamp -3.0..3.0 + 非字典防御；旧整数值无损转为 float；relation_events 过滤非法元素；缺字段回退默认

### 3.2 RelationActions（RefCounted 纯静态）

新增 `features/relations/relation_actions.gd`：

```gdscript
class_name RelationActions
extends RefCounted

const RELATION_MIN := -3.0
const RELATION_MAX := 3.0

static func get_relation(state: GameState, race_id: StringName) -> float
# 缺省 0.0

static func apply_change(state: GameState, race_id: StringName, delta: float) -> float
# clamp(-3.0..+3.0)，返回新值；delta 0 不写

static func is_intimate(state: GameState, race_id: StringName) -> bool
# relation >= +2（亲密级事件位——化身场合解锁，本次只留接口）

static func can_interact(state: GameState, race_id: StringName) -> bool
# 该族已唤醒 + 资源条件满足 + 未触发（id 不在 relation_events）

static func interact(state: GameState, race_id: StringName) -> Dictionary
# {"ok": bool, "text": String, "relation": float}——+0.5 关系、标记已触发、返回事件文本；不可互动 {"ok": false}
```

### 3.3 RelationEvents（const 表，沿 TotemLibrary 模式）

新增 `features/relations/relation_events.gd`：

```gdscript
const EVENTS: Array[Dictionary] = [
    {"race_id": &"human",      "condition": "memory>=4",  "text": "..."},
    {"race_id": &"forestfolk", "condition": "faith>=20",  "text": "..."},
    {"race_id": &"stoneborn",  "condition": "sap>=300",   "text": "..."},
    {"race_id": &"wildfolk",   "condition": "totem>=2",   "text": "..."},
]
```

- 条件文法沿用 awaken_condition 风格（`memory>=N`/`faith>=N`/`sap>=N`/`totem>=N`），`totem>=N` 指 `TotemActions.visible_stage >= N`
- `static func get_event(race_id: StringName) -> Dictionary`（找不到返回空字典）

### 3.4 GameManager 集成

```gdscript
signal relation_changed(race_id: StringName, relation: float)

func interact_relation(race_id: StringName) -> Dictionary:
    var result := RelationActions.interact(_state, race_id)
    if result.get("ok", false):
        relation_changed.emit(race_id, float(result.get("relation", 0.0)))
        resources_changed.emit()
    return result
```

### 3.5 UI（四族面板扩展，颜色表达）

- 每族行（RaceHumanLabel 等）追加关系温度显示：`「人族：人口 58 · 亲近（+2.0）」`；数值必须能显示 `.5`，不得取整
- **字体颜色映射**（Label `theme_override_colors/font_color`）：

| 关系区间 | 温度 | 颜色 |
|---|---|---|
| -3.0..-2.0 | 敌意 | 冷灰蓝 `#7a8a99` |
| -1.5..-0.5 | 冷淡 | 冷灰 `#9aa5ad` |
| 0.0 | 平常 | 默认（背景米白上的常规色） |
| +0.5..+1.5 | 友善 | 浅暖 `#c9a25c` |
| +2.0..+2.5 | 亲近 | 暖 `#e6a23c`（希望暖金，画风主色） |
| +3.0 | 挚友 | 暖金亮 `#f0b64e` |

- 每族一个**互动按钮**：can_interact 时可用；触发后按钮隐藏（一次性）
- 互动文本经 `race_event_label` 显示

## 四、数值模型

- 关系范围：`-3.0..+3.0` 的 float，合法步长 `0.5`；显示层保留半点，不做整数化
- 一次性互动 +0.5（每族一次，共 +2，防刷；2026-09-05 半点制修订）
- 资源条件（待试玩调优）：

| 互动 | 条件 | 资源来源 |
|---|---|---|
| 人族「火塘边的故事」 | 记忆 ≥ 4 | 人族记忆引擎（M3） |
| 林地民「歌会」 | 信仰 ≥ 20 | 林地民信仰主力（M3） |
| 石裔「铸根坊」 | 树液 ≥ 300 | 石裔献工（M3） |
| 野民「壁画」 | 图腾 stage ≥ 2 | 图腾线（M4） |

## 五、内容交付（文风六则 + 巨树叙事基线）

> **叙事基线（设计红线）**：第二人称「你」= 巨树本体；互动发生于根须/年轮/枝叶周围；禁止「坐下/面对面」等人形暗示（化身未引入前）。互动者是四族（他们围你/仰望你），树通过根须与年轮感知。

**人族「火塘边的故事」**（记忆≥4）：

> 火塘生在你的根须旁边。火苗是她用记忆点的，烧得很小心。
> 她说：天裂的那一天，有人把种子藏进了胸口。
> 她不知道你在听。但你的根须听得懂。
> 你的年轮里，有什么东西，轻轻动了一下。

**林地民「歌会」**（信仰≥20）：

> 他们围着你最老的那条根坐下，像围着一座圣坛。
> 开口，先是一声低音，然后整片林子应和。
> 歌声顺着根须爬上来，在你身体里走了一圈——
> 你听见自己的年轮，也跟着唱了一节。
> 唱完，他们不说话，只是把脸贴在树皮上，很久。

**石裔「铸根坊」**（树液≥300）：

> 石裔在你南面的根下挖了一条槽，把熔化的石头浇进去。
> 他们说，这是给你的地基——树站了太多年，该有人替它站一会儿。
> 锤声落下来，一下，一下，像另一种心跳。
> 你不确定那是他们的，还是你的。

**野民「壁画」**（图腾 stage≥2）：

> 夜里，野民在你根旁的石壁上画完第二幅画。
> 画的还是那棵树，但树下多了一行脚印。
> 脚印从画里伸出来，一直延伸到——你这里。
> 他们没有叫你。但他们画的每一步，都像在问：要不要走出来？

（野民文本「要不要走出来」为化身伏笔——巨树阶段觉醒的暗示，与 M5c 化身系统呼应。）

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_relation_actions.gd` | get_relation 缺省 0.0；apply_change 支持 0.5 步长并 clamp（-3/+3 边界、超界钳制）；is_intimate（+2 边界）；can_interact（未醒/资源不足/已触发）；interact（+0.5/标记/文本/幂等） |
| `test_relation_events.gd` | 4 事件齐全、条件格式合法、文本非空、race_id 唯一 |
| `test_game_state.gd` | relations/relation_events 序列化往返 + 旧档回退 + 非字典/非 StringName 过滤 |
| `test_game_manager.gd` | interact_relation 集成（信号 + 关系 +0.5；不可互动不发信号） |
| 全量回归 | 既有 102 测试无回归；headless 冒烟 |

## 七、决策记录

1. **对称 -3..+3**：对齐 spec「±3 极重」「四族各 3」；不对称会破坏明选后果与好结局门槛的数值语义（主人拍板）。
2. **UI 颜色表达关系**：敌意冷色 → 中性默认 → 亲近暖金 `#e6a23c`（画风规范主色），字体颜色区分好坏（主人拍板）。
3. **一次性互动防刷**：每族一次 +0.5，触发标记入存档；大幅关系变化留给明选卡片（±0.5/±1/±1.5）。
4. **按族绑定资源**：互动需对应产出资源（记忆/信仰/树液/图腾 stage），与各族机制挂钩（主人拍板）。
5. **无化身（本里程碑）**：互动为仪式级（巨树身份，四族仰望）；叙事基线禁止人形暗示。
6. **亲密级接口预留**：`is_intimate(relation>=+2)` + 事件位——化身系统（M5c，与意志漂移绑定）落地后填充内容（说书人最后的故事/林地民枯萎倾诉/石裔造船之问/野民最后一幅画）。
7. **关系无自然衰减**：关系只由明选后果与一次性互动改变，不引入漂移（保持系统简单，漂移是意志系统的主题）。
8. **主题引擎**：本系统是「神性→人性→牺牲」弧线的承载层——关系值从「数值」升级为「人与人的温度」，终局告别差分的感情基础。

## 八、后续衔接

- **明选卡片（M5g）**：apply_change 消费半点制数值（常用 ±0.5/±1/±1.5）；好结局阈值「四族各 3」判定在 M6 终局状态机
- **夺梦系统（M5b）**：每次阶段揭示使对应族关系 -0.5，三级累计 -1.5
- **化身系统（M5c）**：is_intimate 事件位填充亲密级事件
- **终局告别差分**：关系温度 → L3 差分文本模板（3 等级）

---

## 附录：存档示例

```jsonc
// M4 旧档（迁移前）：无 relations 字段 → 载入后回退默认
{ "races": {...}, "totem_interpreted": [...], ... }
// M5a 新档：
{ "relations": {"human": 1, "wildfolk": 2}, "relation_events": ["human", "wildfolk"], ... }
```
