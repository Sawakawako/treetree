extends GdUnitTestSuite

const TEST_PATH := "user://test_save.json"

func after_test() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

func test_save_then_load_roundtrip() -> void:
	var s := GameState.new()
	s.daylight = BigNum.new(42.0)
	s.leaf_level = 3
	s.tick = 120
	SaveManager.save(s, TEST_PATH, 123456)
	assert_that(FileAccess.file_exists(TEST_PATH)).is_true()
	var loaded := SaveManager.load_or_create(TEST_PATH)
	assert_that(loaded.daylight.to_value()).is_equal_approx(42.0, 1e-4)
	assert_that(loaded.leaf_level).is_equal(3)
	assert_that(loaded.tick).is_equal(120)
	assert_that(loaded.last_saved_unix).is_equal(123456)

func test_load_when_missing_returns_fresh() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	var loaded := SaveManager.load_or_create(TEST_PATH)
	assert_that(loaded.tick).is_equal(0)
	assert_that(loaded.hope).is_equal(1)

func test_save_timestamp_does_not_move_backwards() -> void:
	var state := GameState.new()
	state.last_saved_unix = 200
	SaveManager.save(state, TEST_PATH, 100)
	assert_that(SaveManager.load_or_create(TEST_PATH).last_saved_unix).is_equal(200)
