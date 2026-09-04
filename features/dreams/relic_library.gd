class_name RelicLibrary
extends RefCounted

const RELICS: Array[Dictionary] = [
	{
		"id": 1,
		"name": "城市废墟",
		"dream_text": "你触到一块刻字的石板。\n字你不认得。\n但你的根须认得——\n它在土里埋了太久，连石头都开始忘记。\n\n你在梦里看见一座会发光的城市。\n人们走在街上。\n没有人抬头看天。",
		"reward": {"memory": 1.0},
		"unlock": {},
		"flags": [],
	},
	{
		"id": 2,
		"name": "陵墓",
		"dream_text": "石板下有棺。\n棺里有骨。\n骨上有指纹——\n是有人把手按在泥土上留下的。\n\n这些\"它\"，曾经是\"他们\"。",
		"reward": {"memory": 1.0},
		"unlock": {},
		"flags": [],
	},
	{
		"id": 3,
		"name": "梦田",
		"dream_text": "这里的土是甜的。\n旧世界的梦沉得太深，化成了肥料。\n\n你吸了一口。\n尝到了许多人的一生。",
		"reward": {"memory": 1.0},
		"unlock": {},
		"flags": [],
	},
	{
		"id": 4,
		"name": "命运之泉",
		"dream_text": "泉已经干了。\n但泉底还有一圈湿痕——\n圆的，像什么曾经在这里坐了很久。\n\n你想起自己醒来时，\n手里那一点希望。\n\n它的形状，和这圈湿痕一样。",
		"reward": {"memory": 1.0},
		"unlock": {},
		"flags": [],
	},
	{
		"id": 5,
		"name": "潘多拉遗迹",
		"dream_text": "你挖到一只盒子。\n没有锁。\n盒盖内侧，留着一句已经褪色的话：\n不要打开。\n\n你的根须停在缝隙前。\n里面没有声音。\n只有一粒很旧的光，在等谁先眨眼。",
		"reward": {"memory": 1.0},
		"unlock": {"relic_found": 4, "memory_gte": 20.0},
		"flags": [&"pandora_found"],
	},
	{
		"id": 6,
		"name": "洞穴遗址",
		"dream_text": "洞穴很浅。\n回声却藏得很深。\n墙上留着火烟，地上留着围坐的痕迹。\n\n有人在这里讲过故事。\n最后一句，没有写完。\n你的根须碰到句号的位置。\n泥土轻轻暖了一下。",
		"reward": {"memory": 1.0},
		"unlock": {"relic_found": 5, "race_awakened": "human", "memory_gte": 25.0},
		"flags": [&"cave_found"],
	},
	{
		"id": 7,
		"name": "梦想机",
		"dream_text": "玻璃槽还是温的。\n细管从空床垂下来，像没有落进土里的根。\n每只枕头旁，都写着同一句话：\n不要叫醒我。\n\n机器还在做梦。\n梦里没有风。\n所以花，一直没有谢。",
		"reward": {"memory": 1.0},
		"unlock": {"relic_found": 6, "insight_gte": 5},
		"flags": [&"dream_machine_found"],
	},
	{
		"id": 8,
		"name": "天裂观测站",
		"dream_text": "塔顶的镜片，仍朝着裂开的天空。\n它记下第九日的光。\n那道光不是落下。\n是从地面，升了回去。\n\n你看见自己的影子向天伸长。\n像很久以前，\n有什么从你身上离开。",
		"reward": {"memory": 1.0, "truth": 2},
		"unlock": {"relic_found": 7, "truth_gte": 2},
		"flags": [&"sky_rift_observed"],
	},
	{
		"id": 9,
		"name": "环形废墟",
		"dream_text": "废墟没有门。\n只有一圈向内倒下的墙。\n墙边摆着许多空椅子。\n都朝着中央。\n\n你的根须伸进那片空地。\n碰到一道熟悉的伤痕。\n原来这个圆，不是一堵墙。\n它曾经想抱住什么，只是忘了松手。",
		"reward": {"memory": 1.0, "insight": 2},
		"unlock": {"relic_found": 8, "truth_gte": 4, "memory_gte": 50.0},
		"flags": [&"circular_ruins_revealed"],
	},
]

static func all_relics() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in RELICS:
		out.append(r.duplicate(true))
	return out

static func get_relic(id: int) -> Dictionary:
	for r in RELICS:
		if r.get("id", 0) == id:
			return r.duplicate(true)
	return {}

static func relic_count() -> int:
	return RELICS.size()
