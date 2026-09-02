extends GdUnitTestSuite

func test_explore_first_relic() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    var result := RootActions.explore(s)
    assert_that(result.get("ok", false)).is_true()
    assert_that(s.root_depth).is_equal(1)
    assert_that(s.memory.to_value()).is_equal_approx(1.0, 1e-4)
    assert_that(s.sap.to_value()).is_equal_approx(0.0, 1e-4)
    assert_that(s.relics_found.size()).is_equal(1)

func test_explore_insufficient_sap() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(199.0)
    var result := RootActions.explore(s)
    assert_that(result.get("ok", false)).is_false()
    assert_that(s.root_depth).is_equal(0)

func test_explore_all_relics_then_blocked() -> void:
    var s := GameState.new()
    for i in RelicLibrary.relic_count():
        s.sap = BigNum.new(200.0)
        var result := RootActions.explore(s)
        assert_that(result.get("ok", false)).is_true()
    # 第 5 次应被阻止（遗迹耗尽）
    s.sap = BigNum.new(200.0)
    var blocked := RootActions.explore(s)
    assert_that(blocked.get("ok", false)).is_false()
    assert_that(s.root_depth).is_equal(RelicLibrary.relic_count())

func test_can_explore() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    assert_that(RootActions.can_explore(s)).is_true()
    s.sap = BigNum.new(199.0)
    assert_that(RootActions.can_explore(s)).is_false()

func test_explore_picks_next_unexplored_relic() -> void:
    # I1：遗迹选择必须以 relics_found 为准，不能假定 id == root_depth+1
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    s.relics_found.assign([1, 3, 4])
    var result := RootActions.explore(s)
    assert_that(result.get("ok", false)).is_true()
    assert_that(int(result.get("relic", {}).get("id", 0))).is_equal(2)
    assert_that(s.relics_found).contains(2)
    assert_that(s.root_depth).is_equal(1)

func test_deep_root_halves_explore_cost() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(150.0)
    assert_that(RootActions.can_explore(s)).is_false()  # 无节点 200 不够
    s.sap = BigNum.new(250.0)
    assert_that(RootActions.can_explore(s)).is_true()
    # 有 deep_root：100 即可
    var s2 := GameState.new()
    s2.lingua_nodes.assign([&"deep_root"])
    s2.sap = BigNum.new(100.0)
    assert_that(RootActions.can_explore(s2)).is_true()
    var r := RootActions.explore(s2)
    assert_that(r.get("ok", false)).is_true()
    assert_that(s2.sap.to_value()).is_equal_approx(0.0, 1e-4)  # 100-100 半价
