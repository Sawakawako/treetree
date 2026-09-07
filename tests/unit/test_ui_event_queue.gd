extends GdUnitTestSuite

const QueueScript := preload("res://features/ui/events/ui_event_queue.gd")

func test_priority_is_ending_then_choice_then_narrative_then_toast() -> void:
	var queue := QueueScript.new()
	queue.enqueue({"kind": &"toast", "body": "t"})
	queue.enqueue({"kind": &"narrative", "body": "n"})
	queue.enqueue({"kind": &"choice", "body": "c"})
	queue.enqueue({"kind": &"ending", "body": "e"})
	assert_that(queue.pop_next().get("kind")).is_equal(&"ending")
	assert_that(queue.pop_next().get("kind")).is_equal(&"choice")
	assert_that(queue.pop_next().get("kind")).is_equal(&"narrative")
	assert_that(queue.pop_next().get("kind")).is_equal(&"toast")

func test_return_and_ending_share_the_highest_priority_in_fifo_order() -> void:
	var queue := QueueScript.new()
	queue.enqueue({"kind": &"return", "body": "first"})
	queue.enqueue({"kind": &"ending", "body": "second"})
	assert_that(queue.pop_next().get("body")).is_equal("first")
	assert_that(queue.pop_next().get("body")).is_equal("second")

func test_same_priority_preserves_arrival_order() -> void:
	var queue := QueueScript.new()
	queue.enqueue({"kind": &"narrative", "body": "first"})
	queue.enqueue({"kind": &"narrative", "body": "second"})
	assert_that(queue.pop_next().get("body")).is_equal("first")
	assert_that(queue.pop_next().get("body")).is_equal("second")

func test_requeue_front_resumes_before_same_priority_items() -> void:
	var queue := QueueScript.new()
	queue.enqueue({"kind": &"narrative", "body": "waiting"})
	queue.requeue_front({"kind": &"narrative", "body": "interrupted"})
	assert_that(queue.peek_priority()).is_equal(1)
	assert_that(queue.pop_next().get("body")).is_equal("interrupted")
	assert_that(queue.pop_next().get("body")).is_equal("waiting")

func test_queue_copies_input_and_clear_empties_it() -> void:
	var queue := QueueScript.new()
	var event := {"kind": &"toast", "body": "before", "nested": {"value": 1}}
	queue.enqueue(event)
	event["body"] = "after"
	event["nested"]["value"] = 2
	var popped := queue.pop_next()
	assert_that(popped.get("body")).is_equal("before")
	assert_that(popped.get("nested", {}).get("value")).is_equal(1)
	queue.enqueue({"kind": &"choice"})
	assert_that(queue.is_empty()).is_false()
	queue.clear()
	assert_that(queue.is_empty()).is_true()
	assert_that(queue.peek_priority()).is_equal(-1)
	assert_that(queue.pop_next()).is_empty()
