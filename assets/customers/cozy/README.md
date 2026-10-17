# Cozy customer cast

Original pixel-art customer drawings created for Potion Shop to match the custom
purple shopkeeper. These are not recolors or enlarged versions of the old pack.
They share the shopkeeper's warm plum outlines, soft skin shading, cheek blush,
large eyes, small boots, and 32×40 chibi proportions.

## Cast

- **Elf herbalist:** blond hair, pointed ears, sage cap with a cream feather,
  leaf collar and a little brown satchel.
- **Knight:** soft steel-blue open helmet, rose plume, warm brown skin, gold
  breastplate crest and matching rose tabard.
- **Wizard:** floppy lavender hat with a star, silver hair, little beard, a
  gold-trimmed robe and lilac crystal staff.
- **Dwarf:** dusty-rose knit cap, copper beard with gold clasps, green apron
  and a sturdy belt.

## Frames and integration

Every character has 24 separately drawn **32×40** SVG/PNG poses: front, rear and
profile idle/walk sets of four frames each. Their hands and accessories
have separate follow-through. Rear art shows hair, backs of helmets/hats,
necklines, cape backs and apron ties rather than visible faces or beards.
`*_idle.png` retains the original front idle strip for reference; `*_sheet.png`
contains all poses in six rows. Profile drawings have a side silhouette, one
visible eye and distinct near/far limbs. Right-profile frames are mirrored for
leftward movement. Runtime textures include the skin variants below.
They hold the relaxed pose longer and expose the blink only briefly rather than
giving every pose the same duration. Customer ID offsets the cycle and selects
the appearance.

The game draws them at a 50-world-pixel canvas height with nearest filtering,
leaving space between people and room for potion icons, labels and patience bars.
Appearance is stable across queue changes and requires no new server state.
Visuals persist by customer ID and follow the host's roaming paths. Customers
enter through the shop door, browse the shelves and look around while waiting,
then leave through the door. All views are used according to movement/facing.

## Fantasy skin colors

Every outfit can appear with any of eight skin palettes: moss green, jade,
sky blue, lavender, rose, ochre, umber, and peach. Skin color is an independent
appearance choice, not tied to a profession, temperament, potion order or stats.
This supports the shop's mixed fantasy population rather than a single human
skin-color range.

`skin_palettes.json` defines matching base, shadow, highlight and blush colors.
The generator applies these only to the skin shapes (face, ears, hands), preserving
clothing, hair, eyes and outlines. The game uses the `*_fantasy.png` atlases:
**128×1920**, four columns and 48 rows of 32×40 cells. Each of eight palettes has
six consecutive rows (front idle/walk, rear idle/walk, profile idle/walk). The
frame index is `palette * 24 + direction_pose_frame`, with offsets 0/4/8/12/16/20.
Customer ID selects both outfit and palette deterministically; each outfit
eventually uses all eight palettes. Angry customers retain their skin color and
show the exclamation mark and red patience bar instead of a whole-body red tint.

## Editing

Edit `tools/draw_cozy_customers.py`, then regenerate with:

```sh
python3 tools/draw_cozy_customers.py
```

Requires Python 3 and ImageMagick. The drawing tool imports the shared palette
from `tools/draw_purple_character.py`; it does not change the player artwork.
Each character's frame SVGs remain editable, but regeneration overwrites direct
edits to those generated files.
