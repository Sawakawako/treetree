class_name GameState
extends RefCounted

var daylight: BigNum
var sap: BigNum
var growth: BigNum
var leaf_level: int = 0
var branch_level: int = 0
var tick: int = 0
var hope: int = 1

func _init() -> void:
    daylight = BigNum.new(0.0)
    sap = BigNum.new(0.0)
    growth = BigNum.new(0.0)

func to_dict() -> Dictionary:
    return {
        "daylight": daylight.to_dict(),
        "sap": sap.to_dict(),
        "growth": growth.to_dict(),
        "leaf_level": leaf_level,
        "branch_level": branch_level,
        "tick": tick,
        "hope": hope,
    }

static func from_dict(d: Dictionary) -> GameState:
    var s := GameState.new()
    s.daylight = BigNum.from_dict(d.get("daylight", {}))
    s.sap = BigNum.from_dict(d.get("sap", {}))
    s.growth = BigNum.from_dict(d.get("growth", {}))
    s.leaf_level = int(d.get("leaf_level", 0))
    s.branch_level = int(d.get("branch_level", 0))
    s.tick = int(d.get("tick", 0))
    s.hope = int(d.get("hope", 1))
    return s
