class_name GameLoop
extends RefCounted

static func sap_cap(state: GameState) -> float:
    var base := 10000.0 + 5000.0 * float(state.nautilus_level)
    if state.lingua_nodes.has(&"wood_heart"):
        base *= 1.5
    return base + 5000.0 * float(MiracleActions.count(state, &"shape"))

static func tick(state: GameState) -> void:
    state.tick += 1
    var eff := 1.0 + 0.25 * float(state.leaf_level)
    var collected := BigNum.new(float(state.branch_level) * eff)
    state.daylight.add(collected)
    # 光合（树液转化）——叶绿体：0.1 + 0.01×L
    var converted := state.daylight.mul_scalar(0.1 + 0.01 * float(state.chloroplast_level))
    state.sap.add(converted)
    # 生长（树高转化）——木质部：0.01 × (1 + 0.05×L)；年轮记忆 ×1.2（M5e）
    var ring_mult := 1.2 if state.lingua_nodes.has(&"ring_memory") else 1.0
    var shape_mult := 1.0 + 0.1 * float(MiracleActions.count(state, &"shape"))
    var grown := state.sap.mul_scalar(0.01 * (1.0 + 0.05 * float(state.xylem_level)) * ring_mult * shape_mult)
    state.growth.add(grown)
    # 树液 clamp 到储量上限（宽裕版）
    state.sap = BigNum.new(minf(state.sap.to_value(), sap_cap(state)))

static func should_auto_save(state: GameState) -> bool:
    return state.tick > 0 and state.tick % 60 == 0
