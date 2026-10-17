extends RefCounted
const Authority = preload("res://authority/main.gd")
const Navigation = preload("res://network/shop_navigation.gd")
const Game = preload("res://network/game.gd")
var failures: Array[String] = []
var _id := 0

func run() -> Array[String]:
	var server := Authority.new()
	_check(server.join(1) and server.join(42), "two players admitted")
	_check(not server.join(99), "third player refused")
	_check(int(server.players[1]["seat"]) != int(server.players[42]["seat"]), "distinct seats")
	_check(not server.move(42, Vector2(-50, 0), 0), "out-of-bounds motion refused")
	_check(not server.move(42, Vector2(620, 400), 0), "teleport refused")
	_check(not server.move(42, Game.FURNITURE["cauldron"]["at"] - Vector2(0, 10), 0), "motion inside furniture refused")
	_check(server.move(42, Game.spawn_point(1) + Vector2(10, 0), 0), "legal motion accepted")
	# Both endpoints are clear and within the speed budget, but the path crosses
	# a chest. Endpoint-only acceptance used to allow this to pass through objects.
	var near_chest := Vector2(64, 312)
	var beyond_chest := Vector2(64, 376)
	_check(Game.floor_clear(near_chest) and Game.floor_clear(beyond_chest), "sweep fixture endpoints are clear")
	server.players[42]["position"] = near_chest
	_check(not server.move(42, beyond_chest, 0), "authority rejects moving through furniture between clear endpoints")
	server.players[42]["position"] = Game.spawn_point(1)
	var before := server.shop.doc.duplicate(true)
	var shelf := Game.shelf_id(Game.MOONLEAF)
	_check(not server.command(42, 0, "take", shelf, Game.MOONLEAF)["ok"], "invalid command id refused")
	_check(not server.command(42, 1, "take", shelf, Game.MOONLEAF)["ok"], "distant action refused")
	_check(server.shop.doc == before, "refused action leaves shop unchanged")
	server.players[1]["position"] = Game.shelf_spot(Game.MOONLEAF)
	server.shop._change_stock(shelf, Game.MOONLEAF, 1 - server.shop.stock_at(shelf, Game.MOONLEAF))
	var other_stock := server.shop.stock_at("fire_east", Game.MOONLEAF)
	var first := server.command(1, 1, "take", shelf, Game.MOONLEAF)
	_check(bool(first["ok"]), "take succeeds")
	_check(server.shop.stock_at("fire_east", Game.MOONLEAF) == other_stock, "taking from one shelf does not remove another shelf's physical stock")
	var effects: int = server.shop.doc["effects"].size()
	_check(server.command(1, 1, "take", shelf, Game.MOONLEAF) == first, "duplicate returns receipt")
	_check(server.shop.doc["effects"].size() == effects, "duplicate command does not replay interaction effects")
	server.players[42]["position"] = Game.shelf_spot(Game.MOONLEAF)
	_check(not server.command(42, 2, "take", shelf, Game.MOONLEAF)["ok"], "last ingredient cannot be duplicated")
	_check(bool(server.command(1, 2, "restock", shelf, Game.MOONLEAF)["ok"]), "ingredient can be put back")
	_check(server.shop.stock_at(shelf, Game.MOONLEAF) == 1 and server.shop.held(0) == "", "restocking conserves inventory")
	server.leave(1)
	_check(server.join(99, 999), "free seat can rejoin")
	_check(int(server.players[99]["character"]) == 1, "appearance index constrained")

	for potion in Game.POTIONS:
		server = Authority.new()
		server.join(1)
		_id = 0
		for raw in Game.recipe_needs(potion):
			for _count in int(Game.recipe_needs(potion)[raw]):
				_check(_act(server, "take", Game.shelf_id(raw), raw), "take recipe ingredient")
				_check(_act(server, "add", "cauldron"), "add raw ingredient directly, with no prep station")
		_check(not _act(server, "collect", "cauldron"), "cannot collect before brew finishes")
		server.shop.doc["cauldron"]["brew_end_msec"] = 0
		server.shop.tick()
		_check(_act(server, "collect", "cauldron"), "collect completed brew directly from cauldron")
		_check(_act(server, "restock", "water_south", potion), "finished bottle can be placed on a potion shelf")
		_check(server.shop.stock_at("water_south", potion) == 1, "potion shelf stores the distinct bottle asset's item id")
		_check(_act(server, "take", "water_south", potion), "stored potion can be retrieved")
		server.shop._arrive(Time.get_ticks_msec())
		var customer: Dictionary = server.shop.doc["customers"][0]
		customer["position"] = Vector2(288, 192)
		customer["order"] = "wrong"
		server.players[1]["position"] = customer["position"]
		_id += 1
		_check(not server.command(1, _id, "serve", "customer", str(customer["id"]))["ok"], "wrong potion refused")
		customer["order"] = potion
		server.players[1]["position"] = Vector2(600, 400)
		_id += 1
		_check(not server.command(1, _id, "serve", "customer", str(customer["id"]))["ok"], "cannot serve a customer across the room")
		server.players[1]["position"] = customer["position"]
		_id += 1
		_check(bool(server.command(1, _id, "serve", "customer", str(customer["id"]))["ok"]), "serve nearby matching customer")
		_check(int(server.shop.doc["coins"]) == Game.reward(potion), "correct coin reward")
		_check(server.shop.held(0) == "" and customer["phase"] == "leaving" and customer["served"], "served customer walks out instead of vanishing")
		_id += 1
		_check(not server.command(1, _id, "serve", "customer", str(customer["id"]))["ok"], "departing customer cannot be rewarded twice")

	server = Authority.new()
	server.join(1)
	_id = 0
	_check(_act(server, "inspect", "storage_west"), "empty chest can be opened")
	_check(_act(server, "take", Game.shelf_id(Game.FIRECAP), Game.FIRECAP), "take item for storage")
	_check(_act(server, "put", "storage_west"), "store carried ingredient")
	_check(_act(server, "take", "storage_south"), "retrieve from shared storage")
	_check(server.shop.held(0) == Game.FIRECAP, "storage returns exact ingredient")
	_check(not _act(server, "prep", "prep"), "removed prep station cannot be used")
	server.players[1]["position"] = Game.DOOR_POINT
	_id += 1
	_check(bool(server.command(1, _id, "door", "door", "")["ok"]), "door can be opened by player")
	_check(int(server.shop.doc["door_open_until"]) > Time.get_ticks_msec(), "door opening is shared state")
	_check(not Game.can_still_brew([Game.MOONLEAF, "invalid"]), "invalid ingredient never completes a recipe prefix")
	_test_browsing()
	return failures

func _test_browsing() -> void:
	var server := Authority.new()
	var now := Time.get_ticks_msec()
	server.shop._next_arrival_msec = now + 1000000
	server.shop._arrive(now)
	server.shop._next_arrival_msec = now + 1000000
	var customer: Dictionary = server.shop.doc["customers"][0]
	_check(customer["position"] == Game.DOOR_ENTRY, "customer starts in doorway")
	var saw_inside := false
	var saw_waiting := false
	var blocked := false
	for i in range(1, 201):
		server.shop.tick(now + i * 100)
		var position: Vector2 = customer["position"]
		saw_inside = saw_inside or position.y > 80
		saw_waiting = saw_waiting or customer["phase"] == "waiting"
		if position.y >= 10 and not Game.floor_clear(position, 9.0):
			blocked = true
	_check(saw_inside and saw_waiting and int(customer["visits"]) > 0, "customer enters, browses, waits and looks elsewhere")
	_check(not blocked, "browsing path avoids furniture")
	# Make patience expire; reputation is charged once while they walk to the exit.
	customer["deadline_msec"] = now
	server.shop.tick(now + 20100)
	var reputation: int = server.shop.doc["reputation"]
	_check(customer["angry"] and customer["phase"] == "leaving", "impatient customer heads for the door")
	for i in range(202, 601):
		server.shop.tick(now + i * 100)
	_check(server.shop.doc["customers"].is_empty(), "departing customer reaches exit and is removed")
	_check(int(server.shop.doc["reputation"]) == reputation, "timeout penalty is charged only once")
	var navigation := Navigation.new()
	for id in Game.FURNITURE:
		var target := Game.station_point(id)
		var route := navigation.route(Game.spawn_point(0), target)
		_check(not route.is_empty() and route[-1].distance_to(target) < 0.1, "furniture interaction point reachable: " + id)
		var previous := Game.spawn_point(0)
		for point in route:
			_check(Game.motion_clear(previous, point, 12.0), "navigation clears angled furniture and clutter: " + id)
			previous = point

func _act(server: RefCounted, action: String, station: String, item: String = "") -> bool:
	server.players[1]["position"] = Game.station_point(station)
	_id += 1
	return bool(server.command(1, _id, action, station, item)["ok"])

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
