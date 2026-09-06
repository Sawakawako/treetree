extends GdUnitTestSuite

func test_category_order_covers_all_current_collections() -> void:
	assert_that(MemoryArchive.category_ids()).contains_exactly([
		&"relics", &"totems", &"stories", &"choices", &"realms", &"miracles", &"endings",
	])

func test_locked_entry_hides_title_and_body() -> void:
	var archive := MemoryArchiveState.new()
	var entries := MemoryArchive.entries_for(archive, &"relics")
	assert_that(entries.size()).is_equal(RelicLibrary.relic_count())
	assert_that(bool(entries[0].get("unlocked", true))).is_false()
	assert_that(str(entries[0].get("title", "leak"))).is_equal("尚未落进年轮")
	assert_that(str(entries[0].get("body", "leak"))).is_empty()

func test_unlocked_entries_read_existing_libraries() -> void:
	var archive := MemoryArchiveState.new()
	archive.relics.append(1)
	archive.totems.append(1)
	archive.stories.append(&"story_4")
	archive.choices.append(&"human_nightmare")
	archive.realms.append(&"midgard")
	archive.miracles.append(&"rain")
	archive.endings.append(&"good")

	assert_that(str(MemoryArchive.entries_for(archive, &"relics")[0].get("title", ""))).is_equal("城市废墟")
	assert_that(str(MemoryArchive.entries_for(archive, &"totems")[0].get("body", ""))).contains("它们在画你")
	assert_that(str(MemoryArchive.entries_for(archive, &"stories")[0].get("title", ""))).contains("火边的人")
	assert_that(str(MemoryArchive.entries_for(archive, &"choices")[0].get("body", ""))).contains("夜里，火塘边的人族")
	assert_that(str(MemoryArchive.entries_for(archive, &"realms")[0].get("title", ""))).contains("米德加德")
	assert_that(str(MemoryArchive.entries_for(archive, &"miracles")[1].get("body", ""))).contains("第一滴落在叶背")
	assert_that(str(MemoryArchive.entries_for(archive, &"endings")[2].get("body", ""))).contains("亡者之河")

func test_choice_body_marks_recorded_paths_only() -> void:
	var archive := MemoryArchiveState.new()
	archive.record_choice(&"human_nightmare", &"b")
	var body := str(MemoryArchive.entries_for(archive, &"choices")[0].get("body", ""))
	assert_that(body).contains("年轮里的路 · 让它做完")
	assert_that(body).not_contains("年轮里的路 · 把梦收下")

func test_complete_library_unlocks_every_current_entry() -> void:
	var archive := MemoryArchiveState.new()
	archive.mark_complete()
	var summary := MemoryArchive.summary(archive)
	assert_that(int(summary.get("unlocked", 0))).is_equal(int(summary.get("total", -1)))
	assert_that(int(summary.get("total", 0))).is_equal(
		RelicLibrary.relic_count() + TotemLibrary.totem_count() + StoryLibrary.story_count()
		+ ChoiceLibrary.choice_count() + RealmCatalog.all_realms().size()
		+ MiracleCatalog.all_miracles().size() + 4)

