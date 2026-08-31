# Task 1 Brief: Godot 项目脚手架 + GdUnit4 安装 + headless 测试跑通

**Files:**
- Create: `project.godot`
- Create: `icon.svg`
- Create: `autoloads/.gitkeep`
- Create: `features/game/.gitkeep`、`features/economy/.gitkeep`、`features/ui/.gitkeep`
- Create: `tests/unit/.gitkeep`
- Create: `tests/unit/test_smoke.gd`（冒烟测试，验证 GdUnit4 可用）
- Create: `addons/gdUnit4/`（安装自 https://github.com/MikeSchulze/gdUnit4）

**Interfaces:**
- Consumes: 无（第一个任务）
- Produces: 可运行项目骨架；`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 能跑并显示 1 个通过用例；`godot` 打开项目无报错

## Global Constraints（本任务相关的硬性要求）

- Godot 版本：4.7.x（勿降级；`godot` 命令在 PATH）。
- 全部数据与逻辑使用 typed GDScript。
- 命名与文案：脚本/节点用 snake_case；游戏内文案简体中文。
- 测试：GdUnit4；命令 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 必须全绿。
- 工作目录：`E:\world tree`（当前就是此目录，`git` 仓库已存在，master 分支）。

## Steps

### Step 1: 创建 project.godot

```ini
; Engine configuration file.
config_version=5

[application]
config/name="世界树"
run/main_scene="res://features/ui/main.tscn"

[display]
window/size/viewport_width=420
window/size/viewport_height=640

[editor_plugins]
enabled=PackedStringArray("gdUnit4")
```

### Step 2: 创建 icon.svg（极简树形图标）

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="#1a1512"/><path d="M64 20 L96 84 L32 84 Z" fill="#3f7a3f"/><rect x="60" y="84" width="8" height="28" fill="#6b5638"/></svg>
```

### Step 3: 安装 GdUnit4 插件

Run（在 `E:\world tree` 下）:
```powershell
New-Item -ItemType Directory -Force -Path addons | Out-Null
git clone --depth 1 https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
```
若 git clone 被网络 reset，改用：
```powershell
$ProgressPreference='SilentlyContinue'
Invoke-WebRequest -Uri 'https://codeload.github.com/MikeSchulze/gdUnit4/zip/refs/heads/master' -OutFile "$env:TEMP\gdunit4.zip" -TimeoutSec 120
Expand-Archive -Path "$env:TEMP\gdunit4.zip" -DestinationPath "$env:TEMP\gdunit4-x" -Force
# 解压出的目录名可能是 gdUnit4-master，重命名为 addons/gdUnit4
$src = Get-ChildItem "$env:TEMP\gdunit4-x" -Directory | Select-Object -First 1
Copy-Item $src.FullName 'E:\world tree\addons\gdUnit4' -Recurse -Force
```
Expected: `addons/gdUnit4/plugin.cfg` 存在。

### Step 4: 创建冒烟测试

```gdscript
# tests/unit/test_smoke.gd
extends GdUnitTestSuite

func test_gdunit_works() -> void:
    assert_that(1 + 1).is_equal(2)
```

### Step 5: 运行冒烟测试验证 headless 链路

Run: `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests`
Expected: 输出包含 test_gdunit_works 通过；退出码 0
（首次运行若报 "Plugin not enabled"，确认 project.godot `[editor_plugins]` 已写入且路径为 `res://addons/gdUnit4/plugin.cfg`。若 GdUnitCmdTool 路径不对，在 addons/gdUnit4 下搜索 `GdUnitCmdTool.gd` 的实际位置并调整命令。）

### Step 6: Commit

```bash
git add project.godot icon.svg autoloads features tests addons/gdUnit4
git commit -m "feat: Godot 4.7 脚手架 + GdUnit4 接入（headless 测试跑通）"
```

## 验收标准

- [ ] project.godot / icon.svg / 目录结构齐全
- [ ] addons/gdUnit4/plugin.cfg 存在
- [ ] `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests` 显示 test_gdunit_works 通过、退出码 0
- [ ] 已 commit
