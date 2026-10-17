# Animated player elf

From **0x72 / Robert's DungeonTileset II v1.7**, CC0 1.0 Universal.
Official source: https://0x72.itch.io/dungeontileset-ii
License: https://creativecommons.org/publicdomain/zero/1.0/

Uses the same pinned source atlas documented in `../customers/README.md`.
`elf_adventurer.png` combines the four `elf_f_idle` frames (row 0) and four
`elf_f_run` frames (row 1). Each frame is 16×20; eight transparent rows at the
top of each original 16×28 frame are removed. Artwork is otherwise unchanged.

Reproduce from the original atlas using ImageMagick:

```sh
magick 0x72_DungeonTilesetII_v1.7.png -crop 64x20+128+12 +repage idle.png
magick 0x72_DungeonTilesetII_v1.7.png -crop 64x20+192+12 +repage walk.png
magick idle.png walk.png -append elf_adventurer.png
```

Rendered at 3× native pixels with nearest-neighbor filtering. Steps advance
with actual distance travelled; standing still selects the looping idle row.
The preview resource displays only the first frame, not the whole sheet.
