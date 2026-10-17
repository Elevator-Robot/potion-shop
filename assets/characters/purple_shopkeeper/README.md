# Renna — cozy purple shopkeeper

Original pixel artwork created for Potion Shop, using the existing
`../potionmaker.png` character as a design reference. The original image is preserved.
Purple hair and elf ears, warm blush, a sage top, a blue apron with a tiny potion
pocket, a flower clip, and little brown boots define the new chibi silhouette.

## Frames

Each editable SVG and transparent PNG is **32×40**. `sheet.png` is **128×80**,
four columns by two rows. Row 0 is idle; row 1 is walking.

| Frame | Drawing |
| --- | --- |
| `idle_0` | Relaxed stance, open eyes, feet planted |
| `idle_1` | Inhale: raised head and shoulders, lifted sleeves, hair curl follow-through |
| `idle_2` | Closed-eye blink, soft smile, relaxed shoulders |
| `idle_3` | Exhale: hands closer to body and settling curls |
| `walk_0` | Left foot forward, right foot lifted, opposing arm swing |
| `walk_1` | Passing pose: raised head/body, feet together, arms passing |
| `walk_2` | Right foot forward, left foot lifted, reversed arm swing |
| `walk_3` | Opposite passing pose with corresponding arm positions |

The frames redraw facial expression, limbs, hair tips and clothing positions;
they are not whole-portrait squash/stretch transformations. These are front-facing
animations with horizontal mirroring, not back-view or four-direction sheets.
Idle holds the relaxed pose longer and gives the blink a brief exposure.

## Editing

Edit the palette, pixel shapes and individual pose definitions in
`tools/draw_purple_character.py`, then run:

```sh
python3 tools/draw_purple_character.py
```

Requires Python 3 and ImageMagick. It regenerates every SVG, frame PNG, and the
sheet. SVGs can also be edited directly for an art pass, but rerunning the generator
overwrites those edits. `preview.tres` selects a single frame for the menu.

Godot uses nearest filtering and a 60-world-pixel frame height for both player
character sheets. Physics stays on the feet and never inherits animation scale.
