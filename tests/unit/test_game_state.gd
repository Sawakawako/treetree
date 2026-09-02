extends GdUnitTestSuite

func test_initial_state() -> void:
    var s := GameState.new()
    assert_that(s.daylight.to_value()).is_equal(0.0)
    assert_that(s.sap.to_value()).is_equal(0.0)
    assert_that(s.growth.to_value()).is_equal(0.0)
    assert_that(s.leaf_level).is_equal(0)
    assert_that(s.branch_level).is_equal(0)
    assert_that(s.tick).is_equal(0)
    assert_that(s.hope).is_equal(1)

func test_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.daylight = BigNum.new(42.0)
    s.leaf_level = 3
    s.tick = 60
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.daylight.to_value()).is_equal_approx(42.0, 1e-4)
    assert_that(back.leaf_level).is_equal(3)
    assert_that(back.tick).is_equal(60)

func test_from_dict_missing_fields_fallback() -> void:
    var back := GameState.from_dict({"sap": {"m": 7.0, "e": 0}})
    assert_that(back.sap.to_value()).is_equal_approx(7.0, 1e-4)
    assert_that(back.leaf_level).is_equal(0)
    assert_that(back.hope).is_equal(1)

func test_new_fields_initial() -> void:
    var s := GameState.new()
    assert_that(s.memory.to_value()).is_equal(0.0)
    assert_that(s.faith.to_value()).is_equal(0.0)
    assert_that(s.root_depth).is_equal(0)
    assert_that(s.races.is_empty()).is_true()
    assert_that(s.relics_found).is_empty()

func test_new_fields_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.memory = BigNum.new(3.0)
    s.faith = BigNum.new(7.0)
    s.root_depth = 2
    s.races["human"] = {"awakened": true, "population": 50.0}
    s.relics_found.assign([1, 2])
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.memory.to_value()).is_equal_approx(3.0, 1e-4)
    assert_that(back.faith.to_value()).is_equal_approx(7.0, 1e-4)
    assert_that(back.root_depth).is_equal(2)
    assert_that(back.races["human"]["awakened"]).is_true()
    assert_that(back.relics_found).contains(1)

func test_old_save_fallback() -> void:
    # 旧档无新字段——from_dict 应回退默认不损坏
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.memory.to_value()).is_equal(0.0)
    assert_that(back.faith.to_value()).is_equal(0.0)
    assert_that(back.root_depth).is_equal(0)
    assert_that(back.races.is_empty()).is_true()
    assert_that(back.relics_found).is_empty()
    assert_that(back.tick).is_equal(5)

func test_from_dict_filters_invalid_relic_ids() -> void:
    # M2：损坏存档中的非数字 relics_found 元素应被过滤而非报错/静默变 0
    var back := GameState.from_dict({"relics_found": [1, "x", {"a": 1}, 3.0]})
    assert_that(back.relics_found.size()).is_equal(2)
    assert_that(back.relics_found).contains(1)
    assert_that(back.relics_found).contains(3)

func test_totem_fields_roundtrip() -> void:
    var s := GameState.new()
    s.totem_interpreted.assign([1, 3])
    s.insight = 2
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.totem_interpreted).contains(1)
    assert_that(back.totem_interpreted).contains(3)
    assert_that(back.insight).is_equal(2)

func test_totem_fields_missing_fallback() -> void:
    # M2/M3 旧档无 totem 字段——回退默认不损坏
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.totem_interpreted).is_empty()
    assert_that(back.insight).is_equal(0)

func test_from_dict_filters_invalid_totem_ids() -> void:
    var back := GameState.from_dict({"totem_interpreted": [1, "x", {"a": 1}, 3.0]})
    assert_that(back.totem_interpreted.size()).is_equal(2)
    assert_that(back.totem_interpreted).contains(1)
    assert_that(back.totem_interpreted).contains(3)

func test_relations_roundtrip() -> void:
    var s := GameState.new()
    s.relations["human"] = 2
    s.relations["wildfolk"] = -1
    s.relation_events.assign([&"human", &"wildfolk"])
    var back := GameState.from_dict(s.to_dict())
    assert_that(int(back.relations["human"])).is_equal(2)
    assert_that(int(back.relations["wildfolk"])).is_equal(-1)
    assert_that(back.relation_events).contains(&"human")
    assert_that(back.relation_events).contains(&"wildfolk")

func test_relations_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.relations.is_empty()).is_true()
    assert_that(back.relation_events).is_empty()

func test_from_dict_guards_corrupt_relations() -> void:
    # 损坏存档：relations 非字典 / 值非数字 → 回退或归一，不崩溃
    var back := GameState.from_dict({"relations": "corrupt"})
    assert_that(back.relations.is_empty()).is_true()
    var back2 := GameState.from_dict({"relations": {"human": "x", "wildfolk": 1.5}})
    assert_that(int(back2.relations.get("human", 0))).is_equal(0)
    assert_that(int(back2.relations["wildfolk"])).is_equal(1)

func test_races_serialization_roundtrip() -> void:
    var s := GameState.new()
    s.races["human"] = {"awakened": true, "population": 58.5}
    s.races["forestfolk"] = {"awakened": false, "population": 0.0}
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.races.has("human")).is_true()
    assert_that(back.races["human"]["awakened"]).is_true()
    assert_that(float(back.races["human"]["population"])).is_equal_approx(58.5, 1e-4)
    assert_that(back.races["forestfolk"]["awakened"]).is_false()

func test_old_save_human_awakened_migrates() -> void:
    # M2 旧档：无 races 但有 human_awakened —— 迁移人族状态
    var back := GameState.from_dict({"human_awakened": true, "tick": 5})
    assert_that(back.races.has("human")).is_true()
    assert_that(back.races["human"]["awakened"]).is_true()
    assert_that(float(back.races["human"]["population"])).is_equal_approx(50.0, 1e-4)

func test_races_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 1})
    assert_that(back.races.is_empty()).is_true()

func test_races_partial_entry_fallback() -> void:
    # races 条目缺 population —— 回退默认 0 不损坏
    var back := GameState.from_dict({"races": {"human": {"awakened": true}}})
    assert_that(float(back.races["human"]["population"])).is_equal_approx(0.0, 1e-4)

func test_races_corrupt_type_fallback() -> void:
    # 损坏存档：races 非字典 / 条目非字典 → 回退不崩溃
    var back := GameState.from_dict({"races": "corrupt"})
    assert_that(back.races.is_empty()).is_true()
    var back2 := GameState.from_dict({"races": {"human": "corrupt"}})
    assert_that(back2.races.is_empty()).is_true()

func test_plundered_roundtrip() -> void:
    var s := GameState.new()
    s.plundered["human"] = 3
    s.plundered["wildfolk"] = 1
    s.plunder_reveals.assign([&"human"])
    var back := GameState.from_dict(s.to_dict())
    assert_that(int(back.plundered["human"])).is_equal(3)
    assert_that(int(back.plundered["wildfolk"])).is_equal(1)
    assert_that(back.plunder_reveals).contains(&"human")

func test_plundered_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.plundered.is_empty()).is_true()
    assert_that(back.plunder_reveals).is_empty()

func test_from_dict_guards_corrupt_plundered() -> void:
    var back := GameState.from_dict({"plundered": "corrupt"})
    assert_that(back.plundered.is_empty()).is_true()
    var back2 := GameState.from_dict({"plundered": {"human": "x", "wildfolk": 2.5}})
    assert_that(int(back2.plundered.get("human", 0))).is_equal(0)
    assert_that(int(back2.plundered["wildfolk"])).is_equal(2)

func test_upgrade_levels_roundtrip() -> void:
    var s := GameState.new()
    s.chloroplast_level = 2
    s.xylem_level = 1
    s.sunflower_level = 3
    s.nautilus_level = 1
    s.root_eff_level = 2
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.chloroplast_level).is_equal(2)
    assert_that(back.xylem_level).is_equal(1)
    assert_that(back.sunflower_level).is_equal(3)
    assert_that(back.nautilus_level).is_equal(1)
    assert_that(back.root_eff_level).is_equal(2)

func test_upgrade_levels_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.chloroplast_level).is_equal(0)
    assert_that(back.xylem_level).is_equal(0)
    assert_that(back.sunflower_level).is_equal(0)
    assert_that(back.nautilus_level).is_equal(0)
    assert_that(back.root_eff_level).is_equal(0)

func test_intimate_events_roundtrip() -> void:
    var s := GameState.new()
    s.intimate_events.assign([&"human", &"wildfolk"])
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.intimate_events).contains(&"human")
    assert_that(back.intimate_events).contains(&"wildfolk")

func test_intimate_events_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.intimate_events).is_empty()

func test_from_dict_filters_invalid_intimate_events() -> void:
    var back := GameState.from_dict({"intimate_events": ["human", 1, {"a": 1}]})
    assert_that(back.intimate_events.size()).is_equal(1)
    assert_that(back.intimate_events).contains(&"human")

func test_soul_river_roundtrip() -> void:
    var s := GameState.new()
    s.soul_river = 88
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.soul_river).is_equal(88)

func test_soul_river_missing_fallback() -> void:
    # M5f 之前旧档无 soul_river —— 回退 100 不损坏
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.soul_river).is_equal(100)

func test_soul_river_corrupt_fallback() -> void:
    # 损坏存档：soul_river 非数字 → 回退 100 不崩溃
    var back := GameState.from_dict({"soul_river": "corrupt"})
    assert_that(back.soul_river).is_equal(100)

func test_m5g_fields_roundtrip() -> void:
    var s := GameState.new()
    s.choices_done.assign([&"human_nightmare", &"odin_sacrifice"])
    s.truth = 3
    s.drift_extra = 1.5
    s.race_memory_eff["human"] = 0.7
    s.choice_flags.assign([&"odin_name", &"ship_built"])
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.choices_done).contains(&"human_nightmare")
    assert_that(back.truth).is_equal(3)
    assert_that(back.drift_extra).is_equal_approx(1.5, 1e-4)
    assert_that(float(back.race_memory_eff["human"])).is_equal_approx(0.7, 1e-4)
    assert_that(back.choice_flags).contains(&"ship_built")

func test_m5g_fields_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.choices_done).is_empty()
    assert_that(back.truth).is_equal(0)
    assert_that(back.drift_extra).is_equal_approx(0.0, 1e-4)
    assert_that(back.race_memory_eff.is_empty()).is_true()
    assert_that(back.choice_flags).is_empty()

func test_m5g_fields_corrupt_fallback() -> void:
    var back := GameState.from_dict({"truth": "corrupt", "drift_extra": "corrupt", "race_memory_eff": "corrupt"})
    assert_that(back.truth).is_equal(0)
    assert_that(back.drift_extra).is_equal_approx(0.0, 1e-4)
    assert_that(back.race_memory_eff.is_empty()).is_true()

func test_m5g_stringname_arrays_filter_invalid() -> void:
    var back := GameState.from_dict({"choices_done": ["a", 1, {"x": 1}], "choice_flags": ["b", 2.0]})
    assert_that(back.choices_done.size()).is_equal(1)
    assert_that(back.choices_done).contains(&"a")
    assert_that(back.choice_flags.size()).is_equal(1)
    assert_that(back.choice_flags).contains(&"b")

func test_m5d2_fields_roundtrip() -> void:
    var s := GameState.new()
    s.seedling_level = 3
    s.firepit_level = 2
    s.ring_level = 1
    s.forge_level = 0
    s.totem_pole_level = 2
    s.deep_dream = true
    s.wind_veil = false
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.seedling_level).is_equal(3)
    assert_that(back.firepit_level).is_equal(2)
    assert_that(back.ring_level).is_equal(1)
    assert_that(back.forge_level).is_equal(0)
    assert_that(back.totem_pole_level).is_equal(2)
    assert_that(back.deep_dream).is_true()
    assert_that(back.wind_veil).is_false()

func test_m5d2_fields_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.seedling_level).is_equal(0)
    assert_that(back.firepit_level).is_equal(0)
    assert_that(back.ring_level).is_equal(0)
    assert_that(back.forge_level).is_equal(0)
    assert_that(back.totem_pole_level).is_equal(0)
    assert_that(back.deep_dream).is_false()
    assert_that(back.wind_veil).is_false()

func test_m5d2_fields_corrupt_fallback() -> void:
    var back := GameState.from_dict({"seedling_level": "corrupt", "deep_dream": "corrupt", "wind_veil": 1})
    assert_that(back.seedling_level).is_equal(0)
    assert_that(back.deep_dream).is_false()
    assert_that(back.wind_veil).is_false()

func test_m5e_fields_roundtrip() -> void:
    var s := GameState.new()
    s.faith_engine_level = 2
    s.memory_engine_level = 1
    s.lingua_life_level = 2
    s.lingua_memory_level = 0
    s.lingua_nodes.assign([&"tree_canopy", &"ring_memory"])
    var back := GameState.from_dict(s.to_dict())
    assert_that(back.faith_engine_level).is_equal(2)
    assert_that(back.memory_engine_level).is_equal(1)
    assert_that(back.lingua_life_level).is_equal(2)
    assert_that(back.lingua_memory_level).is_equal(0)
    assert_that(back.lingua_nodes).contains(&"tree_canopy")
    assert_that(back.lingua_nodes).contains(&"ring_memory")

func test_m5e_fields_missing_fallback() -> void:
    var back := GameState.from_dict({"tick": 5})
    assert_that(back.faith_engine_level).is_equal(0)
    assert_that(back.memory_engine_level).is_equal(0)
    assert_that(back.lingua_life_level).is_equal(0)
    assert_that(back.lingua_memory_level).is_equal(0)
    assert_that(back.lingua_nodes).is_empty()

func test_m5e_fields_corrupt_fallback() -> void:
    var back := GameState.from_dict({"faith_engine_level": "corrupt", "lingua_nodes": [1, {"a": 1}]})
    assert_that(back.faith_engine_level).is_equal(0)
    assert_that(back.lingua_nodes.size()).is_equal(0)
