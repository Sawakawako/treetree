class_name LinguaData
extends RefCounted

# 生命之语升级消耗（信仰）；Lv1 免费激活（设计 §5.1：Lv2=200/Lv3=800）
const LINGUA_LIFE_COSTS := {1: 0, 2: 200, 3: 800}
const LIFE_MAX_LEVEL := 3

# 节点表（设计 §5.2 批 1 注册 11 节点；tier: 1 初阶 2 中阶；聚落之心已实现——M5d2 设施落地，产出 ×1.5）
const NODES: Array[Dictionary] = [
	{"id": &"root_echo", "name": "遗迹回声", "branch": "root", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "遗迹文本回看"},
	{"id": &"root_resonance", "name": "根须共鸣", "branch": "root", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "解锁树液→记忆兑换"},
	{"id": &"deep_root", "name": "深层根须", "branch": "root", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "根须探索成本 -50%"},
	{"id": &"tree_canopy", "name": "树冠舒展", "branch": "trunk", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "解锁树液→信仰兑换"},
	{"id": &"ring_memory", "name": "年轮记忆", "branch": "trunk", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "生长 +20%"},
	{"id": &"cloud_crown", "name": "云冠", "branch": "trunk", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "解锁信仰引擎"},
	{"id": &"wood_heart", "name": "木质强化", "branch": "trunk", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "sap 上限 +50%"},
	{"id": &"song_resonance", "name": "歌之共鸣", "branch": "leaf", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "信仰产出 +10%"},
	{"id": &"village_heart", "name": "聚落之心", "branch": "leaf", "tier": 1, "requirement": 1, "sap_cost": 3000, "effect": "四族设施产出 +50%"},
	{"id": &"grace", "name": "恩泽", "branch": "leaf", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "解锁记忆引擎"},
	{"id": &"altar", "name": "圣坛", "branch": "leaf", "tier": 2, "requirement": 2, "sap_cost": 8000, "effect": "信仰引擎效果 ×2"},
]

static func all_nodes() -> Array[Dictionary]:
	return NODES

static func get_node(id: StringName) -> Dictionary:
	for n in NODES:
		if StringName(str(n.get("id", ""))) == id:
			return n
	return {}

static func life_cost(level: int) -> int:
	# level = 当前等级 → 升到 level+1 的成本
	if level >= LIFE_MAX_LEVEL:
		return -1
	return int(LINGUA_LIFE_COSTS.get(level + 1, 0))