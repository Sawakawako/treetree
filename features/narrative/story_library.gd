class_name StoryLibrary
extends RefCounted

const STORIES: Array[Dictionary] = [
	{
		"id": &"story_4",
		"kind": &"main",
		"order": 4,
		"title": "故事④·火边的人",
		"text": "说书人把一块旧炭放进火塘。\n炭没有燃，只在灰里亮了一下。\n\n她说，很久以前，有人守着一场梦。\n风来时，他替它掩好被角。\n天亮以后，梦里的人醒了。\n守梦的人却坐在火边，慢慢成了灰。\n\n她抬头看你。\n母树，有些梦不必属于谁。\n有人肯守着，就够了。",
		"conditions": {"flags_all": [&"cave_found", &"human_nightmare_protected"]},
		"effects": {"relation": {&"human": 0.5}, "flags": [&"storyteller_story_4"]},
	},
	{
		"id": &"story_5",
		"kind": &"main",
		"order": 5,
		"title": "故事⑤·带不走的火",
		"text": "第二夜，她讲一群渡河的人。\n它们带了种子、盐，还有一簇火。\n\n河水涨起来。\n种子湿了，盐化了。\n火被举在最高的那双手里。\n\n到岸时，那个人什么也没有带来。\n可所有人都围着他的空手取暖。\n\n说书人问：\n母树，留下来的，究竟是哪一簇火？",
		"conditions": {"story_done": &"story_4", "relation_gte": {&"human": 2.0}, "insight_gte": 5},
		"effects": {"flags": [&"storyteller_story_5"]},
	},
	{
		"id": &"story_6",
		"kind": &"main",
		"order": 6,
		"title": "故事⑥·向上落的光",
		"text": "最后一夜，她没有添柴。\n天裂的旧光，从灰里升起来。\n\n她说，第九日并没有太阳坠落。\n是大地把藏了太久的光，还给天空。\n城、河与人的梦，都跟着轻了一瞬。\n\n只有一粒种子留在原处。\n它抱住那些来不及升起的名字。\n根越扎越深，枝越伸越高。\n\n说书人的声音停了。\n母树，那粒种子……\n她没有说完。",
		"conditions": {"story_done": &"story_5", "flags_all": [&"sky_rift_observed"], "truth_gte": 4},
		"effects": {"insight": 1, "flags": [&"storyteller_story_6", &"storyteller_final_story"]},
	},
	{
		"id": &"stream_and_current",
		"kind": &"easter_egg",
		"order": 1,
		"title": "小溪与激流",
		"text": "说书人说，这个故事没有作者。\n只是一头路过的小牛，托她记住。\n\n小溪问激流：\n你走得那么快，要去哪里？\n\n激流说：去海里。\n小溪低头看了看脚边的花。\n我还想再待一会儿。\n\n许多年后，雨落进海里。\n海忽然想起，山脚有一朵花。\n它不知道，那是不是自己的记忆。",
		"conditions": {"story_done": &"story_4", "relation_gte": {&"human": 2.0}},
		"effects": {"flags": [&"storyteller_stream_and_current"]},
	},
]

static func all_stories() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for story in STORIES:
		out.append(story.duplicate(true))
	return out

static func get_story(id: StringName) -> Dictionary:
	for story in STORIES:
		if StringName(story.get("id", &"")) == id:
			return story.duplicate(true)
	return {}

static func story_count() -> int:
	return STORIES.size()

static func _ids_for_kind(kind: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for story in STORIES:
		if StringName(story.get("kind", &"")) == kind:
			out.append(StringName(story.get("id", &"")))
	return out

static func main_story_ids() -> Array[StringName]:
	return _ids_for_kind(&"main")

static func easter_egg_ids() -> Array[StringName]:
	return _ids_for_kind(&"easter_egg")
