class_name BigNum
extends RefCounted

var mantissa: float = 0.0
var exponent: int = 0

func _init(v: float = 0.0) -> void:
    set_value(v)

func set_value(v: float) -> void:
    if v == 0.0:
        mantissa = 0.0
        exponent = 0
        return
    exponent = int(floor(log(abs(v)) / log(10.0)))
    mantissa = v / pow(10.0, exponent)
    _normalize()

func _normalize() -> void:
    if mantissa == 0.0:
        exponent = 0
        return
    var e := int(floor(log(abs(mantissa)) / log(10.0)))
    if e != 0:
        mantissa /= pow(10.0, e)
        exponent += e

func add(other: BigNum) -> void:
    if other.mantissa == 0.0:
        return
    var e := maxi(exponent, other.exponent)
    var a := mantissa * pow(10.0, exponent - e)
    var b := other.mantissa * pow(10.0, other.exponent - e)
    mantissa = a + b
    exponent = e
    _normalize()

func sub(other: BigNum) -> void:
    var neg := BigNum.new()
    neg.mantissa = -other.mantissa
    neg.exponent = other.exponent
    add(neg)

func mul_scalar(f: float) -> BigNum:
    var out := BigNum.new()
    out.mantissa = mantissa * f
    out.exponent = exponent
    out._normalize()
    return out

func is_greater_or_equal(other: BigNum) -> bool:
    # 零以 exponent=0 规范化，必须在比较指数前单独处理；否则 0 会被误判为 >= 0.1。
    if mantissa == 0.0:
        return other.mantissa <= 0.0
    if other.mantissa == 0.0:
        return mantissa >= 0.0
    var self_neg := mantissa < 0.0
    var other_neg := other.mantissa < 0.0
    if self_neg != other_neg:
        return other_neg
    if self_neg:
        if exponent != other.exponent:
            return exponent < other.exponent
        return mantissa >= other.mantissa
    if exponent != other.exponent:
        return exponent > other.exponent
    return mantissa >= other.mantissa

func to_value() -> float:
    return mantissa * pow(10.0, exponent)

func to_dict() -> Dictionary:
    return {"m": mantissa, "e": exponent}

static func from_dict(d: Dictionary) -> BigNum:
    var bn := BigNum.new()
    bn.mantissa = float(d.get("m", 0.0))
    bn.exponent = int(d.get("e", 0))
    bn._normalize()
    return bn
