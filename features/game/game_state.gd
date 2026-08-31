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
var races: Dictionary = {}
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
        "races": races,
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
    # M2 旧档迁移：无 races 但有 human_awakened —— 迁移人族状态
    var rd: Dictionary = d.get("races", {})
    if rd.is_empty() and d.has("human_awakened"):
        rd = {"human": {"awakened": bool(d.get("human_awakened", false)),
                "population": 50.0 if bool(d.get("human_awakened", false)) else 0.0}}
    s.races = {}
    for race_id: Variant in rd:
        var entry: Dictionary = rd[race_id]
        s.races[race_id] = {
            "awakened": bool(entry.get("awakened", false)),
            "population": float(entry.get("population", 0.0)),
        }
    var rf: Array = d.get("relics_found", [])
    var cleaned: Array = []
    for x in rf:
        if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
            cleaned.append(int(x))
    s.relics_found.assign(cleaned)
    return s
