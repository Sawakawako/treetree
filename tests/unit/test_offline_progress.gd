extends GdUnitTestSuite

func _offline_state() -> GameState:
	var state := GameState.new()
	state.lingua_nodes.assign([&"earth_sense"])
	return state

func test_elapsed_seconds_clamps_negative_and_cap() -> void:
	assert_that(OfflineProgress.elapsed_seconds(200, 100)).is_equal(0)
	assert_that(OfflineProgress.elapsed_seconds(100, 200, 60)).is_equal(60)

func test_without_earth_sense_has_no_offline_gain() -> void:
	var state := GameState.new()
	state.branch_level = 1
	var summary: Dictionary = OfflineProgress.apply(state, 60)
	assert_that(summary.get("applied", false)).is_false()
	assert_that(state.daylight.to_value()).is_equal_approx(0.0, 1e-4)

func test_one_second_reuses_online_tree_tick() -> void:
	var state := _offline_state()
	state.branch_level = 1
	var expected := GameState.from_dict(state.to_dict())
	GameLoop.tick(expected)
	RaceManager.tick_races_offline(expected)
	var summary: Dictionary = OfflineProgress.apply(state, 1)
	assert_that(summary.get("applied", false)).is_true()
	assert_that(state.daylight.to_value()).is_equal_approx(expected.daylight.to_value(), 1e-4)
	assert_that(state.sap.to_value()).is_equal_approx(expected.sap.to_value(), 1e-4)
	assert_that(state.growth.to_value()).is_equal_approx(expected.growth.to_value(), 1e-4)

func test_supported_race_one_second_matches_online_formula() -> void:
	var state := _offline_state()
	state.races[&"human"] = {"awakened": true, "population": 50.0}
	state.sap = BigNum.new(100.0)
	var expected := GameState.from_dict(state.to_dict())
	GameLoop.tick(expected)
	RaceManager.tick_races(expected)
	OfflineProgress.apply(state, 1)
	assert_that(float(state.races[&"human"]["population"])).is_equal_approx(float(expected.races[&"human"]["population"]), 1e-4)
	assert_that(state.faith.to_value()).is_equal_approx(expected.faith.to_value(), 1e-4)
	assert_that(state.memory.to_value()).is_equal_approx(expected.memory.to_value(), 1e-4)

func test_sky_light_doubles_before_eight_hour_cap() -> void:
	var state := _offline_state()
	assert_that(OfflineProgress.effective_seconds(state, 1000, 4600)).is_equal(3600)
	state.lingua_nodes.append(&"sky_light")
	assert_that(OfflineProgress.effective_seconds(state, 1000, 4600)).is_equal(7200)
	assert_that(OfflineProgress.effective_seconds(state, 1000, 21000)).is_equal(28800)

func test_offline_tree_production_respects_sap_cap() -> void:
	var state := _offline_state()
	state.daylight = BigNum.new(100000.0)
	OfflineProgress.apply(state, 100)
	assert_that(state.sap.to_value()).is_equal_approx(GameLoop.sap_cap(state), 1e-4)

func test_unsupported_race_freezes_growth_and_output() -> void:
	var state := _offline_state()
	state.races[&"human"] = {"awakened": true, "population": 50.0}
	state.sap = BigNum.new(0.0)
	OfflineProgress.apply(state, 10)
	assert_that(float(state.races[&"human"]["population"])).is_equal_approx(50.0, 1e-4)
	assert_that(state.faith.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(state.memory.to_value()).is_equal_approx(0.0, 1e-4)

func test_engines_and_facilities_are_included() -> void:
	var state := _offline_state()
	state.faith_engine_level = 1
	state.memory_engine_level = 1
	state.firepit_level = 1
	state.ring_level = 1
	state.forge_level = 1
	OfflineProgress.apply(state, 10)
	assert_that(state.faith.to_value()).is_equal_approx(13.0, 1e-4)
	assert_that(state.memory.to_value()).is_equal_approx(2.0, 1e-4)
	assert_that(state.sap.to_value()).is_greater_equal(5.0)

func test_calculate_does_not_mutate_and_offline_does_not_awaken_or_choose() -> void:
	var state := _offline_state()
	state.memory_engine_level = 20
	state.choice_flags.assign([&"dream_machine_found"])
	var snapshot: Dictionary = OfflineProgress.calculate(state, 10)
	assert_that(state.memory.to_value()).is_equal_approx(0.0, 1e-4)
	assert_that(state.races.is_empty()).is_true()
	assert_that(state.choices_done.is_empty()).is_true()
	assert_that(snapshot.get("memory", 0.0)).is_greater(0.0)

func test_rain_ticks_advance_only_when_offline_settlement_runs() -> void:
	var blocked := GameState.new()
	blocked.miracle_rain_ticks = 5
	assert_that(OfflineProgress.apply(blocked, 3).get("applied", false)).is_false()
	assert_that(blocked.miracle_rain_ticks).is_equal(5)
	var state := _offline_state()
	state.miracle_rain_ticks = 5
	OfflineProgress.apply(state, 3)
	assert_that(state.miracle_rain_ticks).is_equal(2)

func test_offline_rain_uses_growth_before_decrementing() -> void:
	var state := _offline_state()
	state.races[&"human"] = {"awakened": true, "population": 50.0}
	state.sap = BigNum.new(100.0)
	state.miracle_rain_ticks = 1
	OfflineProgress.apply(state, 1)
	assert_that(float(state.races[&"human"]["population"])).is_equal_approx(50.5, 1e-4)
	assert_that(state.miracle_rain_ticks).is_equal(0)
