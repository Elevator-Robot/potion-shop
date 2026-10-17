# Potion Shop art direction

## Visual target

Primary user-supplied concept folder:
`/home/aphexlog/Google Drive/Game Dev/Potion Shop/potion-shop/concept`, including
`exterior/`. Inspect the actual references for future artwork. The active
`assets/atmosphere/` pass uses violet windows, plum floors, patterned rugs, angled
decorated shelving, glowing mushrooms and layered trees. Rebuild with
`python3 tools/draw_concept_pass.py`. Tree derivatives retain source paths and
hashes in `assets/atmosphere/trees/sources.json`; their four-frame animation uses
canopy sway and glow changes on supplied cutouts, not redrawn tree poses.

Shelf sheets are 80×128 cells, nine rows and four columns, with a separate
decoration atlas. Two entrance display racks show real stored potion sprites;
ingredient shelves conceal stock. Thoughts use a cloud with round trailing dots;
speech uses a warm rounded panel with a pointed tail. The old bordered icon frame
is exclusive to shelf hints. Customer requests are intermittent or learned by
talking, with an animated potion icon inline in the spoken sentence.

A cozy fantasy potion shop with warm wood, cool stone, stained glass, and friendly
big-headed pixel characters. Recognizable assets are part of the requested game,
not an optional finishing step. Labeled geometry is only a layout placeholder.

Characters share soft plum outlines, large expressive eyes, rosy cheeks, small
hands/boots, readable silhouettes and gentle animation. Outfits, hats, hair and
accessories distinguish characters rather than recoloring one generic silhouette.

## Player identity

- **Aaron** (choice 0): original reference `assets/characters/elf.png` depicts a
  brown-haired witch in a blue coat, brown boots, and a broad floppy purple hat
  with gold and blue bands. Current art is in `assets/characters/blue_witch/`.
- **Renna** (choice 1, default): original reference
  `assets/characters/potionmaker.png`; purple-haired elf with green clothing.
  Current cozy redraw adds curls, blush, a flower clip and blue apron with a
  potion pocket. Art is in `assets/characters/purple_shopkeeper/`.

The imported Elf Adventurer is historical, not a current player choice. Preserve
the original reference images; filenames alone are not a reliable description.

Both current player sheets have **32×40 cells**, **4 columns × 6 rows**, and a
**128×240 atlas**. Rows 0/1 are front idle/walk; rows 2/3 are rear idle/walk;
rows 4/5 are right-profile idle/walk, mirrored for the left profile.
Every upward component, including diagonals, selects the rear drawings. Releasing
input retains that facing for idle. Downward motion uses front art; horizontal
motion uses the drawn profiles. Diagonal motion keeps the front/rear choice
according to its vertical component. Profiles have one visible eye, a projected
nose, side clothing/accessories and near/far limbs, not compressed front art.
Back views show rear hair, hats/helmet plates, apron ties, and clothing seams,
not faces or front pockets showing through the head/body.

Idle durations are 1.2, 0.3, 0.12 and 0.3 seconds. Steps follow actual motion.
The canvas is drawn at 60 world pixels tall, with a feet anchor independent of
collision and movement validation. Carry icons sit above the character.

## Customer cast and fantasy population

All four customer outfits are custom drawings matching Renna's style:

- Elf herbalist: blond hair, sage feathered cap, satchel.
- Knight: steel-blue open helmet, rose plume, gold crest.
- Wizard: lavender star hat, silver hair, crystal staff.
- Dwarf: rose knit cap, copper beard, green apron, belt.

The world includes a broad fantasy population. Skin palettes include moss green,
jade, sky blue, lavender, rose, ochre, umber and peach. Every outfit can use every
palette. Skin color does not determine profession, temperament, order or stats.
Current skin variation does not imply that distinct species anatomy has been drawn.

`assets/customers/cozy/skin_palettes.json` defines skin base, shadow, highlight and
blush colors. Apply these only to face/ear/hand shapes. Keep hair, eyes, clothing
and outlines intact. Angry feedback uses a mark and patience bar, not a red tint
that overwrites the customer's skin.

Runtime customer atlases are **128×1920**, with **4 columns × 48 rows**, each cell
**32×40**. Each skin palette occupies six rows: front idle/walk, rear idle/walk,
profile idle/walk. The frame index is `skin_palette * 24 + direction_pose_frame`.
Customer ID determines outfit and palette independently and consistently on both
clients. Array position must never determine appearance. Customers are drawn at
50 world pixels tall, leaving space for neighboring characters and order UI.
Customer visuals are keyed by customer ID and follow server-owned browsing
paths. They enter through the door, walk around shelves and look at the shop
while waiting. Large bottle request bubbles follow customers; item-name labels
and the old queue rectangle/text are absent.

## Environment

Current environment: `assets/cottage/`. A crooked woodland shop with an irregular
outline, bevels and alcoves, worn plank flooring and a twelve-piece rustic wall
kit. Timber, plaster, logs, mossy stone, ivy, lanterns, niches and stained glass
coordinate without repeating one generic wall. Back walls are full-height;
sides/front are cut away. A narrow scenic forest surround has twisted trunks,
dark foliage, mushrooms and gently blinking motes. It is not an outdoor level.

Nine EMPTY shelf silhouettes include seven tall designs and two low hutches:
bowed ladder case, stacked cubbies, living-wood stands, serpentine cupboard,
leaning tower, domed hutch, barrel-like rack and moon-spired cabinet. Feet meet
the floor; detail comes from structure and carving, not baked item pictures.
There are no chests. Ingredient stock is hidden in the world until searched.
Temporary ingredient bubbles pop, bob and fade over stocked shelves, with a
gentle source-shelf glow. Requests trigger relevant hints plus a distraction.
Searching always shows real contents, so hints are optional aids, not crafting locks.

`network/cottage_layout.gd` is the one floor-outline source for art, collision
segments and navigation. Do not restore the old rectangular wall collider.
The entrance door still reuses `assets/environment/pixel_shop/door.png`.

The cauldron is an independent `assets/props/cauldron/` asset: violet iron, jade
runes, subtle magical fire, separate bubbling liquid and idle/brewing/ready rows.
Props use shared layout anchors and convex ground collision. Interactivity and
visual recognition are the core pillars; preserve both when moving furniture.

## Visual matching catalog

Six potion silhouettes must remain distinguishable without names: crimson narrow
vial, azure globe, amber square flask, violet crescent, acid-green triangle and
pearly pink heart. Each has its own subtly bubbling sprite sheet. Twelve ingredients
also have independent sheets: spectral herb, red fungus, crystal blossom, void eye,
thorned root, moth, bone, violet crystals, slime pearl, raven feather, ember heart
and silver spores. Use silhouette as well as color.

Every item lives in `assets/items/<category>/<id>/` with four 32×40 SVG/PNG frames
and a 128×40 sheet. `ItemIcon` is reused everywhere: shelf hints/search, inventory, recipes, player
hands, cauldron input/result, customer bubbles and transfer animations. Do not
redraw a tiny alternate bottle or substitute a colored rectangle in UI. Recipe
cards show two ingredient sprites leading to their output bottle, not names.
Stock colors must not be tinted by furniture materials. The eight-item bag has
one active selection; any recipe can use its contents regardless of demand.
Heart/question/thinking/sparkle/attention emotes use the cottage emote sheet;
UI discoveries and bag updates have small reveal/pop animations.

## Reproducible asset pipeline

Requires Python 3 and ImageMagick:

```sh
python3 tools/draw_blue_character.py
python3 tools/draw_purple_character.py
python3 tools/draw_cozy_customers.py
python3 tools/draw_shop_interior.py
python3 tools/draw_item_catalog.py
python3 tools/draw_library_assets.py
python3 tools/draw_cottage.py
```

Generators contain palette and pose definitions. They emit independently editable
frame SVGs and transparent PNGs plus packed atlases. Customer generation also bakes
skin variants into rows. Regenerate only the affected art; check for manual output
edits before overwriting. Keep source and runtime textures in version control.
`tools/profile_art.py` contains the six original side-profile drawings, shared
by the generators so skin palettes and pose layout stay consistent across views.
`tools/draw_cottage.py` produces the active shelves, walls, floor, woods and emotes.
`tools/draw_library_assets.py` produces the active cauldron and earlier empty cases;
`tools/shelf_art.py` retains the earlier stocked display-case reference art.
Godot creates `.import` metadata; do not commit the `.godot/` cache.

Player `preview.tres` resources crop a single idle frame for the menu. A menu must
never display the whole sprite sheet as if it were a portrait.

Environment artwork is baked to PNG from editable SVG pixel sources. This also
avoids SVG pattern/mask compatibility issues seen in the earlier room art.
See `assets/environment/pixel_shop/README.md` for atlas dimensions and frame uses.

## Visual acceptance

- Inspect source reference, enlarged frame sheet and actual rendered game.
- Check idle, blink and walk poses for clipped hats/feet and shifted baselines.
- Check all skin palettes and animation rows without recoloring clothing.
- Confirm menu, owner and observer all use the intended character.
- Check labels, icons and neighboring sprites at real gameplay scale.
- A successful script test does not prove the art looks right. Record the actual
  rendered observation; distinguish fixture captures from real gameplay tests.

Per-folder READMEs track sources, credits, modifications and generation. Earlier
0x72 CC0 assets remain documented separately from our current custom drawings.
