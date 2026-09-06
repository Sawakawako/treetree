extends GdUnitTestSuite

const TEST_PATH := "user://test_save.json"

func after_test() -> void:
	SaveManager.delete(TEST_PATH)

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

func test_save_writes_version_and_reports_existence() -> void:
	var state := GameState.new()
	assert_that(SaveManager.exists(TEST_PATH)).is_false()
	assert_that(SaveManager.save(state, TEST_PATH, 1)).is_true()
	assert_that(SaveManager.exists(TEST_PATH)).is_true()
	var raw := JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH)) as Dictionary
	assert_that(int(raw.get("version", 0))).is_equal(SaveManager.CURRENT_VERSION)

func test_corrupt_primary_falls_back_to_backup() -> void:
	var first := GameState.new()
	first.leaf_level = 1
	SaveManager.save(first, TEST_PATH, 1)
	var second := GameState.new()
	second.leaf_level = 2
	SaveManager.save(second, TEST_PATH, 2)
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	assert_that(SaveManager.load_or_create(TEST_PATH).leaf_level).is_equal(1)

func test_delete_removes_primary_backup_and_temp() -> void:
	SaveManager.save(GameState.new(), TEST_PATH, 1)
	SaveManager.save(GameState.new(), TEST_PATH, 2)
	var temp := FileAccess.open(TEST_PATH + ".tmp", FileAccess.WRITE)
	temp.store_string("temp")
	temp.close()
	assert_that(SaveManager.delete(TEST_PATH)).is_true()
	assert_that(FileAccess.file_exists(TEST_PATH)).is_false()
	assert_that(FileAccess.file_exists(TEST_PATH + ".bak")).is_false()
	assert_that(FileAccess.file_exists(TEST_PATH + ".tmp")).is_false()
