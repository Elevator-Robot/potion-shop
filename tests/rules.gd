extends RefCounted

const Authority = preload("res://authority/main.gd")
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
	_check(server.move(42, Game.spawn_point(1) + Vector2(10, 0), 0), "legal motion accepted")
	var before := server.shop.doc.duplicate(true)
	_check(not server.command(42, 0, "take", "shelves", Game.MOONLEAF)["ok"], "invalid command id refused")
	_check(not server.command(42, 1, "take", "shelves", Game.MOONLEAF)["ok"], "distant action refused")
	_check(server.shop.doc == before, "refused action leaves shop unchanged")

	# Fixture positions isolate authority/rule behavior; they do not prove walking.
	server.players[1]["position"] = Game.shelf_spot(Game.MOONLEAF)
	server.shop.doc["shelves"][Game.MOONLEAF] = 1
	var first := server.command(1, 1, "take", "shelves", Game.MOONLEAF)
	_check(bool(first["ok"]), "take succeeds")
	_check(server.command(1, 1, "take", "shelves", Game.MOONLEAF) == first, "duplicate returns receipt")
	server.players[42]["position"] = Game.shelf_spot(Game.MOONLEAF)
	_check(not server.command(42, 2, "take", "shelves", Game.MOONLEAF)["ok"], "last item cannot be taken twice")
	_check(int(server.shop.doc["shelves"][Game.MOONLEAF]) == 0, "stock never negative")
	server.leave(1)
	_check(server.shop.held(0) == "", "disconnect releases carried item")
	_check(server.join(99), "freed seat can rejoin")

	for potion in Game.POTIONS:
		server = Authority.new()
		server.join(1)
		_id = 0
		for raw in Game.recipe_needs(potion):
			for _count in int(Game.recipe_needs(potion)[raw]):
				_check(_act(server, "take", "shelves", raw), "take recipe ingredient")
				_check(_act(server, "prep", "prep"), "prepare ingredient")
				_check(_act(server, "add", "cauldron"), "add ingredient")
		_check(not _act(server, "bottle", "bottling"), "cannot bottle before brew finishes")
		server.shop.doc["cauldron"]["brew_end_msec"] = 0
		server.shop.tick()
		_check(_act(server, "bottle", "bottling"), "bottle completed brew")
		server.shop.doc["customers"] = [{"id": 1, "order": "wrong", "angry": false}]
		_check(not _act(server, "serve", "counter"), "wrong potion refused")
		server.shop.doc["customers"][0]["order"] = potion
		_check(_act(server, "serve", "counter"), "serve matching potion")
		_check(int(server.shop.doc["coins"]) == Game.reward(potion), "correct coin reward")
		_check(server.shop.held(0) == "" and server.shop.doc["customers"].is_empty(), "serving consumes potion and order")
	return failures


func _act(server: RefCounted, action: String, station: String, item: String = "") -> bool:
	server.players[1]["position"] = Game.shelf_spot(item) if station == "shelves" else Game.station_point(station)
	_id += 1
	return bool(server.command(1, _id, action, station, item)["ok"])


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
