# M8 主玩法界面视觉与信息架构重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变玩法、数值、解锁、存档与结局语义的前提下，把主玩法长页重构为顶部资源栏、四个渐进页签、固定底部导航与三级事件层组成的 420×640 触屏优先界面。

**Architecture:** 保留 `features/ui/main.tscn` 作为 `GameManager.MAIN_SCENE`，将 `main.gd` 收敛为只监听全局信号的 `MainShell`。资源栏、底部导航、四个页面和事件层均为独立场景；页面控制器只响应本页按钮、调用既有 `GameManager` 公共动作并向上发出刷新/反馈请求，所有展示判断保持为无副作用投影。

**Tech Stack:** Godot 4.7.1 Mono / typed GDScript / Godot Theme + Container UI / GdUnit4 6.2.1 / Godot Agent Vision。

**Spec:** `docs/superpowers/specs/2026-09-06-world-tree-m8-main-ui-redesign-design.md`

## Global Constraints

- 引擎固定为 Godot **4.7.1 Mono**；本机控制台程序为 `C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe`。
- 保留 `features/ui/main.tscn`、`GameManager.MAIN_SCENE` 及全部既有 `GameManager` 动作签名；不修改 `GameState`、`save.json`、`meta.json` 和迁移规则。
- 不改成本、产出、人口、关系、资源、离线收益、解锁条件、明选或结局判定；UI 只能调用既有 Manager/Actions/Catalog。
- `MainShell` 是唯一连接 `GameManager` 全局信号的 UI 节点；页面只连接本页按钮，并通过 `refresh_requested` / `feedback_requested` 向父级发信号。
- 不新增 `_process` UI 轮询；不直接写 `GameState`；不在展示层复制领域结算公式。
- 目标视口为 **420×640**；所有交互控件最小高度 **44px**；只有当前页面中部滚动，顶部资源栏与底部导航固定。
- 主背景 `#f5f0e6`，强调色 `#e6a23c`，正文与背景对比度不低于 **4.5:1**；颜色不是状态的唯一表达。
- 游戏内既有叙事文本逐字复用当前库与 `docs/world-tree/narrative/09-ui-broadcast.md`，M8 不新增剧情、世界观、遗迹、结局、明选或心语正文。
- 不新增位图图标、插画、音频或运行时依赖；导航只用文字、边框和选中标记表达状态。
- 新增 `class_name` 或场景后先运行 Godot `--import`，检查并提交对应 `.uid`；不得提交 `.godot/`、`reports/`、`.gdskills/` 或视觉截图。
- 每个实现任务遵循 TDD：先写失败测试并确认 RED，再做最小实现并确认 GREEN；每个任务独立提交。
- 全量门槛：GdUnit4 0 error / 0 failure / 0 skipped / 0 orphan；主场景 headless 冒烟无 `SCRIPT ERROR`；运行时视觉 QA 必须实际看图。

---

## File Structure

### 创建

- `features/ui/components/bottom_navigation.gd` / `.tscn`：页签可见性投影、稳定顺序、选中态与首次出现动画。
- `features/ui/components/resource_bar.gd` / `.tscn`：四项折叠摘要、完整资源展开视图与差值反馈。
- `features/ui/pages/ui_page.gd`：四页面共享的 typed `refresh(state)` 与向上信号契约。
- `features/ui/projections/world_axis_projection.gd`：树心下一目标与九界页共用的世界轴缺口文本投影。
- `features/ui/pages/tree_heart_page.gd` / `.tscn`：阶段、既有心语、下一目标、采集、基础升级、根须探索和 M5d2 树体动作。
- `features/ui/pages/beings_page.gd` / `.tscn`：四族、关系、夺梦、亲密、设施、图腾、化身、灵魂与说书人。
- `features/ui/pages/lingua_page.gd` / `.tscn`：转换、引擎、生命/记忆之语与 13 个既有树语节点。
- `features/ui/pages/nine_realms_page.gd` / `.tscn`：九界、六个世界之语节点、五奇迹、四族目标与世界之轴。
- `features/ui/events/ui_event_queue.gd`：纯 `RefCounted` 优先级队列。
- `features/ui/events/event_layer.gd` / `.tscn`：Toast、叙事卡、明选、归还与结局覆盖层。
- `tests/unit/test_main_ui_legacy_contract.gd`：旧入口完整性特征测试。
- `tests/unit/test_bottom_navigation.gd`、`test_resource_bar.gd`、`test_tree_heart_page.gd`、`test_beings_page.gd`、`test_lingua_page.gd`、`test_nine_realms_page.gd`、`test_ui_event_queue.gd`、`test_event_layer.gd`：组件与页面测试。

### 修改

- `features/ui/main.gd` / `main.tscn`：由单页长列表替换为 `MainShell` 组合与全局信号路由。
- `features/ui/world_tree_theme.tres`：补齐页面标题、分区标题、卡片、关键按钮、页签、Toast 与覆盖层类型变体。
- `tests/unit/test_main_ui.gd`：从旧根滚动断言改为主壳结构、映射、固定头尾、焦点与阻塞层断言。
- `tests/unit/test_relation_ui.gd`：关系投影的预载对象从 `main.gd` 改为 `beings_page.gd`。
- `docs/world-tree/CONTINUE.md`、`docs/world-tree/ROADMAP.md`、`AGENTS.md`：M8 封板状态、测试基线和继续指南。
- 本实施计划：执行中勾选步骤，封板时写入验证证据。

---

### Task 0: 冻结旧主界面的入口合同与基线

**Files:**
- Create: `tests/unit/test_main_ui_legacy_contract.gd`
- Read: `features/ui/main.tscn`
- Read: `features/ui/main.gd:320-1205`

**Interfaces:**
- Consumes: 当前 `main.tscn` 中全部按钮和终局节点名称。
- Produces: `ACTION_NODE_NAMES` 与 `EVENT_NODE_NAMES` 两份不可遗漏的迁移合同，供 Task 8 验证新主壳。

- [ ] **Step 1: 写旧入口特征测试**

```gdscript
extends GdUnitTestSuite

const ACTION_NODE_NAMES: Array[String] = [
    "ReturnTitleButton", "GatherButton", "LeafButton", "BranchButton",
    "ChloroplastButton", "XylemButton", "SunflowerButton", "NautilusButton",
    "RootEffButton", "RootExploreButton", "SeedlingButton", "DeepDreamButton",
    "WindVeilButton", "StoryButton", "StreamStoryButton", "TotemInterpretButton",
    "InteractHumanButton", "InteractForestButton", "InteractStoneButton", "InteractWildButton",
    "PlunderHumanButton", "PlunderForestButton", "PlunderStoneButton", "PlunderWildButton",
    "IntimateHumanButton", "IntimateForestButton", "IntimateStoneButton", "IntimateWildButton",
    "ReviveHumanButton", "ReviveForestButton", "ReviveStoneButton", "ReviveWildButton",
    "PlunderSoulHumanButton", "PlunderSoulForestButton", "PlunderSoulStoneButton", "PlunderSoulWildButton",
    "FirepitButton", "RingButton", "ForgeButton", "TotemPoleButton",
    "FaithConvertButton", "MemoryConvertButton", "LifeUpgradeButton", "MemoryLinguaButton",
    "FaithEngineButton", "MemoryEngineButton", "RootEchoButton", "RootResonanceButton",
    "EarthSenseButton", "DeepRootButton", "TreeCanopyButton", "RingMemoryButton",
    "CloudCrownButton", "WoodHeartButton", "SkyLightButton", "SongResonanceButton",
    "VillageHeartButton", "GraceButton", "AltarButton",
    "AsgardButton", "VanaheimButton", "AlfheimButton", "JotunheimButton",
    "MidgardButton", "NidavellirButton", "NiflheimButton", "HelheimButton", "MuspelheimButton",
    "WorldTraceButton", "RainNameButton", "RiverHearingButton", "SkyLadderButton",
    "WorldShapingButton", "WorldBreathButton", "OasisButton", "RainButton",
    "BanishShadowButton", "CallSoulButton", "ShapeButton",
    "MiracleHumanButton", "MiracleForestButton", "MiracleStoneButton", "MiracleWildButton",
    "WorldAxisButton",
]

const EVENT_NODE_NAMES: Array[String] = [
    "ChoicePanel", "ChoiceOptionAButton", "ChoiceOptionBButton",
    "ChoiceOptionCButton", "ChoiceOptionDButton", "ReturnPanel",
    "ReturnAdvanceButton", "EndingPanel", "EndingActionButton",
]

func test_every_existing_action_and_blocking_control_has_a_migration_target() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    for node_name: String in ACTION_NODE_NAMES + EVENT_NODE_NAMES:
        assert_that(root.find_child(node_name, true, false)).is_not_null()
    root.free()
```

- [ ] **Step 2: 运行特征测试并确认当前实现为 GREEN**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_main_ui_legacy_contract.gd -c
```

Expected: 新套件通过，入口总数与当前场景一致；若名称有误，只按 `main.tscn` 的真实名称修正清单，不删入口。

- [ ] **Step 3: 运行全量基线**

```powershell
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode -c
```

Expected: 至少保持 M7 的 46 套件 / 513 测试全部通过，新增特征套件也通过，0 failure / 0 orphan。

- [ ] **Step 4: 提交特征合同**

```powershell
git add -- tests/unit/test_main_ui_legacy_contract.gd tests/unit/test_main_ui_legacy_contract.gd.uid
git commit -m "test: 冻结主界面入口合同"
```

---

### Task 1: 建立渐进页签投影与底部导航

**Files:**
- Create: `features/ui/components/bottom_navigation.gd`
- Create: `features/ui/components/bottom_navigation.tscn`
- Create: `tests/unit/test_bottom_navigation.gd`

**Interfaces:**
- Consumes: `GameState.RACE_IDS`、`LinguaActions.can_upgrade_memory(state)` 和既有状态字段。
- Produces: `BottomNavigation.visible_tabs(state) -> Array[StringName]`、`normalize_active_tab(requested, visible_tabs) -> StringName`、`refresh(visible_tabs, active_tab) -> void`、`tab_selected(tab_id: StringName)`。

- [ ] **Step 1: 写页签投影失败测试**

```gdscript
extends GdUnitTestSuite

const Navigation := preload("res://features/ui/components/bottom_navigation.gd")

func test_fresh_state_only_shows_tree_heart() -> void:
    assert_that(Navigation.visible_tabs(GameState.new())).is_equal([&"tree_heart"])

func test_tabs_appear_from_existing_progress_in_stable_order() -> void:
    var state := GameState.new()
    state.races[&"stoneborn"] = {"awakened": true, "population": 1.0}
    state.faith = BigNum.new(1.0)
    state.relics_found.append(9)
    assert_that(Navigation.visible_tabs(state)).is_equal([
        &"tree_heart", &"beings", &"lingua", &"nine_realms",
    ])

func test_memory_boundary_unlocks_lingua_but_disabled_legacy_button_does_not() -> void:
    var fresh := GameState.new()
    assert_that(Navigation.visible_tabs(fresh).has(&"lingua")).is_false()
    fresh.memory = BigNum.new(500.0)
    fresh.insight = 5
    assert_that(Navigation.visible_tabs(fresh)).contains(&"lingua")

func test_existing_lingua_progress_keeps_tab_visible() -> void:
    var state := GameState.new()
    state.lingua_nodes.append(&"root_echo")
    assert_that(Navigation.visible_tabs(state)).contains(&"lingua")

func test_hidden_requested_tab_falls_back_to_tree_heart() -> void:
    assert_that(Navigation.normalize_active_tab(&"nine_realms", [&"tree_heart"])).is_equal(&"tree_heart")
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_bottom_navigation.gd -c
```

Expected: FAIL，原因是 `bottom_navigation.gd` 尚不存在或接口未定义。

- [ ] **Step 3: 实现纯页签投影**

```gdscript
class_name BottomNavigation
extends HBoxContainer

signal tab_selected(tab_id: StringName)

const TAB_ORDER: Array[StringName] = [&"tree_heart", &"beings", &"lingua", &"nine_realms"]

static func visible_tabs(state: GameState) -> Array[StringName]:
    var result: Array[StringName] = [&"tree_heart"]
    for race_id: StringName in GameState.RACE_IDS:
        if state.races.has(race_id) and bool(state.races[race_id].get("awakened", false)):
            result.append(&"beings")
            break
    var lingua_started := state.lingua_life_level > 0 \
        or state.lingua_memory_level > 0 \
        or not state.lingua_nodes.is_empty() \
        or state.faith_engine_level > 0 \
        or state.memory_engine_level > 0 \
        or state.faith.is_greater_or_equal(BigNum.new(1.0)) \
        or LinguaActions.can_upgrade_memory(state)
    if lingua_started:
        result.append(&"lingua")
    if state.relics_found.has(9):
        result.append(&"nine_realms")
    return result

static func normalize_active_tab(requested: StringName, visible_tabs: Array[StringName]) -> StringName:
    return requested if visible_tabs.has(requested) else &"tree_heart"
```

- [ ] **Step 4: 创建导航场景并实现运行时刷新**

场景结构与关键属性固定为：

```text
BottomNavigation (HBoxContainer, separation=6, size_flags_horizontal=EXPAND_FILL)
├─ TreeHeartTab (Button, unique, min_height=48, text="树心")
├─ BeingsTab (Button, unique, min_height=48, text="众生")
├─ LinguaTab (Button, unique, min_height=48, text="树语")
└─ NineRealmsTab (Button, unique, min_height=48, text="九界")
```

在脚本中建立 `StringName -> Button` 映射；首次 `refresh()` 只建立 `_known_tabs` 而不播放动画，之后新增页签才执行 0.16 秒暖金淡入。动画必须保存 `_tab_tweens: Dictionary`，同一按钮重触发前先 `kill()` 旧 Tween，并 `bind_node(button)`。

```gdscript
func refresh(visible_tabs: Array[StringName], active: StringName) -> void:
    for tab_id: StringName in TAB_ORDER:
        var button: Button = _buttons[tab_id]
        var introduced := _initialized and visible_tabs.has(tab_id) and not _seen_tabs.has(tab_id)
        button.visible = visible_tabs.has(tab_id)
        button.theme_type_variation = &"BottomTabSelected" if tab_id == active else &"BottomTab"
        if introduced:
            _animate_introduction(button)
        if visible_tabs.has(tab_id) and not _seen_tabs.has(tab_id):
            _seen_tabs.append(tab_id)
    _initialized = true
```

`_seen_tabs: Array[StringName]` 在组件本次实例生命期内只增不减；新周目暂时隐藏再出现也不会重复动画。初次刷新会把当时可见页签加入 `_seen_tabs`，所以从标题继续旧档不会补播解锁动画。

- [ ] **Step 5: 补导航场景测试并运行 GREEN**

补测四按钮最小高度、固定顺序、隐藏状态、点击只发一次 `tab_selected`，然后执行：

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_bottom_navigation.gd -c
```

Expected: 新套件全部通过，无 orphan。

- [ ] **Step 6: 提交底部导航**

```powershell
git add -- features/ui/components/bottom_navigation.gd features/ui/components/bottom_navigation.gd.uid features/ui/components/bottom_navigation.tscn tests/unit/test_bottom_navigation.gd tests/unit/test_bottom_navigation.gd.uid
git commit -m "feat: 添加渐进式底部导航"
```

---

### Task 2: 扩展暖纸主题并建立顶部资源栏

**Files:**
- Modify: `features/ui/world_tree_theme.tres`
- Create: `features/ui/components/resource_bar.gd`
- Create: `features/ui/components/resource_bar.tscn`
- Create: `tests/unit/test_resource_bar.gd`
- Modify: `tests/unit/test_memory_library_ui.gd`

**Interfaces:**
- Consumes: `GameState`、`Formatter`、由主壳传入的 `sap_cap: float` 与 `active_tab: StringName`。
- Produces: `ResourceBar.build_view(state, sap_cap, active_tab) -> Dictionary`、`refresh(state, sap_cap, active_tab) -> void`、`collapse() -> void`、`expanded_changed(expanded: bool)`。

- [ ] **Step 1: 写资源投影与主题对比度失败测试**

```gdscript
extends GdUnitTestSuite

const ResourceBarScript := preload("res://features/ui/components/resource_bar.gd")

func test_resource_view_has_four_stable_summary_items_and_complete_expansion() -> void:
    var state := GameState.new()
    state.sap = BigNum.new(12.0)
    state.growth = BigNum.new(3.0)
    state.memory = BigNum.new(4.0)
    state.faith = BigNum.new(5.0)
    state.soul_river = 90
    state.insight = 2
    state.hope = 1
    var view := ResourceBarScript.build_view(state, 100.0, &"beings")
    assert_that(view.get("summary", [])).has_size(4)
    assert_that(view.get("expanded", [])).has_size(8)
    assert_that(view.get("context", [])).is_equal([&"soul", &"insight"])

func test_resource_refresh_does_not_mutate_state() -> void:
    var state := GameState.new()
    var before := state.to_dict()
    ResourceBarScript.build_view(state, 100.0, &"tree_heart")
    assert_that(state.to_dict()).is_equal(before)
```

再实例化 `resource_bar.tscn`，断言 `SummaryPanel`、`ExpandedPanel`、八个值标签、`ExpandButton` 存在，且 `ExpandButton.custom_minimum_size.y >= 44.0`。

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_resource_bar.gd -c
```

Expected: FAIL，资源栏脚本/场景尚不存在。

- [ ] **Step 3: 扩展单一 Theme 资源**

在 `world_tree_theme.tres` 中共享 StyleBox，不在各页面 `_ready()` 新建样式。新增以下类型变体并保持一份配色来源：

```text
PageTitleLabel      base Label, font 28, deep brown
SectionTitleLabel   base Label, font 20, deep brown
MutedLabel          base Label, font 14, muted brown
ResourceValueLabel  base Label, font 16, deep brown
ActionCard          base PanelContainer, warm white, 1px earth-gold, radius 12
PrimaryAction       base Button, warm-gold emphasis, min height supplied by scene
BottomTab           base Button, warm paper
BottomTabSelected   base Button, warm-gold border + text marker
ToastPanel          base PanelContainer, warm white, compact margins
OverlayPanel        base PanelContainer, warm white, 1px earth-gold, radius 12
```

把所有 Button/OptionButton/PanelContainer 的共享 padding、focus outline 和禁用态继续放在 Theme 中；不得在脚本中修改共享 StyleBox。

- [ ] **Step 4: 实现资源栏纯投影**

```gdscript
class_name ResourceBar
extends VBoxContainer

signal expanded_changed(expanded: bool)

static func build_view(state: GameState, sap_cap: float, active_tab: StringName) -> Dictionary:
    var all_items: Array[Dictionary] = [
        {"id": &"daylight", "label": "日光", "value": Formatter.format_number(state.daylight)},
        {"id": &"sap", "label": "树液", "value": "%s / %s" % [Formatter.format_number(state.sap), Formatter.format_cost(int(sap_cap))]},
        {"id": &"growth", "label": "生长", "value": Formatter.format_number(state.growth)},
        {"id": &"memory", "label": "记忆", "value": Formatter.format_number(state.memory)},
        {"id": &"faith", "label": "信仰", "value": Formatter.format_number(state.faith)},
        {"id": &"soul", "label": "灵魂", "value": "%d / %d" % [state.soul_river, SoulActions.RIVER_TOTAL]},
        {"id": &"insight", "label": "领悟", "value": str(state.insight)},
        {"id": &"hope", "label": "希望", "value": str(state.hope)},
    ]
    var summary_ids: Array[StringName] = [&"sap", &"growth", &"memory", &"faith"]
    var context: Array[StringName] = []
    if active_tab == &"beings": context.assign([&"soul", &"insight"])
    elif active_tab == &"lingua": context.assign([&"insight"])
    elif active_tab == &"nine_realms": context.assign([&"hope"])
    return {"summary": _select_items(all_items, summary_ids), "expanded": all_items, "context": context}

static func _select_items(items: Array[Dictionary], ids: Array[StringName]) -> Array[Dictionary]:
    var by_id: Dictionary = {}
    for item: Dictionary in items:
        by_id[StringName(str(item.get("id", &"")))] = item
    var selected: Array[Dictionary] = []
    for id: StringName in ids:
        if by_id.has(id):
            selected.append(by_id[id])
    return selected
```

`_select_items` 必须保持 `summary_ids` 顺序。当前 `GameManager` 没有公共产速查询，因此展开区只显示存量与树液容量，不从 `GameLoop`/`RaceManager` 复制产出公式。

- [ ] **Step 5: 创建资源栏场景与差值反馈**

```text
ResourceBar (VBoxContainer)
├─ SummaryPanel (PanelContainer, ActionCard)
│  ├─ SummaryRow (HBoxContainer, 4 等宽 VBox；树液/生长/记忆/信仰)
│  └─ ExpandButton (Button, full rect, flat, min_height=52, focusable)
└─ ExpandedPanel (PanelContainer, hidden)
   └─ ExpandedGrid (GridContainer, columns=2；八个名称/值行)
```

差值反馈只比较 `_last_values`；值增加时对对应值标签做一次 0.16 秒 `modulate.a 0.45 -> 1.0` Tween。重触发前杀掉同一标签旧 Tween，场景退出时清理字典；首次刷新不播放差值动画。

展开按钮切换 `_expanded`；主壳切页调用的收起接口固定为：

```gdscript
func collapse() -> void:
    if not _expanded:
        return
    _expanded = false
    %ExpandedPanel.visible = false
    expanded_changed.emit(false)
```

- [ ] **Step 6: 加入主题对比度回归并运行 GREEN**

复用 `test_memory_library_ui.gd` 的 `_contrast_ratio()` 算法，对资源栏正文、禁用按钮正文、RichTextLabel 默认正文和背景逐项断言 `>= 4.5`。

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_resource_bar.gd -c
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_memory_library_ui.gd -c
```

Expected: 两套测试通过，M7 图书馆对比度不回退。

- [ ] **Step 7: 提交主题与资源栏**

```powershell
git add -- features/ui/world_tree_theme.tres features/ui/components/resource_bar.gd features/ui/components/resource_bar.gd.uid features/ui/components/resource_bar.tscn tests/unit/test_resource_bar.gd tests/unit/test_resource_bar.gd.uid tests/unit/test_memory_library_ui.gd
git commit -m "feat: 建立主界面主题与资源栏"
```

---

### Task 3: 迁移树心页

**Files:**
- Create: `features/ui/pages/ui_page.gd`
- Create: `features/ui/projections/world_axis_projection.gd`
- Create: `features/ui/pages/tree_heart_page.gd`
- Create: `features/ui/pages/tree_heart_page.tscn`
- Create: `tests/unit/test_tree_heart_page.gd`
- Modify: `tests/unit/test_main_ui.gd`

**Interfaces:**
- Consumes: 既有 `GameManager` 采集/升级/探索动作，`RootActions`、`EndingStateMachine`、`Formatter`。
- Produces: `UiPage.refresh(state: GameState) -> void`、`refresh_requested`、`feedback_requested(event: Dictionary)`；`WorldAxisProjection.gap_text(state) -> String`；TreeHeartPage 的 `growth_stage(state) -> String`、`heart_text(state) -> String`、`next_goal_view(state, costs) -> Dictionary`。

- [ ] **Step 1: 写阶段、心语与下一目标失败测试**

```gdscript
extends GdUnitTestSuite

const TreeHeartPage := preload("res://features/ui/pages/tree_heart_page.gd")

func test_growth_stage_uses_current_run_progress_only() -> void:
    var state := GameState.new()
    assert_that(TreeHeartPage.growth_stage(state)).is_equal("种子")
    state.seedling_level = 1
    assert_that(TreeHeartPage.growth_stage(state)).is_equal("幼苗")
    state.races[&"human"] = {"awakened": true, "population": 1.0}
    assert_that(TreeHeartPage.growth_stage(state)).is_equal("成树")
    state.lingua_life_level = 1
    assert_that(TreeHeartPage.growth_stage(state)).is_equal("巨树")
    state.pending_ending = {"outcome": &"good", "phase": &"return"}
    assert_that(TreeHeartPage.growth_stage(state)).is_equal("世界之轴")

func test_heart_text_reuses_existing_copy() -> void:
    var state := GameState.new()
    assert_that(TreeHeartPage.heart_text(state)).contains("风从旧土上经过")
    state.run_number = 2
    assert_that(TreeHeartPage.heart_text(state)).contains("你记得这缕光")

func test_next_goal_is_deterministic_and_side_effect_free() -> void:
    var state := GameState.new()
    var before := state.to_dict()
    var view := TreeHeartPage.next_goal_view(state, {"seedling": 20, "leaf": 10})
    assert_that(view.get("action", &"")).is_equal(&"seedling")
    assert_that(state.to_dict()).is_equal(before)
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_tree_heart_page.gd -c
```

Expected: FAIL，树心页尚不存在。

- [ ] **Step 3: 建立共享页面契约并实现树心纯投影**

`features/ui/pages/ui_page.gd` 的完整契约为：

```gdscript
class_name UiPage
extends ScrollContainer

signal refresh_requested
signal feedback_requested(event: Dictionary)

func refresh(_state: GameState) -> void:
    return
```

四个页面都 `extends UiPage`，不得重复声明这两个信号。

阶段判定顺序固定为：待结局/世界轴已结算/轴已可用 → 世界之轴；任一树语进度或图腾可见 → 巨树；任一族苏醒 → 成树；任一树体/嫩叶升级 → 幼苗；否则种子。跨周目保留的 `realm_echoes` 不单独抬高本轮阶段。

`heart_text()` 二、三周目复用原 `RUN2_OPENING_TEXT` / `RUN3_OPENING_TEXT`；其余状态复用 M7 标题现有文本 `风从旧土上经过。\n有些名字，还在叶脉里。`，不新增心语。

把旧 `main.gd` 的 `world_axis_gap_text()` 逐字迁入聚焦单一职责的 `WorldAxisProjection.gap_text()`；树心与九界页都只依赖这个 helper，彼此零引用。

`next_goal_view()` 固定优先级：嫩叶教学 0—3 → 七项基础升级中第一个 0 级项（旧顺序）→ 首族苏醒前的根须探索 → 树语出现条件 → 遗迹 9 → `WorldAxisProjection.gap_text(state)`。返回结构固定为：

```gdscript
{"action": &"seedling", "title": "嫩叶教学", "detail": "0/3 · 价格 20 树液"}
```

目标只展示已有条件和成本，不自动执行、不调整按钮禁用态。

- [ ] **Step 4: 创建树心页面场景**

```text
TreeHeartPage (ScrollContainer, horizontal_scroll_mode=disabled)
└─ Content (VBoxContainer, min_width=0, separation=12)
   ├─ StageLabel (PageTitleLabel)
   ├─ HeartLabel (RichTextLabel or autowrap Label)
   ├─ GoalCard (ActionCard → GoalLabel)
   ├─ GatherButton (PrimaryAction, min_height=52)
   ├─ BasicGrowthCard (7 个既有升级按钮及成本标签)
   ├─ RootCard (RootExploreButton + 探索状态)
   └─ BodyMemoryCard (SeedlingButton/Cost、DeepDreamButton、WindVeilButton)
```

保留 Task 0 中树心动作的原节点名；所有按钮最小高度 44，标签智能换行；页面自身不固定头尾。

- [ ] **Step 5: 迁移按钮控制器**

按钮处理器保持统一形态：

```gdscript
func _on_leaf_pressed() -> void:
    if GameManager.buy_leaf():
        feedback_requested.emit({
            "kind": &"toast",
            "body": "叶序螺旋升至 %d 级。" % GameManager.get_state().leaf_level,
        })
    refresh_requested.emit()
```

采集、七项升级、根须探索、嫩叶、深根梦、风语膜均使用现有动作和既有反馈文本。遗迹成功正文不在页面显示，等待 `MainShell` 从 `GameManager.relic_discovered` 路由到事件层；探索失败通过 `RootActions.explore_block_reason` 对应现有四条失败文案。

- [ ] **Step 6: 补页面结构与动作无副作用测试并运行 GREEN**

实例化页面，断言树心全部原按钮存在、最小高度满足 44、横向滚动关闭、纯 `refresh()` 不改变 `state.to_dict()`；用信号监视器确认一次点击最多发一次 `refresh_requested`。

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_tree_heart_page.gd -c
```

Expected: 新套件全绿，无 orphan。

- [ ] **Step 7: 提交树心页**

```powershell
git add -- features/ui/pages/ui_page.gd features/ui/pages/ui_page.gd.uid features/ui/projections/world_axis_projection.gd features/ui/projections/world_axis_projection.gd.uid features/ui/pages/tree_heart_page.gd features/ui/pages/tree_heart_page.gd.uid features/ui/pages/tree_heart_page.tscn tests/unit/test_tree_heart_page.gd tests/unit/test_tree_heart_page.gd.uid tests/unit/test_main_ui.gd
git commit -m "feat: 迁移树心成长页面"
```

---

### Task 4: 迁移众生页

**Files:**
- Create: `features/ui/pages/beings_page.gd`
- Create: `features/ui/pages/beings_page.tscn`
- Create: `tests/unit/test_beings_page.gd`
- Modify: `tests/unit/test_relation_ui.gd`
- Modify: `tests/unit/test_main_ui.gd`

**Interfaces:**
- Consumes: 四族、关系、夺梦、亲密、图腾、化身、灵魂、设施和说书人的既有 Actions/Catalog 与 GameManager 动作。
- Produces: `refresh(state)`、`refresh_requested`、`feedback_requested`，以及从旧 `main.gd` 迁出的 `relation_label`、`relation_color`、`format_relation`、`storyteller_view`。

- [ ] **Step 1: 写众生投影失败测试**

```gdscript
extends GdUnitTestSuite

const BeingsPage := preload("res://features/ui/pages/beings_page.gd")

func test_race_view_has_awake_population_relation_and_text_backup() -> void:
    var state := GameState.new()
    state.races[&"human"] = {"awakened": true, "population": 12.0}
    state.relations[&"human"] = 0.5
    var view := BeingsPage.race_view(state, &"human")
    assert_that(view.get("awakened", false)).is_true()
    assert_that(view.get("summary", "")).contains("人口 12")
    assert_that(view.get("summary", "")).contains("友善")

func test_relation_colors_remain_readable_on_warm_cards() -> void:
    var card_background := Color(1.0, 0.984314, 0.945098, 1.0)
    for relation: float in [-3.0, -0.5, 0.0, 0.5, 2.0, 3.0]:
        assert_that(_contrast_ratio(BeingsPage.relation_color(relation), card_background)).is_greater_equal(4.5)

func test_storyteller_projection_remains_compatible() -> void:
    var state := GameState.new()
    assert_that(BeingsPage.storyteller_view(state).get("visible", true)).is_false()
    state.choice_flags.assign([&"cave_found", &"human_nightmare_protected"])
    assert_that(BeingsPage.storyteller_view(state).get("disabled", true)).is_false()
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_beings_page.gd -c
```

Expected: FAIL，众生页尚不存在。

- [ ] **Step 3: 迁移关系与说书人纯投影**

把旧 `main.gd:3-34` 和 `main.gd:284-318` 的静态函数迁到 `BeingsPage`：关系阈值、名称和 `+0.5` 格式逐字保持，颜色替换为对暖白卡片均达到 4.5:1 的深灰蓝/深棕色阶；暖金只做边框/标记，不直接作为小号正文色。新增 `race_view(state, race_id)`，返回 `awakened`、`summary`、`relation_label`、`relation_text`、`relation_color` 与 `awaken_hint`；关系状态始终同时包含文字和颜色。

```gdscript
static func relation_color(value: float) -> Color:
    if value <= -2.0: return Color("#455564")
    if value <= -0.5: return Color("#5f6b72")
    if value < 0.5: return Color("#5b5140")
    if value < 2.0: return Color("#765514")
    if value < 3.0: return Color("#70420b")
    return Color("#5c3b0a")
```

更新 `test_relation_ui.gd`：

```gdscript
const MainUi = preload("res://features/ui/pages/beings_page.gd")
```

原边界断言保持不变。

- [ ] **Step 4: 创建众生页面场景**

```text
BeingsPage (ScrollContainer, horizontal disabled)
└─ Content (VBoxContainer)
   ├─ PageHeader (title + SoulContextLabel + InsightContextLabel)
   ├─ RaceSummaryCard (四族摘要)
   ├─ RelationCard (Interact* ×4)
   ├─ DreamCard (Plunder* ×4 + Intimate* ×4)
   ├─ FacilityCard (Firepit/Ring/Forge/TotemPole)
   ├─ TotemCard (TotemPanel + TotemInterpretButton)
   ├─ AvatarCard (AvatarPanel)
   ├─ SoulCard (Revive* ×4 + PlunderSoul* ×4)
   └─ StoryCard (StoryStatusLabel + StoryButton + StreamStoryButton)
```

未醒族群保留摘要与既有苏醒条件提示，但本族动作区隐藏；所有 Task 0 众生动作名原样保留。

- [ ] **Step 5: 迁移众生按钮控制器**

从旧 `main.gd:500-678`、`813-895` 迁移显示判断和按钮处理。成功返回正文的本页动作直接发 `feedback_requested({"kind": &"narrative", ...})`；由 `GameManager` 全局信号提供正文的图腾/夺梦/亲密/灵魂/故事事件只发刷新请求，正文由主壳统一接收，避免重复卡片。

页面不得连接 `GameManager.plunder_done` 等全局信号；设施成本继续调用 `GameManager.get_*_cost()`。

- [ ] **Step 6: 补入口、状态与纯刷新测试并运行 GREEN**

测试四族未醒/已醒、关系文字备份、夺梦冻结、亲密门槛、设施可见、图腾阶段、化身、灵魂双向操作、说书人 0/3—3/3；断言所有原按钮恰好位于众生页。

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_beings_page.gd -c
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_relation_ui.gd -c
```

Expected: 两套测试全绿，无 orphan。

- [ ] **Step 7: 提交众生页**

```powershell
git add -- features/ui/pages/beings_page.gd features/ui/pages/beings_page.gd.uid features/ui/pages/beings_page.tscn tests/unit/test_beings_page.gd tests/unit/test_beings_page.gd.uid tests/unit/test_relation_ui.gd tests/unit/test_main_ui.gd
git commit -m "feat: 迁移众生关系页面"
```

---

### Task 5: 迁移树语页

**Files:**
- Create: `features/ui/pages/lingua_page.gd`
- Create: `features/ui/pages/lingua_page.tscn`
- Create: `tests/unit/test_lingua_page.gd`
- Modify: `tests/unit/test_main_ui.gd`

**Interfaces:**
- Consumes: `LinguaData`、`LinguaActions`、`CostCalculator` 与既有 GameManager 转换/引擎/升级/点亮动作。
- Produces: `node_view(state, node_id) -> Dictionary`、`refresh(state)`、`refresh_requested`、`feedback_requested`。

- [ ] **Step 1: 写树语节点完成态与缺口失败测试**

```gdscript
extends GdUnitTestSuite

const LinguaPage := preload("res://features/ui/pages/lingua_page.gd")

func test_completed_node_stays_visible_as_disabled_completion() -> void:
    var state := GameState.new()
    state.lingua_life_level = 1
    state.lingua_nodes.append(&"root_echo")
    var view := LinguaPage.node_view(state, &"root_echo")
    assert_that(view.get("visible", false)).is_true()
    assert_that(view.get("disabled", false)).is_true()
    assert_that(view.get("status", "")).is_equal("已点亮")

func test_locked_node_names_its_first_existing_gap() -> void:
    var state := GameState.new()
    var view := LinguaPage.node_view(state, &"root_resonance")
    assert_that(view.get("visible", false)).is_true()
    assert_that(view.get("status", "")).contains("生命之语")

func test_projection_does_not_mutate_state() -> void:
    var state := GameState.new()
    var before := state.to_dict()
    LinguaPage.node_view(state, &"root_echo")
    assert_that(state.to_dict()).is_equal(before)
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_lingua_page.gd -c
```

Expected: FAIL，树语页尚不存在。

- [ ] **Step 3: 实现 13 节点纯投影**

`node_view()` 只读取 `LinguaData.get_node()` 和 `LinguaActions`。缺口顺序固定为：语言等级 → 前置节点 → 树液成本 → 可以点亮；已点亮始终 `{visible=true, disabled=true, status="已点亮"}`。

```gdscript
static func node_view(state: GameState, node_id: StringName) -> Dictionary:
    var node := LinguaData.get_node(node_id)
    if node.is_empty():
        return {"visible": false, "disabled": true, "status": "节点缺失"}
    if LinguaActions.has_node(state, node_id):
        return {"visible": true, "disabled": true, "status": "已点亮", "node": node}
    var language := StringName(node.get("language", &"life"))
    var level := state.lingua_memory_level if language == &"memory" else state.lingua_life_level
    var requirement := int(node.get("requirement", 99))
    if level < requirement:
        var language_name := "记忆之语" if language == &"memory" else "生命之语"
        return {"visible": true, "disabled": true, "status": "%s还差 Lv%d" % [language_name, requirement - level], "node": node}
    for raw_id: Variant in node.get("prerequisites", []):
        var prerequisite := StringName(str(raw_id))
        if not state.lingua_nodes.has(prerequisite):
            return {"visible": true, "disabled": true, "status": "还差%s" % LinguaData.get_node(prerequisite).get("name", prerequisite), "node": node}
    var cost := int(node.get("sap_cost", 0))
    var status := "可以点亮" if LinguaActions.can_unlock_node(state, node_id) else "树液还差 %s" % Formatter.format_cost(maxi(cost - int(state.sap.to_value()), 0))
    return {"visible": true, "disabled": not LinguaActions.can_unlock_node(state, node_id), "status": status, "node": node}
```

- [ ] **Step 4: 创建树语页面场景**

```text
LinguaPage (ScrollContainer, horizontal disabled)
└─ Content (VBoxContainer)
   ├─ PageHeader (title + InsightContextLabel)
   ├─ LanguageSummaryCard (LifeLevelLabel + MemoryLevelLabel + 建议节点)
   ├─ ConversionCard (FaithConvertButton + MemoryConvertButton)
   ├─ EngineCard (FaithEngineButton/Cost + MemoryEngineButton/Cost)
   ├─ LanguageUpgradeCard (LifeUpgradeButton/Cost + MemoryLinguaButton/Cost)
   └─ NodePathCard (13 个原名按钮，按 LinguaData 注册序)
```

所有按钮最小高度 44；完成节点保留并显示 `◆ 名称 · 已点亮`，不可用节点显示第一缺口。

- [ ] **Step 5: 迁移树语控制器**

从旧 `main.gd:895-1014` 迁移转换、引擎、语言升级和点亮动作。按钮只调用既有 `GameManager` 方法；普通成功发 Toast，节点点亮成功使用既有 `（%s 已点亮）` 文本；世界之语节点不放入本页。

- [ ] **Step 6: 运行树语测试 GREEN**

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_lingua_page.gd -c
```

Expected: 生命/记忆升级、转换、引擎、13 节点的可见/禁用/完成态全部通过，无 orphan。

- [ ] **Step 7: 提交树语页**

```powershell
git add -- features/ui/pages/lingua_page.gd features/ui/pages/lingua_page.gd.uid features/ui/pages/lingua_page.tscn tests/unit/test_lingua_page.gd tests/unit/test_lingua_page.gd.uid tests/unit/test_main_ui.gd
git commit -m "feat: 迁移树语成长页面"
```

---

### Task 6: 迁移九界页

**Files:**
- Create: `features/ui/pages/nine_realms_page.gd`
- Create: `features/ui/pages/nine_realms_page.tscn`
- Create: `tests/unit/test_nine_realms_page.gd`
- Modify: `tests/unit/test_main_ui.gd`

**Interfaces:**
- Consumes: `RealmCatalog/Actions`、`LinguaData/Actions`、`MiracleCatalog/Actions`、`EndingStateMachine`、`WorldAxisProjection.gap_text` 与既有 GameManager 动作。
- Produces: 旧 `main.gd` 的 `realm_run_echo`、`realm_visible_in_panel`、`realm_gap_text`、`miracle_gap_text`，新增 `world_node_view`、`refresh(state)`、`refresh_requested`、`feedback_requested`。

- [ ] **Step 1: 把现有九界静态测试改写为新页面的失败测试**

将 `tests/unit/test_main_ui.gd` 的 M6-D 静态投影断言复制到 `test_nine_realms_page.gd`，预载改为：

```gdscript
const NineRealmsPage := preload("res://features/ui/pages/nine_realms_page.gd")
const WorldAxisProjection := preload("res://features/ui/projections/world_axis_projection.gd")
```

保留近路扩展、主缺口、周目回响、奇迹缺口和世界轴缺口断言；世界轴断言改调用 `WorldAxisProjection.gap_text(state)`。另加：

```gdscript
func test_world_node_completion_is_retained() -> void:
    var state := GameState.new()
    state.lingua_nodes.append(&"world_trace")
    var view := NineRealmsPage.world_node_view(state, &"world_trace")
    assert_that(view.get("status", "")).is_equal("已点亮")
    assert_that(view.get("disabled", false)).is_true()
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_nine_realms_page.gd -c
```

Expected: FAIL，新页面尚不存在。

- [ ] **Step 3: 逐字迁移九界纯投影**

把旧 `main.gd:39-110` 与 `main.gd:1017-1171` 的九界专属纯函数迁入 `NineRealmsPage`，不改缺口优先级、回响符号、周目短句和 Formatter 规则；旧 `world_axis_gap_text` 已由 Task 3 迁入 `WorldAxisProjection`，本页只调用它。`world_node_view` 返回 `{name, status, completed, disabled}`，已点亮节点保留在路径中。

- [ ] **Step 4: 创建九界页面场景**

```text
NineRealmsPage (ScrollContainer, horizontal disabled)
└─ Content (VBoxContainer)
   ├─ PageHeader (title + HopeContextLabel)
   ├─ WorldSummaryCard (WorldHeaderLabel/WorldRunEchoLabel/WorldModeLabel/AxisGateLabel)
   ├─ RealmCard (CrownFlow/TrunkFlow/RootDomainFlow + 9 原名按钮)
   ├─ WorldLinguaCard (6 原名按钮)
   ├─ MiracleCard (5 原名按钮)
   ├─ MiracleTargetCard (四族目标按钮)
   └─ WorldAxisButton (PrimaryAction)
```

`HFlowContainer` 负责窄屏换行，按钮设置合理最小宽度但不手算位置；页面只纵向滚动。

- [ ] **Step 5: 迁移九界控制器**

从旧 `main.gd:1017-1205` 迁移按钮映射与处理；九界/世界之语/奇迹成功正文交给主壳接收全局信号，页面只维护 `_pending_miracle_target_id` 和发刷新请求。世界之轴按钮继续调用 `GameManager.try_start_world_axis()`，不改变守门逻辑。

- [ ] **Step 6: 运行九界测试 GREEN**

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_nine_realms_page.gd -c
```

Expected: 近路、三域、九界、六节点、五奇迹、四目标和世界轴全部通过，无 orphan。

- [ ] **Step 7: 提交九界页**

```powershell
git add -- features/ui/pages/nine_realms_page.gd features/ui/pages/nine_realms_page.gd.uid features/ui/pages/nine_realms_page.tscn tests/unit/test_nine_realms_page.gd tests/unit/test_nine_realms_page.gd.uid tests/unit/test_main_ui.gd
git commit -m "feat: 迁移九界与奇迹页面"
```

---

### Task 7: 建立三级事件队列与覆盖层

**Files:**
- Create: `features/ui/events/ui_event_queue.gd`
- Create: `features/ui/events/event_layer.gd`
- Create: `features/ui/events/event_layer.tscn`
- Create: `tests/unit/test_ui_event_queue.gd`
- Create: `tests/unit/test_event_layer.gd`
- Modify: `tests/unit/test_main_ui.gd`

**Interfaces:**
- Consumes: 规范化事件 Dictionary、`ChoiceActions.option_unlocked`、`ReturnSequence`、`EndingArchive.settlement_view`。
- Produces: `UiEventQueue.enqueue/pop_next/requeue_front/peek_priority/is_empty/clear`；`EventLayer.enqueue(event)`、`show_pending_ending(pending, state)`、`settlement_view(outcome, hope_before, hope_after)`；`choice_submitted`、`return_advance_requested`、`ending_action_requested`、`event_dismissed`。

- [ ] **Step 1: 写队列优先级与 FIFO 失败测试**

```gdscript
extends GdUnitTestSuite

const QueueScript := preload("res://features/ui/events/ui_event_queue.gd")

func test_priority_is_ending_then_choice_then_narrative_then_toast() -> void:
    var queue := QueueScript.new()
    queue.enqueue({"kind": &"toast", "body": "t"})
    queue.enqueue({"kind": &"narrative", "body": "n"})
    queue.enqueue({"kind": &"choice", "body": "c"})
    queue.enqueue({"kind": &"ending", "body": "e"})
    assert_that(queue.pop_next().get("kind")).is_equal(&"ending")
    assert_that(queue.pop_next().get("kind")).is_equal(&"choice")
    assert_that(queue.pop_next().get("kind")).is_equal(&"narrative")
    assert_that(queue.pop_next().get("kind")).is_equal(&"toast")

func test_same_priority_preserves_arrival_order() -> void:
    var queue := QueueScript.new()
    queue.enqueue({"kind": &"narrative", "body": "first"})
    queue.enqueue({"kind": &"narrative", "body": "second"})
    assert_that(queue.pop_next().get("body")).is_equal("first")
    assert_that(queue.pop_next().get("body")).is_equal("second")
```

- [ ] **Step 2: 运行队列测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_ui_event_queue.gd -c
```

Expected: FAIL，队列尚不存在。

- [ ] **Step 3: 实现稳定优先级队列**

```gdscript
class_name UiEventQueue
extends RefCounted

const PRIORITY := {&"toast": 0, &"narrative": 1, &"choice": 2, &"return": 3, &"ending": 3}

var _items: Array[Dictionary] = []
var _serial := 0

func enqueue(event: Dictionary) -> void:
    var item := event.duplicate(true)
    item["priority"] = int(PRIORITY.get(StringName(str(item.get("kind", &"toast"))), 0))
    item["serial"] = _serial
    _serial += 1
    _items.append(item)

func pop_next() -> Dictionary:
    if _items.is_empty():
        return {}
    var best := 0
    for index in range(1, _items.size()):
        var left := _items[index]
        var right := _items[best]
        if int(left["priority"]) > int(right["priority"]) \
                or int(left["priority"]) == int(right["priority"]) and int(left["serial"]) < int(right["serial"]):
            best = index
    return _items.pop_at(best)

func requeue_front(event: Dictionary) -> void:
    var item := event.duplicate(true)
    item["priority"] = int(PRIORITY.get(StringName(str(item.get("kind", &"toast"))), 0))
    item["serial"] = -1
    _items.append(item)

func peek_priority() -> int:
    if _items.is_empty():
        return -1
    var highest := -1
    for item: Dictionary in _items:
        highest = maxi(highest, int(item.get("priority", 0)))
    return highest

func is_empty() -> bool:
    return _items.is_empty()

func clear() -> void:
    _items.clear()
```

`requeue_front()` 用 `serial=-1` 保证被阻塞事件打断的非阻塞内容在同级内容之前恢复；四个方法均由测试覆盖。

- [ ] **Step 4: 写事件层互斥与焦点失败测试**

实例化 `event_layer.tscn` 后覆盖：同帧低优先级延迟到最高优先级之后；阻塞层显示时底层 `mouse_filter=STOP`；叙事卡关闭恢复触发控件焦点；四选项明选按 `ChoiceActions.option_unlocked` 禁用；缺正文时仍显示标题；`show_pending_ending()` 能恢复归还与结算两种 phase。

把旧 `main.gd.settlement_view()` 的测试移入 `test_event_layer.gd`；`EventLayer.settlement_view()` 只返回 `EndingArchive.settlement_view(...)`，保证结局文案和循环语义仍由现有归档拥有。

- [ ] **Step 5: 创建事件层场景**

```text
EventLayer (Control, full rect, mouse_filter=IGNORE)
├─ ToastLayer (MarginContainer, mouse_filter=IGNORE)
│  └─ ToastPanel/ToastLabel
├─ NarrativeScrim (ColorRect, hidden)
├─ NarrativeCard (PanelContainer, hidden)
│  └─ VBox (NarrativeTitleLabel + NarrativeScroll/RichTextLabel + NarrativeCloseButton)
└─ BlockingOverlay (Control, hidden, mouse_filter=STOP)
   ├─ BlockingScrim
   ├─ ChoicePanel (4 原名选项按钮)
   ├─ ReturnPanel (原归还节点)
   └─ EndingPanel (原结局节点)
```

`NarrativeCard` 作为 EventLayer 的非 Container 直系子节点锚定底部，允许从 `position.y + 24` 与 `modulate.a=0` 动画至最终位置；不在 Container 子节点上动画 position。透明非活动层必须 `MOUSE_FILTER_IGNORE`，阻塞层出现时才 `STOP`；弹层所有正文智能换行并可纵向滚动。

- [ ] **Step 6: 实现延迟泵与生命周期安全 Tween**

同一帧首次 `enqueue()` 只 `call_deferred("_pump")`，让同帧事件都进入队列后再选最高优先级。若非阻塞内容显示期间进入阻塞事件，把当前内容重新排队并立即切换；阻塞事件之间不互相穿透。

Toast、叙事卡与页签动画均采用“旧 Tween 有效则 kill → `create_tween().bind_node(self)` → `EASE_OUT/TRANS_QUAD`”；`_exit_tree()` 杀掉所有有效 Tween，不留下遮罩。

- [ ] **Step 7: 运行事件测试 GREEN**

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_ui_event_queue.gd -c
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_event_layer.gd -c
```

Expected: 优先级、FIFO、互斥、恢复焦点、四选项和待结局恢复全绿，无 orphan。

- [ ] **Step 8: 提交事件层**

```powershell
git add -- features/ui/events/ui_event_queue.gd features/ui/events/ui_event_queue.gd.uid features/ui/events/event_layer.gd features/ui/events/event_layer.gd.uid features/ui/events/event_layer.tscn tests/unit/test_ui_event_queue.gd tests/unit/test_ui_event_queue.gd.uid tests/unit/test_event_layer.gd tests/unit/test_event_layer.gd.uid tests/unit/test_main_ui.gd
git commit -m "feat: 添加分级事件覆盖层"
```

---

### Task 8: 组装 MainShell 并删除旧单页实现

**Files:**
- Replace: `features/ui/main.gd`
- Replace: `features/ui/main.tscn`
- Modify: `tests/unit/test_main_ui.gd`
- Modify: `tests/unit/test_main_ui_legacy_contract.gd`

**Interfaces:**
- Consumes: Task 1—7 的组件/页面信号和 `GameManager` 现有全局信号。
- Produces: `MainShell` 单一刷新与事件路由；所有旧动作在一个且仅一个页面可达；主场景路径保持不变。

- [ ] **Step 1: 把主界面测试改为新壳失败断言**

```gdscript
func test_main_scene_uses_fixed_shell_and_independent_pages() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    assert_that(root is Control).is_true()
    for node_name: String in [
        "ResourceBar", "PageStack", "TreeHeartPage", "BeingsPage",
        "LinguaPage", "NineRealmsPage", "BottomNavigation", "EventLayer",
    ]:
        assert_that(root.find_child(node_name, true, false)).is_not_null()
    assert_that(root.find_child("PageStack", true, false) is ScrollContainer).is_false()
    root.free()

func test_every_action_belongs_to_exactly_one_page_or_shell() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    for node_name: String in LegacyContract.ACTION_NODE_NAMES:
        var matches := root.find_children(node_name, "Button", true, false)
        assert_that(matches).has_size(1)
    root.free()
```

并在 `test_main_ui.gd` 顶部加入：

```gdscript
const LegacyContract := preload("res://tests/unit/test_main_ui_legacy_contract.gd")
```

保留 M6 明选四项、归还、结局、原文归档测试；把已迁出的静态函数断言改为预载对应页面脚本。

- [ ] **Step 2: 运行主壳测试确认 RED**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_main_ui.gd -c
```

Expected: 旧根仍是 `ScrollContainer`，新壳节点不存在，因此 FAIL。

- [ ] **Step 3: 重建主场景组合**

```text
MainShell (Control, full rect, world_tree_theme)
├─ Background (ColorRect #f5f0e6, mouse_filter=IGNORE)
├─ SafeMargin (MarginContainer, 16px horizontal / 12px vertical)
│  └─ MainVBox (VBoxContainer)
│     ├─ HeaderRow (HBoxContainer)
│     │  ├─ ReturnTitleButton (min 44)
│     │  └─ ResourceBar (instance)
│     ├─ PageStack (Control, EXPAND_FILL)
│     │  ├─ TreeHeartPage (instance)
│     │  ├─ BeingsPage (instance)
│     │  ├─ LinguaPage (instance)
│     │  └─ NineRealmsPage (instance)
│     └─ BottomNavigation (instance)
└─ EventLayer (instance, topmost)
```

只给 `SafeMargin` 一层外边距，避免深层 `MarginContainer`；页面使用容器 size flags，不在 Container 子节点上手写运行时 position/size。

- [ ] **Step 4: 实现 MainShell 单向刷新**

```gdscript
extends Control

const TAB_TREE_HEART := &"tree_heart"

@onready var resource_bar: ResourceBar = %ResourceBar
@onready var navigation: BottomNavigation = %BottomNavigation
@onready var event_layer: EventLayer = %EventLayer

var _active_tab: StringName = TAB_TREE_HEART
var _pages: Dictionary[StringName, UiPage]
var _page_tween: Tween

func _ready() -> void:
    GameManager.enter_run_scene()
    _pages = {
        &"tree_heart": %TreeHeartPage,
        &"beings": %BeingsPage,
        &"lingua": %LinguaPage,
        &"nine_realms": %NineRealmsPage,
    }
    _wire_local_signals()
    _wire_game_manager_signals()
    _refresh_all()
    _resume_pending_choice()
    _resume_pending_ending()
    _enqueue_offline_summary(GameManager.take_offline_summary())

func _refresh_all() -> void:
    var state := GameManager.get_state()
    var visible_tabs := BottomNavigation.visible_tabs(state)
    _active_tab = BottomNavigation.normalize_active_tab(_active_tab, visible_tabs)
    navigation.refresh(visible_tabs, _active_tab)
    resource_bar.refresh(state, GameManager.get_sap_cap(), _active_tab)
    for tab_id: StringName in _pages:
        var page: UiPage = _pages[tab_id]
        page.visible = tab_id == _active_tab
    _pages[_active_tab].refresh(state)
```

各页 `refresh_requested` 与 `GameManager.resources_changed` 都进入 `_request_refresh()`，由同帧合并器最多执行一次 `_refresh_all()`，避免成功动作同时发页面请求和全局信号时重复刷新：

```gdscript
var _refresh_scheduled := false

func _request_refresh() -> void:
    if _refresh_scheduled:
        return
    _refresh_scheduled = true
    call_deferred("_flush_refresh")

func _flush_refresh() -> void:
    _refresh_scheduled = false
    _refresh_all()
```

页签点击只改 `_active_tab`、调用 `resource_bar.collapse()`、切可见性并请求刷新。页面作为独立 `ScrollContainer`，隐藏时不销毁，因此会话内滚动位置自然保留；重新实例化主场景默认树心。

- [ ] **Step 5: 连接一次全局信号并完成事件映射**

`_wire_game_manager_signals()` 必须且仅连接以下信号：

```text
resources_changed → refresh
relic_discovered → narrative
race_awakened → narrative
totem_interpreted → narrative
relation_changed → refresh（正文由发起页提供）
plunder_done → narrative
intimate_done → narrative
choice_available → blocking choice
choice_resolved → narrative after closing choice
soul_changed → refresh
soul_revived / soul_plundered → narrative
story_heard → narrative
realm_explored → narrative
world_language_changed → narrative
miracle_performed → narrative
ending_resolved → pending ending blocking view
run_restarted → close blocking + existing run-opening narrative + refresh
```

`EventLayer.choice_submitted` 调用 `GameManager.resolve_choice()`；`return_advance_requested` 调用 `advance_return_sequence()`；`ending_action_requested` 根据结算 view 的 `loops` 调用 `restart_run()` 或 `reset_to_title()`。恢复同进程待决明选时仅保留旧实现已有的 `_pending_choice` 读取，不增加或改变 GameManager API；待结局始终用 `get_pending_ending()`。

- [ ] **Step 6: 实现切页动画与焦点**

切页前若 `_page_tween` 有效则 `kill()`；新页面 `modulate.a = 0.0`，显示后以 0.16 秒 `EASE_OUT/TRANS_QUAD` 淡入。切页后聚焦当前页标题或首个可操作控件；阻塞层出现时由 EventLayer 接管焦点，关闭后恢复触发控件。

- [ ] **Step 7: 删除旧巨型刷新与单页节点**

确认 Task 0 入口合同仍通过后，删除旧 `main.gd` 中所有页面级 `@onready`、`_refresh_*`、按钮处理和 `ensure_control_visible` 逻辑；删除旧 `VBox` 长页节点。迁出的纯函数只保留在对应页面，不在 `main.gd` 留兼容复制。

- [ ] **Step 8: 运行主壳、入口合同和关系回归 GREEN**

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_main_ui.gd -c
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_main_ui_legacy_contract.gd -c
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode --add res://tests/unit/test_relation_ui.gd -c
```

Expected: 新壳结构通过，全部旧动作恰好出现一次，终局节点完整，关系投影无回归。

- [ ] **Step 9: 主场景 headless 冒烟**

```powershell
& $godot --headless --path . --quit-after 5
```

Expected: 无 `SCRIPT ERROR`、无场景加载错误、无 orphan 报告。

- [ ] **Step 10: 提交 MainShell 替换**

```powershell
git add -- features/ui/main.gd features/ui/main.gd.uid features/ui/main.tscn tests/unit/test_main_ui.gd tests/unit/test_main_ui_legacy_contract.gd
git commit -m "refactor: 组装渐进式主玩法界面"
```

---

### Task 9: 全流程回归、Agent Vision 视觉验收与 M8 封板

**Files:**
- Modify: `docs/world-tree/CONTINUE.md`
- Modify: `docs/world-tree/ROADMAP.md`
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/plans/2026-09-07-m8-main-ui-redesign.md`
- Temporary ignored: `.gdskills/m8_qa_capture.gd`
- Temporary ignored: `.gdskills/m8-captures/**`

**Interfaces:**
- Consumes: 完整 M8 主壳、现有真实游戏流程、GdUnit4 与 Godot Agent Vision。
- Produces: 全量自动化证据、420×640 多状态截图与量化视觉审查、继续指南和路线图的新基线。

- [ ] **Step 1: 运行静态与导入检查**

```powershell
$godot = 'C:\Users\冯骜\Desktop\Godot_v4.7.1-stable_mono_win64_console.exe'
git diff --check
rg -n "func _process|GameManager\.[A-Za-z0-9_]+\.connect" features/ui
& $godot --headless --path . --import
git status --short
```

Expected: 无空白错误；UI 页面没有 `_process`；`GameManager.*.connect` 只出现在 `features/ui/main.gd`；导入新增 `.uid` 均属于本计划文件且准备入库。

- [ ] **Step 2: 运行全量 GdUnit4 与主场景冒烟**

```powershell
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode -c
& $godot --headless --path . --quit-after 5
```

Expected: 测试总数高于 M7 的 46 套件 / 513 测试，且 0 error / 0 failure / 0 skipped / 0 orphan；冒烟无 `SCRIPT ERROR`。

- [ ] **Step 3: 创建忽略的 420×640 真实状态 QA 驱动**

以现有 `.gdskills/qa_capture.gd` 的 `SceneTree`、`_settle()`、`_capture()`、`_check()` 为基底，新建 `.gdskills/m8_qa_capture.gd`，使用真实节点/动作完成以下状态并保存 PNG 到 `.gdskills/m8-captures/`：

```gdscript
const REQUIRED_CAPTURES: Array[String] = [
    "m8-tree-fresh", "m8-tree-tail", "m8-beings-first-awake",
    "m8-beings-complete", "m8-lingua-early", "m8-lingua-complete",
    "m8-realms-shortcut", "m8-realms-expanded", "m8-toast",
    "m8-narrative-long", "m8-choice", "m8-return", "m8-ending",
]
```

驱动必须逐项 `_check()`：当前页唯一可见、页签出现顺序、每页能滚到尾部、导航不遮挡内容、阻塞层禁止底层点击、关闭后焦点恢复、返回标题/继续游戏仍可用。它可以直接设置隔离 `GameManager.get_state()` 构造视觉快照，但所有动作链冒烟必须至少各走一次真实 GameManager 入口。

- [ ] **Step 4: 在隔离 user:// 下运行 QA 驱动**

```powershell
$qaAppData = Join-Path (Get-Location) '.gdskills\runtime-user-m8'
New-Item -ItemType Directory -Force -Path $qaAppData | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $qaAppData
    & $godot --path . -s res://.gdskills/m8_qa_capture.gd
} finally {
    $env:APPDATA = $previousAppData
}
```

Expected: 驱动退出码 0，输出每项 `QA_PASS` 和 13 个 420×640 捕获；真实用户存档未被读取或修改。

- [ ] **Step 5: 按 godot-master 的 Agent Vision 流程转码并看图**

执行前读取：

```text
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-capture-modes.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-webp-budgets.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-taste-receptors.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-typography-sight.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-hier-contrast-receptors.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-space-affordance-receptors.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-color-icon-receptors.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-composition-fx-receptors.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-anti-slop-sight.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-ui-taste-sight.md
C:\Users\冯骜\.codex\skills\godot-master\references\agent-vision-identity-sight.md
```

用下列命令把每组不超过四张图转为 WebP 联系表，默认 short-edge 512：

```powershell
$vision = 'C:\Users\冯骜\.codex\skills\godot-master\scripts\agent_vision_capture.py'
python $vision asset --project-root . --paths .gdskills/m8-captures/m8-tree-fresh.png .gdskills/m8-captures/m8-tree-tail.png .gdskills/m8-captures/m8-beings-first-awake.png .gdskills/m8-captures/m8-beings-complete.png --sheet --label m8-core-beings
python $vision asset --project-root . --paths .gdskills/m8-captures/m8-lingua-early.png .gdskills/m8-captures/m8-lingua-complete.png .gdskills/m8-captures/m8-realms-shortcut.png .gdskills/m8-captures/m8-realms-expanded.png --sheet --label m8-lingua-realms
python $vision asset --project-root . --paths .gdskills/m8-captures/m8-toast.png .gdskills/m8-captures/m8-narrative-long.png .gdskills/m8-captures/m8-choice.png .gdskills/m8-captures/m8-return.png --sheet --label m8-events
python $vision asset --project-root . --paths .gdskills/m8-captures/m8-ending.png --label m8-ending
```

仅对文字/1px 接缝不清的画面加 `--detail`。不得把 PNG 墙直接送入上下文，也不得提交 `.gdskills/`。

- [ ] **Step 6: 量化审查并修复所有阻断项**

对每组截图按 Taste Receptor Atlas 记录适用项 0/1/2，至少覆盖：首屏层级、正文最差对比度、标题/资源数字/按钮字号、44px 触控区、禁用/选中 affordance、间距节奏、暖纸色彩角色、固定头尾构图、弹层遮挡、焦点可见性、动效静帧、M7↔M8 视觉身份一致性。

任何文字截断、横向溢出、底栏遮挡、透明容器吃输入、正文对比度 <4.5、焦点不可见或 `SLOP-STACK` 阻断项都先写失败回归测试，再修复，再重跑 Task 9 Step 2—5。

- [ ] **Step 7: 执行独立代码审查与验证后完成流程**

调用 `requesting-code-review` 检查：旧入口映射、信号重复连接、页面直接写状态、事件优先级、Tween 生命周期、存档/终局回归。修复确认有效的问题后，调用 `verification-before-completion` 重新执行全量测试、冒烟、`git diff --check`、工作区检查和最终视觉复查。

- [ ] **Step 8: 同步项目状态文档**

在三处记录相同的实际结果：

```text
docs/world-tree/ROADMAP.md：新增路线步骤 10「M8 主玩法界面视觉与信息架构重构」并标记完成。
docs/world-tree/CONTINUE.md：新增 M8 封板章节，写明组件边界、实际套件/测试数、真实流程与视觉 QA 证据、下一步未冻结。
AGENTS.md：当前交接基线追加 M8，替换“下一里程碑尚未冻结”的旧描述，并继续要求新方向先设计。
本计划：勾选完成项，追加封板提交、测试总数、截图状态和审查修复摘要。
```

不得猜测测试数量；从最终 GdUnit4 输出逐字记录套件数、测试数、失败、跳过和 orphan。

- [ ] **Step 9: 提交封板文档与最终修复**

```powershell
git add -- AGENTS.md docs/world-tree/CONTINUE.md docs/world-tree/ROADMAP.md docs/superpowers/plans/2026-09-07-m8-main-ui-redesign.md features/ui tests/unit
git diff --cached --check
git status --short
git commit -m "docs: 封板 M8 主玩法界面重构"
```

Expected: `.gdskills/`、`.godot/`、`reports/` 未进入暂存；提交只包含 M8 代码、测试与文档。

- [ ] **Step 10: 提交后最终核验**

```powershell
& $godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode -c
& $godot --headless --path . --quit-after 5
git status --short
git log --oneline --decorate -10
```

Expected: 最终全量仍为 0 error / 0 failure / 0 skipped / 0 orphan，冒烟无脚本错误，工作区干净，M8 各任务提交与封板提交都在当前分支。

---

## Risk Controls

- **旧入口遗漏**：Task 0 先冻结名称清单，Task 8 要求每个动作恰好出现一次。
- **页面重复处理全局事件**：全局信号连接只允许存在于 `main.gd`，Task 9 用 `rg` 审计。
- **边界存档丢失树语入口**：新档、记忆之语可执行态、已有节点/引擎进度分别测试。
- **固定头尾挤压内容**：每页独立滚动，420×640 对顶部、尾部和弹层逐图验收。
- **主题改动破坏 M7**：保留并扩展 `test_memory_library_ui.gd` 的 ≥4.5 对比度回归。
- **Tween 重入残留遮罩**：所有可重触发动画保存引用并 kill-before-recreate，`_exit_tree()` 清理。
- **存档和终局语义漂移**：不改 `GameState`/GameManager 动作；全量终局、周目、标题和图书馆测试持续运行。
- **视觉只凭代码判断**：M8 不以 headless 通过代替视觉完成，必须执行 Agent Vision 捕获、看图、评分与复查。
