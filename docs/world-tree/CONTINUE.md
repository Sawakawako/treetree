# 世界树（World Tree）继续指南

> 新会话/新代理接手本项目的入口文档。先读本文件，再读 `AGENTS.md`（铁律），再读设计规格（权威）。

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
| **里程碑 5+** | ⏳ 待定（记忆图书馆/夺梦/明选/奇迹/终局）——**下一步从这里挑**（见 §七） |
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
features/economy/           # BigNum（大数）/ CostCalculator（斐波那契成本）/ Formatter（格式化）/ GameActions（动作）
features/game/              # GameState（状态：含 memory/faith/root_depth/races/relics_found）/ GameLoop（tick 逻辑）/ SaveManager
features/dreams/            # RelicLibrary（4 遗迹数据+梦境文本）/ RootActions（根须探索，200 树液/次，一次性 +1 记忆）
features/memories/          # TotemLibrary（5 幅图腾数据）/ TotemActions（浮现阶段/解读/领悟/next_interpretable）——领悟值之家（spec §15）
features/races/             # RaceManager（数据驱动四族：唤醒/供养/逻辑斯蒂人口/信仰产出/石裔献工）+ RaceData（.tres）+ data/*.tres（四族系数与唤醒文本）
features/ui/                # main.tscn + main.gd（只监听信号，不直改数据；含记忆/信仰/根须/梦境弹层/四族面板/图腾区/种族事件）
tests/unit/                 # GdUnit4 测试（102 个，15 套件）
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

## 七、下一步：里程碑 5+ 候选（待主人挑选）

从 CONTINUE.md 原范围与 spec §14 出发，按依赖顺序建议（M4 已完成图腾线/领悟值雏形）：

| 候选 | 内容 | 依赖 | 建议 |
|---|---|---|---|
| **记忆图书馆** | 已发现的遗迹/梦境碎片/图腾可回看（收藏文本回看，补内容缺口） | 遗迹/图腾系统 | 低成本，可先做 |
| **夺梦系统** | 采梦/夺梦暗代价（人族伤神/林地民枯萎）——石裔献工的机制级对照 | 四族系统 | 成树→巨树过渡核心 |
| **明选** | 玩家明面选择（代价/收益可见）——领悟值消费（好结局门槛 ≥10 缺口由环形废墟/说书人补） | 四族+人口+领悟值 | 中后期 |
| **奇迹/绿地扩容** | 信仰消耗改造地貌，进入承载公式（cap 100×(1+繁茂+绿地 0-3)） | 信仰系统 | 扩承载第二来源 |
| **饥荒/迁徙危机** | 供养不足从「冻结增长」升级为减员/迁徙事件 | 人口系统 | 跟随夺梦 |

**文本归档**（可随时做）：把已产出的五阶段文本（遗迹梦境/人族事件/四族唤醒等）落成 `docs/world-tree/narrative/` 文档。

**实施流程**（按 DSH 编程模式，铁律 4）：先读写作 skill（铁律 1）与 godot-master（铁律 2）→ writing-plans 写实施计划 → 主人确认 → TDD/SDD 逐任务执行（先失败测试 → 实现 → 验证 → commit）。

## 八、文风速查（铁律 5）

诗歌化·柔和六则：短句呼吸 / 意象代替说明 / 留白不写尽 / 柔和如风 / 自然词汇（露光土风河火灰种子）/ 人称柔软。
所有游戏内文本（心语/事件/明选/结局/遗迹碎片/升级消息）必须遵循；写作任务完成默认过 `humanize-ai` 自检。详见 spec §11.1（文风六则）与 §11.2（画风规范：梦与画/水彩晕染/留白构图/光为主角；MVP 白+暖色 `#f5f0e6` / `#e6a23c`）。
