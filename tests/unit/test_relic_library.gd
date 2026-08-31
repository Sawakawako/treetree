extends GdUnitTestSuite

func test_relic_count() -> void:
    assert_that(RelicLibrary.relic_count()).is_equal(4)

func test_get_relic() -> void:
    var r := RelicLibrary.get_relic(1)
    assert_that(r.get("id", 0)).is_equal(1)
    assert_that(r.has("name")).is_true()
    assert_that(r.has("dream_text")).is_true()
    assert_that(r.has("reward_memory")).is_true()

func test_get_missing_relic_returns_empty() -> void:
    var r := RelicLibrary.get_relic(99)
    assert_that(r.is_empty()).is_true()

func test_all_relics_have_unique_ids() -> void:
    var ids: Array = []
    for r in RelicLibrary.all_relics():
        var id: int = r.get("id", 0)
        assert_that(ids.has(id)).is_false()
        ids.append(id)

func test_returns_copies_not_shared() -> void:
    # M3：get_relic/all_relics 应返回副本，调用方篡改不得污染 const 数据表
    var r := RelicLibrary.get_relic(1)
    r["name"] = "被篡改"
    assert_that(RelicLibrary.get_relic(1).get("name", "")).is_equal("城市废墟")
    var all := RelicLibrary.all_relics()
    all[0]["name"] = "被篡改"
    assert_that(RelicLibrary.get_relic(1).get("name", "")).is_equal("城市废墟")
