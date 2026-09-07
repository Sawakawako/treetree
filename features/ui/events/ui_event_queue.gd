class_name UiEventQueue
extends RefCounted

const PRIORITY := {&"toast": 0, &"narrative": 1, &"choice": 2, &"return": 3, &"ending": 3}

var _items: Array[Dictionary] = []
var _serial := 0

func enqueue(event: Dictionary) -> void:
	var item := event.duplicate(true)
	item["priority"] = int(PRIORITY.get(StringName(str(item.get("kind", &"toast"))), 0))
	item["serial"] = _serial
	_serial += 1
	_items.append(item)

func pop_next() -> Dictionary:
	if _items.is_empty():
		return {}
	var best := 0
	for index in range(1, _items.size()):
		var left := _items[index]
		var right := _items[best]
		if int(left["priority"]) > int(right["priority"]) \
				or int(left["priority"]) == int(right["priority"]) and int(left["serial"]) < int(right["serial"]):
			best = index
	return _items.pop_at(best)

func requeue_front(event: Dictionary) -> void:
	var item := event.duplicate(true)
	item["priority"] = int(PRIORITY.get(StringName(str(item.get("kind", &"toast"))), 0))
	item["serial"] = -1
	_items.append(item)

func peek_priority() -> int:
	if _items.is_empty():
		return -1
	var highest := -1
	for item: Dictionary in _items:
		highest = maxi(highest, int(item.get("priority", 0)))
	return highest

func is_empty() -> bool:
	return _items.is_empty()

func clear() -> void:
	_items.clear()
