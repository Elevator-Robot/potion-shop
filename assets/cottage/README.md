# Crooked woodland cottage

Original pixel artwork: bowed timbers, stacked cubbies, branch-grown shelves,
carved crowns, stone, cracked plaster, moss, lanterns and crooked stained glass.
The scenic woods have twisted trunks, shadowy foliage and pale mushrooms.

- `shelves.png`: nine designs, four frames each, **64×112** cells (**256×1008**).
  Seven tall cases/stands and two low hutches. Furniture art is empty; ingredients
  appear through hints and search UI, not painted into the boards.
- `walls/`: twelve independent **64×64** four-frame sheets: fieldstone, oak post,
  cracked plaster, mossy boards, logs, cross brace, ivy stone, lantern, round
  stained glass, arched stained glass, shadow niche and root pillar.
- `floor.png`: **400×272**, rendered at 2× from world (0,-24).
- `woods.png`: **512×416**, rendered at 2× from (-112,-160).
- `emotes.png`: heart, question, thinking dots, sparkle and attention mark;
  four frames each, **20×20** cells, **80×100** sheet.

```sh
python3 tools/draw_cottage.py
```

Requires Python 3 and ImageMagick. Frame SVG/PNG sources remain editable.
The generator reads `FLOOR_POINTS` from `network/cottage_layout.gd`, also used
by Godot wall collision and navigation. The outline has bevels and alcoves;
there is no hidden legacy rectangular wall box.

Full-height back panels and low side/front cutaways use the reusable wall kit.
`client/wall_tiles.gdshader` animates lit variants. The woods are a scenic surround,
not a separate explorable level. Transient ingredient hints pop, bob and fade;
their source shelves glow. Useful and distracting hints share the same visuals.
