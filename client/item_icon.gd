extends Sprite2D
## One reusable item asset everywhere: shelf stack, hand, recipe, order or effect.
const TEXTURES := {
	"moonleaf": preload("res://assets/items/ingredients/moonleaf/sheet.png"),
	"firecap": preload("res://assets/items/ingredients/firecap/sheet.png"),
	"waterbloom": preload("res://assets/items/ingredients/waterbloom/sheet.png"),
	"void_eye": preload("res://assets/items/ingredients/void_eye/sheet.png"),
	"blood_root": preload("res://assets/items/ingredients/blood_root/sheet.png"),
	"ghost_moth": preload("res://assets/items/ingredients/ghost_moth/sheet.png"),
	"bone_shard": preload("res://assets/items/ingredients/bone_shard/sheet.png"),
	"dusk_crystal": preload("res://assets/items/ingredients/dusk_crystal/sheet.png"),
	"slime_pearl": preload("res://assets/items/ingredients/slime_pearl/sheet.png"),
	"raven_feather": preload("res://assets/items/ingredients/raven_feather/sheet.png"),
	"ember_heart": preload("res://assets/items/ingredients/ember_heart/sheet.png"),
	"silver_spore": preload("res://assets/items/ingredients/silver_spore/sheet.png"),
	"healing_potion": preload("res://assets/items/potions/healing_potion/sheet.png"),
	"mana_potion": preload("res://assets/items/potions/mana_potion/sheet.png"),
	"ember_tonic": preload("res://assets/items/potions/ember_tonic/sheet.png"),
	"veil_draught": preload("res://assets/items/potions/veil_draught/sheet.png"),
	"venom_elixir": preload("res://assets/items/potions/venom_elixir/sheet.png"),
	"spirit_dew": preload("res://assets/items/potions/spirit_dew/sheet.png"),
}
var item_id := ""
var _elapsed := 0.0

func set_item(item: String) -> void:
	if item == item_id and texture != null:
		return
	item_id = item
	texture = TEXTURES.get(item)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = 4
	vframes = 1
	visible = texture != null
	frame = 0
	modulate = Color.WHITE

func _process(delta: float) -> void:
	if texture == null or not is_visible_in_tree():
		return
	_elapsed = fmod(_elapsed + delta, 1.6)
	frame = int(_elapsed / 0.4) % 4
