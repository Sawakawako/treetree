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

## 二、当前状态（2026-09-05）

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
| **里程碑 5e** | ✅ 完成（树语科技+资源分层：三层资源/点击式兑换/二级引擎/生命之语 Lv1-2 + 11 节点含聚落之心，302 测试全绿 + M5E E2E 14 项 PASS，2026-09-01 实施） |
| **里程碑 5f** | ✅ 完成（灵魂系统：河底守恒 100/复活/夺魂，201 测试全绿 + M5F E2E PASSED，2026-09-01 实施） |
| **里程碑 5g** | ✅ 完成（明选引擎+五卡：ChoiceLibrary/ChoiceActions/choices.json 文本外置/GameState 五账本/GameManager 停顿点明选/UI 弹层，245 测试全绿 + M5G E2E 29 项 PASS，2026-09-01 实施） |
| **里程碑 5d2** | ✅ 完成（增量缺口补齐：嫩叶教学链 3 级/深根梦/风语膜一次性/四族设施 4 个，265 测试全绿 + M5D2 E2E 20 项 PASS，2026-09-01 实施） |
| **里程碑 5h** | ✅ 完成（M5 封板：半点制迁移/遗迹 5-9/体验机器/说书人/记忆之语/离线进度/UI 归档，366 测试全绿 + 66 E2E，2026-09-05 封板） |
| **里程碑 6（M6）** | ✅ 完成（终局+多周目+真结局：EndingStateMachine 四结局判定/可恢复归还序列 7 步×3 周目差分/周目切换 new_run_preserved/二周目六事件（石裔3+野民3）/三周目 RunBoost 快进/明选⑦世界之轴卡/UI 终局链，437 测试全绿 + 37 套件 + M6 E2E 21 项 PASS，2026-09-06 封板并完成首轮 Code Review 修复） |
| **里程碑 6-D（M6-D）** | ✅ 完成（冠/干/根三域九界 + 3/6/9 世界之语 + 五奇迹 + 世界之轴新门槛 + 低保真 UI + 平衡回归；40 套件 / 486 测试全绿，首轮九响确定性基准 27:13，2026-09-06 封板） |
| **文本归档** | ✅ 已做（narrative/ 01-11 全归档：遗迹/图腾/夺梦/唤醒/关系(含二周目6事件)/亲密/化身/明选/UI 播报/说书人/归还序列） |

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
| M5h 收尾设计 | `docs/superpowers/specs/2026-09-05-world-tree-m5h-content-completion-design.md`（关系/遗迹/体验机器/说书人/领悟/离线规则冻结） |
| M5 收尾实施计划 | `docs/superpowers/plans/2026-09-05-m5-completion.md`（T0—T8，T0 决策已冻结） |
| M6 主设计文档 | `docs/superpowers/specs/2026-09-05-world-tree-m6-ending-multirun-design.md`（终局+多周目+真结局：终局触发里程碑门/四结局判定/归还序列周目差分/周目门控 9→12/真结局循环终止/决策记录） |
| M6 实施计划 | `docs/superpowers/plans/2026-09-05-m6-ending-multirun.md`（11 任务 TDD：GameState 周目/EndingStateMachine/ReturnSequence/六事件/world_axis 卡/restart_run/RunBoost/UI/封板） |
| M6-D 设计文档 | `docs/superpowers/specs/2026-09-06-world-tree-m6d-nine-realms-world-language-miracles-design.md`（九界连接/世界之语/五奇迹/终局衔接/UI/验证） |
| M6-D 实施计划 | `docs/superpowers/plans/2026-09-06-m6d-nine-realms-world-language-miracles.md`（T1—T6，已完成） |
| 平衡验证 | `docs/world-tree/BALANCE_PLAN.md`（确定性经营档、25—45 分钟守线、五条纸面路线、真人试玩模板） |
| 项目铁律 | `AGENTS.md`（铁律 1 读写作 skill / 铁律 2 读 godot-master / 铁律 5 文风 / 铁律 6 本文件） |
| SDD 审查记录（M1） | `.superpowers/sdd/2026-08-31-mvp-text-prototype/`（每任务 brief/report/review，含全部 ruling） |

## 四、技术栈与命令

- **引擎**：Godot **4.7.1** mono；本机已验证控制台程序：`D:\GodotEngine\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe`——⚠️ 不是 3.x，project.godot `config_version=5` 即 4.x 格式
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
- **git**：main 分支；每任务一个 commit，风格 `feat: 模块名（要点）`

## 五、架构速览（Layer Cake）

```
autoloads/game_manager.gd   # 主循环：_process 累加器 tick（禁 Timer）+ resources_changed/race_awakened 信号 + 60tick 存档 + explore_relic 入口 + RaceManager.tick_races
features/economy/           # BigNum（大数）/ CostCalculator（斐波那契+指数+线性成本：叶序/分枝/叶绿体/木质部/花盘/螺舱/根须）/ Formatter（格式化）/ actions（GameActions 购买动作）
features/game/              # GameState（状态：memory/faith/root_depth/races/relics/totem/relations/plundered/升级等级）/ GameLoop（tick 逻辑：光合/生长/储量 clamp）/ SaveManager
features/dreams/            # RelicLibrary（9 遗迹数据+梦境文本，M5h 扩）/ RootActions（根须探索，200 树液/次，一次性 +1 记忆）
features/memories/          # TotemLibrary+TotemActions（图腾）/ PlunderData+PlunderActions（夺梦）/ DriftActions+AvatarTiers+IntimateEvents（意志漂移+化身）
features/soul/              # SoulActions（灵魂：河底守恒/复活/夺魂）——M5f 已完成（2026-09-01）
features/relations/         # RelationEvents（4 族仪式互动 + EXTRA_EVENTS 二周目 6 事件，run_gte 门控）/ RelationActions（±3 关系修正/一次性互动/亲密级接口）——明选后果的地基
features/races/             # RaceManager（数据驱动四族：唤醒/供养/逻辑斯蒂人口/信仰产出/石裔献工）+ RaceData（.tres）+ data/*.tres（四族系数与唤醒文本）
features/choices/           # ChoiceLibrary/ChoiceActions + data/choices.json（M5g 明选①-⑤ + M5h ⑥体验机器 + M6 ⑦世界之轴，文本外置）
features/narrative/         # StoryLibrary/StoryActions（说书人主线④-⑥ + 彩蛋）
features/lingua/            # LinguaData/LinguaActions（树语：生命之语/记忆之语 Lv1 + 13 节点，能力解锁）
features/ending/            # EndingStateMachine（世界之轴成型/四结局判定/希望结算）/ ReturnSequence（归还 7 步×3 周目差分）/ RunBoost（三周目浓缩快进）——M6（2026-09-06）
features/ui/                # main.tscn + main.gd（只监听信号，不直改数据；含记忆/信仰/根须/梦境弹层/四族面板/图腾区/种族事件/互动按钮/夺梦按钮/世界之轴终局链）
tests/unit/                 # GdUnit4 当前实测：437 测试，37 套件（M6 首轮 Code Review 修复后；M5 基线 366/34）
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

**设计要点**（决策记录见 M5a 设计文档 §七）：对称 -3..+3；2026-09-01 完工时仪式互动为每族 +1，M5h 半点制定稿要求 T1 迁移为 +0.5；按族绑定资源（记忆/信仰/树液/图腾 stage）；颜色表达关系好坏；无化身叙事基线（互动=仪式级，四族仰望）；亲密级接口（关系≥+2）已由 M5c 化身填充；野民篇「要不要走出来」埋化身伏笔。

**验证**：122 单测全绿（17 套件，0 失败 0 orphan）+ M5A E2E 6 项检查 PASS（四族互动 +1/防刷/clamp ±3/存档往返/旧档回退）+ 冒烟通过。

**主题引擎落地**：关系值是「神性→人性→牺牲」弧线的承载层（ROADMAP §〇）——关系从数值变成人与人的温度，终局告别差分的基础。

## 六·八、里程碑 5b 完成记录（2026-09-01）

**内容**：夺梦系统（主动暗代价）→ `features/memories/`：`PlunderData`（各族产出/信号池/分级揭示文本）+ `PlunderActions`（plunder/reveal_stage/is_frozen，延迟代价机制）；`GameState` 增 `plundered`（隐藏计数器）/`plunder_reveals`（集合语义）；`RaceManager` 增长冻结（揭示后人口冻结）；`GameManager` 增 `plunder_race` + `plunder_done` 信号；UI「把梦收进年轮」伪装按钮 ×4。

**设计要点**（决策记录见 M5b 设计文档 §七）：**延迟代价**（夺梦只显示产出，代价隐藏累积）；**分级揭示 3/6/9**（§13.11 结算时刻——豁然开朗+后悔）；**各族差异化**（人 +1 伤神/林地 +1.2 枯萎/野民 +2 惊扰·人口 -20%/石裔 0 无梦可夺——「不采梦也能有信仰」日常化）；**伪装文案**（按钮级明线伪装，与图腾诚实文案形成善恶不对称）。2026-09-01 完工时揭示代价为每级 -1、累计 -3；M5h T1 将迁移为每级 -0.5、累计 -1.5。

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

- **M5e 树语科技+资源分层**（`2026-08-31-world-tree-m5e-economy-tree-design.md`）：三层资源架构（一级树液可再生/二级信仰记忆可再生可增殖/三级灵魂希望不可再生关键选择）+ 点击式兑换（100 树液→1 信仰、500→1 记忆）+ 二级引擎（信仰/记忆引擎「用信仰买信仰」）+ 树语科技完整框架（三主枝×3 层节点清单，能力解锁型；树语等级=专属二级资源）——**主 spec §14.6 已回填**（d6db660）**已实施完成（2026-09-01，见六·十五）**
- **M5f 灵魂系统**（`2026-08-31-world-tree-m5f-soul-design.md`）：河底存量守恒模型（100 恒，UI 可见=河变浅读数）+ 复活（1 灵魂+500 growth→人口+10，消耗树高联动承载「救得越多自己越矮」）+ 夺魂（需夺梦揭示→河底+1+人口-3；完工时关系-2，M5h T1 将迁移为关系-1）——**已实施完成（2026-09-01，见六·十二）**
- **说书人彩蛋「小溪与激流」**：待落地（人族关系≥+2 火塘故事位，小牛匿名寓言——下次内容里程碑一起）

**下一步**：明选引擎（M5g）——七卡按依赖逐张落地（M5f 夺魂机制已就绪，哲学僵尸明选可复用）；M5e 树语科技批 1 亦可择机插入。

## 六·十二、里程碑 5f 完成记录（2026-09-01）

**内容**：灵魂系统（三级资源·守恒闭环）→ `features/soul/soul_actions.gd`（`RIVER_TOTAL=100` 河底守恒 / 复活 1 灵魂 + 500 growth → 该族人口 +10「唤回…的人」/ 夺魂=夺梦揭示后可抽，人口 -3 + 关系 -2「让它沉回河底」）；`GameState.soul_river` 序列化（缺省/损坏回退 100，旧档不损坏）；`GameManager` 两入口三信号（`revive_race`/`plunder_soul_race` + `soul_changed`/`soul_revived`/`soul_plundered`）；UI 灵魂存量「灵魂：X / 100」+ 复活按钮 ×4 + 夺魂按钮 ×4（夺梦揭示后才可见，文案文风六则）。以上为 2026-09-01 完工快照；M5h T1 将关系代价迁移为 -1。

**设计要点**（决策记录见 M5f 设计文档 §六）：河底存量守恒可见（UI=亡者之河变浅暗线的机制读数）；生机=映射 growth（复活消耗树高，承载联动「救得越多，自己越矮」）；夺魂门槛=夺梦揭示（偷记忆→抽灵魂的暗线递进，哲学僵尸伏笔「没有灵魂的人还算人吗」）；守恒不变式 `river + 已复活 = 100` 恒（实现保证 + 测试验证）。

**验证**：201 单测全绿（23 套件 = 基线 184 + 17 新增，0 失败 0 orphan）+ M5F E2E 11 项检查全 PASS（唤醒→复活人口 60/河底 99→夺梦揭示 1 级→夺魂回 100/人口 57/关系 -3→存档往返→旧档回退，脚本已删）+ 冒烟通过。

**实施教训**：
1. **2 处计划缺陷经 BLOCKED 协议修正**：#1 Task 3 `soul_revived` 的 pop_gain 在 `SoulActions.revive` 已更新人口后计算恒为 0——裁决 R1 改发常量 `REVIVE_POP_GAIN`（与 `plunder_soul_race` 发 `PLUNDER_SOUL_POP_LOSS` 对称，SoulActions/GameState 不动）；#2 Task 5 E2E 关系断言简化值 -2 的前提忽略夺梦第 3 次揭示 -1，实测 -3 为准（运行期探针取证），裁决确认 `== -3`——**写计划时信号语义要与 state 变更时序自洽，E2E 断言要过一遍完整流程数学**。
2. **文案善恶不对称**：夺魂按钮「让它沉回河底」与夺梦「把梦收进年轮」形成不对称——夺梦伪装、夺魂诚实（夺梦揭示后玩家已知代价，按钮不再伪装）。
3. `soul_river` 为 **int** 非 BigNum（守恒计数器非资源量，设计 §3.1 明示）；growth/关系操作走既有 BigNum/RelationActions 接口。
4. E2E 脚本 `load(...).new()` 返回值无静态类型，`var gm :=` 推断失败（已知坑，M2 教训 #4）——用无类型 var + 显式 `var x: Dictionary`。

**下一步**：明选引擎（M5g）——灵魂夺魂机制已供复用（哲学僵尸明选）；M5e 树语科技批 1 亦可择机插入。

## 六·十三、里程碑 5g 完成记录（2026-09-01）

**内容**：明选引擎 + 五卡 → `features/choices/`：`ChoiceLibrary`（读 `data/choices.json`，静态缓存+结构校验）、`ChoiceActions`（触发解释器 9 条件键全支持/available 数组序/can_choose/option_unlocked/resolve 后果执行 effects 全键）、`choices.json`（★ 五卡七条目全文文本外置：①人族噩梦 ②奥丁之祭 ③诺恩三抉择×3 ④菟丝子 ⑤忒修斯，C 选项 unlock `insight_gte:8`）；`GameState` 五账本（`choices_done`/`truth`/`drift_extra`/`race_memory_eff`/`choice_flags`，全部序列化+缺省/损坏回退，旧档不损坏）；`RaceManager` 人族梦产×`race_memory_eff` 系数（缺省 1.0）；`DriftActions.drift_value` 叠加 `drift_extra` 后 clamp 0-10；`GameManager` 明选检测（`_pending_choice` 占用=停顿点/一次只弹一个）+ 双信号（`choice_available`/`choice_resolved`）+ `resolve_choice` 入口；UI 明选弹层（intro/选项按钮×3/门槛灰显/差分播报进 `race_event_label`）。

**设计要点**（决策记录见 M5g 设计文档 §六）：JSON 文本外置（改文本只改 choices.json 一个文件，服务文本工作流）；明选=停顿点（无倒计时，`_pending_choice` 占用即停发新明选，选完清空下 tick 查下一个，JSON 数组序=优先级）；`truth`/`drift_extra`/`race_memory_eff`/`choice_flags` 四新账本供 M6 终局消费；flag 命名约定 `<choice_id 前缀>_<选项语义>` 落定（如 `ship_built`/`theseus_remembered`/`odin_left`）；明选特耗 vs 通用接口刻意区分（③现在「救 1 耗 2 缕」不走 SoulActions.revive——明选救个体更贵）。

**验证**：245 单测全绿（25 套件 = 基线 201 + 44 新增：T1 4 + T2 7 + T3 13 + T4 10 + T5 5 + T6 5，0 失败 0 orphan）+ M5G E2E 29 项检查全 PASS（人族醒→五卡逐一弹出→resolve 全链路→防重复→存档往返→旧档回退，脚本已删）+ 冒烟通过。

**实施教训**：
1. **2 处计划缺陷经 BLOCKED 协议裁决**：#1 Task 5 种族梦产断言未用增长后人口（计划 0.05/0.035，实跑 0.05025/0.035175——tick 先供养后增长再产出）——裁决改断言为增长后精确值（与 test_memory_production_human_only 惯例一致，教训 #4 再犯）；#2 Task 6 pending 测试 `count += 1` 撞 lambda 值捕获（外部恒 0）——裁决按既有惯例改 Dictionary 包装回写。
2. **E2E 类型标注**：临时 E2E 脚本 `var m0 := gm.get_state().memory.to_value()` 之类链式 `:=` 推断失败（gm 无类型，M2 教训 #4 再犯）——显式 `var x: float = ...`/`var s: GameState = ...` 解决。
3. **`--add` 统计口径**：GdUnitCmdTool 带 `--add res://tests/unit/test_xxx.gd` 时套件统计存在双重计数（如 238 vs 全量 212）——以全量（无 `--add`）为权威口径。
4. **.uid 入库**：新增 class_name 脚本（choice_library/choice_actions）与测试文件 .uid 均应显式入库（Task 2/3 各补一次 amend）。
5. **文案善恶不对称延续**：①A 采梦「把梦收下」与 ④B 菟丝子「继续」延续夺梦伪装诚实对照；flag 全文以 choices.json 为准（设计 4.2 与附录不一致处按命名约定统一）。

**下一步**：卡片 ⑥体验机器（隐藏遗迹扩展，RelicLibrary 扩至 9）+ ⑦终局四路径（M6，消费 truth/insight/关系/choice_flags）；M5e 树语科技批 1 亦可择机插入。

## 六·十四、里程碑 5d2 完成记录（2026-09-01，增量缺口补齐）

**内容**：升级表缺口补齐 → `GameState` 7 字段（`seedling_level` 嫩叶 3 级封顶 / `firepit_level` 火塘 / `ring_level` 歌之环 / `forge_level` 铸根坊 / `totem_pole_level` 图腾柱 / `deep_dream` / `wind_veil`，全部序列化+缺省/损坏回退，旧档不损坏）；`CostCalculator` 5 成本（嫩叶线性 `10×(L+1)` 10/20/30，四族设施斐波那契 `1000×fib(L+1)`）；`GameActions` 7 购买（嫩叶封顶守卫/四族设施唤醒门/深根梦 3000→记忆+15/风语膜 2500→信仰+30 一次性幂等）；`GameLoop.gather_daylight` 点击加成 +`seedling_level`；`RaceManager.tick_races` 四族设施独立产出（火塘+图腾柱记忆 0.1×L、歌之环信仰 0.3×L、铸根坊树液 0.5×L，与人口无关）；`GameManager` 7 入口 + 5 成本 getter；UI 嫩叶/深根梦/风语膜/四族设施按钮（一次性购买后消失、设施该族唤醒后显示、深根梦/风语膜叙事播报进 race_event_label，照抄设计 §五定稿文本）。

**设计要点**（决策记录见 M5d2 设计文档 §七）：全缺口补齐（spec line 287 可重复设施 6/6 达成，升级表可重复 7 → 11 + 一次性 2）；嫩叶 3 级封顶防通胀（教学链 10/20/30 几分钟内完成）；一次性大额奖励显著（深根梦 +15 记忆 ≈ 300 tick 人族梦产，记忆稀缺）；四族设施独立产出不与人族系数叠加冲突、回本 2.7 小时为挂机期服务；设施解锁 = 该族唤醒（与 M5a 仪式互动区分：设施=可重复购买，互动=一次性关系事件）。

**验证**：265 单测全绿（25 套件 = 基线 248 + 17 新增：T1 3 + T2 8 + T3 3 + T4 3，0 失败 0 orphan）+ M5D2 E2E 20 项检查全 PASS（嫩叶 3 级封顶→深根梦/风语膜一次性幂等→四族设施唤醒门→tick 设施产出差值→存档往返→旧档回退，脚本已删）+ 冒烟通过。

**实施备注**：Task 2 ⚠️ 裁决走「直写四份」（非反射 `_buy_facility`，项目惯例类型安全）；Task 5 ⚠️ 裁决简化（设施按钮静态 text + visible/disabled 控制，不逐 tick 重写成本 text；设施名映射用 StringName 键避免 String/StringName 字典键混用）；Task 1 锚点随文件结构微调（字段区在 `soul_river` 后，非计划原文 `lingua_nodes` 后——该锚点已不存在，语义不变）；计划原文 `btn.text` 占位行按 ⚠️ 注释删除。E2E 是临时脚本未入库，删后无文件变更，Task 6 Step 4 提交自然跳过。

## 六·十五、里程碑 5e 完成记录（2026-09-01，树语科技+资源分层）

**内容**：三层资源架构 + 树语科技框架 → `GameState` 5 字段（`faith_engine_level`/`memory_engine_level`/`lingua_life_level`/`lingua_memory_level`/`lingua_nodes`，全部序列化+缺省/损坏回退，旧档不损坏）；`features/lingua/`：`LinguaData`（生命之语成本 0/200/800 + 11 节点数据驱动表，含聚落之心）+ `LinguaActions`（免费激活 Lv1/升级扣信仰/节点解锁 3000·8000 树液 + 等级门槛/已购幂等/`has_node` 查询）；`GameActions` 点击式兑换（树液→信仰 100:1 需「树冠舒展」/树液→记忆 500:1 需「根须共鸣」）+ 引擎购买（信仰引擎 200×fib 需「云冠」/记忆引擎 500×fib 需「恩泽」）；`CostCalculator` 引擎成本公式；`RaceManager` tick：信仰引擎 `level×(2 if 圣坛)`/记忆引擎 `level×0.1`/「歌之共鸣」四族信仰 ×1.1/「聚落之心」四族设施产出 ×1.5（M5d2 设施块内乘）；`GameLoop` sap 上限 ×「木质强化」1.5、生长 ×「年轮记忆」1.2；`RootActions` 探索成本 ×「深层根须」0.5；`GameManager` 六入口（兑换×2/引擎×2/树语×2，成功发 `resources_changed`）；UI 树语区（献祭/挖梦/生命之语升级+成本/双引擎+成本/11 节点按钮，visible=节点已购或达等级、disabled 由资源决定，动态刷新）。

**设计要点**（决策记录见 M5e 设计文档 §七）：三层资源=一级可再生（树液）/二级可再生可增殖（信仰·记忆：兑换+引擎）/三级不可再生（灵魂·希望，M5f/M6）；树语=能力解锁层（与数值升级表区分，节点=树液 3000/8000 + 树语等级门槛）；生命之语 Lv1 免费激活（开局即解锁兑换系节点入口，避免卡死）；记忆兑换 500:1 严苛（防战略资源速通）；聚落之心=四族设施产出 +50%（M5d2 设施落地后注册实现）；能力位留白（地脉感应/天光=离线进度、冥河之触/奇迹之语=记忆之语系，批 2）。

**验证**：302 单测全绿（29 套件 = 基线 265 + 37 新增：T1 3 + T2 8 + T3 7 + T4 9 + T5 5 + T6 5，0 失败 0 orphan）+ M5E E2E 14 项检查全 PASS（免费激活 Lv1→解锁树冠舒展/根须共鸣→献祭/挖梦→升 Lv2→云冠→买信仰引擎→tick +1→存档往返→旧档回退，脚本已删）+ 冒烟通过。

**实施备注**：Task 4「歌之共鸣」断言用**增长后人口**精确值 0.11055（⚠️ 计划注释已裁定，0.11 超 1e-4 容差必挂）；Task 7 节点按钮按 `LinguaData.NODES` 生成 **11 个**（含 `VillageHeartButton`——计划正文「10 节点」系计数笔误，⚠️ 注释规定「按 LinguaData 生成」故照执行）；`--import` 生成 4 个新 class_name/测试 `.uid` 全部入库（Task 2 一次到位，Task 3/4 各补 import）；E2E 临时脚本未入库，删后无文件变更，Task 8 Step 4 提交自然跳过；Task 1 字段/序列化锚点放 `wind_veil` 后（计划锚点 `choice_flags` 后语义等价）。

## 七、M5 已封板；下一步 M6

按 `docs/superpowers/plans/2026-09-05-m5-completion.md` 顺序执行：

| 步 | 内容 |
|---|---|
| T1 | ✅ 半点制关系迁移 + 诺恩/灵魂/漂移边界修复 |
| T2 | ✅ 遗迹 5—9 与数据化解锁 |
| T3 | ✅ 第⑥明选「体验机器」 |
| T4 | ✅ 说书人④⑤⑥与「小溪与激流」 |
| T5 | ✅ 记忆之语 Lv1（领悟 5 仅作门槛） |
| T6 | ✅ 地脉感应、天光、8 小时封顶离线进度 |
| T7 | ✅ UI、可发现性、叙事归档、420×640 滚动适配 |
| T8 | ✅ 66 项 E2E、最终回归、M5 封板 |

M6 接手：世界之语、九界、奇迹、终局、多周目；领悟跨周目保留，关系每周目清零；一周目关系最多 9/12，二周目增加六个关系事件后可达 12/12，三个周目使用文本差分。

**T6 验证**：离线进度定向 7 套件 / 135 项、全量 33 套件 / 358 项全绿；结算幂等、时钟回拨、在线公式等价、8 小时封顶与无叙事副作用均有覆盖。

**T7 验证**：当时全量 34 套件 / 365 项全绿；隔离用户目录下完成 420×640 Vulkan 实际场景渲染，主内容滚动、换行与 M6 按钮隔离均通过。T8 修复大数比较后，最终基线增至 366 项。

**T8 封板验证**：一次性真实链路 E2E 66/66 PASS（脚本已删）；最终 34 套件 / 366 项全绿；headless 主场景五帧冒烟无 SCRIPT ERROR；`BigNum` 零值与小数比较缺陷已修复。

**已知环境问题（不阻塞当前 GDScript 项目）**：Godot 4.7.1 Mono 安装包缺少 `Microsoft.VisualStudio.SolutionPersistence.dll`，`--import` 会在 C# 编辑器插件阶段记录 `FileNotFoundException`，但资源扫描完成且退出码为 0。若 M6 采用 C#，需先修复安装包；继续使用 GDScript 不受影响。

**M6 起点**：世界之语、九界、奇迹、终局、多周目。输入基线为体验机器结果、环形废墟、说书人最终 flag、领悟、关系、`truth`、`choice_flags`、`hope`、`soul_river`；周目契约继续遵守关系清零、领悟跨周目保留、二周目新增六个关系事件、三个周目文本差分。

## 七·五、M6 与 M6-D 已封板（2026-09-06）

**M6 主闭环完成**（按 `docs/superpowers/plans/2026-09-05-m6-ending-multirun.md`，11 任务 SDD 执行）：
- **终局**：EndingStateMachine（世界之轴成型 5 闸门/四结局判定 领悟×羁绊×希望/希望结算）+ 明选⑦世界之轴卡（4 路径 a凝/b拒/c还河/d隐藏真结局，available 排除只走主动入口）
- **归还序列**：ReturnSequence 7 步 × 3 周目 21 段差分 + 3 停步（好 7 步/普通坏 4 步停/真不拆）
- **多周目**：GameState run_number/ending_seen + new_run_preserved 周目重置（余烬=hope/insight/truth/知识解锁）+ restart_run + 三周目 RunBoost 浓缩快进（资源赠予 + 4 树语节点解锁 lingua_nodes）
- **二周目六事件**：RelationEvents.EXTRA_EVENTS（石裔 3 + 野民 3，各 +0.5，run_gte 2 门控 → 12/12）
- **真结局**：run3 + 领悟满 + 关系满 + 希望≥2 → 隐藏 d 亮起 → 结束循环（reset_to_title，无独立标题场景的替代语义）

**M6 封板验证**：首轮 Code Review 修复后 **37 套件 / 437 测试全绿**（0 失败 0 orphan；M5 基线 366 → M6 累计新增 71）；隔离 `user://` 的 headless 冒烟可启动并写入存档、无 SCRIPT ERROR；临时 E2E 21 项主链路曾 PASS（axis→归还→restart→boost→good→condense→true→reset，脚本已删），审查后修订的凝结结局矩阵由当前单元与全量回归覆盖。

**M6 首轮 Code Review 修复（2026-09-06）**：
1. 二周目六个关系事件已接入 `GameManager.interact_relation()` 与 UI 互动按钮，不再只有数据和单元测试入口；每族仍按 r2a→r2b→r2c、各 +0.5 顺序触发。
2. 新增持久化 `pending_ending` 快照；世界之轴结算、归还逐步推进都会保存，重启后可继续归还或重新显示结算；旧版已锁死存档会迁移到可恢复状态。
3. 归还路径补上领悟判定：领悟不足只能进入坏结局，不能绕过普通结局门槛。
4. 忒修斯与体验机器的知识型领悟奖励改为按 `knowledge_id` 去重，跨周目不再反复刷取。
5. 归还 UI 增加互补进度镜像：`树留存度` 递减、`世界复苏度` 递增，二者始终合计 100%；对应设计文档措辞已同步。
6. 交接分支名已校正为 `main`。
7. `run >= 4` 的归还正文与停步文案统一回退到三周目版本，避免继续循环时出现空白。
8. 凝结记忆严格回归普通/坏结局线；即使领悟与羁绊双满也不能获得好结局或增加希望，好结局只由归还路径达成。

**M6 已知缺口（待后续）**：
1. **正式标题场景不存在**：真结局「回到标题」现为 `reset_to_title()` 整档回 run1 数据语义；未来做标题界面/记忆图书馆重读画廊（设计 §6.3）需另建持久层（真结局元进度当前被重置清除）。

**M6-D 完成**：废止“六层承载九响”的临时口径，按项目标准译名落成冠/干/根三域九界。九界探索分辨路、并行、合流三段；世界之语由 3/6/9 残响推导；五奇迹读取世界回响并消耗信仰，不改关系，也不进入结局门槛。世界之轴现在要求九响齐备与本轮点亮「天地一息」，已进入终局的旧存档可继续结算。

**M6-D 验证**：`--import` 后全量 **40 套件 / 486 测试全绿**（0 错误、0 失败、0 跳过、0 孤儿节点）；420×640 实际运行走通华纳→赫尔→阿斯加德→天地一息、四族奇迹目标与旧档归还自动滚入视口。确定性首轮经营档 3/6/9 响为 5:41 / 12:23 / 27:13，符合 25—45 分钟目标；无奇迹路线可达，二、三周目残响保留且不重复扣款。详见 `docs/world-tree/BALANCE_PLAN.md`。

**下一步**：ROADMAP 步 9「终局外壳与回看打磨」。先设计正式标题场景、真结局后仍保留的元进度，以及记忆图书馆画廊的数据边界；不要直接在当前整档清空的 `reset_to_title()` 上堆功能。

**实施流程**（按 DSH 编程模式，铁律 4）：先读写作 skill（铁律 1）与 godot-master（铁律 2）→ writing-plans 写实施计划 → 主人确认 → TDD/SDD 逐任务执行（先失败测试 → 实现 → 验证 → commit）。

## 八、文风速查（铁律 5）

诗歌化·柔和六则：短句呼吸 / 意象代替说明 / 留白不写尽 / 柔和如风 / 自然词汇（露光土风河火灰种子）/ 人称柔软。
所有游戏内文本（心语/事件/明选/结局/遗迹碎片/升级消息）必须遵循；写作任务完成默认过 `humanize-ai` 自检。详见 spec §11.1（文风六则）与 §11.2（画风规范：梦与画/水彩晕染/留白构图/光为主角；MVP 白+暖色 `#f5f0e6` / `#e6a23c`）。
