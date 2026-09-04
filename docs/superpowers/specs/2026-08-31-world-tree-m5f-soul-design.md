# 世界树 里程碑 5f 设计文档：灵魂系统（三级资源·守恒闭环）

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：M5e 资源分层（灵魂=三级不可再生）；主规格 §13.8 灵魂系统/§14.5 灵魂约 100 缕；M5b 夺梦（揭示机制）、M5a 关系、M3 人口/承载
> **范围**：灵魂守恒模型 + 复活（灵魂+生机→人口）+ 夺魂（夺梦顶点）——三级资源的关键选择基础

---

## 一、背景与目标

灵魂是三层资源架构（M5e）的三级资源——**不可再生、守恒、关键选择专用**。本里程碑落地：

1. **河底存量模型**：灵魂总量守恒（河底 + 已复活 = 100 恒），河底存量 UI 可见——「亡者之河变浅」暗线的机制读数；
2. **复活**：灵魂 + 生机（growth）→ 该族人口——「用自己换他们」的母亲树之喻机制化（复活消耗 growth → 承载降 → 供养压力）；
3. **夺魂**：夺梦的顶点——把活人灵魂抽回河里（哲学僵尸伏笔「没有灵魂的人还算人吗」）；
4. 为明选（菟丝子/夺魂事件）与终局（牺牲之选）提供三级资源基础。

## 二、范围与边界

### 2.1 包含

- `GameState.soul_river: int = 100`（河底灵魂存量，守恒）
- `SoulActions`（RefCounted 纯静态）：river / can_revive / revive / can_plunder_soul / plunder_soul
- `GameManager`：revive_race / plunder_soul_race 入口 + 信号
- UI：灵魂存量显示（「灵魂：X / 100」）+ 复活/夺魂按钮
- 测试 + E2E

### 2.2 边界（不包含）

- 归河（自然死亡回收）——机制预留接口（后续人口损失事件接入）
- 灵性强化（灵魂→品质，产出效率）——后续
- 传说灵魂（极完整→特殊存在，如人族说书人）——后续
- 明选中的夺魂事件（哲学僵尸）——M5g 明选引擎
- 灵魂跨周目（多周目记忆余烬）——M6

## 三、架构

### 3.1 GameState 扩展

```gdscript
var soul_river: int = 100   # 河底灵魂存量（守恒：河底 + 已复活 = 100 恒）
```

- 序列化 + 缺字段回退 100（M1-M5e 旧档不损坏）
- 守恒不变式：`river + Σ已复活灵魂 = 100`（实现内保证）

### 3.2 SoulActions（RefCounted 纯静态）

新增 `features/soul/soul_actions.gd`：

```gdscript
class_name SoulActions
extends RefCounted

const RIVER_TOTAL := 100
const REVIVE_COST_SOUL := 1
const REVIVE_COST_GROWTH := 500.0
const REVIVE_POP_GAIN := 10
const PLUNDER_SOUL_POP_LOSS := 3
const PLUNDER_SOUL_RELATION_LOSS := 2

static func river(state: GameState) -> int                 # soul_river
static func can_revive(state, race_id) -> bool            # 河底≥1 + growth≥500 + 该族已唤醒
static func revive(state, race_id) -> Dictionary          # 河底-1 + growth-500 + 人口+10 → {"ok","race_id","pop"}
static func can_plunder_soul(state, race_id) -> bool      # 该族已夺梦揭示（PlunderActions.reveal_stage≥1）+ 人口≥3 + 河底<100
static func plunder_soul(state, race_id) -> Dictionary    # 河底+1（cap 100）+ 人口-3 + 关系-1 → {"ok","race_id","pop","relation"}
```

- **守恒不变式**：`revive` 河底-1（灵魂离开河底进入生灵）；`plunder_soul` 河底+1（活人灵魂提前归河，cap RIVER_TOTAL）——总量恒 100
- **夺魂门槛**：该族已夺梦揭示（M5b `PlunderActions.reveal_stage(state, race_id) >= 1`）——暗线递进：先偷记忆（夺梦），才能抽灵魂（夺魂）

### 3.3 GameManager 集成

```gdscript
signal soul_changed(soul_river: int)
signal soul_revived(race_id: StringName, pop_gain: int)
signal soul_plundered(race_id: StringName, pop_loss: int)

func revive_race(race_id: StringName) -> Dictionary
func plunder_soul_race(race_id: StringName) -> Dictionary
# 成功 → 对应信号 + resources_changed.emit()
```

### 3.4 UI

- 灵魂存量显示：「灵魂：X / 100」（河底存量变化 = 河变浅读数）
- 复活按钮（每族，can_revive 时可用）+ 夺魂按钮（can_plunder_soul 时可用——夺梦揭示后才出现，暗线递进的 UI 暗示）

## 四、数值模型

| 项 | 值 | 说明 |
|---|---|---|
| 守恒总量 | 100 | 河底 + 已复活 |
| 复活消耗 | 1 灵魂 + 500 growth | growth 是承载来源——复活→承载降→供养压力 |
| 复活收益 | 该族人口 +10 | 母亲树之喻 |
| 夺魂条件 | 已夺梦揭示 + 人口≥3 + 河底<100 | 暗线递进 |
| 夺魂代价 | 人口 -3 + 关系 -1 | 失魂者 + 惊惧 |

节奏验证：全复活（100 灵魂）→ 人口 +1000（各族分摊）——但 growth 500/次（100 次 = 50000 growth）成本巨大，且承载公式（growth 驱动）同步收缩——「救得越多，自己越矮」的悲剧张力成立。

## 五、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_soul_actions.gd` | river 默认 100；can_revive（河底/成长/唤醒三条件）；revive（河底-1/growth-500/人口+10/幂等）；can_plunder_soul（揭示/人口/河底 cap）；plunder_soul（河底+1 cap 100/人口-3/关系-1/幂等）；守恒不变式（revive+plunder_soul 后 river 变化正确） |
| `test_game_state.gd` | soul_river 序列化往返 + 旧档回退 100 |
| `test_game_manager.gd` | revive/plunder 入口集成（信号/效果） |
| 全量回归 | 既有 184 测试无回归；headless 冒烟 |

## 六、决策记录

1. **河底存量模型**（主人拍板）：守恒可见——河底存量 UI 是「亡者之河变浅」暗线的机制读数。
2. **生机 = 映射 growth**（主人拍板）：复活消耗树高——母亲树之喻机制化；growth 是承载来源 → 复活与人口经济天然联动（救得越多自己越矮）。
3. **复活+夺魂都做**（主人拍板）：守恒闭环（复活=取出、夺魂=提前归河）。
4. **夺魂门槛 = 夺梦揭示**：暗线递进（偷记忆→抽灵魂）——哲学僵尸伏笔「没有灵魂的人还算人吗」的机制入口。
5. **守恒不变式**：river + 已复活 = 100 恒（实现内保证，测试验证）。
6. **夺魂代价**（人口-3 + 关系-1）：失魂者 + 惊惧——比夺梦（人口冻结）更重的直接损失，符合「顶点」定位；仍可重复触发，由 -3 下限钳制。

## 七、衔接

- **归河接口**：`soul_river` 是归河的目标——后续人口损失事件（饥荒/迁徙）接入时灵魂回收
- **明选夺魂事件**（M5g）：哲学僵尸明选复用 plunder_soul 机制
- **灵性强化**：灵魂→品质（人口产出效率）——后续增量
- **终局牺牲之选**（M6）：希望+灵魂的跨周目账目

---

## 附录：存档示例

```jsonc
// M5e 旧档：无 soul_river → 回退 100
{ "lingua_nodes": [...], ... }
// M5f 新档：
{ "soul_river": 88, ... }   // 已复活 12 灵魂（100-88=12）
```
