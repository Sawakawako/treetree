extends GdUnitTestSuite

const TEST_PATH := "user://test_meta.json"

func after_test() -> void:
	MetaSaveManager.delete(TEST_PATH)

func test_missing_meta_returns_fresh_archive() -> void:
	MetaSaveManager.delete(TEST_PATH)
	var archive := MetaSaveManager.load_or_create(TEST_PATH)
	assert_that(archive.library_complete).is_false()
	assert_that(archive.max_run_reached).is_equal(1)

func test_meta_roundtrip_has_version() -> void:
	var archive := MemoryArchiveState.new()
	archive.relics.assign([1, 9])
	archive.library_complete = true
	assert_that(MetaSaveManager.save(archive, TEST_PATH)).is_true()

	var raw := JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH)) as Dictionary
	assert_that(int(raw.get("version", 0))).is_equal(MemoryArchiveState.CURRENT_VERSION)
	var loaded := MetaSaveManager.load_or_create(TEST_PATH)
	assert_that(loaded.relics).contains_exactly([1, 9])
	assert_that(loaded.library_complete).is_true()

func test_corrupt_primary_falls_back_to_backup() -> void:
	var first := MemoryArchiveState.new()
	first.relics.append(1)
	MetaSaveManager.save(first, TEST_PATH)
	var second := MemoryArchiveState.new()
	second.relics.append(2)
	MetaSaveManager.save(second, TEST_PATH)

	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var loaded := MetaSaveManager.load_or_create(TEST_PATH)
	assert_that(loaded.relics).contains_exactly([1])

