class_name EndingArchive
extends RefCounted

const IDS: Array[StringName] = [&"bad", &"normal", &"good", &"true"]
const TITLES := {
	&"bad": "坏结局",
	&"normal": "普通结局",
	&"good": "好结局",
	&"true": "真结局",
}

const GOOD_BODY := "你把记忆一颗一颗还给亡者之河。\n不是交还——是偿还。是归还一笔欠了太久的债。\n「母树，你要去哪儿？」「去成为你们脚下的大地。」\n树缓缓倒下。不是死亡，是延伸。\n根系化作河流，树干化作山丘，年轮化作环形废墟。\n第一株不依赖树的幼苗，从树的影子里长出来。\n世界学会了自行生长。\n希望不再需要被燃烧了。它回到土壤里，像一颗种子。\n河底，终于安静了——那些被捞起又放下的灵魂，\n这一次可以不再被捞起，不再失忆。"
const TRUE_BODY := "「把希望用在自己身上。」\n你第一次把希望对准自己。记忆没有还回河里——你留下了它们。\n你记得一切：你是幸存者的灵魂，旧世界因何而亡，你做过的一切。\n树没有倒下。根须深入冥河，树冠刺破天界——\n你站在那里：记得一切的树，还活着的树。\n四族抬头望你：\n「母树，你记得了。」\n「我记得。而我还想活着。」"
const BAD_BODY := "灰落下来，没有人接住它。\n风穿过空荡荡的枝干——像穿过一扇忘记关的门。\n你没有读懂自己留下了什么。\n那一点希望还在原处，等着被点燃，或被种下。"
const NORMAL_BODY := "这一次你懂了：你曾吞噬，也曾被爱。\n只是爱还不够——不够让人留下，也不够让你放下。\n希望在你手里亮了一会儿，又暗下去。\n你带着这一点亮，走回梦里。"

static func get_entry(ending_id: StringName) -> Dictionary:
	if not IDS.has(ending_id):
		return {}
	var body := ""
	match ending_id:
		&"bad": body = BAD_BODY
		&"normal": body = NORMAL_BODY
		&"good": body = GOOD_BODY
		&"true": body = TRUE_BODY
	return {"id": ending_id, "title": TITLES[ending_id], "body": body}

static func settlement_view(outcome: StringName, hope_before: int, hope_after: int) -> Dictionary:
	var entry := get_entry(outcome)
	var loops := outcome != &"true"
	var body := str(entry.get("body", ""))
	var hope_line := ""
	match outcome:
		&"true":
			hope_line = "你把希望用在了自己身上。循环在这里停住。"
		&"good":
			body += "\n\n人族说书人的声音传来，很轻，带着笑：\n「母树，你种下的希望，发芽了。」"
			hope_line = "希望长了一点：%d → %d" % [hope_before, hope_after]
		&"normal", &"bad":
			hope_line = "希望没有变：%d" % hope_after
	return {
		"title": str(entry.get("title", "结局")),
		"body": body,
		"hope_line": hope_line,
		"action_text": "再次醒来" if loops else "回到标题",
		"loops": loops,
	}

