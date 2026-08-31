# 世界树 里程碑 3 设计文档：四族 + 人口 S 曲线

> **状态**：设计定稿（2026-08-31），待实施计划
> **前置**：主设计规格 `docs/superpowers/specs/2026-08-31-world-tree-design.md`（v2.3）；里程碑 2 完成（61 测试全绿，2026-08-31 审查修复后）
> **范围**：成树阶段核心——四族归位 + 人口经济学
> **流程**：brainstorming（Architectural）→ 本设计文档 → writing-plans 实施计划 → TDD 执行

---

## 一、背景与目标

M2 已实现单一人族系统（记忆≥2 唤醒、每 10/20 tick 平铺产信仰/记忆）。M3 目标：

1. 把 `HumanManager` 泛化为数据驱动的 **`RaceManager`**，人族迁入数据表；
2. 加入林地民/石裔/野民三族（唤醒条件、事件文本、产出）；
3. 落地 **人口 S 曲线**（逻辑斯蒂增长，spec §13.9/§14.4）：供养负担、虔诚加权信仰、树高驱动的承载扩展——「文明繁荣本身就是吞噬」机制化；
4. 兑现 spec §15「种族数据驱动 .tres」的架构承诺（I3 遗留决策闭环）。

## 二、范围

### 2.1 包含

- `RaceData`（Resource）数据驱动框架 + 四族 `.tres` 数据文件
- `RaceManager`（RefCounted 纯逻辑）取代 `HumanManager`：唤醒判定 ×4、供养、逻辑斯蒂人口增长、三产出公式
- `GameState` 扩展 `races` 字典 + 旧档迁移（`human_awakened` → `races["human"]`）
- `GameManager` 集成（`_process` 驱动）+ `race_awakened` 信号（泛化 `human_awakened`）
- UI：四族面板 + 唤醒事件文本
- 唤醒事件文本 ×3（林地民/石裔/野民，文风六则）

### 2.2 边界（不包含，留 M4+）

- 夺梦/采梦暗代价系统（菟丝子明选等）——M4 巨树阶段
- 奇迹（绿地扩容、改造地貌）——M4
- 图腾解读/领悟值（野民探针的完整机制）——M4 巨树图腾线
- 饥荒/迁徙/拥挤危机事件（供养不足的减员后果）——M4，M3 仅冻结增长
- 关系值/明选系统——M4+

## 三、架构

### 3.1 RaceData（`.tres` 数据驱动，spec §15）

新增 `features/races/race_data.gd`：

```gdscript
class_name RaceData
extends Resource

@export var id: StringName          # "human" / "forestfolk" / "stoneborn" / "wildfolk"
@export var display_name: String    # 人族 / 林地民 / 石裔 / 野民
@export var awaken_condition: String  # "memory>=2" / "faith>=30" / "faith>=60" / "faith>=100"
@export var awaken_pop: float       # 唤醒人口：50/30/20/80
@export var growth_rate: float      # 逻辑斯蒂增长率：0.010/0.006/0.005/0.020
@export var support_cost: float     # 供养系数：0.002/0.001/0.003/0.001
@export var devotion: float         # 虔诚：1.0/1.8/0.6/0.3
@export var produce_memory: bool    # 人族 true（记忆引擎）；其余 false
@export var craft_sap: float        # 石裔献工：人口×此系数产树液；其余 0.0
@export var awaken_text: String     # 唤醒事件文本（文风六则）
```

数据文件：`features/races/data/human.tres`、`forestfolk.tres`、`stoneborn.tres`、`wildfolk.tres`。

### 3.2 RaceManager（RefCounted，取代 HumanManager）

纯静态 + 注册表，延续 M2 已验证的可测模式：

```gdscript
class_name RaceManager
extends RefCounted

static func register_race(data: RaceData) -> void        # 注册表（Dictionary: id → RaceData）
static func get_race(id: StringName) -> RaceData
static func all_races() -> Array[RaceData]

static func check_awaken(state: GameState, race: RaceData) -> bool
# 条件匹配则置 races[id].awakened = true、population = awaken_pop，返回 true

static func tick_races(state: GameState) -> Array[Dictionary]
# 每 tick：
#   1) 唤醒判定（人族 memory>=2 即时；三族信仰门槛）→ 命中者收集进返回数组
#   2) 供养：sap -= Σ(pop × support_cost)，clamp ≥ 0
#   3) 人口增长：sap > 0 时 pop += pop × growth_rate × (1 − pop/capacity)，clamp ≤ capacity
#   4) 产出：信仰 += Σ(pop × devotion × FAITH_EFF)；记忆 += 人族 pop × MEMORY_EFF；树液 += Σ(pop × craft_sap)
# 返回本次唤醒事件列表：[{"race_id", "race_name", "awaken_text"}, ...]（保持纯函数可测，GameManager 转发信号）
```

常量（RaceManager 内定义，数值见 §4.2）：

```gdscript
const FAITH_EFF := 0.002   # 信仰效率（四族共享）
const MEMORY_EFF := 0.001  # 记忆效率（仅人族）
# 石裔献工系数直接存于 RaceData.craft_sap（0.01），无独立常量——单一数据源
```

`HumanManager.gd` 删除，人族数据迁入 `human.tres`。旧存档兼容见 §3.3。

### 3.3 GameState 扩展与存档迁移

新增字段：

```gdscript
var races: Dictionary = {}   # { id: {"awakened": bool, "population": float} }
```

- `to_dict()`：`"races": races`（原 `human_awakened` 字段移除）
- `from_dict(d)`：
  1. 若 `d` 含 `"races"` → 直接载入；
  2. 否则若含旧字段 `"human_awakened"`（M2 旧档）→ 迁移：`races["human"] = {"awakened": d.human_awakened, "population": 50.0 if awakened else 0.0}`；
  3. 完全缺失 → 空字典（默认未唤醒）。
- 任一族的 `awakened`/`population` 缺字段回退默认（awakened=false、population=0），不损坏存档。

### 3.4 GameManager 集成

```gdscript
signal race_awakened(race_id: StringName, race_name: String, awaken_text: String)  # 泛化 human_awakened

# _process 的 tick 分支内（GameLoop.tick 之后）：
var awaken_events: Array[Dictionary] = RaceManager.tick_races(_state)
for ev in awaken_events:
    race_awakened.emit(ev["race_id"], ev["race_name"], ev["awaken_text"])
```

- `_ready`：**不**额外调 `tick_races`——`races` 状态已持久化于存档；唤醒判定在 `_process` 首个 tick 自然恢复（`check_awaken` 幂等：已唤醒的族返回 false，不重复触发事件）。
- `is_human_awakened()` 保留（UI 兼容）或改由 UI 查询 `races`；`get_race_state(id)` 新增。

### 3.5 UI 与信号

- 新增四族面板（`main.tscn` VBox 追加）：每族一行 `RaceRow`（名称 + 人口 + 状态）：
  - 未唤醒：显示达成条件（「信仰 30/60/100 时苏醒」或「记忆 2」）
  - 已唤醒：显示人口数
- `main.gd`：监听 `race_awakened` → 事件文本显示（复用 M2 事件标签机制，删轮询 flag）；`_refresh` 更新四族面板
- 信号：`resources_changed`（资源）、`race_awakened`（唤醒事件）

## 四、数值模型

### 4.1 公式（spec §13.9/§14.1/§14.4/§14.5 权威落地）

| 项 | 公式 |
|---|---|
| 承载 | `capacity = 100 × (1 + 树繁茂)`；树繁茂 = growth≥100→1、≥300→2（树高驱动，spec 未定义来源，本设计定稿） |
| 人口增长 | `pop += pop × growth_rate × (1 − pop/capacity)`，每 tick，clamp ≤ capacity |
| 供养 | `sap -= Σ(pop × support_cost)`，clamp ≥ 0；sap ≤ 0 时人口增长冻结 |
| 信仰 | `信仰 += Σ(pop × devotion × 0.002)` |
| 记忆 | `记忆 += 人族人口 × 0.001`（人族记忆引擎） |
| 石裔献工 | `树液 += 石裔人口 × 0.01`（craft_sap 字段存 0.01，生产力引擎 §13.9） |

### 4.2 四族系数（spec §14.4 表 + M3 定稿）

| 种族 | id | 唤醒条件 | 唤醒人口 | 增长率 | 供养系数 | 虔诚 | 特殊 |
|---|---|---|---|---|---|---|---|
| 人族 | human | 记忆≥2（M2 保留） | 50 | 0.010 | 0.002 | 1.0 | 记忆产出 |
| 林地民 | forestfolk | 信仰≥30 | 30 | 0.006 | 0.001 | 1.8 | 信仰主力 |
| 石裔 | stoneborn | 信仰≥60 | 20 | 0.005 | 0.003 | 0.6 | 献工产树液 |
| 野民 | wildfolk | 信仰≥100 | 80 | 0.020 | 0.001 | 0.3 | 漂移探针（叙事，机制 M4） |

### 4.3 节奏验证

- **信仰曲线**：人族唤醒（50 人口×1.0×0.002=0.1/tick）→ ~5 分钟到 30 → 林地民（+30×1.8×0.002=0.108）→ ~2.4 分钟到 60 → 石裔 → ~2.9 分钟到 100 → 野民。约 10 分钟完成三族苏醒，落在幼苗末/成树初。
- **供养**：全族 180 人口供养 0.27 树液/tick（0.1+0.03+0.06+0.08）；石裔献工 0.2/tick 补足 74%，净负担 0.07/tick——树液产出需要可持续供给，供养成为真实约束。
- **承载**：初始 cap 100（人族 50 + 林地民 30 + 石裔 20 = 100 满）；野民唤醒需 pop 达 180 > 100 → 必须树高 growth≥100（繁茂 1、cap 200）→ 树高驱动的扩承载成为成树期的推进目标。

### 4.4 待调优标注

效率系数（0.002/0.001/0.01）、树繁茂阈值（100/300）为节奏对齐估值，spec §14 标注「待试玩调优」；实施中如有手感问题，记录偏离并回填本设计与主 spec。

## 五、内容交付

### 5.1 唤醒事件文本（文风六则：短句呼吸/意象代替说明/留白不写尽/柔和如风/自然词汇/人称柔软）

**林地民「献歌之礼」**：

> 林子深处，先有一声。
> 不是鸟。
> 不是风。
> 是很多年以前，有人把歌种进土里，如今发了芽。
>
> 他们从树根上醒来，浑身是苔，指尖是叶脉。
> 看见你，他们先是一愣，然后笑了——
> 开口，就是一整座森林的合唱。
>
> 「母树。我们梦见你很久了。
> 我们唱歌，你就不孤单。」

**石裔「第一声锤响」**：

> 你听见地底传来闷响。
> 一下，一下，有节奏。
> 不是心跳。
> 是锤。
>
> 他们从岩层里起身，指节粗大如卵石，眼睛像淬火的炭。
> 不唱歌，不祈祷。
> 打量你的年轮，像打量一块料。
>
> 「树。」
> 他们没有再说第二句。
> 锤声落进土里，把地夯实。
> 他们不献梦。
> 他们献的是——手，和接下来的日子。

**野民「夜里的眼睛」**（漂移探针第一信号）：

> 夜里，石壁前多了一圈眼睛。
> 半蹲在月光与阴影之间，毛发覆体，兽瞳发亮。
> 不靠近，也不离开。
> 只是在看。
>
> 你忽然发现，石壁上多了一幅画。
> 线条很旧，像画了很久。
> 画的是一棵树——
> 树冠遮天，根须伸进河流。
> 河在变浅。
>
> 它们在画你。
> 它们从第一天就在画你。

### 5.2 四族面板

- 未唤醒行：`人族  —  记忆 2 时苏醒` / `林地民  —  信仰 30 时苏醒` / `石裔  —  信仰 60 时苏醒` / `野民  —  信仰 100 时苏醒`
- 已唤醒行：`人族  —  人口 58`
- 探索/升级等消息沿用 `LogLabel`；唤醒事件用事件文本标签（删 `_human_announced` 轮询 flag）

## 六、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_race_manager.gd` | 唤醒判定 ×4（含边界：记忆 1.99 不醒/信仰 29.9 不醒）；唤醒瞬间 population=awaken_pop；逻辑斯蒂增长（含 cap 钳制）；供养扣除与 sap≤0 增长冻结；信仰/记忆/树液三产出公式；承载=树高映射（growth 99/100/299/300） |
| `test_game_state.gd` | `races` 序列化往返；M2 旧档（`human_awakened`）迁移；缺字段回退 |
| `test_game_manager.gd` | `_process` 驱动集成：探索×2→唤醒→tick→产出信仰/记忆；`race_awakened` 信号 |
| `test_race_data.gd` | 四 `.tres` 可加载、字段非空、awaken_condition 合法 |
| 全量回归 | 既有 61 测试无回归；headless 冒烟无 SCRIPT ERROR |

## 七、决策记录（对主 spec 的细化/偏离，回填项）

1. **数据驱动 .tres**：兑现 spec §15（I3 闭环）——M2 用 const 表属 MVP 过渡，本设计落地资源化。
2. **产出模型统一**：废弃 M2「每 10/20 tick 平铺」，改为 §14.5 公式（信仰=Σ人口×虔诚×效率；记忆=人族人口×效率）——平铺模型是临时骨架，公式是权威。
3. **唤醒条件细化**：spec 仅「成树·信仰≥100」；本设计定稿陆续唤醒（人族记忆≥2 / 林地民 30 / 石裔 60 / 野民 100），呼应 §7「四族陆续苏醒」。
4. **树繁茂=树高驱动**：spec §13.9 未定义树繁茂来源；本设计定稿 growth≥100/300 → 繁茂 1/2（母树意象 + 既有资源）。
5. **石裔献工双表达**：虔诚 0.6（§14.4 表内）+ 献工产树液（§13.9 生产力引擎）——既入公式又独立于梦，「不采梦也能忠诚」数值化。
6. **野民=漂移探针**（叙事定位确认）：§5.4「照镜子」+ 暗线六条之五「图腾从第一天就在画树」；M3 仅唤醒文本带第一信号（「河在变浅」「它们在画你」），图腾机制 M4。
7. **供养不足=冻结增长**（M3 简化）：不引入减员（饥荒事件 M4），避免死亡螺旋同时保持供养压力。

## 八、M4 衔接

- **图腾线**：野民图腾随采梦量变化（探针读数）+ 解读得领悟值——建立在 M3 野民唤醒与人口基础之上
- **夺梦系统**：采梦/夺梦暗代价（人族伤神、林地民枯萎）——石裔「献工」的对照项（机制级拷问）
- **奇迹**：绿地扩容进入承载公式（cap 100×(1+繁茂+绿地 0-3)）——树高驱动的扩承载是前奏
- **饥荒事件**：供养不足从「冻结增长」升级为「减员/迁徙危机」
- **明选/关系值**：四族关系温度与明选事件

---

## 附录：存档迁移示例

```jsonc
// M2 旧档（迁移前）
{ "human_awakened": true, "memory": {...}, ... }
// M3 载入后（迁移）
{ "races": { "human": { "awakened": true, "population": 50.0 } }, "memory": {...}, ... }
```
