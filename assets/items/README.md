# Visual item catalog

Original dark-fantasy pixel artwork. Every item has its own folder containing
four editable SVG/PNG frames and a **128×40** sheet of four **32×40** cells.
No item is painted into furniture. `client/item_icon.gd` is the shared renderer
used by transient shelf hints, search panels, inventory, carried items, transfer
effects, recipes and customer bubbles. World shelf stock is no longer permanent.

## Six potion silhouettes

| Internal ID (not a UI name) | Visual identity |
| --- | --- |
| `healing_potion` | Crimson narrow vial, gold diamond band |
| `mana_potion` | Azure round globe flask |
| `ember_tonic` | Amber square/hip flask, broad shoulders |
| `veil_draught` | Violet crescent vessel with hanging charm |
| `venom_elixir` | Acid-green triangular flask |
| `spirit_dew` | Pearly pink heart bottle and ribbon |

Liquid bubbles shift slightly inside the glass across four frames; the whole
bottle does not bounce or change shape. Shape supplements color for recognition.

## Twelve independent ingredients

Forked spectral herb, spotted crimson fungus, blue crystal blossom, golden void
eye, thorned blood root, pale ghost moth, curved bone shard, violet crystal cluster,
green slime pearl, dark raven feather, glowing ember heart and silver spore cluster.
Each has subtle dedicated motion: spores, glints, bubbles, pupil movement, wing
movement or shifting glow. Technical IDs appear only in source/state; the play
interface uses sprites rather than item-name labels.

## Rebuild

```sh
python3 tools/draw_item_catalog.py
```

Requires Python 3 and ImageMagick. Preserve manual frame edits before regenerating.
Gameplay definitions are in `network/game.gd`: six two-ingredient recipes
collectively use all twelve ingredients.

For shelf placement the illustration's bottom is around source y=38; anchor this
to the board instead of using the full canvas center/padding.
