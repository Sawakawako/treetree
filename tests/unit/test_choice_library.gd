extends GdUnitTestSuite

func test_load_all_returns_seven_choices() -> void:
	var choices := ChoiceLibrary.load_all()
	assert_that(choices.size()).is_equal(7)

func test_choice_ids_unique_and_valid() -> void:
	var ids := ChoiceLibrary.valid_choice_ids()
	assert_that(ids.size()).is_equal(7)
	assert_that(ids).contains(&"human_nightmare")
	assert_that(ids).contains(&"odin_sacrifice")
	assert_that(ids).contains(&"norne_past")
	assert_that(ids).contains(&"norne_now")
	assert_that(ids).contains(&"norne_future")
	assert_that(ids).contains(&"dodder")
	assert_that(ids).contains(&"theseus")

func test_choice_count() -> void:
	assert_that(ChoiceLibrary.choice_count()).is_equal(7)

func test_get_choice_returns_struct() -> void:
	var c := ChoiceLibrary.get_choice(&"human_nightmare")
	assert_that(str(c.get("title", ""))).is_equal("人族噩梦")
	assert_that(str(c.get("intro", "")).length()).is_greater(10)
	var opts: Array = c.get("options", [])
	assert_that(opts.size()).is_equal(2)
	assert_that(str(opts[0].get("text", ""))).is_not_empty()

func test_get_choice_unknown_returns_empty() -> void:
	assert_that(ChoiceLibrary.get_choice(&"nope").is_empty()).is_true()

func test_option_texts_follow_style_rules() -> void:
	# 文风六则抽样检查：全文非空、无抽象词堆砌关键词黑名单
	for c in ChoiceLibrary.load_all():
		assert_that(str(c.get("intro", ""))).is_not_empty()
		for opt in c.get("options", []):
			assert_that(str(opt.get("text", ""))).is_not_empty()
			assert_that(str(opt.get("result_text", ""))).is_not_empty()
			var rt := str(opt.get("result_text", ""))
			for banned in ["悲伤", "痛苦", "愤怒", "恐惧", "绝望"]:
				assert_that(rt.contains(banned)).is_false()

func test_theseus_c_option_has_unlock_gate() -> void:
	var c := ChoiceLibrary.get_choice(&"theseus")
	var opts: Array = c.get("options", [])
	var c_opt: Dictionary = opts[2]
	assert_that(int(c_opt.get("unlock", {}).get("insight_gte", 0))).is_equal(8)