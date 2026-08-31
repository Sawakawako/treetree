class_name GameState
extends RefCounted

var daylight: BigNum
var sap: BigNum
var growth: BigNum
var memory: BigNum
var faith: BigNum
var leaf_level: int = 0
var branch_level: int = 0
var root_depth: int = 0
var tick: int = 0
var hope: int = 1
var human_awakened: bool = false
var relics_found: Array[int] = []

func _init() -> void:
    daylight = BigNum.new(0.0)
    sap = BigNum.new(0.0)
    growth = BigNum.new(0.0)
    memory = BigNum.new(0.0)
    faith = BigNum.new(0.0)

func to_dict() -> Dictionary:
    return {
        "daylight": daylight.to_dict(),
        "sap": sap.to_dict(),
        "growth": growth.to_dict(),
        "memory": memory.to_dict(),
        "faith": faith.to_dict(),
        "leaf_level": leaf_level,
        "branch_level": branch_level,
        "root_depth": root_depth,
        "tick": tick,
        "hope": hope,
        "human_awakened": human_awakened,
        "relics_found": relics_found,
    }

static func from_dict(d: Dictionary) -> GameState:
    var s := GameState.new()
    s.daylight = BigNum.from_dict(d.get("daylight", {}))
    s.sap = BigNum.from_dict(d.get("sap", {}))
    s.growth = BigNum.from_dict(d.get("growth", {}))
    s.memory = BigNum.from_dict(d.get("memory", {}))
    s.faith = BigNum.from_dict(d.get("faith", {}))
    s.leaf_level = int(d.get("leaf_level", 0))
    s.branch_level = int(d.get("branch_level", 0))
    s.root_depth = int(d.get("root_depth", 0))
    s.tick = int(d.get("tick", 0))
    s.hope = int(d.get("hope", 1))
    s.human_awakened = bool(d.get("human_awakened", false))
    var rf: Array = d.get("relics_found", [])
    s.relics_found.assign(rf.map(func(x): return int(x)))
    return s
