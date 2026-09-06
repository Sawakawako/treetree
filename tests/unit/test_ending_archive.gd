extends GdUnitTestSuite

func test_four_ending_entries_keep_frozen_titles_and_bodies() -> void:
	var expected := {
		&"bad": "灰落下来",
		&"normal": "你曾吞噬，也曾被爱",
		&"good": "你把记忆一颗一颗还给亡者之河",
		&"true": "把希望用在自己身上",
	}
	for ending_id: StringName in expected:
		var entry := EndingArchive.get_entry(ending_id)
		assert_that(str(entry.get("title", ""))).is_not_empty()
		assert_that(str(entry.get("body", ""))).contains(expected[ending_id])

func test_true_settlement_stops_loop_and_returns_to_title() -> void:
	var view := EndingArchive.settlement_view(&"true", 2, 1)
	assert_that(bool(view.get("loops", true))).is_false()
	assert_that(str(view.get("action_text", ""))).is_equal("回到标题")

func test_good_settlement_reports_hope_growth() -> void:
	var view := EndingArchive.settlement_view(&"good", 1, 2)
	assert_that(str(view.get("hope_line", ""))).is_equal("希望长了一点：1 → 2")
	assert_that(str(view.get("body", ""))).contains("母树，你种下的希望，发芽了")

