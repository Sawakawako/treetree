class_name ReturnSequence
extends RefCounted

const STEPS := 7
const MAX_PARTIAL_STEP := 4
const PARTIAL_HALT_AFTER := 4  # normal/bad 拆到第 4 步后停

# 周目 × 步 → 文本。3 周目 × 7 步（全套差分）。文风六则。
const TEXTS := {
	1: {
		1: "你把叶子和光一起放下。树冠低了，天空重了一点。",
		2: "你拆下每一根枝。它们落进土里，变成别的树的骨架。",
		3: "你把根须一根一根从河里拔出来。河面泛起细小的涟漪——像告别。",
		4: "年轮一圈一圈松开。每一圈，都是你活过的一年。",
		5: "你把捞起的灵魂轻轻放回河底。它们下沉的时候，没有挣扎。",
		6: "最后，你低头看那点希望。你没有凝成什么——你把它种进了土壤。",
		7: "你看着自己。你不再是树了。你是一颗种子。一颗什么都不记得，但什么都愿意再试一次的种子。",
	},
	2: {
		1: "TASK4_RUN2_STEP1",
		2: "TASK4_RUN2_STEP2",
		3: "TASK4_RUN2_STEP3",
		4: "TASK4_RUN2_STEP4",
		5: "TASK4_RUN2_STEP5",
		6: "TASK4_RUN2_STEP6",
		7: "TASK4_RUN2_STEP7",
	},
	3: {
		1: "TASK4_RUN3_STEP1",
		2: "TASK4_RUN3_STEP2",
		3: "TASK4_RUN3_STEP3",
		4: "TASK4_RUN3_STEP4",
		5: "TASK4_RUN3_STEP5",
		6: "TASK4_RUN3_STEP6",
		7: "TASK4_RUN3_STEP7",
	},
}

# 普通/坏「拆到一半，忽然舍不得」停步文本（周目差分）
const HALT_TEXTS := {
	1: "你拆到一半，忽然舍不得了。你把剩下的部分拢了拢，凝成一点希望。",
	2: "TASK4_HALT_RUN2",
	3: "TASK4_HALT_RUN3",
}

static func text_for(run: int, step: int) -> String:
	var run_map: Dictionary = TEXTS.get(run, {})
	return str(run_map.get(step, ""))

static func halt_text(run: int) -> String:
	return str(HALT_TEXTS.get(run, ""))

static func max_step_for(outcome: StringName) -> int:
	if outcome == &"good" or outcome == &"true":
		return STEPS
	return MAX_PARTIAL_STEP
