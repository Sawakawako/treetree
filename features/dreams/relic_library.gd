class_name RelicLibrary
extends RefCounted

const RELICS: Array[Dictionary] = [
	{
		"id": 1,
		"name": "城市废墟",
		"dream_text": "你触到一块刻字的石板。\n字你不认得。\n但你的根须认得——\n它在土里埋了太久，连石头都开始忘记。\n\n你在梦里看见一座会发光的城市。\n人们走在街上。\n没有人抬头看天。",
		"reward_memory": 1.0,
	},
	{
		"id": 2,
		"name": "陵墓",
		"dream_text": "石板下有棺。\n棺里有骨。\n骨上有指纹——\n是有人把手按在泥土上留下的。\n\n你第一次意识到：\n这些\"它\"，曾经是\"他们\"。",
		"reward_memory": 1.0,
	},
	{
		"id": 3,
		"name": "梦田",
		"dream_text": "这里的土是甜的。\n旧世界的梦沉得太深，化成了肥料。\n\n你吸了一口。\n尝到了许多人的一生。",
		"reward_memory": 1.0,
	},
	{
		"id": 4,
		"name": "命运之泉",
		"dream_text": "泉已经干了。\n但泉底还有一圈湿痕——\n圆的，像什么曾经在这里坐了很久。\n\n你想起自己醒来时，\n手里那一点希望。\n\n它的形状，和这圈湿痕一样。",
		"reward_memory": 1.0,
	},
]

static func all_relics() -> Array[Dictionary]:
	return RELICS

static func get_relic(id: int) -> Dictionary:
	for r in RELICS:
		if r.get("id", 0) == id:
			return r
	return {}

static func relic_count() -> int:
	return RELICS.size()
