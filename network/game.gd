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
## Frame the raised stone back wall, cutaway sides and the customer queue below
## the shop. This visual framing does not change the playable room bounds.
const CAMERA_RECT := Rect2(-48.0, -112.0, 736.0, 640.0)

const WALK_SPEED := 120.0     # px/s, flat top-down 8-direction walking
const MAX_SPEED := 240.0      # the authority's sanity bound, above WALK_SPEED
const SEND_INTERVAL := 1.0 / 20.0

## One spawn point per seat, in pixels: side by side on the free middle of the
## shop floor, clear of every station.
const SPAWN_POINTS := [Vector2(280.0, 240.0), Vector2(360.0, 240.0)]
## Both players spawn facing the serving counter (down the screen, +y).
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
const RAW_ITEMS := [MOONLEAF, FIRECAP, WATERBLOOM]
const HEALING_POTION := "healing_potion"
const MANA_POTION := "mana_potion"
const EMBER_TONIC := "ember_tonic"
const POTIONS := [HEALING_POTION, MANA_POTION, EMBER_TONIC]

## A raw ingredient becomes its prepped form at the prep station; the cauldron
## brews the prepped ones back down to the raw ingredients a recipe calls for.
const PREPPED_SUFFIX := "_prepped"

## potion id -> the raw ingredients it needs, its brew time, its coin reward.
const RECIPES := {
	HEALING_POTION: {"needs": {MOONLEAF: 1, FIRECAP: 1, WATERBLOOM: 1}, "brew": 5.0, "reward": 12},
	MANA_POTION: {"needs": {WATERBLOOM: 2, MOONLEAF: 1}, "brew": 4.0, "reward": 10},
	EMBER_TONIC: {"needs": {FIRECAP: 2, MOONLEAF: 1}, "brew": 6.0, "reward": 16},
}

## What each item is called on screen, and its flat placeholder colour.
const ITEM_LABELS := {
	MOONLEAF: "Moonleaf", FIRECAP: "Firecap", WATERBLOOM: "Waterbloom",
	"moonleaf_prepped": "Chopped Moonleaf",
	"firecap_prepped": "Chopped Firecap",
	"waterbloom_prepped": "Chopped Waterbloom",
	HEALING_POTION: "Healing", MANA_POTION: "Mana", EMBER_TONIC: "Ember",
}
const ITEM_COLORS := {
	MOONLEAF: Color(0.48, 0.86, 0.55, 1.0),
	FIRECAP: Color(0.92, 0.42, 0.28, 1.0),
	WATERBLOOM: Color(0.42, 0.66, 0.96, 1.0),
	"moonleaf_prepped": Color(0.28, 0.66, 0.4, 1.0),
	"firecap_prepped": Color(0.7, 0.26, 0.18, 1.0),
	"waterbloom_prepped": Color(0.25, 0.45, 0.72, 1.0),
	HEALING_POTION: Color(0.96, 0.4, 0.55, 1.0),
	MANA_POTION: Color(0.5, 0.6, 0.98, 1.0),
	EMBER_TONIC: Color(0.98, 0.64, 0.22, 1.0),
}

## The six stations' interaction points in pixels: the spot just outside each
## station's body where a player stands to use it. The shelves, the storage and
## the counter are entered from the room side; the bottling station from the
## left.
const STATIONS := {
	"shelves": Vector2(70.0, 170.0),
	"storage": Vector2(110.0, 320.0),
	"prep": Vector2(200.0, 112.0),
	"cauldron": Vector2(450.0, 119.0),
	"bottling": Vector2(530.0, 220.0),
	"counter": Vector2(400.0, 336.0),
}

## The three shelf piles along the left wall, one per raw ingredient: the spot
## a player stands on to take that ingredient.
const SHELF_SPOTS := {
	MOONLEAF: Vector2(70.0, 96.0),
	FIRECAP: Vector2(70.0, 170.0),
	WATERBLOOM: Vector2(70.0, 244.0),
}

## How close a player must stand to use a station, and the slack the authority
## adds because a Command is checked a few milliseconds after the pose it was
## sent alongside.
const INTERACT_RADIUS := 34.0
const INTERACT_SLACK := 14.0
## How long the interact action must be held to chop something.
const PREP_HOLD_SECONDS := 1.0

## Day and difficulty. Customers arrive faster and wait less every day.
const DAY_SECONDS := 120.0
const REPUTATION_START := 50
const REPUTATION_MAX := 100
const REPUTATION_GAIN := 4
const REPUTATION_LOSS := 6
const MAX_QUEUE := 4
const ARRIVAL_BASE_SECONDS := 11.0
const ARRIVAL_MIN_SECONDS := 4.5
const ARRIVAL_SPEEDUP := 0.85
const PATIENCE_BASE_SECONDS := 45.0
const PATIENCE_MIN_SECONDS := 18.0
const PATIENCE_SPEEDUP := 0.9
## How long an angry customer keeps standing there before they walk off.
const ANGRY_SHOW_MSEC := 1200
const SHELF_START_STOCK := 6
const SHELF_RESTOCK := 4
const SHELF_MAX_STOCK := 12
const STORAGE_CAPACITY := 6

## Where queued customers stand, first in line nearest the counter.
const QUEUE_SLOTS := [
	Vector2(400.0, 470.0),
	Vector2(344.0, 470.0),
	Vector2(288.0, 470.0),
	Vector2(232.0, 470.0),
]

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

## A raw ingredient's prepped id, and back again.
static func prepped_of(raw: String) -> String:
	return raw + PREPPED_SUFFIX


static func raw_of(item: String) -> String:
	return item.trim_suffix(PREPPED_SUFFIX)


static func is_raw(item: String) -> bool:
	return RAW_ITEMS.has(item)


static func is_prepped(item: String) -> bool:
	return item.ends_with(PREPPED_SUFFIX) and RAW_ITEMS.has(raw_of(item))


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
	var point: Vector2 = STATIONS.get(station, Vector2.ZERO)
	return point


static func shelf_spot(raw: String) -> Vector2:
	var point: Vector2 = SHELF_SPOTS.get(raw, Vector2.ZERO)
	return point


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
	for raw in needs:
		if int(counts.get(str(raw), 0)) > int(needs[raw]):
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
