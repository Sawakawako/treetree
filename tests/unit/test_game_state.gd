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
