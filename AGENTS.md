# 世界树（World Tree）项目铁律

> 本项目所有会话必须遵守以下铁律，任何情况下不得跳过。
> 铁律来源：主人 2026 年指令（读取 skill 库 `C:\Users\10990\.dsh\skills\` 后固化）。

## 铁律 1：创作前必读写作 Skill

凡涉及叙事、世界观、剧本、剧情文案、设定集、对白等创作任务，
动笔前必须先读取并遵循以下写作类 skill（按任务相关度取用）：

**中文写作：**
- `webnovel-writing` —— 中文网文：题材诊断、故事引擎、分卷章纲、节奏、章末留钩、去 AI 味
- `novel-worldbuilding` —— 小说架构：大纲/人物/世界观/伏笔台账（中文）
- `gat-story` —— 游戏剧情/世界观一问一答访谈式挖掘（中文）
- `cw-prose-writing` / `cw-brainstorming` / `cw-official-docs` / `cw-story-critique` —— 正文写作工作流

**文笔与风格：**
- `creative-writing-craft` —— 小说写作工艺：散文、场景、风格、声音
- `creative-writing-modes` —— 写作模式：起草/修订/搭桥/变化/打磨
- `fantasy-fiction-writer` —— 西幻史诗范本（托尔金/马丁，英文结构可借鉴）
- `character-sim` —— 角色模拟：声音、情感、状态

**世界观与游戏叙事：**
- `worldbuilding` —— 世界观诊断（后果级联，含 10 个子模块）
- `narrative-designer` / `narrative-design` —— 游戏叙事系统架构、分支、lore 分层
- `gat-brainstorm` / `gat-design` / `gat-milestone` / `gat-workflow-start` —— GAT 游戏设计管线

**去 AI 味（中文）：**
- `humanize-ai` —— AI 味检测与消除（19 维模式，先诊断后改写）
- `voice-dissolver` —— 写作前声音校准（输出声音锚点卡）
- `editor-revisor` —— 改稿手（删废话/破套话）
- `chinese-write-checker` —— 内容体检总入口
- `humanizer` —— 英文元老版（维基《Signs of AI writing》33 模式）

## 铁律 2：Godot 开发前必读 godot-master

凡涉及 Godot 开发任务，必须先读取 `godot-master`（Godot 4.7+ 专家库总入口），
并按其 Master Decision Matrix 路由到对应领域 skill，例如：

- `godot-genre-idle-clicker` —— 增量/放置游戏蓝图
- `godot-economy-system` —— 经济系统
- `godot-signal-architecture` —— 信号架构
- `godot-save-load-systems` —— 存档/读档
- `godot-procedural-generation` —— 程序化生成
- `godot-state-machine-advanced` —— 状态机
- `godot-resource-data-patterns` —— 数据驱动设计
- `godot-testing-patterns` —— 测试方案（GdUnit4）

不得跳过 godot-master 直接凭印象写 Godot 代码。

## 铁律 3：遵循 Skill 指导

读取 skill 后必须严格遵循其指导执行，视为规范而非参考意见；
如 skill 与项目实际情况冲突，先停下向主人确认，不得擅自偏离。

## 铁律 4：DSH 规则

DSH 编程模式（Programming Mode）的系统规则（技能先行、设计先行、
计划先行、TDD、系统性调试、验证后完成等）在本项目持续生效。

## 铁律 5：文风铁律（诗歌化·柔和）

本项目所有游戏内文本（心语、事件、明选、结局、遗迹碎片、升级消息）
必须遵循文风规范，详见设计文档 `docs/superpowers/specs/2026-08-31-world-tree-design.md` §11.1（文风六则）与 §11.2（画风规范）。核心六则：

1. **短句呼吸**：长句拆短，一段 2-4 行，像诗行。一句一意，不多不少。
2. **意象代替说明**：不说"它很悲伤"，写"它的影子，比白天长"。
3. **留白不写尽**：最痛的句子，写到一半停笔——读者自己补完。
4. **柔和如风**：残酷的事用温柔的笔。"吞噬"是"把一切都拢进怀里，直到怀里空了"。
5. **自然词汇**：露、光、土、风、河、火、灰、种子——拒绝抽象词与形容词堆砌。
6. **人称柔软**：树的心语用"你"对自己低语，不用激烈的感叹。

画风：梦与画（水彩晕染/留白构图/光为主角）；MVP 配色白色系+暖色系（背景 `#f5f0e6`、希望暖金 `#e6a23c`）。

写作任务完成后，默认用 `humanize-ai` 自检一遍再交稿（文风铁律的执行保障）。

## 铁律 6：继续指南

新会话接手本项目时，必须先读 `docs/world-tree/CONTINUE.md`（项目状态与下一步），
再按本文件铁律执行。

## 当前交接基线（2026-09-06）

- M5 已封板（2026-09-05）：34 套件 / 366 测试；M6 主闭环已封板并完成首轮 Code Review 修复（2026-09-06）：**37 套件 / 437 测试**全部通过。
- M6 完成内容：终局状态机（世界之轴成型/四结局判定/希望结算）、可恢复的终局/归还进度、归还序列 7 步×3 周目差分与双向进度、周目切换（new_run_preserved 余烬保留）、二周目六关系事件（石裔3+野民3，已接入运行时互动入口）、三周目 RunBoost 浓缩快进、知识领悟跨周目防重复奖励、明选⑦世界之轴卡、UI 终局链。
- M6-D「九界 + 世界之语 + 奇迹」已封板（2026-09-06）：冠/干/根三域九界、3/6/9 世界之语、五奇迹、世界之轴新门槛、低保真 UI 与平衡回归完成。当前基线 **40 套件 / 486 测试**；确定性首轮九响为 27:13，平衡口径见 `docs/world-tree/BALANCE_PLAN.md`。
- M7「终局外壳与记忆图书馆」已封板（2026-09-06）：正式标题场景、`save.json` 当前周目与 `meta.json` 永久馆藏双层持久化、七类记忆图书馆、真结局完整解锁、旧档迁移与 420×640 视觉验收完成。当前基线 **46 套件 / 513 测试**；`reset_to_title()` 已改为归档元进度、删除当前周目并返回正式标题。
- ROADMAP 现有 1—9 步已全部交付；下一里程碑尚未冻结，继续开发前先与主人确认新方向并完成设计。
- M6 主闭环的设计决策、实现记录与已知缺口（含 reset_to_title 回标题语义），以
  `docs/superpowers/specs/2026-09-05-world-tree-m6-ending-multirun-design.md`、
  `docs/superpowers/plans/2026-09-05-m6-ending-multirun.md` 与
  `docs/world-tree/CONTINUE.md` §七·五 为准。
- M7 的持久层、入口与馆藏边界以
  `docs/superpowers/specs/2026-09-06-world-tree-m7-title-memory-library-design.md`、
  `docs/superpowers/plans/2026-09-06-m7-title-memory-library.md` 与
  `docs/world-tree/CONTINUE.md` §七·六 为准。
- 路线状态以 `docs/world-tree/ROADMAP.md` 为准；如实现改变里程碑状态，必须同步更新
  计划、继续指南、路线图和本节。
