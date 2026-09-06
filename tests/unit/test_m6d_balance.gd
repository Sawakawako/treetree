extends GdUnitTestSuite

const ROUTE: Array[StringName] = [
	&"midgard", &"nidavellir", &"alfheim",
	&"muspelheim", &"jotunheim", &"niflheim",
	&"vanaheim", &"helheim", &"asgard",
]
const MAIN_NODES: Array[StringName] = [&"world_trace", &"river_hearing", &"sky_ladder", &"world_breath"]
const MAX_SIM_SECONDS := 2700

func _first_run_entry_state() -> GameState:
	# “职业操作档”：遗迹 9 后、不带预存资源的稳定末期经营盘。
	# 所有等级都是既有可购买项；模拟过程中不注入资源、不施展奇迹。
	var state := GameState.new()
	state.relics_found.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	state.growth = BigNum.new(500.0)
	state.root_depth = 9
	state.leaf_level = 4
	state.branch_level = 4
	state.chloroplast_level = 3
	state.xylem_level = 3
	state.sunflower_level = 1
	state.nautilus_level = 2
	state.root_eff_level = 2
	state.firepit_level = 1
	state.ring_level = 1
	state.forge_level = 1
	state.totem_pole_level = 1
	state.faith_engine_level = 1
	state.memory_engine_level = 1
	state.lingua_life_level = 3
	state.lingua_memory_level = 1
	state.lingua_nodes.assign([
		&"root_resonance", &"tree_canopy", &"ring_memory", &"cloud_crown",
		&"wood_heart", &"song_resonance", &"village_heart", &"grace", &"altar",
	])
	state.races = {
		&"human": {"awakened": true, "population": 50.0},
		&"forestfolk": {"awakened": true, "population": 30.0},
		&"stoneborn": {"awakened": true, "population": 20.0},
		&"wildfolk": {"awakened": true, "population": 80.0},
	}
	return state

func _next_step(state: GameState) -> Dictionary:
	var count := state.realm_echoes.size()
	if count < 3:
		return {"kind": &"realm", "id": ROUTE[count]}
	if not state.lingua_nodes.has(&"world_trace"):
		return {"kind": &"node", "id": &"world_trace"}
	if count < 6:
		return {"kind": &"realm", "id": ROUTE[count]}
	if not state.lingua_nodes.has(&"river_hearing"):
		return {"kind": &"node", "id": &"river_hearing"}
	if not state.lingua_nodes.has(&"sky_ladder"):
		return {"kind": &"node", "id": &"sky_ladder"}
	if count < 9:
		return {"kind": &"realm", "id": ROUTE[count]}
	if not state.lingua_nodes.has(&"world_breath"):
		return {"kind": &"node", "id": &"world_breath"}
	return {}

func _resource_blocker(state: GameState, step: Dictionary) -> StringName:
	var sap_cost := 0.0
	var memory_cost := 0.0
	var faith_cost := 0.0
	if step.get("kind") == &"realm":
		var realm := RealmCatalog.get_realm(step.get("id", &""))
		sap_cost = realm.sap_cost
		memory_cost = realm.memory_cost
		faith_cost = realm.faith_cost
	else:
		var node := LinguaData.get_node(step.get("id", &""))
		sap_cost = float(node.get("sap_cost", 0.0))
	var gaps := {
		&"sap": maxf(sap_cost - state.sap.to_value(), 0.0),
		&"memory": maxf(memory_cost - state.memory.to_value(), 0.0),
		&"faith": maxf(faith_cost - state.faith.to_value(), 0.0),
	}
	var blocker: StringName = &"none"
	var largest_ratio := 0.0
	for resource_id: StringName in [&"sap", &"memory", &"faith"]:
		var cost := sap_cost if resource_id == &"sap" else memory_cost if resource_id == &"memory" else faith_cost
		if cost <= 0.0:
			continue
		var ratio: float = float(gaps[resource_id]) / cost
		if ratio > largest_ratio:
			largest_ratio = ratio
			blocker = resource_id
	return blocker

func _simulate_main_route() -> Dictionary:
	var state := _first_run_entry_state()
	var stage_seconds: Array[int] = []
	var blocked_seconds := {&"sap": 0, &"memory": 0, &"faith": 0}
	for second in range(1, MAX_SIM_SECONDS + 1):
		GameLoop.tick(state)
		RaceManager.tick_races(state)
		MiracleActions.advance_tick(state)
		var step := _next_step(state)
		if step.is_empty():
			return {
				"seconds": second,
				"stage_seconds": stage_seconds,
				"blocked_seconds": blocked_seconds,
				"state": state,
			}
		var count_before := state.realm_echoes.size()
		var ok := false
		if step.get("kind") == &"realm":
			ok = bool(RealmActions.explore(state, step.get("id", &"")).get("ok", false))
		else:
			ok = bool(LinguaActions.unlock_node(state, step.get("id", &"")).get("ok", false))
		if state.realm_echoes.size() > count_before and state.realm_echoes.size() in [3, 6, 9]:
			stage_seconds.append(second)
		if not ok:
			var blocker := _resource_blocker(state, step)
			if blocked_seconds.has(blocker):
				blocked_seconds[blocker] += 1
	return {
		"seconds": MAX_SIM_SECONDS + 1,
		"stage_seconds": stage_seconds,
		"blocked_seconds": blocked_seconds,
		"state": state,
	}

func test_source_tables_keep_no_miracle_budget() -> void:
	var realm_totals := {&"sap": 0.0, &"memory": 0.0, &"faith": 0.0}
	for realm: RealmDefinition in RealmCatalog.all_realms():
		realm_totals[&"sap"] += realm.sap_cost
		realm_totals[&"memory"] += realm.memory_cost
		realm_totals[&"faith"] += realm.faith_cost
	var node_sap := 0.0
	for node_id: StringName in MAIN_NODES:
		node_sap += float(LinguaData.get_node(node_id).get("sap_cost", 0.0))
	assert_that(RealmCatalog.get_realm(&"alfheim").memory_cost).is_equal_approx(200.0, 1e-4)
	assert_that(RealmCatalog.get_realm(&"niflheim").memory_cost).is_equal_approx(300.0, 1e-4)
	assert_that(RealmCatalog.get_realm(&"asgard").memory_cost).is_equal_approx(500.0, 1e-4)
	assert_that(RealmCatalog.get_realm(&"asgard").faith_cost).is_equal_approx(7000.0, 1e-4)
	assert_that(float(realm_totals[&"sap"]) + node_sap).is_equal_approx(87000.0, 1e-4)
	assert_that(float(realm_totals[&"memory"])).is_equal_approx(1000.0, 1e-4)
	assert_that(float(realm_totals[&"faith"])).is_equal_approx(8000.0, 1e-4)

func test_first_run_professional_profile_reaches_axis_in_25_to_45_minutes() -> void:
	var report := _simulate_main_route()
	print("M6-D balance report: ", {
		"seconds": report["seconds"],
		"stage_seconds": report["stage_seconds"],
		"blocked_seconds": report["blocked_seconds"],
		"final_resources": {
			"sap": (report["state"] as GameState).sap.to_value(),
			"memory": (report["state"] as GameState).memory.to_value(),
			"faith": (report["state"] as GameState).faith.to_value(),
		},
	})
	var stage_seconds := report["stage_seconds"] as Array
	var blocked_seconds := report["blocked_seconds"] as Dictionary
	assert_that(stage_seconds.size()).is_equal(3)
	assert_that(int(stage_seconds[2])).is_between(1500, 2700)
	assert_that(int(report["seconds"])).is_between(1500, 2700)
	assert_that(int(blocked_seconds[&"memory"])).is_less_equal(1200)
	assert_that(int(blocked_seconds[&"faith"])).is_between(60, 600)
	assert_that((report["state"] as GameState).lingua_nodes).contains(&"world_breath")
	assert_that((report["state"] as GameState).miracle_counts).is_empty()

func test_preserved_echoes_do_not_charge_again() -> void:
	var first := _first_run_entry_state()
	first.realm_echoes.assign(ROUTE)
	var next := GameState.new_run_preserved(first)
	next.sap = BigNum.new(123.0)
	next.memory = BigNum.new(45.0)
	next.faith = BigNum.new(67.0)
	var before := [next.sap.to_value(), next.memory.to_value(), next.faith.to_value()]
	assert_that(RealmActions.explore(next, &"midgard").get("ok", true)).is_false()
	assert_that([next.sap.to_value(), next.memory.to_value(), next.faith.to_value()]).is_equal(before)

func test_paper_route_sap_rich_memory_tight_keeps_one_path_open() -> void:
	var state := _first_run_entry_state()
	state.sap = BigNum.new(20000.0)
	state.memory = BigNum.new(0.0)
	assert_that(RealmActions.explore(state, &"midgard").get("ok", false)).is_true()
	assert_that(RealmActions.can_explore(state, &"nidavellir")).is_true()
	assert_that(RealmActions.can_explore(state, &"alfheim")).is_false()

func test_paper_route_second_stage_accepts_non_numeric_order() -> void:
	var state := _first_run_entry_state()
	state.sap = BigNum.new(100000.0)
	state.memory = BigNum.new(1000.0)
	state.faith = BigNum.new(1000.0)
	state.growth = BigNum.new(1000.0)
	state.realm_echoes.assign([&"midgard", &"nidavellir", &"alfheim"])
	state.lingua_nodes.append(&"world_trace")
	for realm_id: StringName in [&"niflheim", &"jotunheim", &"muspelheim"]:
		assert_that(RealmActions.explore(state, realm_id).get("ok", false)).is_true()
	assert_that(state.realm_echoes.slice(3)).is_equal([&"niflheim", &"jotunheim", &"muspelheim"])
