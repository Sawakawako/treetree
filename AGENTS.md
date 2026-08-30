# 世界树（World Tree）项目铁律

> 本项目所有会话必须遵守以下铁律，任何情况下不得跳过。
> 铁律来源：主人 2026 年指令（读取 skill 库 `C:\Users\10990\.dsh\skills\` 后固化）。

## 铁律 1：创作前必读写作 Skill

凡涉及叙事、世界观、剧本、剧情文案、设定集、对白等创作任务，
动笔前必须先读取并遵循以下写作类 skill（按任务相关度取用）：

- `webnovel-writing` —— 中文网文：题材诊断、故事引擎、分卷章纲、节奏、章末留钩、去 AI 味
- `creative-writing-craft` —— 小说写作工艺：散文、场景、风格、声音
- `creative-writing-modes` —— 写作模式：起草/修订/搭桥/变化/打磨
- `creative-writing-muse` —— 单人创意写作（无 subagent 时切换立场）
- `fantasy-fiction-writer` —— 西幻史诗范本（托尔金/马丁，英文结构可借鉴）
- `character-sim` —— 角色模拟：声音、情感、状态

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

不得跳过 godot-master 直接凭印象写 Godot 代码。

## 铁律 3：遵循 Skill 指导

读取 skill 后必须严格遵循其指导执行，视为规范而非参考意见；
如 skill 与项目实际情况冲突，先停下向主人确认，不得擅自偏离。

## 铁律 4：DSH 规则

DSH 编程模式（Programming Mode）的系统规则（技能先行、设计先行、
计划先行、TDD、系统性调试、验证后完成等）在本项目持续生效。
