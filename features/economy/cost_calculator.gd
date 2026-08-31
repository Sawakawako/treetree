class_name CostCalculator
extends RefCounted

static func fib(n: int) -> int:
	if n <= 0:
		return 0
	if n <= 2:
		return 1
	var a := 1
	var b := 1
	for i in range(3, n + 1):
		var t := a + b
		a = b
		b = t
	return b

static func leaf_cost(level: int) -> int:
	return 500 * fib(level + 1)

static func branch_cost(level: int) -> int:
	return 1200 * fib(level + 1)
