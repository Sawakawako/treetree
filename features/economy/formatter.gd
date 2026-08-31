class_name Formatter
extends RefCounted

const SUFFIX := ["", "K", "M", "B", "T"]

static func format_number(bn: BigNum) -> String:
	if bn.mantissa == 0.0:
		return "0"
	var tier := bn.exponent / 3
	if tier <= 0:
		# 绝对值 < 1 的小数：直接显示原值（≤6 位有效小数，去尾零）
		var small := bn.to_value()
		return _trim_zeros(String.num(small, 6))
	var mant := bn.mantissa * pow(10.0, bn.exponent - tier * 3)
	var text := String.num(mant, 2)
	if text.begins_with("1000"):
		# 四舍五入进位（如 999.999 → "1000.00"）：升一档重算
		tier += 1
		mant = bn.mantissa * pow(10.0, bn.exponent - tier * 3)
		text = String.num(mant, 2)
	var idx := mini(tier, SUFFIX.size() - 1)
	return "%s%s" % [_trim_zeros(text), SUFFIX[idx]]

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
