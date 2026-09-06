class_name RunBoost
extends RefCounted

# 三周目浓缩快进（spec §8.6）：开局赠予，直扑终局。数值估值待试玩调优。
const BOOST_SAP := 5000.0
const BOOST_MEMORY := 80.0
const BOOST_FAITH := 200.0
const BOOST_GROWTH := 600.0
const BOOST_LEAF := 3
const BOOST_ROOT := 3
const BOOST_LIFE_LV := 2
const BOOST_FLAGS: Array[StringName] = [&"tree_canopy", &"root_resonance", &"cloud_crown", &"grace"]

static func apply_boost(state: GameState) -> void:
	if state.run_number < 3:
		return
	state.sap.add(BigNum.new(BOOST_SAP))
	state.memory.add(BigNum.new(BOOST_MEMORY))
	state.faith.add(BigNum.new(BOOST_FAITH))
	state.growth.add(BigNum.new(BOOST_GROWTH))
	state.leaf_level = maxi(state.leaf_level, BOOST_LEAF)
	state.root_depth = maxi(state.root_depth, BOOST_ROOT)
	state.lingua_life_level = maxi(state.lingua_life_level, BOOST_LIFE_LV)
	for f in BOOST_FLAGS:
		if not state.choice_flags.has(f):
			state.choice_flags.append(f)
	# 明选全开：已完成卡保留（跨周目知识 flag），本局可触发卡正常轮询
