# Customer sprites

The game now uses the original matching-style drawings in **`cozy/`**. See
[the cozy cast guide](cozy/README.md) for frame sources, designs and regeneration.
The earlier CC0 strips below remain available as source/reference assets; they
are no longer used by the customer scene.

## Earlier imported sprites

Artist: **Robert / 0x72**, DungeonTileset II v1.7 (palette credited to GrafxKid).

- Official source and license statement: https://0x72.itch.io/dungeontileset-ii
- License: **CC0 1.0 Universal**, https://creativecommons.org/publicdomain/zero/1.0/
- Retrieved 2026-10-17 from a pinned public mirror of the original atlas:
  https://raw.githubusercontent.com/balagurf/The-Biding-of-Isaac-Caves---/d4614a3f6996b326de73eb481e0187a1d93a8c92/Sprites/0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7.png

Only the following four-frame idle strips were extracted, without repainting:

| Local file | Original animation | Atlas crop (x, y, width, height) |
| --- | --- | --- |
| `elf_idle.png` | `elf_f_idle_anim_f0..3` | 128, 4, 64, 28 |
| `knight_idle.png` | `knight_m_idle_anim_f0..3` | 128, 100, 64, 28 |
| `wizard_idle.png` | `wizzard_m_idle_anim_f0..3` | 128, 164, 64, 28 |
| `dwarf_idle.png` | `dwarf_m_idle_anim_f0..3` | 128, 292, 64, 28 |

Each frame is 16×28. Godot uses nearest-neighbor filtering and four-frame idle
animation. Customer ID selects the character deterministically, so a customer's
appearance survives queue reordering and matches on both clients. IDs are game
state; appearance itself is a presentation choice, not a new network field.

`order_bottle.svg` is original project artwork, drawn white so the existing potion
colors can tint it. Imported art and its attribution can ship with the game.

To reproduce a strip from the downloaded original atlas with ImageMagick:

```sh
magick 0x72_DungeonTilesetII_v1.7.png -crop 64x28+128+4 +repage elf_idle.png
```
