# 世界树（World Tree）继续指南

> 新会话/新代理接手本项目的入口文档。先读本文件，再读 `AGENTS.md`（铁律），再读设计规格（权威）。

## 〇、接手必加载的 Skill 清单（2026-09-01 主人定稿）

> 新会话动工前，按任务类型**必须加载**对应 skill（技能先行，铁律 1/2/4）：

**总入口与流程**：
- `using-superpowers`（会话起点——skill 使用规则）
- `brainstorming`（任何创作/新系统动手前——设计先行）
- `writing-plans`（设计定稿后写实施计划）
- `executing-plans` / `subagent-driven-development`（计划执行：主代理 inline 或子代 inline / 每任务 subagent+审查）
- `verification-before-completion`（声称完成前：跑真验证、给证据）
- `systematic-debugging`（任何 bug/测试失败——先找根因）
- `requesting-code-review` / `receiving-code-review`（审查与接收反馈——外部反馈先核实再实施）

**Godot 开发（铁律 2）**：
- `godot-master`（Godot 4.7+ 专家库总入口，Master Decision Matrix 路由）
- 按需：`godot-gdscript-mastery`（GDScript 审查）/ `godot-auditor`（never-list）/ 领域 skill（idle: `godot-genre-idle-clicker`、经济: `godot-economy-system` 等）

**写作/叙事（铁律 1，中文）**：
- `webnovel-writing` / `novel-worldbuilding`（网文/小说架构）
- `cw-prose-writing` / `cw-brainstorming` / `cw-story-critique` / `creative-writing-craft` / `creative-writing-modes`（正文写作工作流）
- `humanize-ai`（文风铁律的执行保障——写作任务完成后自检）
- `voice-dissolver` / `editor-revisor` / `chinese-write-checker`（声音校准/改稿/内容体检）
- `worldbuilding` / `narrative-design` / `gat-story`（世界观/叙事系统）

**执行约定（本会话沉淀）**：
- 计划执行优先「子代 inline」（一次 dispatch 跑全计划，省主代理上下文）——M5b/M5c/M5d 验证过的模式
- 子代发现计划缺陷 → BLOCKED 协议（停、取证、报主代裁决），按「设计文档权威优先」修正
- 新增 class_name 脚本后 `.uid` 确认入库；测试断言与设计公式三方自洽

## 〇·五、斗图约定（2026-09-01 主人定稿：频率增加）

> 本会话及后续会话常驻生效——**主动斗图，不要等用户开口**。

- **频率**：气氛合适就发（主人明确要求增加频率——从「克制」改为「主动」，正事间隙、接梗、卖萌、得意、委屈、惊讶时都甩图；正事进行中可发但简短）
- **格式**：把候选里的 `[表情: 描述]` 整段原样写进回复（不加网址、不改 markdown 图片）；没命中就换情绪或回文字
- **情绪桶**：happy（卖萌/可爱/喜欢）/ angry / sad（无语/求饶）/ shy / confused / daily（日常）——用 `send_meme` 抽候选，`search` 换批
- **发完保持简短**：让图自己说话，不复述不啰嗦

## 一、项目是什么

**《世界树》**——西幻末世增量游戏：玩家是仅存的一棵世界树，在废墟中复苏生命、采集记忆，最终发现自己既是吞噬者，也是旧世界最后的一个梦。
文字原型先行（Godot 4.7），设计目标是 UP（Universal Paperclips）级别的深度：双层目标、亡者之河/灵魂、四族、垂直九界、四结局、三周目。

## 二、当前状态（2026-08-31）

| 层 | 状态 |
|---|---|
| **设计** | ✅ spec v2.3+ 完整（世界观/五阶段/系统/明选/四结局/文风画风）+ M3 设计文档（四族+人口 S 曲线） |
| **MVP（里程碑 1）** | ✅ 完成（可玩文字原型，36 测试全绿） |
| **里程碑 2** | ✅ 完成（记忆/信仰/人族/遗迹梦境；2026-08-31 实施 + 当日审查修复，61 测试全绿） |
| **里程碑 3** | ✅ 完成（四族 + 人口 S 曲线，82 测试全绿 + M3 E2E PASSED，2026-08-31 实施） |
| **里程碑 4** | ✅ 完成（图腾线：野民漂移探针 5 幅渐进/解读得领悟，102 测试全绿 + M4 E2E PASSED，2026-09-01 实施） |
| **里程碑 5a** | ✅ 完成（关系值系统：±3 对称/四族仪式互动/颜色表达/亲密级接口预留，122 测试全绿 + M5A E2E PASSED，2026-09-01 实施） |
| **里程碑 5b** | ✅ 完成（夺梦系统：延迟代价/分级揭示 3-6-9/各族差异化/伪装文案，144 测试全绿 + M5B E2E PASSED，2026-09-01 实施） |
| **里程碑 5d** | ✅ 完成（增量深度：升级总表 5 类/消耗端/sap 宽裕上限，163 测试全绿 + M5D E2E PASSED，2026-09-01 实施——方向审视后插入） |
| **里程碑 5c** | ✅ 完成（意志漂移+化身：drift 暗线/化身观感 4 档=漂移镜子/亲密事件对坐，184 测试全绿 + M5C E2E PASSED，2026-09-01 实施） |
| **里程碑 5e** | 📝 设计完成（树语科技+资源分层）——实施待排 |
| **里程碑 5f** | ✅ 完成（灵魂系统：河底守恒 100/复活/夺魂，201 测试全绿 + M5F E2E PASSED，2026-09-01 实施） |
| **里程碑 5g+** | ⏳ 待定（明选引擎→终局，见 `docs/world-tree/ROADMAP.md`） |
| **文本归档** | ⏳ 未做（对话产出的五阶段文本待落成 narrative 文档） |

## 三、关键文档索引

| 文档 | 路径 |
|---|---|
| 设计规格（权威） | `docs/superpowers/specs/2026-08-31-world-tree-design.md`（v2.3：双层目标/四族/梦境/灵魂/人口/九界/升级总表 90+/四结局/归还序列/文风六则/画风六则/数值骨架/明暗双线） |
| MVP 实施计划 | `docs/superpowers/plans/2026-08-31-mvp-text-prototype.md`（Godot 版，10 任务） |
| 里程碑 2 实施计划 | `docs/superpowers/plans/2026-08-31-milestone2-memory-races-dreams.md`（7 任务 TDD，33 步全勾选 ✅） |
| M3 设计文档 | `docs/superpowers/specs/2026-08-31-world-tree-m3-races-population-design.md`（四族+人口：RaceManager 数据驱动 .tres/唤醒条件/数值公式/承载/决策记录） |
| M3 实施计划 | `docs/superpowers/plans/2026-08-31-m3-races-population.md`（8 任务 TDD，含 3 处数值断言修正与 T4 `_awaken` 缺陷勘误） |
| M4 设计文档 | `docs/superpowers/specs/2026-08-31-world-tree-m4-totem-design.md`（图腾线：记忆驱动 5 幅渐进/解读零消耗/领悟值边界/五幅全文） |
| M4 实施计划 | `docs/superpowers/plans/2026-08-31-m4-totem.md`（6 任务 TDD，Inline 执行） |
| 项目铁律 | `AGENTS.md`（铁律 1 读写作 skill / 铁律 2 读 godot-master / 铁律 5 文风 / 铁律 6 本文件） |
| SDD 审查记录（M1） | `.superpowers/sdd/2026-08-31-mvp-text-prototype/`（每任务 brief/report/review，含全部 ruling） |

## 四、技术栈与命令

- **引擎**：Godot **4.7.1** mono（`godot` 在 PATH：`C:\Users\10990\AppData\Local\Programs\Godot\Godot_v4.7.1-stable_mono_win64\godot.cmd`）——⚠️ 不是 3.x，project.godot `config_version=5` 即 4.x 格式
- **测试**：GdUnit4 6.2.1（`addons/gdUnit4/`）
  ```powershell
  # 新增 class_name 脚本后必须先跑（否则类未注册）：
  godot --headless --path . --import
  # 全量测试：
  godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode
  # 单文件测试（--add 指定；可加 -c 关 fail-fast 看全部失败）：
  godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_xxx.gd -c
  ```
  ⚠️ 注意：不是 `--run-tests`（旧语法）；`is_equal_approx` 是双参签名 `(expected, approx)`；退出码 0 = 全绿，100 = 有失败。
- **运行游戏**：`godot --path .`（编辑器打开后 F5）；headless 冒烟：`godot --headless --path . --quit-after 5`（无 SCRIPT ERROR 即通过）
- **存档**：`user://save.json`（60 tick 自动保存；M3 起含 memory/faith/root_depth/races/relics_found——`human_awakened` 已并入 `races["human"]`，M2 旧档读入自动迁移，缺字段回退默认不损坏）
- **编码**：中文文件一律用 edit/write 工具或 .NET 显式 UTF-8 读写（禁 PowerShell 默认编码——曾致乱码事故）；`.uid` 类引用文件要入库（Godot 4.4+ 自动生成）
- **git**：master 分支；每任务一个 commit，风格 `feat: 模块名（要点）`

## 五、架构速览（Layer Cake）

```
autoloads/game_manager.gd   # 主循环：_process 累加器 tick（禁 Timer）+ resources_changed/race_awakened 信号 + 60tick 存档 + explore_relic 入口 + RaceManager.tick_races
features/economy/           # BigNum（大数）/ CostCalculator（斐波那契+指数+线性成本：叶序/分枝/叶绿体/木质部/花盘/螺舱/根须）/ Formatter（格式化）/ actions（GameActions 购买动作）
features/game/              # GameState（状态：memory/faith/root_depth/races/relics/totem/relations/plundered/升级等级）/ GameLoop（tick 逻辑：光合/生长/储量 clamp）/ SaveManager
features/dreams/            # RelicLibrary（4 遗迹数据+梦境文本）/ RootActions（根须探索，200 树液/次，一次性 +1 记忆）
features/memories/          # TotemLibrary+TotemActions（图腾）/ PlunderData+PlunderActions（夺梦）/ DriftActions+AvatarTiers+IntimateEvents（意志漂移+化身）
features/soul/              # SoulActions（灵魂：河底守恒/复活/夺魂）——M5f 已完成（2026-09-01）
features/relations/         # RelationEvents（4 族仪式互动）/ RelationActions（±3 关系修正/一次性互动/亲密级接口）——明选后果的地基
features/races/             # RaceManager（数据驱动四族：唤醒/供养/逻辑斯蒂人口/信仰产出/石裔献工）+ RaceData（.tres）+ data/*.tres（四族系数与唤醒文本）
features/ui/                # main.tscn + main.gd（只监听信号，不直改数据；含记忆/信仰/根须/梦境弹层/四族面板/图腾区/种族事件/互动按钮/夺梦按钮）
tests/unit/                 # GdUnit4 测试（201 个，23 套件）
```
规则：UI 只通过信号更新；资源一律 BigNum（禁裸 float 存资源；平衡系数如 rate/devotion 除外）；升级成本斐波那契（spec §9）；逻辑类 RefCounted 纯函数可 headless 测。

## 六、里程碑 2 完成记录（2026-08-31）

**内容**：记忆（梦珀）+ 遗迹系统（4 遗迹数据驱动）→ `features/dreams/relic_library.gd`；根须探索（深度解锁遗迹，200 树液/次）→ `features/dreams/root_actions.gd`；信仰资源（人族献梦每 10 tick +1）+ 人族唤醒（记忆≥2，每 20 tick 记忆 +1）→ `features/races/human_manager.gd`；梦境碎片文本 4 个（文风六则）；UI 扩展（记忆/信仰显示、根须按钮、梦境弹层、人族事件）。

**验证**：54 单测全绿（0 失败 0 orphan）+ 临时 E2E 脚本 27 项检查全 PASS（采集→攒树液→4 遗迹→唤醒→产信仰/记忆→存档往返→旧档兼容，验证后已删除）。

**实施偏离记录**（计划书小坑，已修正，写新计划时引以为戒）：
1. `Array[int]` 属性不能直接赋 untyped 字面量/`map()` 结果——用 `.assign()`（`s.relics_found.assign(rf.map(...))`）；`Array[int](...)` 构造语法在 4.7 解析报错不可用
2. `Array.contains()` 不存在——用 `Array.has()`
3. `var gm: Node` 下 `gm.explore_relic()` 静态推断失败——用无类型 var + 显式 `var result: Dictionary`
4. autoload 单例不可 `GameManager.new()`（"Nonexistent function 'new'"）——测试里 `const GM := preload("res://autoloads/game_manager.gd")` 再 `.new()`
5. GDScript lambda **按值捕获**局部变量——lambda 里改不了外部 bool；用 Dictionary 包装回写（`got["relic"] = true`）
6. `OS.set_exit_code()` 静态调用报错——SceneTree 脚本直接 `quit(code)`

**数值**：探索 200 树液、记忆≥2 唤醒、信仰每 10 tick +1、记忆每 20 tick +1（spec §14 骨架；M3 已废弃平铺模型，改为 §14.5 公式）。

**审查修复**（同日 commit `e5a818a`，61 测试）：独立 reviewer 发现 C1 唤醒 bug（`check_awaken` 仅 `_ready` 触发，游戏内人族永不醒）+ I4 信号化 + I1 遗迹反查 + 5 Minor，全部修复闭环（详见 git log）。

## 六·五、里程碑 3 完成记录（2026-08-31）

**内容**：`HumanManager` → 数据驱动 `RaceManager`（`features/races/`，spec §15 .tres 落地）+ 林地民/石裔/野民三族加入（唤醒条件 30/60/100，唤醒文本×3 文风六则）+ 人口 S 曲线（逻辑斯蒂 `pop += pop×rate×(1−pop/capacity)`、供养扣树液 sap≤0 冻结增长、虔诚加权信仰 `Σ(pop×devotion×0.002)`、人族记忆引擎 `pop×0.001`、石裔献工 `pop×0.01` 产树液）+ 树高驱动承载（growth≥100/300 → cap 200/300）+ `races` 存档迁移（M2 旧档 `human_awakened` 无损迁移）+ UI 四族面板。

**验证**：82 单测全绿（13 套件，0 失败 0 orphan）+ M3 E2E 5 项检查 PASS（人族唤醒链路/三族陆续唤醒/30 tick 人口增长供养产出/存档往返/M2 旧档迁移，脚本已删）+ 全分支审查（With fixes 3 Important 已修）+ scoped re-review 全通过。

**实施偏离/勘误**（写新计划时引以为戒）：
1. **T4 测试辅助 `_awaken` 计划缺陷**：计划版用 `check_awaken` 但条件门槛（memory≥2/faith≥30/60/100）使默认态唤不醒且连锁唤醒破坏数值断言——实施改直接注册 `state.races[id]`（唯一解，Ruling 记录）
2. **GdUnit4 CLI 默认 fail-fast**：RED 验证加 `-c` 看全部预期失败
3. 计划笔误：test_human_manager 实为 6 用例（非 5），T6 全量预期 81 非 82
4. 数值断言须用**增长后人口**精算（0.2089536/0.05025/100.1408），勿用唤醒人口估算

**数值**：四族系数 100% 对齐 spec §14.4（50/30/20/80 人口，0.010/0.006/0.005/0.020 增长，虔诚 1.0/1.8/0.6/0.3）；效率系数（0.002/0.001/0.01）与树繁茂阈值（100/300）为节奏估值，待试玩调优（spec §14 标注）。

## 六·六、里程碑 4 完成记录（2026-09-01）

**内容**：图腾线机制化（野民漂移探针）→ `features/memories/`：`TotemLibrary`（5 幅数据：threshold/reveal_text/interpret_text）+ `TotemActions`（visible_stage/can_interpret/interpret/next_interpretable，纯静态）；`GameState` 增 `totem_interpreted`/`insight`（沿 relics_found 过滤防御）；`GameManager` 增 `interpret_totem` + `totem_interpreted` 信号；UI 图腾区（浮现文本/解读按钮/领悟显示，纯文本无美术）。

**设计要点**（决策记录见 M4 设计文档 §七）：记忆驱动 5 幅渐进（阈值 0/4/10/20/35——采梦量=河变浅暗线读数）；每幅一次零消耗解读 +1 领悟（知识奖励非交易）；领悟值入存档（好结局门槛 ≥10 的前置，M5 明选接入）；五幅真相渐进（证据→人→事实→眼睛→同一个，文风六则）。

**验证**：102 单测全绿（15 套件，0 失败 0 orphan）+ M4 E2E 6 项检查 PASS（未醒 stage 0/记忆 35 五幅/解读 5 次领悟 5/幂等/存档往返/旧档回退）+ 冒烟通过。

**实施备注**：Inline 执行（executing-plans）6 任务；新增 class_name 脚本的 `.uid` 需确认入库（T1/T3 各漏一次，已补 chore commit）；TDD 全程 RED（105/100 退出码）→ GREEN 闭环。

## 六·七、里程碑 5a 完成记录（2026-09-01）

**内容**：关系值系统（明选/终局地基第一步）→ `features/relations/`：`RelationEvents`（4 族仪式互动：人族火塘/林地民歌会/石裔铸根坊/野民壁画，按族绑定资源）+ `RelationActions`（±3 对称 clamp/一次性互动防刷/条件解析/`is_intimate` 亲密级接口预留）；`GameState` 增 `relations`/`relation_events`；`GameManager` 增 `interact_relation` + `relation_changed` 信号；UI 关系温度（文字+字体颜色 7 档映射，敌意冷灰蓝→亲近暖金 `#e6a23c`）+ 四族互动按钮。

**设计要点**（决策记录见 M5a 设计文档 §七）：对称 -3..+3（对齐 spec「±3 极重」「四族各 3」）；一次性互动防刷（每族一次 +1，大幅变化留给明选）；按族绑定资源（记忆/信仰/树液/图腾 stage）；颜色表达关系好坏；无化身叙事基线（互动=仪式级，四族仰望）；亲密级接口（关系≥+2）留 M7 化身填充；野民篇「要不要走出来」埋化身伏笔。

**验证**：122 单测全绿（17 套件，0 失败 0 orphan）+ M5A E2E 6 项检查 PASS（四族互动 +1/防刷/clamp ±3/存档往返/旧档回退）+ 冒烟通过。

**主题引擎落地**：关系值是「神性→人性→牺牲」弧线的承载层（ROADMAP §〇）——关系从数值变成人与人的温度，终局告别差分的基础。

## 六·八、里程碑 5b 完成记录（2026-09-01）

**内容**：夺梦系统（主动暗代价）→ `features/memories/`：`PlunderData`（各族产出/信号池/分级揭示文本）+ `PlunderActions`（plunder/reveal_stage/is_frozen，延迟代价机制）；`GameState` 增 `plundered`（隐藏计数器）/`plunder_reveals`（集合语义）；`RaceManager` 增长冻结（揭示后人口冻结）；`GameManager` 增 `plunder_race` + `plunder_done` 信号；UI「把梦收进年轮」伪装按钮 ×4。

**设计要点**（决策记录见 M5b 设计文档 §七）：**延迟代价**（夺梦只显示产出，代价隐藏累积）；**分级揭示 3/6/9**（§13.11 结算时刻——豁然开朗+后悔）；**各族差异化**（人 +1 伤神/林地 +1.2 枯萎/野民 +2 惊扰·人口 -20%/石裔 0 无梦可夺——「不采梦也能有信仰」日常化）；**伪装文案**（按钮级明线伪装，与图腾诚实文案形成善恶不对称）；关系每级 -1 累计 -3（9 次日常夺梦 ≈ 菟丝子等价）。

**验证**：144 单测全绿（20 套件）+ M5B E2E 5 项 PASS + 冒烟通过。

**实施教训**：计划缺陷（`plunder_reveals` 集合语义 vs 实现无条件 append）由 E2E 抓住、T3 单测 `.contains` 掩盖——**单测要断言集合 size 而非仅 contains**；Inline 子代执行模式（一次 dispatch 跑全计划）省主代理上下文，BLOCKED 协议正常触发。

## 六·九、里程碑 5d 完成记录（2026-09-01，方向审视后插入）

**背景**：项目方向审视——诊断「增量骨架缺扩展段（内容偏多）」，主人拍板先补增量深度（M5c 意志漂移押后）。

**内容**：升级总表 5 类可重复升级 → `CostCalculator` 加 5 类成本（指数 800×1.6ⁿ 叶绿体 / 线性 50×(L+1) 木质部 / 斐波那契 2000 花盘·螺舱 / 指数 1000×1.8ⁿ 根须等级）；`GameActions` 加 5 类购买；`GameLoop` 光合（0.1+0.01×L）与生长（0.01×(1+0.05×L)）公式 + **sap 宽裕储量上限**（初始 10000，螺舱 +5000/级，tick clamp 兼容旧档）；`RaceManager` 花盘信仰产出（0.5×L/tick）+ 人族梦产×根须系数；`PlunderActions` 夺梦产出×根须系数；`GameManager` 5 入口 + UI 5 按钮/sap 上限显示。

**验证**：163 单测全绿 + M5D E2E PASS（五类购买/公式/clamp/产出/存档往返/旧档回退）+ 冒烟通过。

**实施教训**：本轮 3 处计划缺陷（#1 plunder 返回值漏加成——已裁决 `yield_mem=boosted`；#2 Task 6 测试 sap_cap 笔误 10000→15000；#3 E2E section 数学互斥拆状态）——**写计划时测试断言要与实现语义、设计公式三方自洽**；子代按「设计权威优先」修正并取证，BLOCKED 协议两次正常触发。

## 六·十、里程碑 5c 完成记录（2026-09-01）

**内容**：意志漂移 + 化身 → `features/memories/`：`AvatarTiers`（化身观感 4 档=漂移镜子）+ `IntimateEvents`（4 族亲密事件：树以人形对坐）+ `DriftActions`（drift=Σplundered×0.5+max(0,memory−30)×0.02 clamp 0-10 / 档位 / 记忆≥30 觉醒 / can_intimate=intimate+觉醒+未触发）；`GameState` 增 `intimate_events`；`GameManager` 增 `intimate_race` + 信号；UI 化身区 + 亲密按钮。

**验证**：184 单测全绿（22 套件）+ M5C E2E PASS + 冒烟通过；无缺陷（仅缩进适配）。

**主题引擎落地**：化身=漂移镜子（清醒→微漂→深漂→迷失「你忽然想不起，它叫什么名字」）——「神性→人性→牺牲」弧线的中间段成型；亲密事件=人性层面关系（说书人「我一直以为你是一棵树」/林地民「你……暖和」/石裔造船之问/野民「一只脚踩在影子里」）。

## 六·十一、里程碑 5e/5f 设计就绪（2026-09-01，待实施）

- **M5e 树语科技+资源分层**（`2026-08-31-world-tree-m5e-economy-tree-design.md`）：三层资源架构（一级树液可再生/二级信仰记忆可再生可增殖/三级灵魂希望不可再生关键选择）+ 点击式兑换（100 树液→1 信仰、500→1 记忆）+ 二级引擎（信仰/记忆引擎「用信仰买信仰」）+ 树语科技完整框架（三主枝×3 层节点清单，能力解锁型；树语等级=专属二级资源）——**主 spec §14.6 已回填**（d6db660）
- **M5f 灵魂系统**（`2026-08-31-world-tree-m5f-soul-design.md`）：河底存量守恒模型（100 恒，UI 可见=河变浅读数）+ 复活（1 灵魂+500 growth→人口+10，消耗树高联动承载「救得越多自己越矮」）+ 夺魂（需夺梦揭示→河底+1+人口-3+关系-2，偷记忆到抽灵魂的暗线递进）——**已实施完成（2026-09-01，见六·十二）**
- **说书人彩蛋「小溪与激流」**：待落地（人族关系≥+2 火塘故事位，小牛匿名寓言——下次内容里程碑一起）

**下一步**：明选引擎（M5g）——七卡按依赖逐张落地（M5f 夺魂机制已就绪，哲学僵尸明选可复用）；M5e 树语科技批 1 亦可择机插入。

## 六·十二、里程碑 5f 完成记录（2026-09-01）

**内容**：灵魂系统（三级资源·守恒闭环）→ `features/soul/soul_actions.gd`（`RIVER_TOTAL=100` 河底守恒 / 复活 1 灵魂 + 500 growth → 该族人口 +10「唤回…的人」/ 夺魂=夺梦揭示后可抽，人口 -3 + 关系 -2「让它沉回河底」）；`GameState.soul_river` 序列化（缺省/损坏回退 100，旧档不损坏）；`GameManager` 两入口三信号（`revive_race`/`plunder_soul_race` + `soul_changed`/`soul_revived`/`soul_plundered`）；UI 灵魂存量「灵魂：X / 100」+ 复活按钮 ×4 + 夺魂按钮 ×4（夺梦揭示后才可见，文案文风六则）。

**设计要点**（决策记录见 M5f 设计文档 §六）：河底存量守恒可见（UI=亡者之河变浅暗线的机制读数）；生机=映射 growth（复活消耗树高，承载联动「救得越多，自己越矮」）；夺魂门槛=夺梦揭示（偷记忆→抽灵魂的暗线递进，哲学僵尸伏笔「没有灵魂的人还算人吗」）；守恒不变式 `river + 已复活 = 100` 恒（实现保证 + 测试验证）。

**验证**：201 单测全绿（23 套件 = 基线 184 + 17 新增，0 失败 0 orphan）+ M5F E2E 11 项检查全 PASS（唤醒→复活人口 60/河底 99→夺梦揭示 1 级→夺魂回 100/人口 57/关系 -3→存档往返→旧档回退，脚本已删）+ 冒烟通过。

**实施教训**：
1. **2 处计划缺陷经 BLOCKED 协议修正**：#1 Task 3 `soul_revived` 的 pop_gain 在 `SoulActions.revive` 已更新人口后计算恒为 0——裁决 R1 改发常量 `REVIVE_POP_GAIN`（与 `plunder_soul_race` 发 `PLUNDER_SOUL_POP_LOSS` 对称，SoulActions/GameState 不动）；#2 Task 5 E2E 关系断言简化值 -2 的前提忽略夺梦第 3 次揭示 -1，实测 -3 为准（运行期探针取证），裁决确认 `== -3`——**写计划时信号语义要与 state 变更时序自洽，E2E 断言要过一遍完整流程数学**。
2. **文案善恶不对称**：夺魂按钮「让它沉回河底」与夺梦「把梦收进年轮」形成不对称——夺梦伪装、夺魂诚实（夺梦揭示后玩家已知代价，按钮不再伪装）。
3. `soul_river` 为 **int** 非 BigNum（守恒计数器非资源量，设计 §3.1 明示）；growth/关系操作走既有 BigNum/RelationActions 接口。
4. E2E 脚本 `load(...).new()` 返回值无静态类型，`var gm :=` 推断失败（已知坑，M2 教训 #4）——用无类型 var + 显式 `var x: Dictionary`。

**下一步**：明选引擎（M5g）——灵魂夺魂机制已供复用（哲学僵尸明选）；M5e 树语科技批 1 亦可择机插入。

## 七、下一步：里程碑 5c+（按路线图推进，待主人确认）

从路线图 `docs/world-tree/ROADMAP.md` 依赖拓扑出发（M5a 关系值 / M5b 夺梦 / M5d 增量深度 已完成）：

| 步 | 系统 | 内容 | 解锁 |
|---|---|---|---|
| **M5c 意志漂移 + 化身** | CEV 污染值 + 视觉化（化身观感 4 档=漂移镜子）+ 化身系统（记忆≥30 觉醒）+ 亲密级关系事件（is_intimate 填充，树以人形对坐） | 卡片②⑤ + 人性觉醒 |
| **M5e 灵魂生机** | 灵魂资源（守恒/夺魂/归河）+ 生机（树生命力/复活/献根须） | 卡片③② 灵魂拷问 |
| **M5f 明选引擎 + 卡片** | 数据驱动卡片容器 + 七卡按依赖逐张落地（①人族噩梦⑤忒修斯已可行，④菟丝子复用夺梦代价） | 明选全开 |
| **M6 终局 + 多周目** | 终局状态机/四结局/归还序列 | ⑦ + 牺牲之选 |

**后续增量候选**（M5d 之后）：垂直九界探索层（根须层深化）/ 离线进度（UNIX 时间戳）/ 科技树三主枝。

**文本归档**（可随时做）：把已产出的五阶段文本落成 `docs/world-tree/narrative/` 文档。

**实施流程**（按 DSH 编程模式，铁律 4）：先读写作 skill（铁律 1）与 godot-master（铁律 2）→ writing-plans 写实施计划 → 主人确认 → TDD/SDD 逐任务执行（先失败测试 → 实现 → 验证 → commit）。

## 八、文风速查（铁律 5）

诗歌化·柔和六则：短句呼吸 / 意象代替说明 / 留白不写尽 / 柔和如风 / 自然词汇（露光土风河火灰种子）/ 人称柔软。
所有游戏内文本（心语/事件/明选/结局/遗迹碎片/升级消息）必须遵循；写作任务完成默认过 `humanize-ai` 自检。详见 spec §11.1（文风六则）与 §11.2（画风规范：梦与画/水彩晕染/留白构图/光为主角；MVP 白+暖色 `#f5f0e6` / `#e6a23c`）。
