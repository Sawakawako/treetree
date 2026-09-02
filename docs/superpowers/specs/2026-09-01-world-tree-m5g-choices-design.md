# 世界树 里程碑 M5g 设计文档：明选引擎与卡片（五卡落地）

> **状态**：设计定稿（2026-09-01），待实施计划
> **前置**：M5a 关系值（±3/亲密接口）、M5b 夺梦（揭示机制）、M5c 意志漂移+化身、M5d 增量深度、M5f 灵魂系统（河底守恒/复活/夺魂）——七卡依赖全景中 ①-⑤ 五卡依赖全部就绪
> **范围**：数据驱动明选引擎（`features/choices/`）+ 卡片 ①人族噩梦 ②奥丁之祭 ③诺恩三抉择（拆 3 项）④菟丝子 ⑤忒修斯之树；⑥体验机器（隐藏遗迹）后置、⑦终局四路径（M6）
> **主规格**：§13.5 关键时刻明选清单（7 个完整卡片）/ §13.6 领悟值与关系值 / §四 明选后果标准 / §15 架构（`choices/` 明选事件数据驱动）

---

## 一、背景与目标

明选是《世界树》「神性→人性→自我牺牲」主题引擎的承重墙（ROADMAP §〇）。七卡明选让玩家在文明转折的关键节点做 A/B/C 抉择，有剧情后果与道德分量——不是数值开关，是**停顿点**（spec 六章：明选=停顿点，强制无倒计时思考）。

M5a-M5f 已把七卡的依赖系统全部做完，本里程碑把它们变成**可玩的明选**：

1. **明选引擎**：数据驱动卡片容器——触发/选项/后果/差分的通用运行时（spec §15 架构预留 `features/choices/`）；
2. **五卡内容落地**：①人族噩梦（第一次明选）/②奥丁之祭/③诺恩三抉择×3/④菟丝子/⑤忒修斯之树，全部含文风六则全文；
3. **后果系统对接**：关系/记忆/信仰/领悟/漂移/灵魂/真相——复用 M5a-M5f 全部后果接口；
4. 为 M6 终局（⑦四路径、真结局隐藏选项）铺账本：`truth`（真相）、`drift_extra`（明选注入漂移）、明选 flag。

## 二、范围与边界

### 2.1 包含

- `features/choices/choice_actions.gd`（纯静态逻辑：available 触发判定 / resolve 执行后果）
- `features/choices/choice_library.gd`（读 `data/choices.json` → 卡片数据）
- `features/choices/data/choices.json`（★ 五卡全部数据，含全文文本）
- `GameState` 扩展：`choices_done` / `truth` / `drift_extra` / `race_memory_eff`（全部序列化+旧档回退）
- `GameManager`：明选检测/信号/`resolve_choice` 入口
- UI：明选弹层（intro + 选项按钮 + 差分文本）
- 测试 + E2E

### 2.2 边界（不包含）

- 卡片 ⑥体验机器（依赖隐藏遗迹库扩展——遗迹现仅 4 个，后置）
- 卡片 ⑦终局四路径（M6 终局状态机范围）
- 归还序列/真结局/多周目（M6）
- 隐藏遗迹「潘多拉/梦想机」（遗迹批次扩展，与 ⑥ 同批）
- 说书人故事线 ④⑤⑥ 与亲密事件（叙事批次，非本 M）

## 三、架构

```
features/choices/
  choice_actions.gd      # class_name ChoiceActions extends RefCounted（纯静态）
  choice_library.gd      # class_name ChoiceLibrary extends RefCounted（读 JSON）
  data/choices.json      # ★ 卡片数据（id/title/stage_hint/intro/trigger/options）
autoloads/game_manager.gd  # 明选检测 + choice_available/choice_resolved 信号 + resolve_choice
features/game/game_state.gd # + choices_done/truth/drift_extra/race_memory_eff
features/ui/main.tscn/.gd   # 明选弹层（只监听信号）
```

数据流（Layer Cake，信号向上）：
```
tick → GameManager 查 ChoiceActions.available(state) → 有且无 pending → choice_available 信号
  → UI 弹层（intro+选项）→ 玩家选 → GameManager.resolve_choice(id, option)
  → ChoiceActions.resolve 应用后果（改 GameState）+ 记录 choices_done → choice_resolved 信号
  → UI 显示差分文本 → 清 pending → 下个 tick 查下一个 available
```

### 3.1 GameState 扩展

```gdscript
var choices_done: Array[StringName] = []   # 已处理明选，防重复触发（集合语义）
var truth: int = 0                          # 真相值（吞噬者揭示线账本；③过去/②奥丁入口）
var drift_extra: float = 0.0                # 明选注入漂移（②献名字/⑤B；叠加在 DriftActions 派生值上）
var race_memory_eff: Dictionary = {}        # 种族梦产修正系数（①A 人族失眠 {"human": 0.7}）
var choice_flags: Array[StringName] = []    # 明选 flag（跨 M 伏笔：odin_left/theseus_remembered/ship_built 等）
```

- 序列化 + 缺字段回退（choices_done→[] / truth→0 / drift_extra→0.0 / race_memory_eff→{}）；损坏防御沿用既有模式
- `race_memory_eff` 并入 RaceManager 人族梦产公式（见 3.5）

### 3.2 ChoiceLibrary（读 JSON）

```gdscript
class_name ChoiceLibrary
extends RefCounted

static func load_all() -> Array[Dictionary]   # 解析 data/choices.json 的 "choices" 数组，带结构校验（id/title/options 非空）
static func get_choice(id: StringName) -> Dictionary
static func choice_count() -> int
static func valid_choice_ids() -> Array[StringName]
```

- JSON 读取：`FileAccess.get_file_as_string("res://features/choices/data/choices.json")` + `JSON.parse_string`（Godot 4 原生，UTF-8 天然正确）
- 解析失败（缺字段/坏结构）→ `push_error` + 空数组，不崩溃（测试覆盖）

### 3.3 ChoiceActions（纯静态逻辑）

```gdscript
class_name ChoiceActions
extends RefCounted

static func _race_awakened(state, id) -> bool                      # state.races 检查
static func _trigger_met(state, trigger: Dictionary) -> bool       # 触发条件全部 AND
static func available(state) -> Array[StringName]                  # 数组序：未 done 且 trigger 满足 → id 列表
static func first_available(state) -> StringName                   # 下一个待处理（无则 &""）
static func can_choose(state, choice_id) -> bool                   # 未 done 且 trigger 满足（UI 弹层前再验一次）
static func option_unlocked(state, choice_id, option_id) -> bool   # 选项级门槛（⑤C insight≥8）
static func resolve(state, choice_id, option_id) -> Dictionary     # 应用后果 → {"ok", "id", "option", "result_text", "effects"}
```

**触发条件解释器**（`_trigger_met`）——JSON 里全条件 **AND**（缺字段=该条件不要求）：

| JSON 条件键 | 语义 | 实现 |
|---|---|---|
| `races_awakened: [StringName]` | 这些族全部已唤醒 | `_race_awakened` 全真 |
| `memory_gte: float` | 记忆 ≥ 阈值 | `state.memory.is_greater_or_equal(BigNum.new(v))` |
| `faith_gte: float` | 信仰 ≥ 阈值 | 同上 |
| `growth_gte: float` | 树高 ≥ 阈值 | 同上 |
| `insight_gte: int` | 领悟 ≥ 阈值 | `state.insight >= v` |
| `relation_gte: {race: int}` | 与某族关系 ≥ 值 | `RelationActions.get_relation >= v` |
| `plundered_gte: {race: int}` | 对某族夺梦次数 ≥ 值 | `PlunderActions.count >= v` |
| `soul_revived: bool` | 是否复活过（河底 < 100 即表明发生过） | `state.soul_river < SoulActions.RIVER_TOTAL` |
| `soul_river_lte: int` | 河底 ≤ 值（河变浅读数） | `state.soul_river <= v` |

### 3.4 后果系统（effects）——JSON 结构

每个 option 携带 `effects`（Dictionary，全部可选缺省=无变化）：

| 键 | 类型 | 语义 | 实现 |
|---|---|---|---|
| `memory: float` | 资源 | 记忆 ±（BigNum.add） | `state.memory.add(BigNum.new(v))` |
| `faith: float` | 资源 | 信仰 ± | 同上 |
| `growth_pct: float` | 资源 | 树高 ±%（绝对值按当前值乘） | `growth.add(growth.value × v)`（②A -0.30） |
| `faith_pct: float` | 资源 | 信仰 ±%（④A -0.30） | 同上 |
| `relation: {race: int}` | 关系 | 每族 ±（clamp ±3） | `RelationActions.apply_change`（①-2/①+2/④±3/⑤+1） |
| `insight: int` | 领悟 | 领悟 ±（⑤C +2） | `state.insight += v` |
| `truth: int` | 真相 | 真相值 ±（③过去 +2） | `state.truth += v` |
| `drift: float` | 漂移 | 注入漂移（⑤B +1/②B 献名字） | `state.drift_extra += v`（叠加 DriftActions） |
| `memory_eff: {race: float}` | 修正 | 梦产系数（①A 人族 0.7） | `state.race_memory_eff[race] = v`（合并进 RaceManager） |
| `soul: Dictionary` | 灵魂 | 特殊操作（③现在） | 见下表 |
| `flags: [String]` | flag | 明选 flag 记录（供 M6/后续差分） | `state.choice_flags.append(...)`（见 3.5 决策） |

**soul 操作表**（③现在：救将死的林地民）：

| soul 子键 | 语义 | 实现 |
|---|---|---|
| `{ "revive_pop": {"forestfolk": 3}, "soul_cost": 2, "relation": {"forestfolk": 1} }` | 救：灵魂-2（明选特耗）、林地民人口+3、关系+1 | 直改 state.soul_river/races/relations |
| `{ "soul_gain": 0, "relation": {"forestfolk": -1} }` | 放手归河：无消耗、林地民关系-1（疏远） | 只改 relations |

> 注：此处「救 1 耗 2 缕」是明选特耗（spec ③现在原文），与 SoulActions.revive（1 缕+500 growth→+10 人口）是两条独立路径——明选不走通用复活接口。数值节奏估值，待试玩调优。

### 3.5 RaceManager 人族梦产并入梦产修正

`race_memory_eff` 合并进 `RaceManager.tick_races` 第 4 步人族/各族记忆产出：

```gdscript
var mem_eff := float(state.race_memory_eff.get(race.id, 1.0))
if race.produce_memory:
    state.memory.add(BigNum.new(pop * MEMORY_EFF * mem_eff * (1.0 + 0.1 * float(state.root_eff_level))))
```

- 缺省无修正（旧档 {} → 系数 1.0）；①A 采梦后 `{"human": 0.7}` → 人族梦产 -30%（spec ①A「人族失眠」）

### 3.6 DriftActions 叠加 drift_extra

```gdscript
static func drift_value(state: GameState) -> float:
    ...  # 原 plundered/memory 派生
    return clampf(派生值 + state.drift_extra, 0.0, DRIFT_MAX)
```

- ②B 献名字「此后心语第一人称模糊化」→ drift_extra +1，跨过 3.0 档位线即漂移观感升档（drift_tier 原逻辑自动反映）
- ⑤B 「我不知道」→ drift 注入同样走此通道

### 3.7 GameManager 集成

```gdscript
signal choice_available(choice_id: StringName, title: String, intro: String, options: Array)
signal choice_resolved(choice_id: StringName, option_id: StringName, result_text: String, option_text: String)

var _pending_choice: StringName = &""   # 当前待处理明选（有则不触发新的——明选=停顿点）

func _process(delta):  # 现有 tick 末尾追加：
    if _pending_choice == &"":
        var cid := ChoiceActions.first_available(_state)
        if cid != &"":
            _pending_choice = cid
            var c := ChoiceLibrary.get_choice(cid)
            choice_available.emit(cid, str(c.get("title","")), str(c.get("intro","")), c.get("options", []))

func resolve_choice(choice_id: StringName, option_id: StringName) -> Dictionary:
    # 校验 _pending_choice == choice_id + ChoiceActions.can_choose → resolve
    # 成功：_pending_choice = &""；choice_resolved.emit(...)；resources_changed.emit()
    # 失败（未到 / 重复）：{"ok": false}
```

- **明选不排队**：一次只弹一个（`_pending_choice` 占用即停发），玩家选完清空、下个 tick 查下一个 available——「明选全开」时逐一出（JSON 数组序 = 优先级）
- **防重复**：`choices_done` 集合语义——resolve 后记入，`available` 永不再含
- `choice_available` 带 `options`（数组由 JSON 结构直接传入 UI，UI 渲染按钮——UI 不重新读 JSON）

### 3.8 UI（明选弹层）

- 新增弹层（PanelContainer，仿 DreamPanel/TotemPanel 模式）：`%ChoicePanel`（visible 默认 false）+ `%ChoiceTitleLabel` + `%ChoiceIntroLabel` + 选项按钮 ×3（动态 `text`/`visible`）+ 差分文本 Label
- 监听 `GameManager.choice_available` → 填充弹层、`visible = true`（**模态停顿**：不需要冻结游戏循环，明选无倒计时，玩家想多久选多久）
- 选项按钮：`option_unlocked` 为 false 的选项灰显（⑤C 领悟门槛）；点击 → `GameManager.resolve_choice` 
- 监听 `choice_resolved` → 差分文本进 `race_event_label`（现有叙事播报位）+ 弹层关闭
- 读档恢复：`_ready` 时若 `_pending_choice` 非空（存档中途退出），重发 `choice_available`（用现有信号兜底模式——同人族唤醒读档播报）

### 3.9 明选 flag（state.choice_flags）

- GameState 增 `choice_flags: Array[StringName]`（序列化+回退）
- 用途：②C「转身离开→冥河层再遇，时机后移」记录 `&"odin_left"`；②A「献根须」记录 `&"odin_root"`；⑤C「我记得我是」记录 `&"theseus_remembered"`（真结局伏笔提前亮起，M6 消费）；③未来「造船/不造」记录 `&"ship_built"`/`&"ship_refused"`（世界之轴前置）
- 本 M 只记录 + JSON `flags` 写入，M6 消费——**flag 命名约定**：`<choice_id 前缀>_<选项语义>`，kebab-case

## 四、数值模型与五卡触发

### 4.1 触发条件（明选全开）与优先级（JSON 数组序）

| 序 | choice_id | 卡 | 触发（全 AND） | 时机意图 |
|---|---|---|---|---|
| 1 | `human_nightmare` | ① 人族噩梦 | `races_awakened: ["human"]` | 成树·第一次明选——人族苏醒即触发 |
| 2 | `odin_sacrifice` | ② 奥丁之祭 | `memory_gte: 30` | 巨树·记忆线（化身觉醒线=记忆 30，M5c） |
| 3 | `norne_past` | ③过去 | `memory_gte: 35` | 巨树·图腾线全开阈（M4 第 5 幅=记忆 35）后，真相之问 |
| 4 | `norne_now` | ③现在 | `memory_gte: 30` + `races_awakened: ["forestfolk"]` | 林地民登场后，灵魂拷问 |
| 5 | `norne_future` | ③未来 | `memory_gte: 30` + `races_awakened: ["stoneborn"]` | 石裔登场后，世界之轴前置 |
| 6 | `dodder` | ④ 菟丝子 | `plundered_gte: {"forestfolk": 1}` | 只在对林地民夺过梦后出现（暗线递进） |
| 7 | `theseus` | ⑤ 忒修斯之树 | `memory_gte: 30` | 巨树·身份之问（C 选项另需 insight≥8） |

> 注：⑤ 与 ② 都挂 memory_gte:30——按数组序 ② 先弹，⑤ 随后（明选逐一出，玩家感知为「成树后接连的停顿点」）。② 在前也符合「记忆线先献祭、后身份质疑」的叙事节拍。

### 4.2 卡片内容与后果数值（spec §13.5 对齐）

**① 人族噩梦**（成树·第一次）——人族集体梦见"那一天"：天裂、光熄。
| 选项 | 文本（按钮） | 后果 | 差分（result_text） |
|---|---|---|---|
| A 采梦 | 「把梦收下」 | memory +3、truth +1（真相线开启）、relation human -2、memory_eff human 0.7（梦产-30%） | 「没有梦的我们，还算人吗。」——有人梦里睁开了眼（哲学僵尸伏笔） |
| B 护梦 | 「让它做完」 | relation human +2、flag `nightmare_protected` | 人族的孩子追着光跑。你们围住了梦。（关系+1 差分由后续说书人线承载） |

**② 奥丁之祭**（巨树·记忆线）——献"你的一部分"换河底完整记忆。
| 选项 | 文本 | 后果 | 差分 |
|---|---|---|---|
| A 献根须 1/3 | 「折断一根根须」 | growth_pct -0.30、truth +2（「第九日」完整记忆）、flag `odin_root` | 断口处，年轮一圈圈翻开。第九日的天空，落进你怀里。 |
| B 献名字 | 「献出名字」 | memory +6、drift +1.0（第一人称模糊化）、flag `odin_name` | 你忽然想不起，自己叫什么。树不需要名字。……可你刚才，差点想起来。 |
| C 转身离开 | 「转身离开」 | flag `odin_left`（冥河层再遇，时机后移） | 记忆沉回河底。它没有挣扎。——就像你曾经见过的那些。 |

**③ 诺恩三抉择**（巨树·拆 3 项，独立触发）
- **过去**（`norne_past`）：「是否揭开旧世界毁灭细节」
  - A 揭开：truth +2（真相大步）、flag `norne_past_revealed` —— 人族噩梦加剧（effects `memory_eff: {"human": 0.7}`；该键幂等——已设 0.7 则保持，不会二次扣减）
  - B 合上：「天裂那天的事，就让它沉在河底。」—— 无真相、无代价（留白）
- **现在**（`norne_now`）：「夺魂救将死的林地民 / 放手归河」（灵魂守恒拷问）
  - A 救：soul `{soul_cost: 2, revive_pop: {forestfolk: 3}, relation: {forestfolk: 1}}`、flag `norne_now_saved`
  - B 放手：soul `{relation: {forestfolk: -1}}`、flag `norne_now_let_go` ——「河底多了一缕。它很轻。」
- **未来**（`norne_future`）：「是否让石裔造离开这片土地的船」
  - A 造：flag `ship_built`（世界之轴前置）——「石裔开始丈量天空。他们说，船要造得能装下所有歌。」
  - B 不造：flag `ship_refused`（四族分裂隐忧）——「锤声停了。有人在夜里，指着海的方向。」

**④ 菟丝子**（巨树·夺梦）——你发现自己在吸林地民的歌。
| 选项 | 文本 | 后果 | 差分 |
|---|---|---|---|
| A 松开 | 「松开」 | faith_pct -0.30、relation forestfolk +3、flag `dodder_released` | 萤光重新亮起。歌之环，接上了。 |
| B 继续 | 「继续吸」 | memory +8、relation forestfolk -3、flag `dodder_kept` | 叶尖挂着半个音。风一吹，就散了。——只剩风声。 |

**⑤ 忒修斯之树**（巨树·身份）——"你换了十七次根须、九次枝干——还是当初那棵树吗？"
| 选项 | 文本 | 门槛 | 后果 | 差分 |
|---|---|---|---|---|
| A 是 | 「是」 | — | 关系不变、flag `theseus_yes` | 人族学者为此争论了三天。（灵魂即身份） |
| B 我不知道 | 「我不知道」 | — | drift +1.0、relation 四族各 +1 | 它们靠得更近了些。真实的你，它们认识。 |
| C 我记得 | 「不是，但我记得我是」 | insight ≥ 8 | insight +2、truth +1、flag `theseus_remembered`（真结局伏笔提前亮起） | 说书人看了你很久。她说：'母树，你正在想起自己。' |

### 4.3 节奏估值声明

② 的 memory +6、④B 的 memory +8（明选单次大额记忆——与 M5d 升级引擎形成"关键选择"手感）；灵魂特耗 2 缕/救 3 人（与复活 1 缕/+10 人刻意构成偷工减料反差：明选救人贵——救的是"将死的"个体）；drift +1.0 注入（≈2 次夺梦的漂移量）——均为节奏估值，待试玩调优（惯例标注，同 M3 §14 注释）。

## 五、测试策略（GdUnit4，headless）

| 套件 | 覆盖 |
|---|---|
| `test_choice_library.gd` | JSON 解析：5 卡（7 条目）加载、必填字段校验、id 唯一、文本非空、坏 JSON 不崩溃 |
| `test_choice_actions.gd` | 触发解释器各条件键（races/memory/faith/growth/insight/relation/plundered/soul）；available 数组序；first_available；can_choose 幂等；option_unlocked（⑤C）；resolve 各 effects 键（memory/faith/growth_pct/faith_pct/relation/insight/truth/drift/memory_eff/soul/flags）；choices_done 防重复 |
| `test_game_state.gd` | 4 新字段（choices_done/truth/drift_extra/race_memory_eff/choice_flags）序列化往返 + 缺省回退 + 损坏防御 |
| `test_race_manager.gd` | race_memory_eff 并入产出（0.7 → 记忆 ×0.7） |
| `test_drift_actions.gd` | drift_extra 叠加（plundered 0 + extra 1 → tier 0；extra 4 → tier 1） |
| `test_game_manager.gd` | 触发信号（人族唤醒→human_nightmare 弹出）；resolve 信号 + 后果落地；pending 占用不重复触发；resolve 失败不发信号 |
| 全量回归 | 既有 201 测试无回归；headless 冒烟 |

## 六、决策记录

1. **JSON 文本外置**（主人拍板 2026-09-01）：改文本只改 `choices.json` 一个文件、不动代码——与项目现有 const Dictionary（Totem/Plunder）拉开，服务文本工作流；Godot 4 原生 JSON 解析 + UTF-8 天然正确（用 write 工具写，杜绝 PowerShell 乱码）。
2. **范围 = 引擎 + ①-⑤ 五卡**（主人拍板）：⑥体验机器（依赖遗迹扩展）与 ⑦终局（M6）后置；七卡依赖全景中五卡依赖已全就绪，一次交付完整可玩明选主线。
3. **明选 = 停顿点**（spec 六章原义）：一次只弹一个、玩家选完才继续；不排队、不设倒计时。`_pending_choice` 占用即停发新明选。
4. **`truth` 新账本**：spec §13.1 真相双揭示（吞噬者即我/环形废墟）与明选③过去「真相+2」都有明确要求，但 GameState 无字段——本 M 补 `truth: int`，M6 终局消费。
5. **`drift_extra` 新账本**：②献名字/⑤B 的漂移注入是明选专属效果，现有 drift 为 plundered/memory 派生值（不可直接改）——补注入位并叠加进 `DriftActions.drift_value`。
6. **`race_memory_eff` 新修正位**：①A「人族失眠梦产-30%」需要人族产出修正系数——并入 RaceManager 公式（缺省 1.0 不破坏旧档）。
7. **明选 flag `choice_flags`**：跨 M 伏笔（odin_left→冥河层再遇、theseus_remembered→真结局、ship_built→世界之轴）统一落账本数组，JSON `flags` 写入，M6 消费；命名 `<choice_id 前缀>_<选项语义>`。
8. **③诺恩拆 3 项 → 3 个独立明选**：spec §13.5「可拆 3 项」原义——过去/现在/未来各自独立触发条件独立弹层，时机由叙事节拍驱动。
9. **明选特耗 vs 通用接口刻意区分**：③现在「救 1 耗 2 缕」不走 SoulActions.revive（1 缕+500 growth→+10 人）——明选救个体更贵、不加 growth，是"关键选择的代价"而非"系统动作"，数值反差即主题。
10. **触发数值对齐既有里程碑阈**：memory 30（M5c 化身觉醒线）/35（M4 图腾第 5 幅线）/夺梦 1 次（M5b 揭示线前）——引擎不发明新阈值，复用已建立的感觉线。

## 七、衔接

- **⑥体验机器 + 隐藏遗迹**：遗迹库 `RelicLibrary` 扩至 9 个（潘多拉/梦想机等）后，⑥卡按 3.3/3.4 结构追加 JSON 条目 + `features/dreams/` 遗迹解锁（trigger 增 `relic_found_gte` 条件键，引擎解释器预留扩展位）——后续遗迹批次
- **⑦终局四路径**（M6）：消费 truth/insight/关系总值/希望 + `theseus_remembered` 真结局伏笔；归还序列状态机
- **说书人故事线 ④⑤⑥**：①B 护梦 → 说书人信任开启（flag `nightmare_protected` 衔接叙事批次）
- **多周目**（M6）：truth/drift_extra/choice_flags 跨周目账目（记忆余烬）

---

## 附录：choices.json 结构示例（①人族噩梦）

```json
{
  "choices": [
    {
      "id": "human_nightmare",
      "title": "人族噩梦",
      "stage_hint": "成树·第一次",
      "intro": "夜里，火塘边的人族一起做了同一个梦。\n梦里天裂开，光熄了。\n有人在梦里喊你的名字。",
      "trigger": { "races_awakened": ["human"] },
      "options": [
        {
          "id": "a",
          "text": "把梦收下",
          "effects": {
            "memory": 3.0,
            "truth": 1,
            "relation": { "human": -2 },
            "memory_eff": { "human": 0.7 },
            "flags": ["human_nightmare_harvested"]
          },
          "result_text": "梦很沉。\n醒来的它们眼神发直。\n——没有梦的我们，还算人吗。"
        },
        {
          "id": "b",
          "text": "让它做完",
          "effects": {
            "relation": { "human": 2 },
            "flags": ["nightmare_protected"]
          },
          "result_text": "你没有动。\n梦里，人族的孩子追着一道光跑。\n你们围住了那个梦，没有碰它。"
        }
      ]
    }
  ]
}
```

> 文风六则示例自查：短句呼吸（每行 2-4 短句）、意象代替说明（「火塘边」「天裂开」不解释）、留白（「还算人吗」句号后停笔）、柔和如风（「梦很沉」而非「痛苦」）、自然词汇（夜/火塘/光/河/土）、人称柔软（树对梦低语，无感叹堆叠）。