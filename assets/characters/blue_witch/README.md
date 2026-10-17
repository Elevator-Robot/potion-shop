# Aaron — cozy blue witch

Original pixel-art redraw of the project's original `../elf.png` portrait:
chestnut hair, floppy plum witch hat with gold/blue bands, blue coat, leather
belt and pouch, and brown boots. The original portrait is preserved.

Matches the purple shopkeeper's warm outlines, large eyes, blush, small smile
and chibi proportions. This replaces Elf Adventurer in player slot 0. The purple
shopkeeper stays available in slot 1 and remains the default menu selection.

Eight individually editable SVG/PNG frames, **32×40** each:

- `idle_0`: relaxed, open eyes, planted boots.
- `idle_1`: inhale, raised head/hat/shoulders, lifted hands and moving hair ends.
- `idle_2`: short closed-eye blink and soft smile.
- `idle_3`: exhale, hands tucked in and hair settling.
- `walk_0`: left-foot contact and opposing arm swing.
- `walk_1`: raised passing pose, feet together.
- `walk_2`: right-foot contact and reversed arm swing.
- `walk_3`: opposite raised passing pose.

`sheet.png` packs four idle frames above four walk frames, **128×80** total.
`preview.tres` selects the first frame for the menu. Walking follows distance;
idle holds the relaxed pose longer and exposes the blink briefly. Front-facing
art is mirrored for horizontal direction; these are not four-direction sheets.

Regenerate using Python 3 and ImageMagick:

```sh
python3 tools/draw_blue_character.py
```

The generator shares the purple character's palette and pose definitions but
draws its own hair, face placement, hat, sleeves, coat and accessories. Generated
frame SVGs can be edited directly, but regeneration overwrites those edits.
