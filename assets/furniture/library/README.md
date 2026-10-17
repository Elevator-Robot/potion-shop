# Empty ingredient-library furniture

These nine original wood designs are **completely empty furniture art**. No
ingredient, potion, jar, plant, book or container is baked into a shelf texture.
Posts, boards, drawers, hardware, feet and contact shadows are furniture only.
The worn wood palettes are restrained so item shapes/colors are the focal point.
Feet terminate at the frame's bottom baseline, not above it.

- `shelves.png`: **64×80** cells, 4 interaction frames × 9 variants, **256×720**.
- Individual `shelves_<variant>_<frame>.svg/.png` files remain editable.
- Floor clutter files contain empty crates/baskets or books, never ingredient art.

Runtime `ItemIcon` nodes sit on the board anchors in `Game.SHELF_ROWS` /
`Game.shelf_slots()`. A stock stack is several independent item sprites. Empty
stock disappears; while holding an allowed item, its empty placement slot shows
a translucent preview. Highlighting and Tab cycling select item types, not names.

Stock belongs to each cabinet (`shelf_stock[station][item]`), not to all shelves
of the same ingredient. Crafted bottles can be placed on either potion rack and
picked up again. Potion racks begin empty. Aggregate `shelves` totals remain for
diagnostics, but rendering and transactions use local cabinet stock.

```sh
python3 tools/draw_library_assets.py
```

The room uses loose library rows and upright, grounded cases. Each variant has
explicit board heights and shared feet-level collision. Boards render at 1.5×;
item bottoms align to them independently. Regeneration overwrites frame sources.
