extends RefCounted
## Shared by the client and the authority: ids, the shop room geometry and the
## network helpers. Client and shared code never load anything from authority/.

const MAX_PLAYERS := 2
const Cottage = preload("res://network/cottage_layout.gd")

## Room extent for the irregular cottage. Exact floor and wall boundaries live
## in Cottage.FLOOR_POINTS and are shared by art, physics and navigation.
const ROOM_SIZE := Vector2(640.0, 436.0)
const WALL := 16.0
const PLAYER_RADIUS := 10.0
## Bounding rectangle only; the actual walkable outline is not rectangular.
const PLAY_BOUNDS := Rect2(0.0, -20.0, 624.0, 436.0)
## Frame the building, including the raised back wall and cutaway front.
const CAMERA_RECT := Rect2(-112.0, -144.0, 848.0, 664.0)

const WALK_SPEED := 120.0     # px/s, flat top-down 8-direction walking
const MAX_SPEED := 240.0      # the authority's sanity bound, above WALK_SPEED
const SEND_INTERVAL := 1.0 / 20.0

## One spawn point per seat, in pixels: side by side on the free middle of the
## shop floor, clear of every station.
const SPAWN_POINTS := [Vector2(248.0, 240.0), Vector2(280.0, 240.0)]
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
	"moon_west": {"kind": "shelf", "stock": [MOONLEAF, FIRECAP, WATERBLOOM], "at": Vector2(64, 120), "variant": 0},
	"fire_north": {"kind": "shelf", "stock": ["void_eye", "blood_root", "ghost_moth"], "at": Vector2(88, 272), "variant": 1},
	"water_east": {"kind": "shelf", "stock": ["bone_shard", "dusk_crystal", "slime_pearl"], "at": Vector2(552, 120), "variant": 2},
	"moon_island": {"kind": "shelf", "stock": ["raven_feather", "ember_heart", "silver_spore"], "at": Vector2(192, 320), "variant": 3},
	"fire_east": {"kind": "shelf", "stock": [MOONLEAF, "void_eye", "bone_shard", "raven_feather"], "at": Vector2(552, 264), "variant": 4},
	"water_south": {"kind": "shelf", "stock": POTIONS, "at": Vector2(432, 80), "variant": 5, "display": true},
	"moon_nook": {"kind": "shelf", "stock": [FIRECAP, "blood_root", "dusk_crystal", "ember_heart"], "at": Vector2(536, 376), "variant": 6},
	"fire_low": {"kind": "shelf", "stock": [WATERBLOOM, "ghost_moth", "slime_pearl", "silver_spore"], "at": Vector2(72, 376), "variant": 7},
	"water_north": {"kind": "shelf", "stock": POTIONS, "at": Vector2(192, 80), "variant": 8, "display": true},
	"cauldron": {"kind": "cauldron", "at": Vector2(352, 272)},
}
## Board rows of empty library furniture, in native 64x80 sprite coordinates.
## Runtime item nodes are anchored to these boards, independently of the wood art.
const SHELF_ROWS := [[42, 78, 116], [42, 78, 116], [42, 78, 116], [42, 78, 116], [42, 78, 116], [86, 116], [42, 78, 116], [74, 116], [86, 116]]
const SHELF_MIRROR := [false, false, true, false, true, true, true, false, false]
const SHELF_SIDEWAYS := [false, true, false, false, true, false, false, true, false]
const SHELF_SCALE := 1.2
const CLUTTER := {
	"books": {"at": Vector2(288, 368), "size": Vector2(40, 12), "variant": 1},
}
static var _polygons := {}
const DOOR_ENTRY := Vector2(312, -38)
const DOOR_POINT := Vector2(312, 12)
const CUSTOMER_SPEED := 52.0
const BROWSE_POINTS := [Vector2(120, 168), Vector2(248, 144), Vector2(496, 168), Vector2(488, 304), Vector2(240, 352), Vector2(416, 352), Vector2(128, 312), Vector2(304, 176)]
const INVENTORY_CAPACITY := 8

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
const FIRST_CUSTOMER_SECONDS := 8.0
const ARRIVAL_BASE_SECONDS := 34.0
const ARRIVAL_MIN_SECONDS := 20.0
const ARRIVAL_SPEEDUP := 0.85
const PATIENCE_BASE_SECONDS := 150.0
const PATIENCE_MIN_SECONDS := 110.0
const PATIENCE_SPEEDUP := 0.97
## How long an angry customer keeps standing there before they walk off.
const ANGRY_SHOW_MSEC := 1200
const SHELF_START_STOCK := 6
const SHELF_RESTOCK := 4
const SHELF_MAX_STOCK := 12

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
	return position.is_finite() and Geometry2D.is_point_in_polygon(position, PackedVector2Array(Cottage.FLOOR_POINTS))


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
	return anchor + (data.get("approach", Vector2(0, 18) if station == "moon_nook" else Vector2(0, 28)) as Vector2)


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
		for x in [20, 40, 60]:
			result.append((shelf_project(int(FURNITURE[id]["variant"]), Vector2(x, row)) - Vector2(40, 128)) * SHELF_SCALE)
	return result

static func shelf_project(variant: int, point: Vector2) -> Vector2:
	var side: bool = SHELF_SIDEWAYS[variant]
	var projected := Vector2(point.x * (0.55 if side else 0.82) + (18 if side else 10), point.y + point.x * (0.16 if side else 0.12) - (8 if side else 6))
	if SHELF_MIRROR[variant]:
		projected.x = 80 - projected.x
	return projected


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
		var variant := int(data["variant"])
		var left := shelf_project(variant, Vector2(10, 125))
		var right := shelf_project(variant, Vector2(68, 125))
		var depth := Vector2(-12 if SHELF_MIRROR[variant] else 12, -18)
		for point in [left, right, right + depth, left + depth]:
			points.append(anchor + (point - Vector2(40, 128)) * SHELF_SCALE)
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
	var boundary := PackedVector2Array(Cottage.FLOOR_POINTS)
	for i in boundary.size():
		var nearest := Geometry2D.get_closest_point_to_segment(point, boundary[i], boundary[(i + 1) % boundary.size()])
		if point.distance_to(nearest) < radius - 0.05:
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
	return maxf(ARRIVAL_BASE_SECONDS - float(maxi(day - 1, 0)) * 3.0, ARRIVAL_MIN_SECONDS)

static func customer_limit(day: int) -> int:
	return clampi(day, 1, MAX_CUSTOMERS)


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
