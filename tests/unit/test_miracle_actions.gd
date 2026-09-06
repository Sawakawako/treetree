extends GdUnitTestSuite

func _ready_state() -> GameState:
	var state := GameState.new()
	state.faith = BigNum.new(10000.0)
	state.sap = BigNum.new(1000.0)
	state.lingua_life_level = 3
	state.lingua_nodes.assign([&"rain_name", &"river_hearing", &"world_shaping"])
	state.realm_echoes.assign([
		&"midgard", &"nidavellir", &"alfheim", &"muspelheim", &"jotunheim",
		&"niflheim", &"vanaheim", &"helheim", &"asgard",
	])
	for race_id: StringName in [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]:
		state.races[race_id] = {"awakened": true, "population": 50.0}
	return state

func test_catalog_has_five_unique_valid_definitions() -> void:
	var definitions := MiracleCatalog.all_miracles()
	assert_that(definitions.size()).is_equal(5)
	var ids: Array[StringName] = []
	for definition: MiracleDefinition in definitions:
		assert_that(ids).not_contains(definition.id)
		ids.append(definition.id)
		assert_that(definition.display_name).is_not_empty()
		assert_that(definition.faith_costs).is_not_empty()
		assert_that(definition.first_text).is_not_empty()
		assert_that(definition.repeat_text).is_not_empty()
		assert_that(["none", "race"]).contains(definition.target_mode)

func test_prerequisite_gates_are_checked_before_spending() -> void:
	var state := _ready_state()
	state.realm_echoes.erase(&"midgard")
	var faith_before := state.faith.to_value()
	assert_that(MiracleActions.perform(state, &"oasis").get("ok", false)).is_false()
	assert_that(state.faith.to_value()).is_equal_approx(faith_before, 1e-4)
	state.realm_echoes.append(&"midgard")
	state.lingua_nodes.erase(&"rain_name")
	assert_that(MiracleActions.can_perform(state, &"oasis")).is_false()
	state.lingua_nodes.append(&"rain_name")
	state.lingua_life_level = 1
	assert_that(MiracleActions.can_perform(state, &"oasis")).is_false()

func test_oasis_escalates_cost_caps_at_three_and_multiplies_capacity() -> void:
	var state := _ready_state()
	state.faith = BigNum.new(2000.0)
	assert_that(MiracleActions.faith_cost(state, &"oasis")).is_equal(150)
	for expected_cost: int in [150, 300, 600]:
		var result := MiracleActions.perform(state, &"oasis")
		assert_that(result.get("ok", false)).is_true()
		assert_that(int(result.get("faith_cost", 0))).is_equal(expected_cost)
	assert_that(MiracleActions.count(state, &"oasis")).is_equal(3)
	assert_that(RaceManager.capacity(state)).is_equal_approx(400.0, 1e-4)
	assert_that(MiracleActions.perform(state, &"oasis").get("ok", false)).is_false()
	assert_that(state.faith.to_value()).is_equal_approx(950.0, 1e-4)

func test_rain_doubles_growth_for_exactly_remaining_population_ticks() -> void:
	var state := _ready_state()
	var result := MiracleActions.perform(state, &"rain")
	assert_that(result.get("ok", false)).is_true()
	assert_that(state.miracle_rain_ticks).is_equal(120)
	RaceManager.tick_races(state)
	assert_that(float(state.races[&"human"]["population"])).is_equal_approx(50.5, 1e-4)
	MiracleActions.advance_tick(state)
	assert_that(state.miracle_rain_ticks).is_equal(119)
	state.miracle_rain_ticks = 1
	MiracleActions.advance_tick(state)
	assert_that(state.miracle_rain_ticks).is_equal(0)
	assert_that(MiracleActions.can_perform(state, &"rain")).is_true()

func test_active_rain_cannot_be_recast_and_spends_nothing() -> void:
	var state := _ready_state()
	state.miracle_rain_ticks = 10
	var faith_before := state.faith.to_value()
	assert_that(MiracleActions.perform(state, &"rain").get("ok", false)).is_false()
	assert_that(state.faith.to_value()).is_equal_approx(faith_before, 1e-4)

func test_banish_shadow_cleanses_until_next_successful_plunder() -> void:
	var state := _ready_state()
	state.plundered[&"human"] = 3
	state.relations[&"human"] = 1.0
	assert_that(PlunderActions.is_frozen(state, &"human")).is_true()
	assert_that(MiracleActions.perform(state, &"banish_shadow", &"human").get("ok", false)).is_true()
	assert_that(PlunderActions.is_frozen(state, &"human")).is_false()
	assert_that(float(state.relations[&"human"])).is_equal_approx(1.0, 1e-4)
	assert_that(PlunderActions.plunder(state, &"human").get("ok", false)).is_true()
	assert_that(state.miracle_cleansed_races).not_contains(&"human")
	assert_that(PlunderActions.is_frozen(state, &"human")).is_true()

func test_banish_shadow_rejects_unfrozen_unawakened_and_stoneborn_targets() -> void:
	var state := _ready_state()
	assert_that(MiracleActions.can_perform(state, &"banish_shadow", &"human")).is_false()
	state.plundered[&"human"] = 3
	state.races.erase(&"human")
	assert_that(MiracleActions.can_perform(state, &"banish_shadow", &"human")).is_false()
	state.plundered[&"stoneborn"] = 3
	assert_that(MiracleActions.can_perform(state, &"banish_shadow", &"stoneborn")).is_false()

func test_call_soul_is_atomic_and_does_not_spend_growth_or_relation() -> void:
	var state := _ready_state()
	state.faith = BigNum.new(250.0)
	state.growth = BigNum.new(10.0)
	state.soul_river = 1
	state.relations[&"human"] = -0.5
	var result := MiracleActions.perform(state, &"call_soul", &"human")
	assert_that(result.get("ok", false)).is_true()
	assert_that(state.faith.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(state.soul_river).is_equal(0)
	assert_that(float(state.races[&"human"]["population"])).is_equal_approx(60.0, 1e-4)
	assert_that(state.growth.to_value()).is_equal_approx(10.0, 1e-4)
	assert_that(float(state.relations[&"human"])).is_equal_approx(-0.5, 1e-4)

func test_call_soul_failure_mutates_nothing() -> void:
	var state := _ready_state()
	state.faith = BigNum.new(249.0)
	state.soul_river = 1
	var snapshot := state.to_dict()
	assert_that(MiracleActions.perform(state, &"call_soul", &"human").get("ok", false)).is_false()
	assert_that(state.to_dict()).is_equal(snapshot)
	state.faith = BigNum.new(250.0)
	state.soul_river = 0
	snapshot = state.to_dict()
	assert_that(MiracleActions.perform(state, &"call_soul", &"human").get("ok", false)).is_false()
	assert_that(state.to_dict()).is_equal(snapshot)

func test_shape_adds_fixed_cap_after_existing_multipliers_and_boosts_growth() -> void:
	var state := _ready_state()
	state.faith = BigNum.new(2000.0)
	state.nautilus_level = 1
	state.lingua_nodes.append(&"wood_heart")
	assert_that(MiracleActions.perform(state, &"shape").get("ok", false)).is_true()
	assert_that(MiracleActions.perform(state, &"shape").get("ok", false)).is_true()
	assert_that(GameLoop.sap_cap(state)).is_equal_approx(32500.0, 1e-4)
	state.daylight = BigNum.new(0.0)
	state.sap = BigNum.new(100.0)
	state.growth = BigNum.new(0.0)
	GameLoop.tick(state)
	assert_that(state.growth.to_value()).is_equal_approx(1.2, 1e-4)
	assert_that(state.faith.to_value()).is_equal_approx(800.0, 1e-4)

func test_shape_requires_both_realms_and_stops_after_three_uses() -> void:
	var state := _ready_state()
	state.realm_echoes.erase(&"niflheim")
	assert_that(MiracleActions.can_perform(state, &"shape")).is_false()
	state.realm_echoes.append(&"niflheim")
	state.faith = BigNum.new(2800.0)
	for _use in range(3):
		assert_that(MiracleActions.perform(state, &"shape").get("ok", false)).is_true()
	assert_that(MiracleActions.perform(state, &"shape").get("ok", false)).is_false()
	assert_that(state.faith.to_value()).is_equal_approx(0.0, 1e-4)

func test_unknown_miracle_and_wrong_target_mode_are_rejected() -> void:
	var state := _ready_state()
	assert_that(MiracleActions.perform(state, &"unknown").get("ok", false)).is_false()
	assert_that(MiracleActions.can_perform(state, &"oasis", &"human")).is_false()
	assert_that(MiracleActions.can_perform(state, &"call_soul")).is_false()
	state.races[&"unknown"] = {"awakened": true, "population": 10.0}
	assert_that(MiracleActions.can_perform(state, &"call_soul", &"unknown")).is_false()

func test_miracles_follow_three_six_eight_nine_echo_rhythm() -> void:
	var state := _ready_state()
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	state.lingua_nodes.assign([&"rain_name"])
	state.lingua_life_level = 2
	assert_that(MiracleActions.can_perform(state, &"oasis")).is_true()
	assert_that(MiracleActions.can_perform(state, &"rain")).is_true()
	state.realm_echoes.append_array([&"muspelheim", &"jotunheim", &"niflheim"])
	state.lingua_nodes.append(&"river_hearing")
	state.plundered[&"human"] = 3
	assert_that(MiracleActions.can_perform(state, &"banish_shadow", &"human")).is_true()
	state.realm_echoes.append_array([&"vanaheim", &"helheim"])
	state.lingua_life_level = 3
	assert_that(MiracleActions.can_perform(state, &"call_soul", &"human")).is_true()
	state.realm_echoes.append(&"asgard")
	state.lingua_nodes.append(&"world_shaping")
	assert_that(MiracleActions.can_perform(state, &"shape")).is_true()
