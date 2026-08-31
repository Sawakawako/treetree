# Task 1 审查报告：Godot 项目脚手架 + GdUnit4 安装 + headless 测试跑通

- 审查者：Task 1 任务审查代理
- 审查日期：2026-08-31
- 审查对象：commit `f9c876ad49f17ae1a321bab1d91dc802f142f5c8`（12 个自有文件 + addons/gdUnit4 517 个文件）
- 审查方式：静态核对 diff + 仓库实测复验（复跑测试命令、复核 git 跟踪状态、抽查关键文件内容、核对 GdUnit4 CLI 源码）

---

## 一、spec 合规判定：✅ 合规

**依据（逐项核对 brief Files / Steps / 验收标准，并附实测证据）：**

| brief 要求 | 实测结果 |
|---|---|
| `project.godot` 内容（世界树 / main.tscn / 420×640 / editor_plugins） | ✅ 逐字一致（仅 section 间空行格式差异，无语义影响） |
| `icon.svg` 极简树形图标 | ✅ 逐字一致 |
| `autoloads/.gitkeep`、`features/{game,economy,ui}/.gitkeep`、`tests/unit/.gitkeep` | ✅ 5 个 .gitkeep 全部齐全 |
| `tests/unit/test_smoke.gd` | ✅ 与 brief 原文一致，含真实断言 |
| `addons/gdUnit4/` 安装 | ✅ `plugin.cfg` 存在，`name="gdUnit4"`、`version="6.2.1"`，与 project.godot `[editor_plugins] enabled=PackedStringArray("gdUnit4")` 匹配；`bin/GdUnitCmdTool.gd` 存在且路径与 brief 预期一致 |
| 验收① project.godot / icon.svg / 目录结构齐全 | ✅ 成立 |
| 验收② plugin.cfg 存在 | ✅ 成立 |
| 验收③ 冒烟测试通过 + 退出码 0 | ✅ 成立（见"可信度验证"） |
| 验收④ 已 commit | ✅ HEAD=f9c876a，message 与 brief Step 6 完全一致 |
| Global：Godot 4.7.x | ✅ 4.7.1.stable.mono |
| Global：typed GDScript | ✅ 本任务唯一脚本 test_smoke.gd 函数签名 `-> void`，无未类型化变量 |
| Global：snake_case + 简体中文 | ✅ 文件/目录均 snake_case；项目名「世界树」 |
| Global：不提交 `.godot/`、`reports/` | ✅ git ls-files 实证两者均无混入 |

**对"测试命令偏离"的评估（brief 原命令 → 实际命令）：**

brief 原命令 `... --run-tests` 在本任务被替换为 `... -a res://tests/unit --ignoreHeadlessMode`。经实测与源码双重复核，**该偏离合理且必要**：

1. 实测：复跑 brief 原命令 → `Abnormal exit with 100`（未知命令），与报告记录的退出码 100 一致。`--run-tests` 在 GdUnit4 6.2.1 下确实已失效。
2. 源码：`addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd` 中 CLI 注册为 `runtest -a <directory>`（L17/L235），并注册了 `--ignoreHeadlessMode`（L346）——v6 CLI 语法与 brief 编写时的 4.x 时代语法不同。
3. 验收意图（test_gdunit_works 通过 + 退出码 0）已达成，验收标准的实质未被破坏。
4. 偏离已被管理层固化：`progress.md` Rulings 记录"GdUnit4 6.2.1 CLI 变更…将同步更新 plan 文件与后续 brief"。

结论：brief 命令文本本身过时（spec 维护问题，非实施问题），实施者以最小偏离达成验收目标并完整记录，判合规。

---

## 二、质量判定：Approved（通过）

**依据：**

1. **project.godot 配置正确性**：主场景指向占位 `features/ui/main.tscn` 不产生问题——实测 `godot --headless --path . --import` 退出码 0、无 ERROR。占位场景（单 Control、无脚本、全屏锚点）运行仅显示空屏，属 T9 替换前的预期状态，报告已明确声明。占位场景是解决 brief 自身矛盾（Files 清单无 main.tscn，但 project.godot 指向它、Produces 又要求"打开无报错"）的必要补充，非擅自发挥；progress.md 已记录 T9 将整体替换。
2. **test_smoke.gd 有效性**：`extends GdUnitTestSuite` + `assert_that(1 + 1).is_equal(2)` 为真实断言，被框架实际执行并 PASSED（5ms）。作为"验证 GdUnit4 可用"的冒烟测试，恒定真断言完全符合任务意图（brief 原文即是此断言）。
3. **.gitignore 完整性**：覆盖 `.godot/`、`/reports/`、`*.translation`、平台杂项。仓库原本无 .gitignore，本任务补建是落实 Global Constraints「不提交 .godot/」的必要动作；`git ls-files` 证实无 `.godot/`、无 `reports/` 混入。
4. **.uid / .import 提交合规**：`.uid` 文件提交符合 Godot 4.4+ 官方要求（官方文章明确 "*.uid should not be added to .gitignore"）；`.import` 文件提交符合官方 Import process 文档建议（"commit these files… contain important metadata"）。
5. **报告可信度（强验证）**：审查者亲自复跑最终测试命令，输出与报告文本**逐字一致**（PASSED 5ms、Statistics 1/0/0/0/0/0、Overall Summary、Exit code: 0），`$LASTEXITCODE=0` 二次确认成立。报告引用的 GdUnitTestCIRunner.gd 行号（354-379 区域）与源码实际位置吻合。git 状态（HEAD、工作区干净、仅 `.superpowers/` 未跟踪）全部复验一致。
6. **git 跟踪总量自洽**：532 个跟踪文件 = 12（本任务自有）+ 517（addons/gdUnit4）+ 3（仓库原有：AGENTS.md、plan、spec 文档），无异常混入。

---

## 三、发现的问题

### Critical：0 个

无。

### Important：0 个

无。

### Minor：3 个

1. **报告 commit 文件数不准（Minor）**
   - 问题：报告称 commit "共 528 个文件"，实际 `git show --stat f9c876a` 为 **529 files changed**（12 自有 + 517 addons）。
   - 证据：`git show --stat f9c876a` → "529 files changed, 31269 insertions(+)"
   - 建议：更正为 529；对后续任务报告，文件数建议直接用 `git show --stat` 输出而非手数。

2. **GdUnit4 版本未锁定 release tag（Minor，报告自身 Concern #3）**
   - 问题：安装的是 master 分支（v6.2.1），非固定 release tag，存在 CLI/API 漂移风险（本任务已亲历一次 `--run-tests` 语法漂移）。
   - 证据：plugin.cfg `version="6.2.1"`；brief Step 3 给的两种安装方式均取 master。
   - 建议：后续任务或 CI 固化前，改用 release tag（如 `v6.2.1`）安装并记录版本；此为流程建议，不构成本任务缺陷（实施者遵循了 brief 原文）。

3. **占位 main.tscn 根节点名 "Main" 非 snake_case（Minor，字面合规争议）**
   - 问题：brief Global Constraints 写"节点用 snake_case"，占位场景根节点名为 PascalCase 的 "Main"。
   - 证据：`features/ui/main.tscn` → `[node name="Main" type="Control"]`。
   - 评估：符合 Godot 社区惯例（godot-project-foundations：PascalCase 节点名），且为 Godot 编辑器默认生成的根节点命名，T9 将整体替换——无实际影响。仅按 brief 字面记录，不作为缺陷。

---

## 四、⚠️ 无法从 diff 验证的项

1. **addons/gdUnit4 517 个文件与官方仓库 master 的一致性**：按指示未逐文件审查第三方插件。已抽查关键点（plugin.cfg、bin/GdUnitCmdTool.gd 存在、CLI 源码与报告吻合）；插件完整性的最强间接证据是测试实际跑通（框架真实执行、报告生成）。
2. **实施过程叙述**：git clone 180s 超时、首次目录多套一层后修正、清理空 `.git` 半成品等过程性描述无法从最终产物回放。最终产物状态已实测验证（无 `addons/gdUnit4/addons/gdUnit4` 嵌套、无 `.git` 残留、plugin.cfg 归位）。
3. **占位场景创建前的 "--quit 退出码 1"**：场景已存在，无法回放旧状态。逻辑自洽（brief 指向不存在的 `res://features/ui/main.tscn`，引擎必然报错），且修复后 `--import` 退出码 0 已实测。
4. **报告附带声明**：`-rd` 参数留存报告、`$LASTEXITCODE` 历史值等次要细节未逐一复验（核心的 `$LASTEXITCODE=0` 已复验）。

---

## 五、结论

- **spec 合规：✅**——brief 全部 Files/Steps/验收标准满足；唯一命令偏离（`--run-tests` → `-a ... --ignoreHeadlessMode`）经源码与实测双重证实为 GdUnit4 6.2.1 CLI 变更所致，偏离合理且已达成验收意图。
- **质量：Approved**——配置正确、测试有效、报告高度可信（复跑逐字一致 + 退出码双确认），无 Critical/Important 问题，3 个 Minor 均不阻塞。
