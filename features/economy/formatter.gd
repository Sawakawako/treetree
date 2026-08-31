class_name Formatter
extends RefCounted

const SUFFIX := ["", "K", "M", "B", "T"]

static func format_number(bn: BigNum) -> String:
	if bn.mantissa == 0.0:
		return "0"
	var tier := bn.exponent / 3
	if tier == 0:
		var small := bn.to_value()
		var rounded: float = floor(small * 100.0) / 100.0
		return _trim_zeros(String.num(rounded, 2))
	var mant := bn.mantissa * pow(10.0, bn.exponent - tier * 3)
	var idx := mini(tier, SUFFIX.size() - 1)
	return "%s%s" % [_trim_zeros(String.num(mant, 2)), SUFFIX[idx]]

static func format_cost(cost: int) -> String:
	var s := str(cost)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out

static func _trim_zeros(s: String) -> String:
	if s.contains("."):
		var t := s.rstrip("0")
		if t.ends_with("."):
			t = t.trim_suffix(".")
		return t
	return s
