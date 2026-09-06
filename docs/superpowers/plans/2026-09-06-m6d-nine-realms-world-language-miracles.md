# M6-D 九界 + 世界之语 + 奇迹实施计划

> 状态：执行中
> 设计基线：`docs/superpowers/specs/2026-09-06-world-tree-m6d-nine-realms-world-language-miracles-design.md`
> 方法：TDD；每批先写失败测试，再写最小实现。每批完成后跑相关套件，封板前跑全量 GdUnit4 与 Godot UI 冒烟。

## T1 数据定义与九界纯逻辑 ✅

- [x] 新增 RealmDefinition、九份神话世界 `.tres` 与 RealmCatalog。
- [x] 先写 `test_realm_actions.gd`：九界前置、资源原子扣款、重复防护、3/6/9 语阶。
- [x] 新增 GameState `realm_echoes`，完成读档清洗与周目保留测试。
- 完成证据：`test_realm_actions.gd` 9/9 通过；全量回归留到 T6。

## T2 世界之语第三语系 ✅

- [x] 向 LinguaData 加六个世界节点和通用 `prerequisites`。
- [x] LinguaActions 按 RealmActions 推导的世界语阶判门。
- [x] 世界节点周目重置；九界残响保留。
- 完成证据：`test_lingua_data/actions` 18/18 通过；全量 38 套件 / 450 测试通过。

## T3 五奇迹与系统效果

- [ ] 新增 MiracleDefinition、五份 `.tres`、MiracleCatalog、MiracleActions。
- [ ] 新增 GameState 奇迹运行字段和兼容迁移。
- [ ] 接入 RaceManager、GameLoop、PlunderActions、SoulActions。
- [ ] 覆盖绿洲承载、雨势、驱影复发、唤灵守恒、塑形倍率。
- 完成证据：奇迹、人口、夺梦、灵魂、离线相关测试通过。

## T4 终局与 GameManager 集成

- [ ] GameManager 增加探界、奇迹请求及信号。
- [ ] 世界之轴增加九响与 `world_breath` 门槛。
- [ ] 保证已进入 `pending_ending` 的旧存档继续结算。
- 完成证据：GameManager、EndingStateMachine 和 E2E 终局链通过。

## T5 低保真 UI 与内容

- [ ] 主界面增加冠/干/根三域九世界状态、六世界节点、五奇迹入口。
- [ ] 驱影/唤灵提供四族目标按钮；禁用态显示主要缺口。
- [ ] 写入九界和奇迹短文本，按文风六则与 stop-slop 自检。
- [ ] 420×640 视口检查滚动、遮挡、按钮状态和结局恢复。
- 完成证据：UI 静态测试、运行截图和一次手工链路记录。

## T6 平衡、回归与交接

- [ ] 写 `BALANCE_PLAN.md`：主指标为首轮九界耗时，次指标为信仰/记忆停滞时长。
- [ ] 用源数据驱动的确定性职业模拟检查 25—45 分钟目标；记录数值调整。
- [ ] Godot `--import` 后执行全量 GdUnit4；检查错误、失败、跳过、孤儿节点与导入副作用。
- [ ] 更新主设计冲突注、M6 主计划后置状态、CONTINUE、ROADMAP、AGENTS。
- [ ] Code review 后修复问题，提交到 `main`；推送前核对并获得远端仓库授权。
- 完成证据：全量测试、UI 验证、干净工作树、本地 HEAD；推送获准后验证 `HEAD == origin/main`。

## 风险顺序

1. 九次探索若只剩资源缴费，先改前置分叉与反馈，不追加更多界域。
2. 800 信仰和 300 记忆可能与现有引擎产出不匹配，必须从运行数据校准。
3. 单列 UI 已很长；优先折叠已完成界域，必要时再拆独立场景。
