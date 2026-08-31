class_name TotemLibrary
extends RefCounted

const TOTEMS: Array[Dictionary] = [
	{
		"id": 1,
		"threshold": 0.0,
		"reveal_text": "石壁上多了一幅画。画的是一棵树——树冠遮天，根须伸进河流。河在变浅。",
		"interpret_text": "它们在画你。它们从第一天就在画你——你才知道，那不是风景，是证据。",
	},
	{
		"id": 2,
		"threshold": 4.0,
		"reveal_text": "画里多了一行小人。跪在树前，黑黑的一排，像种子。",
		"interpret_text": "那是人。活过、哭过、把名字刻进石头的人。你仔细看——它们的脸，正对着你。",
	},
	{
		"id": 3,
		"threshold": 10.0,
		"reveal_text": "树的根须，缠着什么东西。像拥抱，又像收紧。",
		"interpret_text": "它们不画仇恨。它们只画事实。你吞下去的，不止是梦。",
	},
	{
		"id": 4,
		"threshold": 20.0,
		"reveal_text": "画旁多了一双眼睛。不眨，看着你，已经看了很久。",
		"interpret_text": "那是野民的眼睛。也是你看自己的眼睛。中间没有隔着河。",
	},
	{
		"id": 5,
		"threshold": 35.0,
		"reveal_text": "画的角落里，树的倒影里，站着一个人影。树与人影，是同一个。",
		"interpret_text": "你想起自己醒来时，手里那一点希望。它从来不是火种。是最后的证据——旧世界记得你，你忘了你也是它。",
	},
]

static func all_totems() -> Array[Dictionary]:
	return TOTEMS

static func get_totem(id: int) -> Dictionary:
	for t in TOTEMS:
		if int(t.get("id", 0)) == id:
			return t
	return {}

static func totem_count() -> int:
	return TOTEMS.size()
