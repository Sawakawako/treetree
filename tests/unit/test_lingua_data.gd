extends GdUnitTestSuite

func test_life_costs_table() -> void:
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[1])).is_equal(0)   # Lv1 免费激活
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[2])).is_equal(200) # 设计 §5.1
	assert_that(int(LinguaData.LINGUA_LIFE_COSTS[3])).is_equal(800)

func test_memory_lv1_cost_and_cap() -> void:
	assert_that(LinguaData.memory_cost(0)).is_equal(500)
	assert_that(LinguaData.memory_cost(1)).is_equal(-1)

func test_nodes_registered() -> void:
	var nodes := LinguaData.all_nodes()
	# 批 1 注册：根枝 3 + 干枝 4 + 叶枝 4 = 11 节点（含聚落之心——M5d2 设施已落地）
	var ids: Array[StringName] = []
	for n in nodes:
		ids.append(StringName(str(n.get("id", ""))))
	assert_that(ids).contains(&"root_echo")     # 遗迹回声
	assert_that(ids).contains(&"root_resonance") # 根须共鸣
	assert_that(ids).contains(&"deep_root")     # 深层根须
	assert_that(ids).contains(&"tree_canopy")   # 树冠舒展
	assert_that(ids).contains(&"ring_memory")   # 年轮记忆
	assert_that(ids).contains(&"cloud_crown")   # 云冠
	assert_that(ids).contains(&"wood_heart")    # 木质强化
	assert_that(ids).contains(&"song_resonance")# 歌之共鸣
	assert_that(ids).contains(&"village_heart") # 聚落之心
	assert_that(ids).contains(&"grace")         # 恩泽
	assert_that(ids).contains(&"altar")         # 圣坛
	assert_that(ids).contains(&"earth_sense")   # 地脉感应
	assert_that(ids).contains(&"sky_light")     # 天光
	assert_that(nodes.size()).is_equal(19)

func test_m6d_adds_six_world_language_nodes() -> void:
	var ids: Array[StringName] = []
	for node: Dictionary in LinguaData.all_nodes():
		if StringName(node.get("language", &"life")) == &"world":
			ids.append(StringName(node.get("id", &"")))
	assert_that(ids).is_equal([
		&"world_trace", &"rain_name", &"river_hearing",
		&"sky_ladder", &"world_shaping", &"world_breath",
	])
	assert_that(LinguaData.all_nodes().size()).is_equal(19)
