# 世界树（World Tree）继续指南

> 新会话/新代理接手本项目的入口文档。先读本文件，再读 AGENTS.md（铁律）。

## 一、项目是什么

**《世界树》**——西幻末世增量游戏：玩家是仅存的一棵世界树，在废墟中复苏生命、采集记忆，最终发现自己既是吞噬者，也是旧世界最后的一个梦。
文字原型先行（Godot 4.7），设计目标是 UP（Universal Paperclips）级别的深度：双层目标、亡者之河/灵魂、四族、垂直九界、四结局、三周目。

## 二、当前状态（2026-08-31）

| 层 | 状态 |
|---|---|
| **设计** | ✅ spec v2.3+ 完整（世界观/五阶段/系统/明选/四结局/文风画风） |
| **MVP（里程碑 1）** | ✅ 完成（可玩文字原型，36 测试全绿） |
| **里程碑 2** | ✅ 完成（记忆/信仰/人族/遗迹梦境，54 测试全绿 + M2 E2E VERIFY PASSED，2026-08-31 实施） |
| **里程碑 3-5** | ⏳ 待定（四族扩展/人口/明选/终局） |
| **文本归档** | ⏳ 未做（对话产出的五阶段文本待落成 narrative 文档） |

## 三、关键文档索引

| 文档 | 路径 |
|---|---|
| 设计规格（权威） | `docs/superpowers/specs/2026-08-31-world-tree-design.md`（v2.3：双层目标/四族/梦境/灵魂/人口/九界/升级总表 90+/四结局/归还序列/文风六则/画风六则/数值骨架/明暗双线） |
| MVP 实施计划 | `docs/superpowers/plans/2026-08-31-mvp-text-prototype.md`（Godot 版，10 任务） |
| 项目铁律 | `AGENTS.md`（铁律 1 读写作 skill / 铁律 2 读 godot-master / 铁律 5 文风 / 铁律 6 本文件） |
| SDD 审查记录 | `.superpowers/sdd/2026-08-31-mvp-text-prototype/`（每任务 brief/report/review，含全部 ruling） |

## 四、技术栈与命令

- **引擎**：Godot 4.7.1 mono（`godot` 在 PATH：`C:\Users\10990\AppData\Local\Programs\Godot\Godot_v4.7.1-stable_mono_win64\godot.cmd`）
- **测试**：GdUnit4 6.2.1（`addons/gdUnit4/`）
  ```powershell
  # 新增 class_name 脚本后必须先跑（否则类未注册）：
  godot --headless --path . --import
  # 全量测试：
  godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode
  ```
  ⚠️ 注意：不是 `--run-tests`（旧语法）；`is_equal_approx` 是双参签名 `(expected, approx)`。
- **运行游戏**：`godot --path .`（编辑器打开后 F5）
- **存档**：`user://save.json`（60 tick 自动保存）
- **编码**：中文文件一律用 edit 工具或 .NET 显式 UTF-8 读写（禁 PowerShell 默认编码——曾致乱码事故）

## 五、架构速览（Layer Cake）

```
autoloads/game_manager.gd   # 主循环：_process 累加器 tick（禁 Timer）+ resources_changed 信号 + 60tick 存档
features/economy/           # BigNum（大数）/ CostCalculator（斐波那契成本）/ Formatter（格式化）/ GameActions（动作）
features/game/              # GameState（状态）/ GameLoop（tick 逻辑）/ SaveManager（user:// 存档）
features/ui/                # main.tscn + main.gd（只监听信号，不直改数据）
tests/unit/                 # GdUnit4 测试（36 个）
```
规则：UI 只通过信号更新；资源一律 BigNum（禁裸 float 存资源）；升级成本斐波那契（spec §9）。

## 六、里程碑 2 范围（✅ 已实施，2026-08-31）

**MVP-2 最小可玩增量（已完成）**：
- 记忆（梦珀）资源 + 遗迹系统（数据驱动：遗迹 id/名称/梦境碎片文本/奖励）→ `features/dreams/relic_library.gd`
- 根须探索（深度解锁遗迹，消耗树液 200/次，一次性 +1 记忆）→ `features/dreams/root_actions.gd`
- 信仰资源（人族献梦产生：每 10 tick +1）→ `features/races/human_manager.gd`
- 人族（说书人）唤醒事件（记忆≥2 触发；每 20 tick 记忆 +1）
- 梦境碎片文本 4 个（诗歌化文风，spec §11.1 六则）
- UI：记忆/信仰显示、根须探索按钮、梦境文本弹层、人族事件 → `features/ui/main.tscn` + `main.gd`
- 验证：54 单测全绿 + `M2 E2E VERIFY PASSED`（27 项端到端检查）

**实施记录**：计划 `docs/superpowers/plans/2026-08-31-milestone2-memory-races-dreams.md`（7 任务 TDD，33 步全勾选）。
**实施偏离**（计划书小坑，已修正）：① `Array[int]` 赋 untyped 字面量报错，用 `.assign()`/`Array[int](...)` 修正（Godot 4 typed array 严格性）；② `Array.contains()` → `Array.has()`；③ `var gm: Node` 静态类型无法推断动态方法 → 改无类型 + 显式 `Dictionary` 返回；④ autoload 单例不可 `GameManager.new()` → `preload` 脚本建实例；⑤ GDScript lambda 按值捕获 → Dictionary 包装回写；⑥ `OS.set_exit_code` 静态调用错误 → `quit(code)`。

**暂不做（里程碑 3+）**：林地民/石裔/野民、人口 S 曲线、记忆图书馆、明选、奇迹。
**数值**：沿用 spec §14 骨架（记忆≥2 唤醒人族；遗迹一次性记忆；信仰=献梦产出）。

## 七、文风速查（铁律 5）

诗歌化·柔和六则：短句呼吸 / 意象代替说明 / 留白不写尽 / 柔和如风 / 自然词汇（露光土风河火灰种子）/ 人称柔软。
写作任务完成默认过 `humanize-ai` 自检。详见 spec §11.1。
