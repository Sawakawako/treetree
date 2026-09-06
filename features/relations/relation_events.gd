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

# M6 二周目新增事件（run_gte=2；每族 3 个各 +0.5，补足两族到 +3 → 12/12）
const EXTRA_EVENTS: Array[Dictionary] = [
	# 石裔 ×3 —— 二周目「你记得」主题
	{"event_id": &"stoneborn_r2a", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=300",
		"text": "一个石裔在你根旁停下，看了很久。\n它说：这圈刻痕，我来过。\n你低头。那是上一轮的你，靠过的地方。\n它没有多问。只是把工具放下，陪你坐了一会儿。"},
	{"event_id": &"stoneborn_r2b", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=600",
		"text": "石裔抬来一块碑。\n碑上没有字，只有一道断痕——\n是你上一轮折断的根须的形状。\n为首的石裔说：我们照着记忆打的。\n它没说为谁打的。但碑立在你面前时，\n你听见所有锤声，都静了一下。"},
	{"event_id": &"stoneborn_r2c", "race_id": &"stoneborn", "run_gte": 2, "condition": "sap>=900",
		"text": "夜里，一个年轻的石裔问你：\n母树，你这次还会走吗。\n它问得很轻，像怕惊醒什么。\n你没有回答。\n它把一块温热的石头放进你的根隙。\n说：不走的话，这个给你垫着。"},
	# 野民 ×3
	{"event_id": &"wildfolk_r2a", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=2",
		"text": "野民在你根旁画了一幅新画。\n画的是树——可那棵树，比你老。\n老得像上一轮。\n画完，他们没有走。\n他们看着画，又看着你，像在确认什么。"},
	{"event_id": &"wildfolk_r2b", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=4",
		"text": "野民首领把火把举到图腾前。\n图腾上的眼睛，正对着你。\n他说：这双眼睛，见过你两次了。\n第一次，你还不认得自己。\n他顿了顿。\n这一次，你认得吗？"},
	{"event_id": &"wildfolk_r2c", "race_id": &"wildfolk", "run_gte": 2, "condition": "totem>=5",
		"text": "夜里，野民围着火堆唱歌。\n唱到一半，他们忽然改了词——\n唱的是河。河底的东西，一样一样浮上来，又沉回去。\n你听懂了。\n那是你上一轮，还给河的记忆。\n他们把那些记忆编成了歌。\n唱完，首领朝你的方向举了举杯。\n像敬一位老友。"},
]

static func extra_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in EXTRA_EVENTS:
		out.append(e.duplicate(true))
	return out

static func get_extra_event(event_id: StringName) -> Dictionary:
	for e in EXTRA_EVENTS:
		if e.get("event_id") == event_id:
			return e.duplicate(true)
	return {}
