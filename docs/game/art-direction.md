# Potion Shop art direction

## Visual target

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

Both current player sheets have **32×40 cells**, **4 columns × 2 rows**, and a
**128×80 atlas**. Row 0: relaxed, inhale, blink, settle. Row 1: left-foot contact,
passing, right-foot contact, opposite passing. These are front-facing drawings
mirrored for horizontal direction; there are no authored back-view frames.

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

Runtime customer atlases are **128×320**, with **4 animation columns × 8 skin
rows**, each cell **32×40**. The frame index is `skin_row * 4 + idle_frame`.
Customer ID determines outfit and palette independently and consistently on both
clients. Queue position must never determine appearance. Customers are drawn at
50 world pixels tall, leaving space for neighboring characters and order UI.

## Environment

Oak floorboards with seams, grain, knots and nails; shaded stone-block walls;
three arched stained-glass windows with potion motifs and colored light. Use a
full-height back wall and cutaway side/front walls to keep gameplay readable.

Current station furniture is still labeled placeholder geometry. Do not describe
the entire interior as finished or mistake labels for actual furniture artwork.
Preserve existing collision and interaction points when replacing those placeholders.

## Reproducible asset pipeline

Requires Python 3 and ImageMagick:

```sh
python3 tools/draw_blue_character.py
python3 tools/draw_purple_character.py
python3 tools/draw_cozy_customers.py
```

Generators contain palette and pose definitions. They emit independently editable
frame SVGs and transparent PNGs plus packed atlases. Customer generation also bakes
skin variants into rows. Regenerate only the affected art; check for manual output
edits before overwriting. Keep source and runtime textures in version control.
Godot creates `.import` metadata; do not commit the `.godot/` cache.

Player `preview.tres` resources crop a single idle frame for the menu. A menu must
never display the whole sprite sheet as if it were a portrait.

Pattern/mask-heavy environment SVGs are baked to PNG because the floor pattern
failed in Godot's SVG importer. See `assets/environment/README.md` for commands.

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
