#!/usr/bin/env python3
"""Original detailed pixel furniture, masonry, floorboards and interaction frames.

All drawing coordinates are native pixels. SVG sources and transparent PNG sheets
are retained; no runtime vector patterns or external asset downloads are needed.
"""
from pathlib import Path
import random
import subprocess
import tempfile
from shelf_art import draw_shelf

OUT = Path(__file__).resolve().parents[1] / "assets/environment/pixel_shop"


class Art:
    def __init__(self, w, h):
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">']

    def rect(self, x, y, w, h, color, opacity=1):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}" opacity="{opacity}"/>')

    def path(self, points, color, opacity=1):
        self.parts.append(f'<path d="{points}" fill="{color}" opacity="{opacity}"/>')

    def ellipse(self, x, y, rx, ry, color, opacity=1):
        self.parts.append(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{color}" opacity="{opacity}"/>')

    def svg(self):
        return "\n".join(self.parts + ["</svg>"]) + "\n"


def floor():
    a = Art(320, 210)
    rng = random.Random(2031)
    a.rect(0, 0, 320, 210, "#382b29")
    for row, y in enumerate(range(0, 210, 12)):
        for x in range(-48 + (row % 3) * 16, 320, 48):
            base = rng.choice(["#785b47", "#80634c", "#71513f", "#87694f", "#7a5843"])
            a.rect(x + 1, y + 1, 46, 10, base)
            a.rect(x + 2, y + 1, 44, 1, "#aa8a62")
            a.rect(x + 2, y + 10, 44, 1, "#594338")
            for _ in range(5):
                gx, gy = x + rng.randrange(3, 35), y + rng.randrange(3, 9)
                a.rect(gx, gy, rng.randrange(4, 11), 1, rng.choice(["#967452", "#634b3b", "#a28059"]))
            if rng.random() < .35:
                k = x + 25
                a.ellipse(k, y + 6, 4, 2, "#765039")
                a.rect(k - 1, y + 6, 3, 1, "#51392e")
            for nx in [x + 3, x + 44]:
                a.rect(nx, y + 3, 1, 1, "#453536")
                a.rect(nx, y + 4, 1, 1, "#c09a64")
    # The room has a framed perimeter, scuffs and worn traffic near the entrance.
    for x, y, w, h in [(0, 0, 320, 4), (0, 206, 320, 4), (0, 0, 4, 210), (316, 0, 4, 210)]:
        a.rect(x, y, w, h, "#4c3930")
    a.rect(4, 4, 312, 1, "#bc945d")
    a.rect(4, 205, 312, 1, "#bc945d")
    for _ in range(32):
        a.rect(rng.randrange(8, 310), rng.randrange(8, 202), rng.randrange(1, 4), 1, "#d1ad77", .25)
    return a


def stone():
    a = Art(64, 32)
    a.rect(0, 0, 64, 32, "#343d4d")
    rng = random.Random(44)
    for row, y in enumerate([0, 16]):
        for x in range(-16 if row else 0, 64, 32):
            a.path(f'M{x+2} {y+1}h27l2 2v10l-3 2h-26l-1-3V{y+3}z', "#6b7885")
            a.rect(x + 3, y + 2, 25, 2, "#9ca6a5")
            a.rect(x + 4, y + 4, 25, 7, "#7e8c94")
            a.rect(x + 3, y + 13, 25, 1, "#4d5e70")
            a.rect(x + 2, y + 5, 1, 7, "#8a979b")
            for _ in range(9):
                a.rect(x + rng.randrange(4, 28), y + rng.randrange(5, 12), rng.randrange(1, 3), 1, rng.choice(["#a2ada6", "#617382", "#8c989b"]))
            a.path(f'M{x+23} {y+2}h1v3h-2v2h1v2h-1v-2h-1V{y+5}h2z', "#4c5e70")
    return a


def bottle(a, x, y, color, small=False):
    w, h = (4, 8) if small else (6, 10)
    a.rect(x + 1, y - h, w - 2, 2, "#c8a274")
    a.rect(x + 1, y - h + 2, w - 2, 2, "#b6d1cf")
    a.rect(x, y - h + 4, w, h - 4, "#283644")
    a.rect(x + 1, y - h + 4, w - 2, h - 5, color)
    a.rect(x + 1, y - h + 4, 1, 2, "#ecedce")
    a.rect(x + 1, y - 2, w - 2, 1, "#e5cf9d", .55)


def shelf(variant, frame):
    return draw_shelf(Art, variant, frame)


def chest(frame):
    a = Art(48, 40)
    a.ellipse(24, 37, 22, 3, "#17232c", .5)
    a.rect(3, 16, 42, 20, "#352a31")
    a.rect(5, 18, 38, 16, "#326467")
    for y in [20, 26, 32]:
        a.rect(6, y, 36, 1, "#79b2a2")
        a.rect(6, y + 2, 36, 1, "#203f4b")
    for x in [7, 36]:
        a.rect(x, 17, 4, 19, "#4a5662")
        a.rect(x, 18, 1, 17, "#8b9a97")
        for y in [20, 31]:
            a.rect(x + 1, y, 1, 1, "#c7c7ac")
    top = [12, 8, 3, 2][frame]
    a.rect(5, top, 38, 8, "#382d32")
    a.rect(6, top + 1, 36, 6, "#437c79")
    a.rect(7, top + 1, 34, 1, "#a6d0af")
    if frame > 0:
        a.rect(6, 15, 36, 6, "#2b2934")
        bottle(a, 10, 20, "#9abe80")
        bottle(a, 19, 20, "#a793c3", True)
        a.path('M28 14h8l4 7H25z', "#c3a77a")
        a.rect(30, 14, 2, 6, "#ecd3a4")
    a.rect(22, 20 if frame else 18, 5, 5, "#d2a85c")
    a.rect(24, 21 if frame else 19, 1, 2, "#4c3b35")
    return a


def cauldron(frame, liquid=False):
    a = Art(64, 64)
    if liquid:
        a.ellipse(32, 29, 19, 5, "#b6c9ba")
        a.ellipse(30, 28, 15, 3, "#e0ead0")
        for i, x in enumerate([20, 29, 39, 45]):
            y = 28 - ((frame + i) % 4)
            a.rect(x, y, 2, 2, "#ffffff")
        for x in [25, 38]:
            y = 19 - (frame * 3 + x) % 13
            a.rect(x, y, 2, 4, "#e9f4e7", .38)
            a.rect(x + 1, y - 2, 2, 3, "#e9f4e7", .25)
        return a
    a.ellipse(32, 59, 29, 5, "#131f28", .5)
    for x in [8, 20, 32, 44]:
        a.rect(x, 54, 12, 7, "#555b69")
        a.rect(x + 1, 54, 10, 1, "#a1a496")
    for i, x in enumerate([19, 28, 36, 43]):
        h = 7 + (i + frame) % 4
        a.path(f'M{x} 59v-{h}h2v-3h2v5h2v{h-2}z', "#d67f4f")
        a.rect(x + 2, 55, 2, 4, "#f4ce7e")
    a.path('M12 28h40v16l-5 9H18l-6-9z', "#252b3b")
    a.path('M15 30h34v14l-5 6H20l-5-7z', "#465569")
    a.path('M17 33h5v9h2v5h-4l-3-5z', "#788996")
    a.path('M43 33h5v10l-4 6h-6l5-6z', "#303b50")
    a.ellipse(32, 28, 24, 8, "#222d3d")
    a.ellipse(32, 27, 23, 6, "#83929b")
    a.ellipse(32, 28, 20, 5, "#2e4b4e")
    for x in [5, 53]:
        a.rect(x, 29, 6, 12, "#242d3b")
        a.rect(x + 1, 30, 4, 2, "#8d9a9f")
    a.rect(23, 45, 3, 2, "#aab3ad")
    a.rect(28, 46, 2, 2, "#778e96")
    return a


def door(frame):
    a = Art(48, 64)
    a.path('M1 63V24l3-8 5-7 7-5h16l8 6 6 12v41z', "#333b4c")
    a.path('M4 61V24l3-8 5-5 5-4h14l7 5 5 12v37z', "#84909b")
    a.path('M8 59V25l3-8 6-5h14l6 6 3 7v34z', "#16232d")
    for x,y in [(7,18),(12,12),(20,8),(29,9),(36,15),(40,24),(4,33),(40,36),(4,48),(40,51)]:
        a.rect(x, y, 5, 2, "#b2b6a8")
    a.rect(9, 46, 30, 13, "#40585a")
    a.rect(9, 53, 30, 6, "#8c7653")
    a.rect(10, 55, 28, 1, "#c3a06a")
    width = [28, 20, 10, 3][frame]
    if width >= 14:
        a.path(f'M10 59V25l3-7 4-3h{width-14}l7 10v34z', "#362c31")
    else:
        a.path(f'M10 59V24l{width} -9v44z', "#362c31")
    a.rect(11, 24, width, 34, "#825638")
    for x in range(12, 11 + width, 5):
        a.rect(x, 25, 1, 32, "#c3975d")
        a.rect(x + 2, 29, 1, 24, "#64432f")
    for y in [28, 47]:
        a.rect(10, y, width + 1, 3, "#3c4856")
        a.rect(11, y, width - 1, 1, "#829095")
        a.rect(12, y + 1, 1, 1, "#d6c59b")
    if width > 6:
        a.rect(8 + width, 38, 3, 4, "#e0b16a")
        a.rect(9 + width, 39, 1, 2, "#544334")
    a.rect(3, 59, 42, 4, "#9a9e8f")
    a.rect(4, 59, 40, 1, "#d1c9a6")
    a.rect(31 + (frame % 2), 13, 1, 5, "#aa8c65")
    a.rect(30 + (frame % 2), 17, 4, 3, "#e5bb73")
    return a


def window(frame):
    a = Art(32, 48)
    a.path('M1 46V19l3-7 6-7 6-4 7 4 6 8 2 6v27z', "#374452")
    a.path('M3 44V19l3-7 5-5 5-3 6 4 5 6 2 5v25z', "#a0a79a")
    a.path('M6 42V20l3-7 7-6 7 6 3 7v22z', "#2e4054")
    colors = ["#8ec7c1", "#b49bd6", "#e8ca83", "#7eadd0"]
    for row in range(4):
        for col in range(3):
            x, y = 8 + col * 6, 18 + row * 6
            a.path(f'M{x} {y}l3-3 3 3-3 4z', colors[(row + col) % 4])
    a.path('M11 14l5-5 5 5-5 5z', "#dec488")
    bottle(a, 13, 36, "#92d0b0")
    a.rect(2, 43, 28, 4, "#6f7e80")
    a.rect(3, 43, 26, 1, "#d1c9a8")
    a.rect(9 + frame * 3, 21 + (frame % 2) * 6, 1, 3, "#fff1c7")
    return a


def item(index, frame):
    a = Art(16, 20)
    bob = 1 if frame == 1 else 0
    if index == 0:
        a.path(f'M7 {18-bob}V7H5V5H3V2h4v3h2V1h4v4h-2v3H9v10z', "#365b4a")
        a.path(f'M7 {16-bob}V7H5V3h2v3h2V3h2v3H9v10z', "#9bc88c")
        a.rect(6, 9, 5, 3, "#6caa76")
        a.rect(7, 8, 1, 9, "#cbdca1")
    elif index == 1:
        a.rect(6, 10 - bob, 4, 8, "#dec5a0")
        a.path(f'M2 {11-bob}V7h2V5h2V3h4v2h3v2h1v4z', "#6d3542")
        a.path(f'M3 {9-bob}V7h3V5h4v2h3v2z', "#df8a69")
        a.rect(6, 6 - bob, 2, 2, "#ffe2af")
        a.rect(10, 8 - bob, 2, 1, "#fff0c8")
    elif index == 2:
        a.rect(7, 8, 2, 10, "#4d8a71")
        for x,y in [(4,4),(9,4),(3,8),(10,8)]:
            a.rect(x, y - bob, 4, 4, "#79b9d8")
            a.rect(x, y - bob, 2, 1, "#c0e7e7")
        a.rect(7, 7 - bob, 3, 3, "#edd994")
    else:
        bottle(a, 4, 18, ["#e792a1", "#8faedf", "#edbd75"][index - 3])
        if frame in (1, 3):
            a.rect(11, 8, 1, 4, "#fff1ce")
            a.rect(10, 9, 3, 1, "#fff1ce")
    return a


def clutter(variant):
    a = Art(48, 32)
    a.ellipse(24, 29, 21, 3, "#17232c", .35)
    a.path('M5 15h17l-2 13H8z', "#74543a")
    for y in [17, 21, 25]:
        a.rect(8, y, 12, 1, "#bd945e")
    for x in [10,14,18]:
        a.rect(x, 17, 1, 10, "#d1ad74")
    for i in range(4):
        a.rect(8 + i * 3, 12 + i % 2, 4, 5, ["#8ca96c", "#cb8a69", "#9dbab3"][variant % 3])
    for x,y in [(26,24),(33,27)]:
        bottle(a, x, y, "#ab94c5", True)
    a.path('M25 10h13l4 5H28z', "#8a6371")
    a.path('M27 14h14v3H27z', "#dec59e")
    a.rect(37, 28, 5, 1, "#c3a270")
    return a


def export(name, art):
    svg, png = OUT / (name + ".svg"), OUT / (name + ".png")
    svg.write_text(art.svg())
    subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
    return png


def sheet(name, rows):
    strips = []
    with tempfile.TemporaryDirectory(prefix="shop-sheets-", dir="/tmp/opencode" if Path("/tmp/opencode").is_dir() else None) as tmp:
        for row, frames in enumerate(rows):
            paths = [str(export(f"{name}_{row}_{i}", art)) for i, art in enumerate(frames)]
            strip = str(Path(tmp) / f"{row}.png")
            subprocess.run(["magick", *paths, "+append", strip], check=True)
            strips.append(strip)
        subprocess.run(["magick", *strips, "-append", str(OUT / f"{name}.png")], check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    export("floor", floor())
    export("stone", stone())
    sheet("shelves", [[shelf(v, f) for f in range(4)] for v in range(9)])
    sheet("chest", [[chest(f) for f in range(4)]])
    sheet("cauldron", [[cauldron(f) for f in range(4)]])
    sheet("liquid", [[cauldron(f, True) for f in range(4)]])
    sheet("door", [[door(f) for f in range(4)]])
    sheet("window", [[window(f) for f in range(4)]])
    sheet("items", [[item(i, f) for f in range(4)] for i in range(6)])
    for i in range(3):
        export(f"clutter_{i}", clutter(i))


if __name__ == "__main__":
    main()
