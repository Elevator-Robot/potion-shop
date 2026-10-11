extends RefCounted
## The shop's rules, with no network in them: one of these keeps every shared
## fact - the customer queue, the shelf and storage contents, the cauldron, the
## coins, the reputation and the day clock. authority/main.gd works out who
## asked and where they were standing, then calls in here; the document this
## holds is what every client renders.

const Game = preload("res://network/game.gd")

## Who is carrying what, and the whole shop besides. Plain dictionaries only:
## this document is JSON-packed on its way to the clients.
var doc := {}
var _next_customer := 1
var _next_arrival_msec := 0
var _order_index := 0


func _init() -> void:
	reset()


## A fresh day 1 shop.
func reset() -> void:
	var now := Time.get_ticks_msec()
	doc = {
		"coins": 0,
		"reputation": Game.REPUTATION_START,
		"day": 1,
		"day_started_msec": now,
		"day_seconds": Game.DAY_SECONDS,
		"now_msec": now,
		"held": {},
		"shelves": {},
		"storage": [],
		"cauldron": {"contents": [], "potion": "", "brew_start_msec": 0, "brew_end_msec": 0, "ready": false},
		"customers": [],
	}
	# JSON object keys are Strings, so a seat's carried item is keyed by "0"/"1"
	# on both sides of the wire.
	for seat in Game.MAX_PLAYERS:
		doc["held"][str(seat)] = ""
	for raw in Game.RAW_ITEMS:
		doc["shelves"][raw] = Game.SHELF_START_STOCK
	_next_customer = 1
	_order_index = 0
	# The first customer of the day walks in well before the steady rate.
	_next_arrival_msec = now + int(Game.arrival_interval(1) * 600.0)


## What a seat is carrying, "" for empty hands.
func held(seat: int) -> String:
	return str(doc["held"].get(str(seat), ""))


## ---------------------------------------------------------------------------
## The six actions. Each one checks everything, then changes as little as
## possible; nothing changes when it returns a refusal.
## ---------------------------------------------------------------------------

## Take a raw ingredient off its shelf pile, or (item == "") one item out of the
## storage crate. One carried item at a time.
func take(seat: int, item: String) -> Dictionary:
	if held(seat) != "":
		return _no("hands_full")
	if item == "":
		return _take_from_storage(seat)
	if not Game.is_raw(item):
		return _no("no_such_item")
	if int(doc["shelves"].get(item, 0)) <= 0:
		return _no("shelf_empty")
	doc["shelves"][item] = int(doc["shelves"][item]) - 1
	_carry(seat, item)
	return _yes({"item": item})


## Put the carried item into the storage crate.
func put(seat: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if doc["storage"].size() >= Game.STORAGE_CAPACITY:
		return _no("storage_full")
	doc["storage"].append(item)
	_carry(seat, "")
	return _yes({"item": item})


## Chop a raw ingredient: the client holds interact for the whole action, the
## authority only sees the moment it finished.
func prep(seat: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if not Game.is_raw(item):
		return _no("already_prepped")
	var prepped := Game.prepped_of(item)
	_carry(seat, prepped)
	return _yes({"item": prepped})


## Add a prepped ingredient to the cauldron. The last ingredient of a recipe
## starts the brew.
func add(seat: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if not Game.is_prepped(item):
		return _no("needs_prep")
	var cauldron: Dictionary = doc["cauldron"]
	if not str(cauldron["potion"]).is_empty() or bool(cauldron["ready"]):
		return _no("already_brewing")
	var raw := Game.raw_of(item)
	var contents: Array = cauldron["contents"].duplicate()
	contents.append(raw)
	if not Game.can_still_brew(contents):
		return _no("not_a_recipe")
	cauldron["contents"] = contents
	_carry(seat, "")
	var potion := Game.potion_for(contents)
	if potion != "":
		var now := Time.get_ticks_msec()
		cauldron["potion"] = potion
		cauldron["brew_start_msec"] = now
		cauldron["brew_end_msec"] = now + int(float(Game.recipe(potion)["brew"]) * 1000.0)
	return _yes({"item": raw, "brewing": potion})


## Take the finished potion out of the cauldron, into empty hands.
func bottle(seat: int) -> Dictionary:
	if held(seat) != "":
		return _no("hands_full")
	var cauldron: Dictionary = doc["cauldron"]
	if not bool(cauldron["ready"]):
		return _no("not_ready")
	var potion := str(cauldron["potion"])
	cauldron["contents"] = []
	cauldron["potion"] = ""
	cauldron["brew_start_msec"] = 0
	cauldron["brew_end_msec"] = 0
	cauldron["ready"] = false
	_carry(seat, potion)
	return _yes({"item": potion})


## Serve the customer at the front of the queue. Only the potion they ordered
## is accepted; anything else leaves them waiting.
func serve(seat: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if not Game.is_potion(item):
		return _no("not_a_potion")
	var customer := _front_customer()
	if customer.is_empty():
		return _no("no_customer")
	if str(customer["order"]) != item:
		return _no("wrong_order")
	doc["customers"].erase(customer)
	_carry(seat, "")
	var gain := Game.reward(item)
	doc["coins"] = int(doc["coins"]) + gain
	doc["reputation"] = clampi(int(doc["reputation"]) + Game.REPUTATION_GAIN, 0, Game.REPUTATION_MAX)
	return _yes({"item": item, "reward": gain})


## ---------------------------------------------------------------------------
## The clock: brewing, patience, new customers, and the end of the day.
## ---------------------------------------------------------------------------

## Advances the shop. Returns true when the document changed, so the authority
## knows it has something new to publish.
func tick() -> bool:
	var changed := false
	var now := Time.get_ticks_msec()
	doc["now_msec"] = now

	var cauldron: Dictionary = doc["cauldron"]
	if not str(cauldron["potion"]).is_empty() and not bool(cauldron["ready"]) \
			and now >= int(cauldron["brew_end_msec"]):
		cauldron["ready"] = true
		changed = true

	changed = _age_customers(now) or changed

	if now >= _next_arrival_msec and doc["customers"].size() < Game.MAX_QUEUE:
		_arrive(now)
		changed = true

	if now - int(doc["day_started_msec"]) >= int(Game.DAY_SECONDS * 1000.0):
		_start_day(int(doc["day"]) + 1, now)
		changed = true
	return changed


## A customer whose patience runs out turns angry and costs reputation, then
## walks off a moment later.
func _age_customers(now: int) -> bool:
	var changed := false
	var survivors: Array = []
	for entry in doc["customers"]:
		var customer: Dictionary = entry
		if bool(customer.get("angry", false)):
			if now >= int(customer.get("gone_msec", 0)):
				changed = true
			else:
				survivors.append(customer)
			continue
		if now >= int(customer["deadline_msec"]):
			customer["angry"] = true
			customer["gone_msec"] = now + Game.ANGRY_SHOW_MSEC
			doc["reputation"] = clampi(int(doc["reputation"]) - Game.REPUTATION_LOSS, 0, Game.REPUTATION_MAX)
			changed = true
		survivors.append(customer)
	if changed:
		doc["customers"] = survivors
	return changed


## A new customer at the back of the queue, wanting the next potion in the
## cycle, with a patience that shrinks a little every day.
func _arrive(now: int) -> void:
	var order: String = Game.POTIONS[_order_index % Game.POTIONS.size()]
	_order_index += 1
	var patience := Game.patience_seconds(int(doc["day"]))
	doc["customers"].append({
		"id": _next_customer,
		"order": order,
		"patience_seconds": patience,
		"deadline_msec": now + int(patience * 1000.0),
		"angry": false,
		"gone_msec": 0,
	})
	_next_customer += 1
	_next_arrival_msec = now + int(Game.arrival_interval(int(doc["day"])) * 1000.0)


## A new day: the clock restarts, the shelf piles are restocked and the
## customers start coming faster.
func _start_day(day: int, now: int) -> void:
	doc["day"] = day
	doc["day_started_msec"] = now
	for raw in Game.RAW_ITEMS:
		doc["shelves"][raw] = mini(int(doc["shelves"][raw]) + Game.SHELF_RESTOCK, Game.SHELF_MAX_STOCK)
	if _next_arrival_msec < now:
		_next_arrival_msec = now + int(Game.arrival_interval(day) * 1000.0)


## A player left for good: their hands are free again.
func release(seat: int) -> void:
	doc["held"][str(seat)] = ""


func _take_from_storage(seat: int) -> Dictionary:
	var stored: Array = doc["storage"]
	if stored.is_empty():
		return _no("storage_empty")
	var item := str(stored.pop_back())
	_carry(seat, item)
	return _yes({"item": item})


func _carry(seat: int, item: String) -> void:
	doc["held"][str(seat)] = item


## The customer who is being served: the first one still waiting, never one
## who has already given up.
func _front_customer() -> Dictionary:
	for entry in doc["customers"]:
		var customer: Dictionary = entry
		if not bool(customer.get("angry", false)):
			return customer
	return {}


func _yes(value: Dictionary) -> Dictionary:
	return {"ok": true, "reason": "", "value": value}


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "value": {}}
