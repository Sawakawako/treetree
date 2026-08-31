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
