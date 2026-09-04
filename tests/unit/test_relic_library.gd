extends GdUnitTestSuite

func test_relic_count() -> void:
    assert_that(RelicLibrary.relic_count()).is_equal(9)

func test_get_relic() -> void:
    var r := RelicLibrary.get_relic(1)
    assert_that(r.get("id", 0)).is_equal(1)
    assert_that(r.has("name")).is_true()
    assert_that(r.has("dream_text")).is_true()
    assert_that(r.has("reward")).is_true()
    assert_that(r.has("unlock")).is_true()
    assert_that(r.has("flags")).is_true()
    assert_that(float(r.get("reward", {}).get("memory", 0.0))).is_equal_approx(1.0, 1e-4)

func test_get_missing_relic_returns_empty() -> void:
    var r := RelicLibrary.get_relic(99)
    assert_that(r.is_empty()).is_true()

func test_all_relics_have_unique_ids() -> void:
    var ids: Array = []
    for r in RelicLibrary.all_relics():
        var id: int = r.get("id", 0)
        assert_that(ids.has(id)).is_false()
        ids.append(id)

func test_all_relics_have_complete_schema() -> void:
    for r in RelicLibrary.all_relics():
        assert_that(int(r.get("id", 0))).is_greater(0)
        assert_that(str(r.get("name", "")).is_empty()).is_false()
        assert_that(str(r.get("dream_text", "")).is_empty()).is_false()
        assert_that(typeof(r.get("reward", null))).is_equal(TYPE_DICTIONARY)
        assert_that(typeof(r.get("unlock", null))).is_equal(TYPE_DICTIONARY)
        assert_that(typeof(r.get("flags", null))).is_equal(TYPE_ARRAY)

func test_hidden_relic_ids_names_and_contracts() -> void:
    var expected := {
        5: "潘多拉遗迹",
        6: "洞穴遗址",
        7: "梦想机",
        8: "天裂观测站",
        9: "环形废墟",
    }
    for id in expected:
        var r := RelicLibrary.get_relic(id)
        assert_that(str(r.get("name", ""))).is_equal(expected[id])
        assert_that(float(r.get("reward", {}).get("memory", 0.0))).is_equal_approx(1.0, 1e-4)
    assert_that(RelicLibrary.get_relic(5).get("flags", [])).contains(&"pandora_found")
    assert_that(RelicLibrary.get_relic(6).get("flags", [])).contains(&"cave_found")
    assert_that(RelicLibrary.get_relic(7).get("flags", [])).contains(&"dream_machine_found")
    assert_that(float(RelicLibrary.get_relic(8).get("reward", {}).get("truth", 0))).is_equal_approx(2.0, 1e-4)
    assert_that(float(RelicLibrary.get_relic(9).get("reward", {}).get("insight", 0))).is_equal_approx(2.0, 1e-4)

func test_returns_copies_not_shared() -> void:
    # M3：get_relic/all_relics 应返回副本，调用方篡改不得污染 const 数据表
    var r := RelicLibrary.get_relic(1)
    r["name"] = "被篡改"
    assert_that(RelicLibrary.get_relic(1).get("name", "")).is_equal("城市废墟")
    var all := RelicLibrary.all_relics()
    all[0]["name"] = "被篡改"
    assert_that(RelicLibrary.get_relic(1).get("name", "")).is_equal("城市废墟")
    var hidden := RelicLibrary.get_relic(5)
    hidden["reward"]["memory"] = 99.0
    hidden["flags"].append(&"polluted")
    assert_that(float(RelicLibrary.get_relic(5).get("reward", {}).get("memory", 0.0))).is_equal_approx(1.0, 1e-4)
    assert_that(RelicLibrary.get_relic(5).get("flags", []).has(&"polluted")).is_false()
