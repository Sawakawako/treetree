class_name AvatarTiers
extends RefCounted

const TIERS: Array[Dictionary] = [
	{"tier": 0, "min": 0.0, "max": 3.0, "text": "火塘边，你的影子晃了一下。像有个人，从树里探出头，又缩了回去。"},
	{"tier": 1, "min": 3.0, "max": 6.0, "text": "影子的轮廓清晰了一些。它站在你旁边，树皮的纹理在它身上慢慢退去。"},
	{"tier": 2, "min": 6.0, "max": 9.0, "text": "它的五官开始模糊。枝条从它的肩头长出来，它低头看了看，没有惊讶。"},
	{"tier": 3, "min": 9.0, "max": 10.0, "text": "只剩一个人形的影子。它站在你的树影里，分不清谁是谁。你忽然想不起，它叫什么名字。"},
]

static func tier_text(tier: int) -> String:
	for t in TIERS:
		if int(t.get("tier", -1)) == tier:
			return str(t.get("text", ""))
	return ""