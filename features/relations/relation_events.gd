class_name RelationEvents
extends RefCounted

const EVENTS: Array[Dictionary] = [
	{
		"race_id": &"human",
		"condition": "memory>=4",
		"text": "火塘生在你的根须旁边。火苗是她用记忆点的，烧得很小心。\n她说：天裂的那一天，有人把种子藏进了胸口。\n她不知道你在听。但你的根须听得懂。\n你的年轮里，有什么东西，轻轻动了一下。",
	},
	{
		"race_id": &"forestfolk",
		"condition": "faith>=20",
		"text": "他们围着你最老的那条根坐下，像围着一座圣坛。\n开口，先是一声低音，然后整片林子应和。\n歌声顺着根须爬上来，在你身体里走了一圈——\n你听见自己的年轮，也跟着唱了一节。\n唱完，他们不说话，只是把脸贴在树皮上，很久。",
	},
	{
		"race_id": &"stoneborn",
		"condition": "sap>=300",
		"text": "石裔在你南面的根下挖了一条槽，把熔化的石头浇进去。\n他们说，这是给你的地基——树站了太多年，该有人替它站一会儿。\n锤声落下来，一下，一下，像另一种心跳。\n你不确定那是他们的，还是你的。",
	},
	{
		"race_id": &"wildfolk",
		"condition": "totem>=2",
		"text": "夜里，野民在你根旁的石壁上画完第二幅画。\n画的还是那棵树，但树下多了一行脚印。\n脚印从画里伸出来，一直延伸到——你这里。\n他们没有叫你。但他们画的每一步，都像在问：要不要走出来？",
	},
]

static func get_event(race_id: StringName) -> Dictionary:
	for e in EVENTS:
		if e.get("race_id") == race_id:
			return e
	return {}

static func event_count() -> int:
	return EVENTS.size()
