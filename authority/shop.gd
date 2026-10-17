extends RefCounted
## The shop's rules, with no network in them: one of these keeps every shared
## fact - browsing customers, shelf and storage contents, the cauldron, the
## coins, the reputation and the day clock. authority/main.gd works out who
## asked and where they were standing, then calls in here; the document this
## holds is what every client renders.

const Game = preload("res://network/game.gd")
const Navigation = preload("res://network/shop_navigation.gd")

## Who is carrying what, and the whole shop besides. Plain dictionaries only:
## this document is copied into the snapshots sent to clients.
var doc := {}
var _next_customer := 1
var _next_arrival_msec := 0
var _order_index := 0
var _navigation := Navigation.new()
var _paths := {}
var _last_customer_tick := 0
var _effect_id := 0


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
		"shelf_stock": {},
		"storage": [],
		"cauldron": {"contents": [], "potion": "", "brew_start_msec": 0, "brew_end_msec": 0, "ready": false},
		"customers": [],
		"door_open_until": 0,
		"effects": [],
	}
	# JSON object keys are Strings, so a seat's carried item is keyed by "0"/"1"
	# on both sides of the wire.
	for seat in Game.MAX_PLAYERS:
		doc["held"][str(seat)] = ""
	for item in Game.ALL_ITEMS:
		doc["shelves"][item] = 0
	for station in Game.FURNITURE:
		if Game.FURNITURE[station]["kind"] != "shelf":
			continue
		doc["shelf_stock"][station] = {}
		for item in Game.shelf_items(station):
			var amount := Game.SHELF_START_STOCK if Game.is_raw(item) else 0
			doc["shelf_stock"][station][item] = amount
			doc["shelves"][item] += amount
	_next_customer = 1
	_order_index = 0
	_paths.clear()
	_last_customer_tick = now
	_effect_id = 0
	# The first customer of the day walks in well before the steady rate.
	_next_arrival_msec = now + 3000


## What a seat is carrying, "" for empty hands.
func held(seat: int) -> String:
	return str(doc["held"].get(str(seat), ""))


## ---------------------------------------------------------------------------
## The six actions. Each one checks everything, then changes as little as
## possible; nothing changes when it returns a refusal.
## ---------------------------------------------------------------------------

## Take a raw ingredient off its shelf pile, or (item == "") one item out of the
## storage crate. One carried item at a time.
func take(seat: int, item: String, station: String = "") -> Dictionary:
	if held(seat) != "":
		return _no("hands_full")
	if item == "":
		return _take_from_storage(seat)
	if not Game.is_item(item):
		return _no("no_such_item")
	if station == "":
		station = Game.shelf_id(item)
	if not Game.shelf_items(station).has(item):
		return _no("wrong_shelf")
	if stock_at(station, item) <= 0:
		return _no("shelf_empty")
	_change_stock(station, item, -1)
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


## Put an ingredient back onto a matching shelf.
func restock(seat: int, raw: String, station: String = "") -> Dictionary:
	var item := held(seat)
	if station == "":
		station = Game.shelf_id(raw)
	if item != raw or not Game.is_item(raw) or not Game.shelf_items(station).has(item):
		return _no("wrong_shelf")
	if stock_at(station, raw) >= Game.SHELF_MAX_STOCK:
		return _no("shelf_full")
	_change_stock(station, raw, 1)
	_carry(seat, "")
	return _yes({"item": item})

func stock_at(station: String, item: String) -> int:
	return int((doc["shelf_stock"].get(station, {}) as Dictionary).get(item, 0))

func _change_stock(station: String, item: String, delta: int) -> void:
	doc["shelf_stock"][station][item] = stock_at(station, item) + delta
	doc["shelves"][item] = int(doc["shelves"][item]) + delta


## Add an ingredient directly to the cauldron. The last ingredient of a recipe
## starts the brew.
func add(seat: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if not Game.is_raw(item):
		return _no("not_an_ingredient")
	var cauldron: Dictionary = doc["cauldron"]
	if not str(cauldron["potion"]).is_empty() or bool(cauldron["ready"]):
		return _no("already_brewing")
	var raw := item
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
func collect(seat: int) -> Dictionary:
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


## Serve the specific nearby customer chosen by the player, not a queue slot.
func serve(seat: int, customer_id: int) -> Dictionary:
	var item := held(seat)
	if item == "":
		return _no("hands_empty")
	if not Game.is_potion(item):
		return _no("not_a_potion")
	var customer := get_customer(customer_id)
	if customer.is_empty() or customer["phase"] == "leaving" or bool(customer["angry"]):
		return _no("no_customer")
	if str(customer["order"]) != item:
		return _no("wrong_order")
	customer["served"] = true
	_leave(customer)
	_carry(seat, "")
	var gain := Game.reward(item)
	doc["coins"] = int(doc["coins"]) + gain
	doc["reputation"] = clampi(int(doc["reputation"]) + Game.REPUTATION_GAIN, 0, Game.REPUTATION_MAX)
	return _yes({"item": item, "reward": gain, "customer": customer_id})


func clear_cauldron(seat: int) -> Dictionary:
	if held(seat) != "":
		return _no("hands_full")
	if doc["cauldron"]["potion"] != "":
		return _no("already_brewing")
	doc["cauldron"]["contents"] = []
	return _yes({"message": "Cauldron emptied"})


func talk(customer_id: int, from: Vector2) -> Dictionary:
	var customer := get_customer(customer_id)
	if customer.is_empty() or customer["phase"] == "leaving":
		return _no("no_customer")
	customer["phase"] = "waiting"
	customer["look_until"] = Time.get_ticks_msec() + 3000
	customer["next_glance"] = customer["look_until"]
	customer["facing"] = (from - (customer["position"] as Vector2)).angle()
	_paths.erase(customer_id)
	return _yes({"message": "This bottle, please!", "customer": customer_id})


func door() -> Dictionary:
	var now := Time.get_ticks_msec()
	var occupied := false
	for customer in doc["customers"]:
		if (customer["position"] as Vector2).distance_to(Game.DOOR_POINT) < 80.0:
			occupied = true
	if int(doc["door_open_until"]) > now and not occupied:
		doc["door_open_until"] = now
	else:
		_open_door(now)
	return _yes({})


func record_effect(action: String, station: String, seat: int, from: Vector2, to: Vector2, value: Dictionary) -> void:
	_effect_id += 1
	doc["effects"].append({"id": _effect_id, "action": action, "station": station, "seat": seat, "from": from, "to": to, "item": str(value.get("item", "")), "reward": int(value.get("reward", 0)), "customer": int(value.get("customer", 0))})
	while doc["effects"].size() > 20:
		doc["effects"].pop_front()


## ---------------------------------------------------------------------------
## The clock: brewing, patience, new customers, and the end of the day.
## ---------------------------------------------------------------------------

## Advances the shop. Returns true when the document changed, so the authority
## knows it has something new to publish.
func tick(now: int = -1) -> bool:
	var changed := false
	if now < 0:
		now = Time.get_ticks_msec()
	doc["now_msec"] = now

	var cauldron: Dictionary = doc["cauldron"]
	if not str(cauldron["potion"]).is_empty() and not bool(cauldron["ready"]) \
			and now >= int(cauldron["brew_end_msec"]):
		cauldron["ready"] = true
		changed = true

	changed = _move_customers(now) or changed

	if now >= _next_arrival_msec and doc["customers"].size() < Game.MAX_CUSTOMERS:
		_arrive(now)
		changed = true

	if now - int(doc["day_started_msec"]) >= int(Game.DAY_SECONDS * 1000.0):
		_start_day(int(doc["day"]) + 1, now)
		changed = true
	return changed


## Server-side browsing paths and patience. Clients interpolate these positions.
func _move_customers(now: int) -> bool:
	if now - _last_customer_tick < 100:
		return false
	var delta := minf(float(now - _last_customer_tick) / 1000.0, 0.25)
	_last_customer_tick = now
	var survivors: Array = []
	for entry in doc["customers"]:
		var customer: Dictionary = entry
		var id := int(customer["id"])
		if customer["phase"] != "leaving" and now >= int(customer["deadline_msec"]):
			customer["angry"] = true
			doc["reputation"] = clampi(int(doc["reputation"]) - Game.REPUTATION_LOSS, 0, Game.REPUTATION_MAX)
			_leave(customer)
		if customer["phase"] == "waiting" and now >= int(customer["look_until"]):
			customer["visits"] = int(customer["visits"]) + 1
			_browse(customer)
		elif customer["phase"] == "waiting" and now >= int(customer.get("next_glance", 0)):
			customer["facing"] = float(customer["facing"]) + PI / 2.0
			customer["next_glance"] = now + 1600
		var position: Vector2 = customer["position"]
		var path: Array = _paths.get(id, [])
		if not path.is_empty():
			var next: Vector2 = path[0]
			var moved := position.move_toward(next, Game.CUSTOMER_SPEED * delta)
			if moved.distance_to(position) > 0.01:
				customer["facing"] = (moved - position).angle()
			customer["position"] = moved
			if moved.distance_to(next) < 0.1:
				path.pop_front()
			if path.is_empty():
				if customer["phase"] == "leaving":
					_paths.erase(id)
					continue
				customer["phase"] = "waiting"
				customer["look_until"] = now + 4000 + posmod(id, 4) * 1000
				customer["next_glance"] = now + 1600
				customer["facing"] = [-PI / 2.0, 0.0, PI, PI / 2.0][posmod(id + int(customer["visits"]), 4)]
		if (customer["position"] as Vector2).distance_to(Game.DOOR_POINT) < 65.0:
			_open_door(now)
		survivors.append(customer)
	doc["customers"] = survivors
	return not survivors.is_empty()


func _open_door(now: int) -> void:
	doc["door_open_until"] = maxi(int(doc["door_open_until"]), now + 1800)


func _browse(customer: Dictionary) -> void:
	var id := int(customer["id"])
	var goal: Vector2 = Game.BROWSE_POINTS[posmod(id - 1 + int(customer["visits"]) * 3, Game.BROWSE_POINTS.size())]
	var entering: bool = (customer["position"] as Vector2).y < 10.0
	var route := _navigation.route(Game.DOOR_POINT if entering else customer["position"], goal)
	if entering:
		route.push_front(Game.DOOR_POINT)
	_paths[id] = route
	customer["phase"] = "browsing"
	if route.is_empty():
		customer["phase"] = "waiting"
		customer["look_until"] = int(doc["now_msec"]) + 3000


func _leave(customer: Dictionary) -> void:
	customer["phase"] = "leaving"
	var route := _navigation.route(customer["position"], Game.DOOR_POINT)
	route.append(Game.DOOR_ENTRY)
	_paths[int(customer["id"])] = route


## A new customer enters through the door, wanting the next potion in the
## cycle, with a patience that shrinks a little every day.
func _arrive(now: int) -> void:
	var order: String = Game.POTIONS[_order_index % Game.POTIONS.size()]
	_order_index += 1
	var patience := Game.patience_seconds(int(doc["day"]))
	var customer := {
		"id": _next_customer,
		"order": order,
		"patience_seconds": patience,
		"deadline_msec": now + int(patience * 1000.0),
		"angry": false,
		"served": false,
		"position": Game.DOOR_ENTRY,
		"facing": PI / 2.0,
		"phase": "entering",
		"visits": 0,
		"look_until": 0,
		"next_glance": 0,
	}
	doc["customers"].append(customer)
	_browse(customer)
	_open_door(now)
	_next_customer += 1
	_next_arrival_msec = now + int(Game.arrival_interval(int(doc["day"])) * 1000.0)


## A new day: the clock restarts, the shelf piles are restocked and the
## customers start coming faster.
func _start_day(day: int, now: int) -> void:
	doc["day"] = day
	doc["day_started_msec"] = now
	for station in doc["shelf_stock"]:
		for raw in Game.shelf_items(station):
			if Game.is_raw(raw):
				_change_stock(station, raw, mini(Game.SHELF_RESTOCK, Game.SHELF_MAX_STOCK - stock_at(station, raw)))
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


func get_customer(id: int) -> Dictionary:
	for entry in doc["customers"]:
		var customer: Dictionary = entry
		if int(customer.get("id", -1)) == id:
			return customer
	return {}


func _yes(value: Dictionary) -> Dictionary:
	return {"ok": true, "reason": "", "value": value}


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "value": {}}
