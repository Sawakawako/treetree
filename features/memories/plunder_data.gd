class_name PlunderData
extends RefCounted

const DATA: Array[Dictionary] = [
	{
		"race_id": &"human",
		"yield": 1.0,
		"signals": [
			"她说故事的时候，停了一下。像在数着什么。",
			"火塘的火，比上次小了一些。",
			"她看了你一眼。很快移开。",
		],
		"reveals": [
			"你忽然想起来——你已经听了她 3 次梦。故事不是讲到一半停住的。是她每次讲完，都觉得少了什么。",
			"火塘还亮着。但她讲故事的时候，会用手捂着嘴——像怕梦从嘴里漏出来。",
			"她不再看你了。她对着火塘讲，讲给没有人听。你才知道，你把她梦里的那个人，一点一点，借走了。",
		],
	},
	{
		"race_id": &"forestfolk",
		"yield": 1.2,
		"signals": [
			"歌会散了之后，有个人回头看了你的根，很久。",
			"萤光。好像比昨天暗了一点。",
			"有一首歌，他们今天没唱。没有人提起。",
		],
		"reveals": [
			"歌会照常。但你数了一下——今天的歌，比昨天少了一首。没有人注意到。除了你。",
			"有棵树下，坐着一个不唱歌的林地民。她看着自己的手，像在看一件坏掉的乐器。",
			"萤光熄了大半。他们还在唱，唱给谁听呢——树不说话。树把它们的歌，都收进了年轮。",
		],
	},
	{
		"race_id": &"wildfolk",
		"yield": 2.0,
		"signals": [
			"夜里，石壁前多了一双眼睛。",
			"画里那棵树，根须好像粗了一圈。",
			"风声里，有一声很轻的，像是叹息。",
		],
		"reveals": [
			"夜里，石壁上的画多了一幅：一棵树，根须伸进河流，河底躺着很多萤火虫。",
			"野民不再靠近你的根了。他们绕路。画里的树，越长越大，越画越像——一张嘴。",
			"它们在石壁上画完了最后一幅：树在吞噬。树冠是嘴，根须是舌。你盯着看了很久——忽然认出，那就是你。",
		],
	},
	{
		"race_id": &"stoneborn",
		"yield": 0.0,
		"signals": [
			"你伸向它们。它们摊开手——手里是锤子和凿子。「我们没有梦。」它们说。「我们只有手，和接下来要造的东西。」",
		],
		"reveals": [],
	},
]

static func get_data(race_id: StringName) -> Dictionary:
	for d in DATA:
		if d.get("race_id") == race_id:
			return d
	return {}

static func signal_text(race_id: StringName, plundered_count: int) -> String:
	var d := get_data(race_id)
	var signals: Array = d.get("signals", [])
	if signals.is_empty():
		return ""
	return str(signals[plundered_count % signals.size()])