extends GdUnitTestSuite

func _rich_state() -> GameState:
	var state := GameState.new()
	state.relics_found.append(9)
	state.root_depth = 9
	state.growth = BigNum.new(2000.0)
	state.sap = BigNum.new(100000.0)
	state.memory = BigNum.new(10000.0)
	state.faith = BigNum.new(10000.0)
	for race_id: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		state.races[race_id] = {"awakened": true, "population": 50.0}
	return state

func test_catalog_has_nine_unique_worlds_in_three_tree_domains() -> void:
	var realms := RealmCatalog.all_realms()
	assert_that(realms.size()).is_equal(9)
	var ids: Array[StringName] = []
	var domains: Array[StringName] = []
	for realm: RealmDefinition in realms:
		assert_that(ids).not_contains(realm.id)
		ids.append(realm.id)
		if not domains.has(realm.tree_domain):
			domains.append(realm.tree_domain)
	assert_that(domains.size()).is_equal(3)

func test_first_realm_requires_ring_ruin_and_growth() -> void:
	var state := _rich_state()
	state.relics_found.clear()
	assert_that(RealmActions.can_explore(state, &"midgard")).is_false()
	state.relics_found.append(9)
	state.growth = BigNum.new(499.0)
	assert_that(RealmActions.can_explore(state, &"midgard")).is_false()
	state.growth = BigNum.new(500.0)
	assert_that(RealmActions.can_explore(state, &"midgard")).is_true()

func test_explore_spends_atomically_and_cannot_repeat() -> void:
	var state := _rich_state()
	state.sap = BigNum.new(5000.0)
	var result := RealmActions.explore(state, &"midgard")
	assert_that(result.get("ok", false)).is_true()
	assert_that(state.realm_echoes).contains(&"midgard")
	assert_that(state.sap.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(RealmActions.explore(state, &"midgard").get("ok", false)).is_false()
	assert_that(state.realm_echoes.size()).is_equal(1)

func test_missing_one_resource_spends_nothing() -> void:
	var state := _rich_state()
	state.realm_echoes.assign([&"midgard", &"nidavellir"])
	state.sap = BigNum.new(12000.0)
	state.faith = BigNum.new(199.0)
	var result := RealmActions.explore(state, &"muspelheim")
	assert_that(result.get("ok", false)).is_false()
	assert_that(state.sap.to_value()).is_equal_approx(12000.0, 1e-4)
	assert_that(state.faith.to_value()).is_equal_approx(199.0, 1e-4)

func test_prerequisite_and_race_gates() -> void:
	var state := _rich_state()
	assert_that(RealmActions.can_explore(state, &"nidavellir")).is_false()
	state.realm_echoes.append(&"midgard")
	state.races.erase(&"stoneborn")
	assert_that(RealmActions.can_explore(state, &"nidavellir")).is_false()
	state.races[&"stoneborn"] = {"awakened": true, "population": 20.0}
	assert_that(RealmActions.can_explore(state, &"nidavellir")).is_true()

func test_sky_requires_world_language_node() -> void:
	var state := _rich_state()
	state.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim", &"muspelheim", &"jotunheim", &"niflheim",
	])
	assert_that(RealmActions.can_explore(state, &"vanaheim")).is_false()
	state.lingua_nodes.append(&"sky_ladder")
	assert_that(RealmActions.can_explore(state, &"vanaheim")).is_true()

func test_world_level_is_derived_at_three_six_and_nine() -> void:
	var state := GameState.new()
	assert_that(RealmActions.world_level(state)).is_equal(0)
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	assert_that(RealmActions.world_level(state)).is_equal(1)
	state.realm_echoes.append_array([&"muspelheim", &"jotunheim", &"niflheim"])
	assert_that(RealmActions.world_level(state)).is_equal(2)
	state.realm_echoes.append_array([&"vanaheim", &"helheim", &"asgard"])
	assert_that(RealmActions.world_level(state)).is_equal(3)

func test_game_state_roundtrip_filters_unknown_and_duplicates() -> void:
	var state := GameState.from_dict({"realm_echoes": ["midgard", "unknown", "midgard", 7]})
	assert_that(state.realm_echoes).is_equal([&"midgard"])
	var back := GameState.from_dict(state.to_dict())
	assert_that(back.realm_echoes).is_equal([&"midgard"])

func test_new_run_preserves_realm_knowledge() -> void:
	var state := GameState.new()
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	state.lingua_nodes.assign([&"world_trace"])
	var next := GameState.new_run_preserved(state)
	assert_that(next.realm_echoes).is_equal(state.realm_echoes)
	assert_that(next.lingua_nodes).is_empty()
	assert_that(RealmActions.world_level(next)).is_equal(1)
