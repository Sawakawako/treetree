# Task 1 报告：Godot 项目脚手架 + GdUnit4 安装 + headless 测试跑通

- 执行者：Task 1 执行代理（未派遣任何 subagent，符合硬性契约）
- 环境：Godot 4.7.1.stable.mono（`godot --version` → `4.7.1.stable.mono.official.a13da4feb`）；Windows + PowerShell；工作目录 `E:\world tree`（git master）
- 完成状态：**DONE_WITH_CONCERNS**（详见"遗留担忧"）
- Commit：`f9c876ad49f17ae1a321bab1d91dc802f142f5c8`

## 一、做了什么

### Step 1-2：项目骨架文件（全部按 brief 逐字写入）
- `project.godot`：配置名「世界树」、主场景 `res://features/ui/main.tscn`、420×640 视口、`[editor_plugins] enabled=PackedStringArray("gdUnit4")` —— 与 brief 完全一致
- `icon.svg`：极简树形图标（brief 原文）
- 目录骨架 + `.gitkeep`：`autoloads/`、`features/game/`、`features/economy/`、`features/ui/`、`tests/unit/`
- `tests/unit/test_smoke.gd`：冒烟测试（brief 原文）

### Step 3：安装 GdUnit4（版本 6.2.1）
- `git clone --depth 1` 在 180s 后超时（网络被 reset，符合 brief 预判），无文件落地（仅残留空 `.git` 目录，已清理）
- 改用 brief 备用方案：codeload zip 下载（471,696 字节）→ 解压 → 复制，成功
- **遇到的结构问题**：zip 根目录是 `gdUnit4-master/`，插件本体在 `gdUnit4-master/addons/gdUnit4/`（仓库 master 分支把插件包在仓库内层）。首次复制多套了一层，得到 `addons/gdUnit4/addons/gdUnit4/`。已修正为 `addons/gdUnit4/plugin.cfg` 位于预期路径，且无 `.git` 残留（zip 方式天然干净）
- 验证：`addons/gdUnit4/plugin.cfg` 存在，`name="gdUnit4"` 与 project.godot 的 `enabled` 匹配；`bin/GdUnitCmdTool.gd` 存在（路径与 brief 预期一致）

### Step 4：冒烟测试
- `tests/unit/test_smoke.gd`：`extends GdUnitTestSuite`，`test_gdunit_works()` 断言 `1 + 1 == 2`（brief 原文）

### Step 5：headless 测试跑通
- brief 原命令 `--run-tests` 在 GdUnit4 6.2.1 下已失效（见"问题与解决"），实际跑通命令：
  ```
  godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode
  ```
- 结果：`test_gdunit_works PASSED`，1/1 用例通过，退出码 0

### 额外产出（brief 未列但必要，均已在报告中说明）
- `.gitignore`（仓库原本没有）：忽略 `.godot/`、`*.translation`、`/reports/`（GdUnit4 测试报告产物）、Windows/macOS 杂项 —— 符合 godot-project-foundations 铁律"NEVER 提交 .godot/"
- `features/ui/main.tscn`：**极简占位场景**（一个全屏 Control，无脚本）—— 理由见"问题与解决 #4"
- 提交了 Godot 自动生成的 `icon.svg.import`、各脚本的 `.uid` 文件（Godot 4.4+ 规范要求随仓库提交）

### Step 6：Commit
- `f9c876ad49f17ae1a321bab1d91dc802f142f5c8`，message：`feat: Godot 4.7 脚手架 + GdUnit4 接入（headless 测试跑通）`
- 共 528 个文件（含 GdUnit4 插件全部源码），已核对无 `.godot/`、无 `reports/` 混入
- commit 后工作区干净（仅 `.superpowers/` 未跟踪，属 SDD 工作区，不在 brief 提交范围内）

## 二、headless 测试实际输出（文本）

命令：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`

```
Godot Engine v4.7.1.stable.mono.official.a13da4feb - https://godotengine.org

--------------------------------------------------------------------------------------------------
GdUnit4 Comandline Tool
--------------------------------------------------------------------------------------------------

Headless mode is ignored by option '--ignoreHeadlessMode'"

Please note that tests that use UI interaction do not work correctly in headless mode.
Godot 'InputEvents' are not transported by the Godot engine in headless mode and therefore
have no effect in the test!

Scanning for test suites in: res://tests/unit
Installing GdUnit4 session system hooks.
Session hook 'GdUnitHtmlTestReporter' installed.
Session hook 'GdUnitXMLTestReporter' installed.
Run Test Suite: res://tests/unit/test_smoke.gd
  res://tests/unit/test_smoke.gd > test_gdunit_works STARTED
  res://tests/unit/test_smoke.gd > test_gdunit_works PASSED 5ms

Statistics: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 12ms

Overall Summary: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
Executed test suites: (1/1)
Executed test cases : (1/1)
Total execution time: 12ms
Open XML Report at: file://E:/world tree/reports/report_1/results.xml
Open HTML Report at: file://E:/world tree/reports/report_1/index.html
Exit code: 0
Run dispose test resources
```

（终端带 ANSI 颜色码，上述为去除颜色码后的纯文本；`Exit code: 0` 即进程退出码 0，PowerShell `$LASTEXITCODE=0` 已二次确认。）

## 三、退出码汇总

| 步骤 | 命令 | 退出码 |
|---|---|---|
| git clone GdUnit4 | `git clone --depth 1 ...` | 超时被杀（180s） |
| 项目打开（占位 main.tscn 之前） | `godot --headless --path . --quit` | 1（主场景缺失报错） |
| 项目打开（占位 main.tscn 之后） | `godot --headless --path . --import` | 0，无 ERROR |
| brief 原测试命令 | `... --run-tests` | 100（未知命令） |
| **headless 冒烟测试（最终）** | `... -a res://tests/unit --ignoreHeadlessMode` | **0** ✅ |

## 四、遇到的问题与解决方式

1. **git clone 网络超时**：180s 无进展。→ 按 brief Step 3 备用方案走 codeload zip，成功（git clone 被 reset 的环境下，zip 通道可用）。清理了残留的空 `.git` 半成品。
2. **插件目录嵌套错误**：zip 解压后为 `gdUnit4-master/addons/gdUnit4/`，首次复制多套一层导致 `addons/gdUnit4/addons/gdUnit4/plugin.cfg`。→ 删除后从 `gdUnit4-master/addons/gdUnit4` 重新复制到 `addons/gdUnit4`，`plugin.cfg` 归位。
3. **brief 的测试命令失效（GdUnit4 CLI 变更）**：`--run-tests` 报 `Unknown '--run-tests' command!`（退出码 100）。当前 master（v6.2.1）CLI 语法为 `-a <目录>`（`runtest` 只是用法示例里的程序名，不是字面子命令）；且 v6 默认**禁止 headless 模式运行**，必须加 `--ignoreHeadlessMode`（源码 `GdUnitTestCIRunner.gd:354-379` 确认）。→ 用修正命令跑通，退出码 0。
4. **主场景缺失导致编辑器启动报错**：brief 的 project.godot 逐字指向 `res://features/ui/main.tscn`，但本任务 Files 清单没有该场景；`--quit`/`--import` 启动时引擎尝试加载主场景 → `ERROR: Cannot open file 'res://features/ui/main.tscn'`。而 brief 的 Produces 契约要求「可运行项目骨架」+「godot 打开项目无报错」。→ 创建了**极简占位** `features/ui/main.tscn`（单 Control 节点、无脚本、无内容决策），解决报错（`--import` 退出码 0、无 ERROR）。T9 将整体替换为真实主场景（plan/progress.md 记录 T9 负责 main.tscn ↔ main.gd 接线，无冲突）。
5. **测试产物目录**：跑测试会生成 `reports/`（HTML/XML 报告）。→ 加入 `.gitignore` 的 `/reports/`，避免误提交。
6. **`icon.svg.import` / `.uid` 文件**：Godot 导入与脚本扫描自动生成。→ 按 Godot 4.4+ 官方规范随仓库提交（.uid 保证资源引用稳定）。

## 五、遗留担忧（Concerns）

1. **brief 原测试命令已过时**：`--run-tests` 是 GdUnit4 4.x 时代语法，当前 6.2.1 必须用
   `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode`。
   后续任务与 CI 脚本请统一使用新命令；如需批量跑整个 tests 目录，`-a res://tests` 即可。**这是对 brief 命令文本的唯一偏离**（验收目标"test_gdunit_works 通过 + 退出码 0"已达成）。
2. **`features/ui/main.tscn` 是占位场景**：T9 落地真实 main.tscn 前，`godot`（GUI 编辑器）可正常打开、无报错；但直接"运行项目"（F5/`--quit`）会显示占位空屏——属预期，非缺陷。
3. **GdUnit4 版本锁定**：本次装的是 master 分支（v6.2.1）。建议后续用 release tag 固定版本，避免 CLI/API 漂移。
4. **git clone 通道在本机网络不可用**：后续安装任何 GitHub 插件，建议直接走 codeload zip。
5. `reports/report_1/` 为本地生成产物，已 gitignore；如需 CI 留存报告可加 `-rd` 参数另存。

## 六、验收对照

- [x] project.godot / icon.svg / 目录结构齐全
- [x] addons/gdUnit4/plugin.cfg 存在
- [x] headless 测试显示 test_gdunit_works 通过、退出码 0
- [x] 已 commit（f9c876a）
