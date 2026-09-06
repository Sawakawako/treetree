extends GdUnitTestSuite

func test_progress_is_mirrored_and_bounded() -> void:
	var previous_world := -1
	for step in range(0, ReturnSequence.STEPS + 1):
		var progress := ReturnSequence.progress_for(step)
		var tree_remaining := int(progress.get("tree_remaining", -1))
		var world_restored := int(progress.get("world_restored", -1))
		assert_that(tree_remaining + world_restored).is_equal(100)
		assert_that(world_restored).is_greater_equal(previous_world)
		previous_world = world_restored
	assert_that(ReturnSequence.progress_for(-1).get("world_restored")).is_equal(0)
	assert_that(ReturnSequence.progress_for(99).get("world_restored")).is_equal(100)

func test_good_goes_full_seven_steps() -> void:
	assert_that(ReturnSequence.max_step_for(&"good")).is_equal(7)

func test_normal_and_bad_stop_at_four() -> void:
	assert_that(ReturnSequence.max_step_for(&"normal")).is_equal(4)
	assert_that(ReturnSequence.max_step_for(&"bad")).is_equal(4)

func test_text_per_run_and_step_nonempty() -> void:
	for run: int in [1, 2, 3]:
		for step: int in range(1, 8):
			assert_that(str(ReturnSequence.text_for(run, step)).length()).is_greater(10)

func test_run_differs() -> void:
	# 每周目 7 步全套差分 → run1 step1 ≠ run2 step1
	assert_that(ReturnSequence.text_for(1, 1)).is_not_equal(ReturnSequence.text_for(2, 1))

func test_halt_text_nonempty() -> void:
	for run: int in [1, 2, 3]:
		assert_that(str(ReturnSequence.halt_text(run)).length()).is_greater(10)
