extends GdUnitTestSuite

func _awaken(state: GameState, id: StringName) -> void:
    state.races[id] = {"awakened": true, "population": 50.0}

func test_river_default_100() -> void:
    var s := GameState.new()
    assert_that(SoulActions.river(s)).is_equal(100)

func test_can_revive_requires_awakened() -> void:
    var s := GameState.new()
    s.growth = BigNum.new(500.0)
    assert_that(SoulActions.can_revive(s, &"human")).is_false()
    _awaken(s, &"human")
    assert_that(SoulActions.can_revive(s, &"human")).is_true()

func test_can_revive_requires_soul_and_growth() -> void:
    var s := GameState.new()
    _awaken(s, &"human")
    s.soul_river = 0
    assert_that(SoulActions.can_revive(s, &"human")).is_false()  # 河底空
    s.soul_river = 100
    s.growth = BigNum.new(499.0)
    assert_that(SoulActions.can_revive(s, &"human")).is_false()  # growth 不足
    s.growth = BigNum.new(500.0)
    assert_that(SoulActions.can_revive(s, &"human")).is_true()

func test_revive_success() -> void:
    var s := GameState.new()
    _awaken(s, &"human")
    s.growth = BigNum.new(700.0)
    var r := SoulActions.revive(s, &"human")
    assert_that(r.get("ok", false)).is_true()
    assert_that(s.soul_river).is_equal(99)       # 河底 -1
    assert_that(s.growth.to_value()).is_equal_approx(200.0, 1e-4)  # 700-500
    assert_that(float(s.races["human"]["population"])).is_equal_approx(60.0, 1e-4)  # 50+10

func test_revive_blocked_no_effect() -> void:
    var s := GameState.new()  # 未唤醒
    s.growth = BigNum.new(500.0)
    var r := SoulActions.revive(s, &"human")
    assert_that(r.get("ok", false)).is_false()
    assert_that(s.soul_river).is_equal(100)
    assert_that(s.growth.to_value()).is_equal_approx(500.0, 1e-4)

func test_can_plunder_soul_requires_reveal() -> void:
    var s := GameState.new()
    _awaken(s, &"human")
    s.soul_river = 99
    assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(0)
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_false()  # 未夺梦揭示
    s.plundered["human"] = 3  # 1 级揭示门槛
    assert_that(PlunderActions.reveal_stage(s, &"human")).is_equal(1)
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_true()

func test_can_plunder_soul_requires_pop_and_river_cap() -> void:
    var s := GameState.new()
    _awaken(s, &"human")
    s.plundered["human"] = 3
    s.races["human"]["population"] = 2.0
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_false()  # 人口 <3
    s.races["human"]["population"] = 5.0
    s.soul_river = 100
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_false()  # 河底已满
    s.soul_river = 99
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_true()

func test_plunder_soul_success() -> void:
    var s := GameState.new()
    _awaken(s, &"human")
    s.plundered["human"] = 3
    s.relations["human"] = 1
    s.soul_river = 99
    var r := SoulActions.plunder_soul(s, &"human")
    assert_that(r.get("ok", false)).is_true()
    assert_that(s.soul_river).is_equal(100)      # 河底 +1（提前归河）
    assert_that(float(s.races["human"]["population"])).is_equal_approx(47.0, 1e-4)  # 50-3
    assert_that(int(s.relations["human"])).is_equal(-1)  # 1-2（RelationActions clamp）

func test_plunder_soul_river_caps_at_100() -> void:
    # 守恒：夺魂总量不超过 100（河底存量就是计数器本身，cap 进 can 条件）
    var s := GameState.new()
    _awaken(s, &"human")
    s.plundered["human"] = 3
    s.relations["human"] = 0
    s.soul_river = 99
    SoulActions.plunder_soul(s, &"human")
    assert_that(s.soul_river).is_equal(100)
    assert_that(SoulActions.can_plunder_soul(s, &"human")).is_false()  # 满则停

func test_conservation_revive_then_plunder() -> void:
    # 守恒闭环：复活取出 1（river 100→99），夺魂提前归河 1（99→100）
    var s := GameState.new()
    _awaken(s, &"human")
    s.growth = BigNum.new(1000.0)
    s.plundered["human"] = 3
    SoulActions.revive(s, &"human")
    assert_that(s.soul_river).is_equal(99)
    SoulActions.plunder_soul(s, &"human")
    assert_that(s.soul_river).is_equal(100)