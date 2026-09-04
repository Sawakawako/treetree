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
    assert_that(str(result.get("reason", ""))).is_equal("insufficient_sap")
    assert_that(s.root_depth).is_equal(0)

func test_explore_all_relics_then_blocked() -> void:
    var s := GameState.new()
    for i in 4:
        s.sap = BigNum.new(200.0)
        var result := RootActions.explore(s)
        assert_that(result.get("ok", false)).is_true()
    # 隐藏遗迹门槛未满足时，第 5 次应被阻止
    s.sap = BigNum.new(200.0)
    var blocked := RootActions.explore(s)
    assert_that(blocked.get("ok", false)).is_false()
    assert_that(str(blocked.get("reason", ""))).is_equal("no_available_relic")
    assert_that(s.root_depth).is_equal(4)

func test_explore_distinguishes_all_relics_found() -> void:
    var s := GameState.new()
    s.sap = BigNum.new(200.0)
    s.relics_found.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
    var blocked := RootActions.explore(s)
    assert_that(blocked.get("ok", false)).is_false()
    assert_that(str(blocked.get("reason", ""))).is_equal("all_relics_found")

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

func test_hidden_relic_requires_unlock_conditions() -> void:
    var s := GameState.new()
    s.relics_found.assign([1, 2, 3, 4])
    s.sap = BigNum.new(200.0)
    s.memory = BigNum.new(19.99)
    assert_that(RootActions._next_relic(s).is_empty()).is_true()
    assert_that(RootActions.can_explore(s)).is_false()
    s.memory = BigNum.new(20.0)
    assert_that(int(RootActions._next_relic(s).get("id", 0))).is_equal(5)
    assert_that(RootActions.can_explore(s)).is_true()

func test_hidden_relic_chain_applies_rewards_and_flags_once() -> void:
    var s := GameState.new()
    s.relics_found.assign([1, 2, 3, 4])
    s.sap = BigNum.new(1000.0)
    s.memory = BigNum.new(50.0)
    s.insight = 5
    s.truth = 2
    s.races["human"] = {"awakened": true, "population": 50.0}
    for expected_id in [5, 6, 7, 8, 9]:
        var result := RootActions.explore(s)
        assert_that(result.get("ok", false)).is_true()
        assert_that(int(result.get("relic", {}).get("id", 0))).is_equal(expected_id)
    assert_that(s.relics_found.size()).is_equal(9)
    assert_that(s.memory.to_value()).is_equal_approx(55.0, 1e-4)
    assert_that(s.truth).is_equal(4)
    assert_that(s.insight).is_equal(7)
    for flag in [&"pandora_found", &"cave_found", &"dream_machine_found", &"sky_rift_observed", &"circular_ruins_revealed"]:
        assert_that(s.choice_flags).contains(flag)
    assert_that(RootActions.explore(s).get("ok", false)).is_false()

func test_cave_requires_human_awakened() -> void:
    var s := GameState.new()
    s.relics_found.assign([1, 2, 3, 4, 5])
    s.memory = BigNum.new(25.0)
    assert_that(RootActions._next_relic(s).is_empty()).is_true()
    s.races["human"] = {"awakened": true, "population": 50.0}
    assert_that(int(RootActions._next_relic(s).get("id", 0))).is_equal(6)
