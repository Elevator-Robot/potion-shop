extends RefCounted
## Shared by the client and the authority: ids, the shop room geometry and the
## network helpers. Client and shared code never load anything from authority/.

const MAX_PLAYERS := 2

## Room geometry in pixels, shared so the client's floor drawing and the
## authority's bounds check cannot drift apart. The interior is 640x420; the
## 16 px walls sit just outside it.
const ROOM_SIZE := Vector2(640.0, 420.0)
const WALL := 16.0
const PLAYER_RADIUS := 10.0
## Where a player centre may legally be: the interior inset by the player
## radius (10, 10 to 630, 410).
const PLAY_BOUNDS := Rect2(10.0, 10.0, 620.0, 400.0)
## Frame the building, including the raised back wall and cutaway front.
const CAMERA_RECT := Rect2(-48.0, -116.0, 736.0, 580.0)

const WALK_SPEED := 120.0     # px/s, flat top-down 8-direction walking
const MAX_SPEED := 240.0      # the authority's sanity bound, above WALK_SPEED
const SEND_INTERVAL := 1.0 / 20.0

## One spawn point per seat, in pixels: side by side on the free middle of the
## shop floor, clear of every station.
const SPAWN_POINTS := [Vector2(280.0, 252.0), Vector2(312.0, 252.0)]
## Both players initially face into the room (down the screen, +y).
const SPAWN_FACING := 1.5707964

## Placeholder tints by seat: 0 is green-teal (P1), 1 is purple (P2).
const TINT_P1 := Color(0.25, 0.8, 0.55, 1.0)
const TINT_P2 := Color(0.62, 0.42, 0.92, 1.0)

## ---------------------------------------------------------------------------
## Shop rules. The client and the authority both read every line below, so item
## ids, recipes, station positions and timings can never drift apart.
## ---------------------------------------------------------------------------

## Items. These cross JSON inside the snapshot and inside Commands, and a JSON
## round trip always hands back plain Strings, so the ids are Strings too.
const MOONLEAF := "moonleaf"
const FIRECAP := "firecap"
const WATERBLOOM := "waterbloom"
const RAW_ITEMS := [MOONLEAF, FIRECAP, WATERBLOOM, "void_eye", "blood_root", "ghost_moth", "bone_shard", "dusk_crystal", "slime_pearl", "raven_feather", "ember_heart", "silver_spore"]
const HEALING_POTION := "healing_potion"
const MANA_POTION := "mana_potion"
const EMBER_TONIC := "ember_tonic"
const POTIONS := [HEALING_POTION, MANA_POTION, EMBER_TONIC, "veil_draught", "venom_elixir", "spirit_dew"]
const ALL_ITEMS := RAW_ITEMS + POTIONS

## potion id -> the raw ingredients it needs, its brew time, its coin reward.
const RECIPES := {
	HEALING_POTION: {"needs": {MOONLEAF: 1, FIRECAP: 1}, "brew": 5.0, "reward": 12},
	MANA_POTION: {"needs": {WATERBLOOM: 1, "silver_spore": 1}, "brew": 4.0, "reward": 12},
	EMBER_TONIC: {"needs": {"bone_shard": 1, "ember_heart": 1}, "brew": 6.0, "reward": 16},
	"veil_draught": {"needs": {"void_eye": 1, "dusk_crystal": 1}, "brew": 5.5, "reward": 16},
	"venom_elixir": {"needs": {"blood_root": 1, "slime_pearl": 1}, "brew": 4.5, "reward": 14},
	"spirit_dew": {"needs": {"ghost_moth": 1, "raven_feather": 1}, "brew": 6.0, "reward": 18},
}

## What each item is called on screen, and its flat placeholder colour.
const ITEM_LABELS := {
	MOONLEAF: "Moonleaf", FIRECAP: "Firecap", WATERBLOOM: "Waterbloom",
	HEALING_POTION: "Healing", MANA_POTION: "Mana", EMBER_TONIC: "Ember",
}
const ITEM_COLORS := {
	MOONLEAF: Color(0.48, 0.86, 0.55, 1.0),
	FIRECAP: Color(0.92, 0.42, 0.28, 1.0),
	WATERBLOOM: Color(0.42, 0.66, 0.96, 1.0),
	HEALING_POTION: Color("cf456f"),
	MANA_POTION: Color("438fdf"),
	EMBER_TONIC: Color("e49c37"),
	"veil_draught": Color("9762d6"), "venom_elixir": Color("8bbf40"), "spirit_dew": Color("dfb7ca"),
}

## Feet anchors of the furniture. Art, interaction and navigation use this one
## layout; the tall parts of shelves are above their shallow collision bases.
const FURNITURE := {
	"moon_west": {"kind": "shelf", "stock": [MOONLEAF, FIRECAP, WATERBLOOM], "at": Vector2(88, 112), "variant": 0},
	"fire_north": {"kind": "shelf", "stock": ["void_eye", "blood_root", "ghost_moth"], "at": Vector2(216, 112), "variant": 1},
	"water_east": {"kind": "shelf", "stock": ["bone_shard", "dusk_crystal", "slime_pearl"], "at": Vector2(560, 112), "variant": 2},
	"moon_island": {"kind": "shelf", "stock": ["raven_feather", "ember_heart", "silver_spore"], "at": Vector2(224, 272), "variant": 3},
	"fire_east": {"kind": "shelf", "stock": [MOONLEAF, "void_eye", "bone_shard", "raven_feather"], "at": Vector2(544, 272), "variant": 4},
	"water_south": {"kind": "shelf", "stock": POTIONS, "at": Vector2(512, 376), "variant": 5},
	"moon_nook": {"kind": "shelf", "stock": [FIRECAP, "blood_root", "dusk_crystal", "ember_heart"], "at": Vector2(96, 272), "variant": 6},
	"fire_low": {"kind": "shelf", "stock": [WATERBLOOM, "ghost_moth", "slime_pearl", "silver_spore"], "at": Vector2(160, 376), "variant": 7},
	"water_north": {"kind": "shelf", "stock": POTIONS, "at": Vector2(432, 112), "variant": 8},
	"storage_west": {"kind": "storage", "at": Vector2(64, 360), "approach": Vector2(44, -30)},
	"storage_south": {"kind": "storage", "at": Vector2(320, 376)},
	"cauldron": {"kind": "cauldron", "at": Vector2(400, 272)},
}
## Board rows of empty library furniture, in native 64x80 sprite coordinates.
## Runtime item nodes are anchored to these boards, independently of the wood art.
const SHELF_ROWS := [[28, 50, 72], [32, 52, 72], [32, 52, 72], [30, 51, 72], [32, 52, 72], [48, 72], [30, 51, 72], [48, 72], [48, 72]]
const CLUTTER := {
	"basket": {"at": Vector2(80, 408), "size": Vector2(56, 16), "variant": 0},
	"books": {"at": Vector2(272, 340), "size": Vector2(40, 12), "variant": 1},
	"bottles": {"at": Vector2(604, 338), "size": Vector2(44, 14), "variant": 2},
}
static var _polygons := {}
const DOOR_ENTRY := Vector2(320, -18)
const DOOR_POINT := Vector2(320, 32)
const CUSTOMER_SPEED := 52.0
const BROWSE_POINTS := [Vector2(136, 168), Vector2(272, 160), Vector2(496, 160), Vector2(488, 304), Vector2(224, 328), Vector2(400, 352), Vector2(112, 328), Vector2(304, 192)]

## How close a player must stand to use a station, and the slack the authority
## adds because a Command is checked a few milliseconds after the pose it was
## sent alongside.
const INTERACT_RADIUS := 44.0
const INTERACT_SLACK := 14.0

## Day and difficulty. Customers arrive faster and wait less every day.
const DAY_SECONDS := 120.0
const REPUTATION_START := 50
const REPUTATION_MAX := 100
const REPUTATION_GAIN := 4
const REPUTATION_LOSS := 6
const MAX_CUSTOMERS := 4
const ARRIVAL_BASE_SECONDS := 14.0
const ARRIVAL_MIN_SECONDS := 8.0
const ARRIVAL_SPEEDUP := 0.85
const PATIENCE_BASE_SECONDS := 90.0
const PATIENCE_MIN_SECONDS := 45.0
const PATIENCE_SPEEDUP := 0.9
## How long an angry customer keeps standing there before they walk off.
const ANGRY_SHOW_MSEC := 1200
const SHELF_START_STOCK := 6
const SHELF_RESTOCK := 4
const SHELF_MAX_STOCK := 12
const STORAGE_CAPACITY := 12

## How often the authority re-sends the Shop document even when nothing
## changed, so late joiners and a lossy network always catch up.
const SHOP_HEARTBEAT := 0.25


## A seat's spawn point on the shop floor.
static func spawn_point(seat: int) -> Vector2:
	var point: Vector2 = SPAWN_POINTS[clampi(seat, 0, SPAWN_POINTS.size() - 1)]
	return point


## A seat's first pose. `entity` ties the pose to the player's entity and
## `seat` lets each client colour players by seat.
static func spawn_pose(seat: int, entity_id: int) -> Dictionary:
	return {
		"entity": entity_id,
		"seat": seat,
		"character": seat,
		"position": spawn_point(seat),
		"facing": SPAWN_FACING,
	}


## The authority's bounds check: a finite point inside the room, inset by the
## player radius so a player centre can never sit in a wall.
static func in_bounds(position: Vector2) -> bool:
	return position.is_finite() and PLAY_BOUNDS.has_point(position)


## Rebuilds a pose with exactly the declared field types. Submitting a pose
## whose types do not match the schema is refused as an invalid state, so both
## player scripts normalise whatever they receive before they re-send it.
static func pose_from(state: Dictionary) -> Dictionary:
	var position_value: Variant = state.get("position", Vector2.ZERO)
	return {
		"entity": int(state.get("entity", -1)),
		"seat": int(state.get("seat", -1)),
		"character": int(state.get("character", state.get("seat", 0))),
		"position": position_value if position_value is Vector2 else Vector2.ZERO,
		"facing": float(state.get("facing", 0.0)),
	}


## The placeholder colour of a seat.
static func seat_color(seat: int) -> Color:
	return TINT_P1 if seat == 0 else TINT_P2


## ---------------------------------------------------------------------------
## Item helpers.
## ---------------------------------------------------------------------------

static func is_raw(item: String) -> bool:
	return RAW_ITEMS.has(item)

static func is_item(item: String) -> bool:
	return ALL_ITEMS.has(item)


static func is_potion(item: String) -> bool:
	return POTIONS.has(item)


static func item_label(item: String) -> String:
	return str(ITEM_LABELS.get(item, "nothing"))


static func item_color(item: String) -> Color:
	var color: Color = ITEM_COLORS.get(item, Color(0.6, 0.6, 0.6, 1.0))
	return color


static func recipe(potion: String) -> Dictionary:
	var found: Dictionary = RECIPES.get(potion, {})
	return found


static func reward(potion: String) -> int:
	return int(recipe(potion).get("reward", 0))


## ---------------------------------------------------------------------------
## Station and difficulty helpers.
## ---------------------------------------------------------------------------

static func station_point(station: String) -> Vector2:
	if station == "door":
		return DOOR_POINT
	var data: Dictionary = FURNITURE.get(station, {})
	var anchor: Vector2 = data.get("at", Vector2.ZERO)
	return anchor + (data.get("approach", Vector2(0, 28)) as Vector2)


static func shelf_spot(raw: String) -> Vector2:
	return station_point(shelf_id(raw))


static func shelf_id(raw: String) -> String:
	for id in FURNITURE:
		if shelf_items(id).has(raw):
			return id
	return ""

static func shelf_items(id: String) -> Array:
	return FURNITURE.get(id, {}).get("stock", [])

static func shelf_slots(id: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for row in SHELF_ROWS[int(FURNITURE[id]["variant"])]:
		for x in [14, 32, 50]:
			result.append(Vector2(x - 32, row - 80) * 1.5)
	return result


static func furniture_rect(id: String) -> Rect2:
	var points := furniture_polygon(id)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


static func furniture_polygon(id: String) -> PackedVector2Array:
	if _polygons.has(id):
		return _polygons[id]
	var points := PackedVector2Array()
	var data: Dictionary = FURNITURE.get(id, CLUTTER.get(id, {}))
	var anchor: Vector2 = data["at"]
	if data.get("kind", "") == "shelf":
		for point in [Vector2(-42, -28), Vector2(42, -28), Vector2(42, 0), Vector2(-42, 0)]:
			points.append(anchor + point)
	elif data.get("kind", "") == "cauldron":
		for point in [Vector2(-26, -42), Vector2(26, -42), Vector2(36, -26), Vector2(30, -4), Vector2(-30, -4), Vector2(-36, -26)]:
			points.append(anchor + point)
	else:
		var size: Vector2 = data.get("size", Vector2(58, 32))
		for point in [Vector2(-size.x / 2, -size.y), Vector2(size.x / 2, -size.y), Vector2(size.x / 2, 0), Vector2(-size.x / 2, 0)]:
			points.append(anchor + point)
	_polygons[id] = points
	return points


static func floor_clear(point: Vector2, radius: float = 10.0) -> bool:
	if not in_bounds(point):
		return false
	for id in FURNITURE.keys() + CLUTTER.keys():
		var polygon := furniture_polygon(id)
		if Geometry2D.is_point_in_polygon(point, polygon):
			return false
		for i in polygon.size():
			var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
			if point.distance_squared_to(closest) < pow(maxf(radius - 0.05, 0.0), 2):
				return false
	return true


static func motion_clear(from: Vector2, to: Vector2, radius: float = PLAYER_RADIUS) -> bool:
	# Check the complete travel segment, not just a destination on the far side.
	var steps := maxi(1, ceili(from.distance_to(to) / 2.0))
	for i in range(steps + 1):
		if not floor_clear(from.lerp(to, float(i) / steps), radius):
			return false
	return true


## Seconds between customers on `day`: every day they come a little faster.
static func arrival_interval(day: int) -> float:
	var factor := pow(ARRIVAL_SPEEDUP, float(maxi(day - 1, 0)))
	return maxf(ARRIVAL_BASE_SECONDS * factor, ARRIVAL_MIN_SECONDS)


## Seconds a customer waits on `day` before giving up and leaving angry.
static func patience_seconds(day: int) -> float:
	var factor := pow(PATIENCE_SPEEDUP, float(maxi(day - 1, 0)))
	return maxf(PATIENCE_BASE_SECONDS * factor, PATIENCE_MIN_SECONDS)


## ---------------------------------------------------------------------------
## Cauldron rules: the contents are raw ingredient ids, and a recipe is exact.
## ---------------------------------------------------------------------------

## The potion a pile of raw ingredients makes, or "" while it is still on its
## way to one.
static func potion_for(contents: Array) -> String:
	for potion in POTIONS:
		if _counts_match(contents, recipe_needs(potion)):
			return potion
	return ""


## True while the cauldron's contents could still become some potion, so an
## ingredient that fits no recipe at all is refused before it goes in.
static func can_still_brew(contents: Array) -> bool:
	for potion in POTIONS:
		if _within(contents, recipe_needs(potion)):
			return true
	return false


static func recipe_needs(potion: String) -> Dictionary:
	var needs: Dictionary = recipe(potion).get("needs", {})
	return needs


static func _counts(contents: Array) -> Dictionary:
	var counts := {}
	for item in contents:
		var key := str(item)
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


## True while nothing in `contents` overshoots what `needs` asks for.
static func _within(contents: Array, needs: Dictionary) -> bool:
	var counts := _counts(contents)
	for raw in counts:
		if not needs.has(raw) or int(counts[raw]) > int(needs[raw]):
			return false
	return true


static func _counts_match(contents: Array, needs: Dictionary) -> bool:
	var counts := _counts(contents)
	if counts.size() != needs.size():
		return false
	var total := 0
	for raw in needs:
		var want := int(needs[raw])
		if int(counts.get(str(raw), 0)) != want:
			return false
		total += want
	return total == contents.size()


## ---------------------------------------------------------------------------
## The shared clock reading.
## ---------------------------------------------------------------------------

## Seconds left before `deadline_msec`. A snapshot carries the authority's own
## clock reading at the moment of the snapshot, plus when we received it, so
## every client can animate the same countdown between snapshots without ever
## synchronising clocks.
static func seconds_left(deadline_msec: float, server_now_msec: float, local_at_msec: float, local_now_msec: float) -> float:
	return (deadline_msec - server_now_msec - (local_now_msec - local_at_msec)) / 1000.0
