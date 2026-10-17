# Violet / jade cauldron

Original standalone **64×72** pixel-art animation cells, not part of a room
background. `cauldron.png` and `liquid.png` each have four columns and three rows
(**256×216**): quiet/empty, brewing, and ready.

The violet iron body has jade rune inlays, silver-purple highlights, feet touching
the floor, and violet/green magical fire. A separate liquid layer carries bubbles
and steam and takes the recipe's potion color. Ready frames have small glints.
The exact output bottle asset appears above the pot, translucent during brewing
and solid when ready. Unfinished inputs use their own ingredient assets.

```sh
python3 tools/draw_library_assets.py
```

All frame SVG/PNG sources are retained. The cauldron is an independent
`shop_prop.tscn` instance with `prop_id = "cauldron"`, using the shared interaction
and collision layout, and can be reused without drawing an entire room.
