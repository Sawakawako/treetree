# SDD ledger — plan: docs/superpowers/plans/2026-08-31-mvp-text-prototype.md

## Rulings
- Ruling: 直接在 `E:\world tree`（master 分支）开发 — 这是项目唯一工作目录与设计文档所在，主人明确指示"开始"执行 MVP — 若出错可 git revert 恢复。
- Ruling: SDD 辅助脚本为 shell 脚本，Windows 无 bash — 手动实现同等功能（workspace/brief/review-package 用 pwsh 完成）。
- Ruling: GdUnit4 6.2.1 CLI 变更（Task 1 实施者发现）— `--run-tests` 已失效，统一改用 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`（跑 tests 目录用 `-a res://tests`）— 若不更新，后续任务测试命令全部失效；将同步更新 plan 文件与后续 brief。
- Ruling: `features/ui/main.tscn` 为占位场景（Task 1 创建，T9 整体替换）— 解决主场景缺失报错 — 若 T9 忘替换会导致空屏；已在 T9 简报中强调替换。
- Ruling: 新增 class_name 脚本后，headless 需先 `godot --headless --path . --import` 刷新 global_script_class_cache.cfg 再跑测试（Task 2 发现）— 否则报 "Identifier not declared" — 已写入后续所有 brief 的 Step 2 前置步骤。
- Ruling: GdUnit4 6.2.1 的 `is_equal_approx` 为双参数签名 `(expected, approx)`（Task 2 发现）— 后续 brief 的测试代码统一带容差 `, 1e-4`。

## Pre-flight 扫描（接口一致性）
| 任务对 | 产出→消费 | 结论 |
|---|---|---|
| T2 big_num → T4-8 | BigNum 方法 add/sub/mul_scalar/is_greater_or_equal/to_value/to_dict/from_dict | 一致（plan 测试与实现签名匹配）|
| T3 cost_calculator → T6 | fib/leaf_cost/branch_cost | 一致 |
| T5 game_state → T6-8 | daylight/sap/growth/leaf_level/branch_level/tick/hope | 一致 |
| T7 game_loop → T9 | tick/should_auto_save | 一致 |
| T8 save_manager → T9 | save/load_or_create(path) | 一致 |
| T9 main.tscn ↔ main.gd | %UniqueName ↔ @onready 引用 | 一致（task 内已核对）|
| Global Constraints | BigNum 禁 float / _process 累加器 / 信号更新 / user:// / 斐波那契成本 | plan 各任务自洽 |

结论：扫描干净，无任务间冲突。

## 进度
Task 1: complete (commits 2b74133..f9c876a, review clean)
Task 1: minor (deferred): ① commit 文件数 528 vs 529 字面出入 ② GdUnit4 未锁 release tag（建议后续固定版本）③ 占位 main.tscn 根节点名非 snake_case（T9 替换，仅字面）
Task 1: minor (deferred): ⚠️ addons/gdUnit4 517 文件与官方一致性未逐审（第三方插件，以测试跑通为间接证据）
Task 2: complete (commits f9c876a..8221293, review pending)
Task 2: minor (deferred): 极端跨量级相加 float 精度（1e300+1e-10）MVP 可接受；防 1e308 INF 回归测试建议后续资源系统引入时补
