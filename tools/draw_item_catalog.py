#!/usr/bin/env python3
"""Six distinct potion bottles and twelve dark-fantasy ingredients.

Each item is its own four-frame transparent 32x40 sprite sheet, shared by shelves,
recipes, held items and customer requests. Source artwork is independently editable.
"""
from pathlib import Path
import subprocess
from draw_shop_interior import Art

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/items"
INK = "#241f36"
POTIONS = [
    ("healing_potion", "#cf456f", "#f49ca9", "M12 3h8v4h-2v8l5 5v12l-3 5h-8l-3-5V20l5-5V7h-2z", "M14 7h4v9l4 5v10l-3 5h-6l-3-5V21l4-5z", 23),
    ("mana_potion", "#438fdf", "#a1dcf3", "M13 3h6v4h-1v7c15 3 16 22-2 24C-2 36-1 17 14 14V7h-1z", "M15 7h2v8c14 3 14 20-1 21C1 35 1 18 15 15z", 21),
    ("ember_tonic", "#e49c37", "#ffe0a2", "M9 5h10v5h-2v5h8l3 4v16l-3 2H6l-3-2V19l3-4h6v-5H9z", "M12 10h4v6h8l2 4v14l-2 1H7l-2-1V20l2-4h7v-6z", 22),
    ("veil_draught", "#9762d6", "#ddbef4", "M20 3h7v5h-3v7c9 12 1 24-11 23C-3 35 0 15 15 12c-8 8-7 15 2 17 7 0 9-6 4-12V8h-1z", "M22 8h1v8c8 11 0 21-10 20C1 33 2 18 10 16c-5 8-2 14 7 15 9-1 10-8 5-15z", 20),
    ("venom_elixir", "#8bbf40", "#dbf59c", "M12 3h8v5h-2v7l11 18v4H3v-4l11-18V8h-2z", "M15 8h2v8l10 18v1H5v-1l10-18z", 25),
    ("spirit_dew", "#dfb7ca", "#fff0e1", "M13 3h6v5h-1v7c9-8 18 4 10 12L16 38 4 27c-8-8 1-20 10-12V8h-1z", "M15 8h2v10c9-10 16 1 9 8L16 36 6 26C-1 19 6 8 15 18z", 23),
]
INGREDIENTS = ["moonleaf", "firecap", "waterbloom", "void_eye", "blood_root", "ghost_moth", "bone_shard", "dusk_crystal", "slime_pearl", "raven_feather", "ember_heart", "silver_spore"]


def potion(index, frame):
    item, color, light, outer, inner, level = POTIONS[index]
    a = Art(32, 40)
    a.parts.append(f'<defs><clipPath id="glass"><path d="{inner}"/></clipPath></defs>')
    a.path(outer, INK)
    a.path(inner, "#697b89")
    a.parts.append('<g clip-path="url(#glass)">')
    a.rect(0, level, 32, 40 - level, color)
    a.rect(0, level, 32, 1, light)
    a.rect(0, 33, 32, 4, "#241d3e", .22)
    for i, x in enumerate([12, 18, 23]):
        y = 33 - (frame + i * 3) % 9
        a.rect(x, y, 2 if i == 0 else 1, 2 if i == 0 else 1, light, .85)
        a.rect(x, y, 1, 1, "#fff5df")
    a.rect(7, 20, 1, 9, "#e5eff0", .75)
    a.rect(8, 19, 2, 2, "#f7f3dd")
    a.rect(24, 26, 1, 6, "#d8dde4", .55)
    a.parts.append('</g>')
    cap_x = [12, 13, 9, 20, 12, 13][index]
    cap_w = [8, 6, 10, 7, 8, 6][index]
    cap_y = 5 if index == 2 else 3
    a.rect(cap_x + 1, cap_y, cap_w - 2, 3, "#98714f")
    a.rect(cap_x + 1, cap_y, cap_w - 2, 1, "#d6b27e")
    a.rect(cap_x, cap_y + 3, cap_w, 1, light)
    if index == 0:
        a.rect(10, 24, 12, 2, "#ad7b53")
        a.path('M16 22l3 3-3 3-3-3z', "#f4d08a")
    elif index == 2:
        a.rect(6, 31, 19, 1, "#f3d79f")
        a.rect(6, 20, 2, 3, "#f3d79f")
    elif index == 3:
        a.rect(24, 8, 1, 3, "#d5bd89")
        a.path('M26 10l2 3-2 3-2-3z', "#d8bded")
    elif index == 4:
        a.path('M13 29h6l-3 5z', "#d7ed98")
    elif index == 5:
        a.rect(12, 7, 8, 2, "#d59bb7")
        a.rect(12, 9, 1, 4, "#e9b5c6")
    return a


def ingredient(kind, frame):
    a = Art(32, 40)
    r, p, e = a.rect, a.path, a.ellipse
    if kind == "moonleaf":
        p('M13 37V25H9v-5H5v-7H3V7h6v4h5V3h6v8h6V7h4v8h-4v6h-6v6h-3v10z', INK)
        p('M15 36V23h-4v-5H7v-7H5V9h3v5h6v6h2V5h2v13h4v-5h6v-3h1v4h-5v5h-5v7h-2v10z', "#5fae9a")
        r(16, 7, 1, 25, "#c3ead5")
        r(8, 15, 4, 2, "#90d4af")
        r(21, 18, 4, 1, "#9fdcb9")
        if frame in (1, 3):
            r(22, 5, 1, 3, "#c2e9d7")
    elif kind == "firecap":
        p('M11 35V22H3v-8h3V9h5V5h10v4h5v5h3v8h-9v13l-4 3z', INK)
        p('M13 35V19h5v16l-2 1z', "#d3b99d")
        p('M5 19v-4h3v-5h5V7h6v3h5v5h3v4z', "#be4c67")
        r(7, 18, 19, 2, "#7d354d")
        for x,y in [(9,12),(16,9),(21,15)]:
            r(x, y, 3, 3, "#f1c9a0")
        r(15, 24, 2, 8, "#f5d8b5")
        r(6 + frame * 5, 3, 1, 1, "#d87d83")
    elif kind == "waterbloom":
        r(14, 17, 3, 20, "#3a716b")
        for points in ['M15 18L9 10l3-7 5 3 1 10z','M17 18l6-12 7 6-4 7z','M15 19L4 12l-2 9 9 4z','M17 20l11 2-1 8-8-3z','M15 20l-7 7 5 7 5-8z']:
            p(points, "#355578")
        for x,y in [(12,7),(22,12),(6,19),(22,25),(12,27)]:
            r(x,y,4,4,"#79c3df")
            r(x,y,2,1,"#c9edf0")
        e(16,19,4,4,"#ded38c")
        r(15,17,2,2,"#fff0be")
        r(15,30-frame%2,2,5,"#8ebba0")
    elif kind == "void_eye":
        p('M7 33l3-7-5-4V12l6-6h10l6 6v10l-5 5 3 8-7-3-4 5z', "#412e60")
        e(16,17,12,9,INK)
        e(16,17,10,7,"#d3c3d7")
        e(17,17,6,6,"#d6ad64")
        x = [17,18,17,16][frame]
        r(x,12,2,11,"#32273e")
        r(x-2,13,2,2,"#fff0cf")
        p('M10 26l-4 8 4-2 2-6zM21 25l6 9-5-2-3-6z', "#8e65ac")
    elif kind == "blood_root":
        p('M13 3h7v11l5 6-2 5 5 10-5-3-4-7-3 12-4-4 2-10-6 7-5 2 3-8 7-7z', INK)
        p('M15 5h3v11l5 5-3 3 5 9-3-2-4-9-3 12-1-2 2-12-8 8 1-3 6-7z', "#bd4b62")
        r(16,9,1,11,"#ee9290")
        p('M12 12l-4-4h5zM20 18l7-5-2 6z', "#8b394e")
        r(15,26-frame,1,3,"#edaba0")
    elif kind == "ghost_moth":
        spread = [0,1,2,1][frame]
        p(f'M14 17L{4-spread} 7l-2 12 5 7-2 8 9-5zM18 17L{28+spread} 7l2 12-5 7 2 8-9-5z', "#7f759c")
        p(f'M13 18L{5-spread} 10v8l5 5-3 8 6-4zM19 18L{27+spread} 10v8l-5 5 3 8-6-4z', "#e5dfe0")
        r(14,14,4,18,"#9b85ae")
        r(15,16,2,13,"#fff1d7")
        p('M15 15L11 7h2l3 6 3-6h2l-4 8z', "#c2b5d0")
        for x in [7,23]:
            e(x,19,2,3,"#aaa0c0")
    elif kind == "bone_shard":
        p('M10 3h6l2 4 5-1 4 5-3 5-6-1-2 12-5 10-4-3 4-11 2-10-6-3z', INK)
        p('M11 5h4l2 5 6-2 2 3-2 3-6-2-3 15-4 8-1-2 4-11 2-10-6-3z', "#d7c49b")
        p('M13 6h1l2 6-3 14-2 5 1-7 2-12z', "#fff0c9")
        r(16,15+frame%2,2,3,"#acc8b8")
    elif kind == "dusk_crystal":
        p('M4 33V18l5-7 4 7 4-15 6 7-1 12 6-8 3 5-3 16z', INK)
        p('M6 31V19l3-5 3 7 5-14 4 5-2 16 7-10 3 2-3 13z', "#8861bd")
        p('M17 8l2 4-3 17-2 3zM8 17l2 4-1 10H7z', "#c6a6e6")
        r(20,4+frame,1,3,"#e8e2f3")
    elif kind == "slime_pearl":
        e(16,33,13,4,"#395846")
        e(16,23,11,11-frame%2,INK)
        e(16,22,9,9-frame%2,"#87b946")
        e(13,19,5,5,"#c3dc77")
        r(9,16,3,2,"#f0efad")
        p('M17 20h2v3h3v2h-3v5h-2v-5h-3v-2h3z', "#4e7851")
        r(24,30,3,3,"#a8ca62")
    elif kind == "raven_feather":
        p('M6 37l5-11-4-7 4-9 8-7 9-1-1 11-6 12-9 3-4 10z', INK)
        p('M10 27l1-6-1-3 4-8 7-5 5-1-1 8-6 10-7 3z', "#425574")
        p('M7 36L23 7h2L9 37z', "#8aadb9")
        for x,y in [(13,16),(17,11),(18,19)]:
            r(x,y+frame%2,4,1,"#6b82a5")
    elif kind == "ember_heart":
        p('M5 12l6-7 6 4 6-3 5 7-2 13-10 11L5 26 3 18z', INK)
        p('M7 13l5-5 5 5 6-4 3 5-3 11-7 9-9-9-2-7z', "#693b4b")
        p('M12 10l4 7 5-5-2 9 4 2-7 9-4-8-5-5 6 2z', "#e48a41")
        r(15,19-frame%2,2,8,"#ffda83")
        r(10,25,2,2,"#eeaa5b")
    else:
        # Silver spore cluster: domed caps, glowing gills and drifting motes.
        for x,y,w in [(4,20,10),(14,13,14),(18,27,10)]:
            r(x+w//2-1,y,3,35-y,"#8a7a9c")
            e(x+w//2,y,w//2,4,INK)
            e(x+w//2,y-1,w//2-1,3,"#d2cadf")
            r(x+3,y-2,w-6,1,"#fff0dc")
        for x,y in [(7,8),(25,4),(11,15)]:
            r(x,y-frame%3,1,2,"#d8e5dc")
    return a


def export_item(group, name, frames):
    folder = OUT / group / name
    folder.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, art in enumerate(frames):
        svg, png = folder / f"frame_{i}.svg", folder / f"frame_{i}.png"
        svg.write_text(art.svg())
        subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
        paths.append(str(png))
    subprocess.run(["magick", *paths, "+append", str(folder / "sheet.png")], check=True)


def main():
    for i, (name, *_rest) in enumerate(POTIONS):
        export_item("potions", name, [potion(i, frame) for frame in range(4)])
    for name in INGREDIENTS:
        export_item("ingredients", name, [ingredient(name, frame) for frame in range(4)])


if __name__ == "__main__":
    main()
