extends RefCounted
## The shop's rules, with no network in them: one of these keeps every shared
## fact - browsing customers, shelf and player inventory, the cauldron, the
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
var _hint_id := 0
var _hint_pending: Array = []
const CHAT_SECONDS := 5.0
const CHAT_GRACE_SECONDS := 2.0
const REQUEST_LINES := [
	["I'd like ", ", please."],
	["Could I have ", "? My shadow has the hiccups."],
	["One ", ", please. My teapot is haunted."],
	["May I try ", "? The mushrooms recommended it."],
	["A little ", ", please. It's for a small dragon."],
	["Could you brew ", " for me?"],
]
const BANTER := [["Lovely spooky day.", "The best kind!"], ["Did that fern wink?", "It owes me money."], ["Nice hat!", "It chose me."], ["Smells like magic.", "Or mushroom soup."]]


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
		"inventory": {},
		"shelves": {},
		"shelf_stock": {},
		"hints": [],
		"cauldron": {"contents": [], "potion": "", "brew_start_msec": 0, "brew_end_msec": 0, "ready": false},
		"customers": [],
		"door_open_until": 0,
		"effects": [],
	}
	# JSON object keys are Strings, so a seat's carried item is keyed by "0"/"1"
	# on both sides of the wire.
	for seat in Game.MAX_PLAYERS:
		doc["held"][str(seat)] = ""
		doc["inventory"][str(seat)] = []
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
	_hint_id = 0
	_hint_pending.clear()
	# The first customer of the day walks in well before the steady rate.
	_next_arrival_msec = now + int(Game.FIRST_CUSTOMER_SECONDS * 1000.0)


## What a seat is carrying, "" for empty hands.
func held(seat: int) -> String:
	return str(doc["held"].get(str(seat), ""))


## ---------------------------------------------------------------------------
## The six actions. Each one checks everything, then changes as little as
## possible; nothing changes when it returns a refusal.
## ---------------------------------------------------------------------------

## Collect a shelf item into the bag, selecting it for the next interaction.
func take(seat: int, item: String, station: String = "") -> Dictionary:
	if inventory(seat).size() >= Game.INVENTORY_CAPACITY:
		return _no("inventory_full")
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


func inventory(seat: int) -> Array:
	return doc["inventory"].get(str(seat), [])

func select_item(seat: int, item: String) -> Dictionary:
	if item != "" and not inventory(seat).has(item):
		return _no("not_in_inventory")
	doc["held"][str(seat)] = item
	return _yes({})


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


## Take the finished potion into the bag if there is room.
func collect(seat: int) -> Dictionary:
	if inventory(seat).size() >= Game.INVENTORY_CAPACITY:
		return _no("inventory_full")
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
	var now := Time.get_ticks_msec()
	_pause_for_chat(customer, now)
	customer["phase"] = "talking"
	customer["look_until"] = now + int(CHAT_SECONDS * 1000)
	customer["next_glance"] = customer["look_until"]
	customer["facing"] = (from - (customer["position"] as Vector2)).angle()
	customer["speech"] = "..."
	customer["speech_start"] = now
	customer["speech_until"] = customer["chat_until"]
	customer["speaking"] = true
	_paths.erase(customer_id)
	_schedule_hints(customer, now)
	var line: Array = REQUEST_LINES[posmod(customer_id - 1, REQUEST_LINES.size())]
	return _yes({"dialogue_before": line[0], "dialogue_after": line[1], "potion": customer["order"], "customer": customer_id})

func _pause_for_chat(customer: Dictionary, now: int) -> void:
	if int(customer.get("pause_until", 0)) <= now:
		customer["pause_started"] = now
	customer["chat_until"] = now + int(CHAT_SECONDS * 1000)
	customer["pause_until"] = now + int((CHAT_SECONDS + CHAT_GRACE_SECONDS) * 1000)
	customer["patience_paused"] = true
	customer["next_social"] = now + 22000

func _try_social(now: int) -> void:
	var visitors: Array = doc["customers"]
	for i in visitors.size():
		var a: Dictionary = visitors[i]
		if a["phase"] not in ["waiting", "browsing"] or now < int(a.get("next_social", 0)):
			continue
		for j in range(i + 1, visitors.size()):
			var b: Dictionary = visitors[j]
			if b["phase"] not in ["waiting", "browsing"] or now < int(b.get("next_social", 0)):
				continue
			var from: Vector2 = a["position"]
			var to: Vector2 = b["position"]
			if from.distance_to(to) > 72.0 or not Game.motion_clear(from, to, 1.0):
				continue
			var line: Array = BANTER[posmod(int(a["id"]) + int(b["id"]), BANTER.size())]
			for k in 2:
				var person: Dictionary = a if k == 0 else b
				_pause_for_chat(person, now)
				person["phase"] = "chatting"
				person["speech"] = line[k]
				person["speech_start"] = now + k * 2500
				person["speech_until"] = now + (k + 1) * 2500
				person["speaking"] = k == 0
				_paths.erase(int(person["id"]))
			a["facing"] = (to - from).angle()
			b["facing"] = (from - to).angle()
			break


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
	changed = _update_hints(now) or changed

	if now >= _next_arrival_msec and doc["customers"].size() < Game.customer_limit(int(doc["day"])):
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
	var previous_tick := _last_customer_tick
	_last_customer_tick = now
	var survivors: Array = []
	for entry in doc["customers"]:
		var customer: Dictionary = entry
		var id := int(customer["id"])
		if customer["phase"] != "leaving":
			var paused := maxi(0, mini(now, int(customer.get("pause_until", 0))) - maxi(previous_tick, int(customer.get("pause_started", 0))))
			customer["deadline_msec"] = int(customer["deadline_msec"]) + paused
		customer["patience_paused"] = now < int(customer.get("pause_until", 0)) and customer["phase"] != "leaving"
		customer["speaking"] = now >= int(customer.get("speech_start", 0)) and now < int(customer.get("speech_until", 0))
		if customer["phase"] in ["talking", "chatting"] and now >= int(customer["chat_until"]):
			customer["phase"] = "waiting"
			customer["look_until"] = now + 1500
			customer["next_glance"] = now + 1500
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
	_try_social(now)
	return not survivors.is_empty()


func _open_door(now: int) -> void:
	doc["door_open_until"] = maxi(int(doc["door_open_until"]), now + 1800)


func _browse(customer: Dictionary) -> void:
	var id := int(customer["id"])
	var goal: Vector2 = Game.BROWSE_POINTS[posmod(id - 1 + int(customer["visits"]) * 3, Game.BROWSE_POINTS.size())]
	var entering := not Game.in_bounds(customer["position"])
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
		"next_social": now + 6000,
		"pause_started": 0,
		"pause_until": 0,
		"patience_paused": false,
		"chat_until": 0,
		"speech": "",
		"speech_start": 0,
		"speech_until": 0,
		"speaking": false,
	}
	doc["customers"].append(customer)
	_schedule_hints(customer, now)
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
	doc["inventory"][str(seat)] = []


func _carry(seat: int, item: String) -> void:
	var bag := inventory(seat)
	if item != "":
		bag.append(item)
		doc["held"][str(seat)] = item
	else:
		bag.erase(held(seat))
		doc["held"][str(seat)] = str(bag[0]) if not bag.is_empty() else ""

func _schedule_hints(customer: Dictionary, now: int) -> void:
	var needs := Game.recipe_needs(str(customer["order"]))
	var index := 0
	for item in needs:
		_hint_pending.append({"due": now + 800 + index * 350, "customer": int(customer["id"]), "item": str(item)})
		index += 1
	var choice := posmod(int(customer["id"]) * 5, Game.RAW_ITEMS.size())
	while needs.has(Game.RAW_ITEMS[choice]):
		choice = (choice + 1) % Game.RAW_ITEMS.size()
	_hint_pending.append({"due": now + 1500, "customer": int(customer["id"]), "item": Game.RAW_ITEMS[choice]})
	# Bound repeated requests; a talk action may remind the player, never flood state.
	while _hint_pending.size() > 24:
		_hint_pending.pop_front()

func _update_hints(now: int) -> bool:
	var changed := false
	var active: Array = []
	for hint in doc["hints"]:
		if int(hint["until"]) > now:
			active.append(hint)
		else:
			changed = true
	var pending: Array = []
	for job in _hint_pending:
		if int(job["due"]) > now:
			pending.append(job)
			continue
		var customer := get_customer(int(job["customer"]))
		if customer.is_empty() or customer["phase"] == "leaving":
			continue
		var stations: Array[String] = []
		for station in doc["shelf_stock"]:
			if stock_at(station, job["item"]) > 0:
				stations.append(station)
		if stations.is_empty():
			continue
		_hint_id += 1
		active.append({"id": _hint_id, "station": stations[posmod(int(job["customer"]), stations.size())], "item": job["item"], "until": now + 3200})
		changed = true
	_hint_pending = pending
	doc["hints"] = active
	return changed


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
