extends GdUnitTestSuite

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
