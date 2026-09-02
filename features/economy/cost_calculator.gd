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

static func chloroplast_cost(level: int) -> int:
	return int(800.0 * pow(1.6, float(level)))

static func xylem_cost(level: int) -> int:
	return 50 * (level + 1)

static func sunflower_cost(level: int) -> int:
	return 2000 * fib(level + 1)

static func nautilus_cost(level: int) -> int:
	return 2000 * fib(level + 1)

static func root_eff_cost(level: int) -> int:
	return int(1000.0 * pow(1.8, float(level)))

static func seedling_cost(level: int) -> int:
	return 10 * (level + 1)

static func firepit_cost(level: int) -> int:
	return 1000 * fib(level + 1)

static func ring_cost(level: int) -> int:
	return 1000 * fib(level + 1)

static func forge_cost(level: int) -> int:
	return 1000 * fib(level + 1)

static func totem_pole_cost(level: int) -> int:
	return 1000 * fib(level + 1)

static func faith_engine_cost(level: int) -> int:
	return 200 * fib(level + 1)

static func memory_engine_cost(level: int) -> int:
	return 500 * fib(level + 1)
