# Renna — cozy purple shopkeeper

Original pixel artwork created for Potion Shop, using the existing
`../potionmaker.png` character as a design reference. The original image is preserved.
Purple hair and elf ears, warm blush, a sage top, a blue apron with a tiny potion
pocket, a flower clip, and little brown boots define the new chibi silhouette.

## Frames

Each editable SVG and transparent PNG is **32×40**. `sheet.png` is **128×240**,
four columns by six rows: front idle/walk, rear idle/walk, then profile idle/walk.

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

Every listed pose also has a `back_` version. Rear views have a fully drawn mass
of violet hair, visible ear backs, the opposite-side flower and apron ties;
there are no eyes, cheeks or front pockets on the back. Eight `profile_` poses
have one visible eye, a side nose and pointed ear, layered rear curls, side apron,
and alternating near/far limbs. There are 24 poses total.
The frames redraw limbs, hair tips and clothing positions rather than deforming
the whole portrait. Upward/diagonal motion uses rear art and retains rear idle
when stopped. Horizontal motion selects the right-profile drawings, mirrored
for left-facing movement. Profile idle persists after release.
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
