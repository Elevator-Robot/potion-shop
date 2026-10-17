#!/usr/bin/env python3
"""Draw four original cozy NPCs using the purple shopkeeper's pixel-art language.

Outputs individually editable SVG/PNG poses and four-frame idle strips.
Requires Python 3 and ImageMagick; no downloaded character pixels are used.
"""

from pathlib import Path
import json
import subprocess
import tempfile

from draw_purple_character import PALETTE, POSES as PLAYER_POSES, pack_rows
from profile_art import draw_profile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/customers/cozy"
THEMES = {
    "elf": dict(hair="#d6ac66", hair_dark="#967044", hair_light="#ffe0a0",
                cloth="#8cab70", cloth_dark="#53694e", cloth_light="#bfd093", accent="#e3b67d"),
    "knight": dict(hair="#72534f", hair_dark="#493b42", hair_light="#ac7c61",
                   skin="#c99274", skin_shadow="#9c665e", skin_light="#e7b08c", blush="#cf807b",
                   cloth="#8eacb0", cloth_dark="#516c80", cloth_light="#c4d4c9", accent="#d58e9a"),
    "wizard": dict(hair="#d4d6df", hair_dark="#9299af", hair_light="#fff0dd",
                   skin="#e1b199", skin_shadow="#bd897d", skin_light="#f5ceb0",
                   cloth="#858dc1", cloth_dark="#535b86", cloth_light="#c0bce2", accent="#e9be73"),
    "dwarf": dict(hair="#be7d58", hair_dark="#825446", hair_light="#e9b17a",
                  cloth="#ba7c86", cloth_dark="#784e66", cloth_light="#e7a5a2", accent="#e9be73"),
}
# An extended relaxed hold, inhale, blink and settled pose. Hands and accessories
# have their own follow-through rather than translating the entire finished sprite.
POSES = [
    dict(name="idle_0", lift=0, hands=0, blink=False, settle=0),
    dict(name="idle_1", lift=-1, hands=-1, blink=False, settle=1),
    dict(name="idle_2", lift=0, hands=0, blink=True, settle=0),
    dict(name="idle_3", lift=0, hands=1, blink=False, settle=-1),
]
WALK_POSES = [
    dict(name=p["name"], lift=p["head"], hands=0, blink=False, settle=p["curl"],
         feet=p["feet"], arms=(p["left"], p["right"]))
    for p in PLAYER_POSES if p["name"].startswith("walk_")
]
ALL_POSES = POSES + WALK_POSES


class Drawing:
    def __init__(self, kind, pose, skin=None):
        self.colors = PALETTE | THEMES[kind] | (skin or {})
        self.parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40" shape-rendering="crispEdges">',
                      f'<title>Cozy {kind} — {pose["name"]}</title>']

    def rect(self, x, y, w, h, color):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{self.colors[color]}"/>')

    def path(self, data, color):
        self.parts.append(f'<path d="{data}" fill="{self.colors[color]}"/>')

    def group(self, dy):
        self.parts.append(f'<g transform="translate(0 {dy})">')

    def end(self):
        self.parts.append('</g>')

    def face(self, blink, pointed=False):
        r, p = self.rect, self.path
        if pointed:
            p("M1 13h5v2h2v5H5v-1H3v-2H1zM26 13h5v4h-2v2h-2v1h-3v-5h2z", "ink")
            p("M2 14h4v2h1v3H5v-2H3v-1H2zM26 14h4v2h-1v1h-2v2h-2v-3h1z", "skin_shadow")
            r(2, 14, 3, 1, "skin_light")
            r(27, 14, 3, 1, "skin_light")
        else:
            r(4, 15, 4, 6, "ink")
            r(24, 15, 4, 6, "ink")
            r(5, 16, 3, 4, "skin_shadow")
            r(24, 16, 3, 4, "skin_shadow")
        p("M9 9h14v2h2v10h-2v3h-3v1h-9v-1H8v-3H6V12h3z", "skin_shadow")
        p("M10 10h12v2h2v9h-2v2h-3v1h-7v-1H9v-2H7v-8h3z", "skin")
        p("M11 11h9v2h2v7h-2v1H10v-2H8v-5h3z", "skin_light")
        if blink:
            r(9, 18, 4, 1, "eye")
            r(19, 18, 4, 1, "eye")
            r(9, 17, 1, 1, "eye")
            r(22, 17, 1, 1, "eye")
        else:
            for x in (9, 19):
                r(x, 16, 4, 4, "eye")
                r(x + 1, 19, 2, 1, "iris")
                r(x, 16, 2, 1, "cream")
        r(7, 20, 4, 2, "blush")
        r(21, 20, 4, 2, "blush")
        r(15, 20, 1, 1, "skin_shadow")
        r(14, 22, 1, 1, "skin_shadow")
        r(15, 23, 2, 1, "skin_shadow")
        r(17, 22, 1, 1, "skin_shadow")


def draw_limbs(d, pose):
    r, p = d.rect, d.path
    for x, y, forward in pose.get("feet", ((9, 35, False), (18, 35, False))):
        width = 7 if forward else 6
        r(x, y, width, 4, "ink")
        r(x + 1, y, width - 2, 3, "boot")
        r(x + 1, y, 3, 1, "boot_light")
    arms = pose.get("arms", ((4, 26 + pose["hands"]), (23, 26 + pose["hands"])))
    for x, y in arms:
        r(x, y, 5, 6, "ink")
        r(x + 1, y, 3, 3, "cloth")
        r(x + 1, y, 3, 1, "cloth_light")
        r(x + 1, y + 3, 3, 3, "skin_shadow")
        r(x + 1, y + 3, 2, 2, "skin_light")


def draw_rear(kind, pose, skin):
    d = Drawing(kind, pose, skin)
    r, p = d.rect, d.path
    draw_limbs(d, pose)
    d.group(pose["lift"])
    p("M10 23h12v2h2v6h-2v5H9v-5H7v-6h3z", "ink")
    p("M10 24h11v2h2v4h-2v5H10v-5H8v-4h2z", "cloth_dark")
    p("M11 24h9v2h2v3h-2v5h-9v-5H9v-3h2z", "cloth")
    if kind == "elf":
        p("M9 24h13v4h1v4l-7 4-7-4z", "cloth_dark")
        p("M11 25h9v4h1v2l-5 3-5-3z", "cloth")
        r(15, 27, 1, 6, "cloth_light")
        r(8, 30, 4, 4, "ink")
        r(9, 31, 3, 2, "boot")
    elif kind == "knight":
        r(10, 26, 12, 7, "cloth_dark")
        r(11, 27, 10, 5, "cloth")
        r(15, 27, 1, 5, "cloth_light")
        r(11, 29, 10, 1, "cloth_light")
        r(10, 33, 12, 2, "accent")
    elif kind == "wizard":
        p("M10 25h11v7h2v4H8v-3h2z", "cloth_dark")
        p("M11 26h9v7h1v2H10z", "cloth")
        r(15, 27, 1, 8, "cloth_light")
        r(9, 35, 13, 1, "gold")
    else:
        r(10, 27, 12, 8, "cloth_dark")
        r(11, 28, 10, 6, "cloth")
        p("M11 27h2v2h2v2h-2v-1h-2zM19 27h2v3h-2v1h-2v-2h2z", "green_light")
        r(10, 32, 12, 2, "boot")
        r(15, 31, 2, 4, "green_dark")
    # Ears and nape show the same fantasy skin palette as the face and hands.
    r(13, 23, 7, 3, "skin_shadow")
    if kind == "elf":
        p("M1 13h5v2h2v5H5v-1H3v-2H1zM26 13h5v4h-2v2h-2v1h-3v-5h2z", "ink")
        p("M2 14h4v2h1v3H5v-2H3v-1H2zM26 14h4v2h-1v1h-2v2h-2v-3h1z", "skin_shadow")
        r(2, 14, 3, 1, "skin")
        r(27, 14, 3, 1, "skin")
    else:
        r(4, 16, 4, 5, "ink")
        r(24, 16, 4, 5, "ink")
        r(5, 17, 3, 3, "skin_shadow")
        r(24, 17, 3, 3, "skin_shadow")
    p("M11 3h10v2h4v3h2v14h-3v3H8v-3H5V8h2V5h4z", "ink")
    p("M11 4h10v2h3v3h2v12h-3v3H9v-3H6V9h2V6h3z", "hair_dark")
    p("M10 9h13v3h2v9h-3v2H10v-2H7v-9h3z", "hair")
    r(10, 14, 1, 7, "hair_light")
    r(20, 14, 1, 7, "hair_light")
    p("M15 12h2v6h-1v6h-2v-6h1z", "hair_dark")
    if kind == "elf":
        p("M5 10V8h2V5h5V3h10V2h6v2h-3v3h-3v3z", "ink")
        p("M7 9V7h5V5h10V3h3v1h-2v3h-3v2z", "cloth")
        r(7, 9, 17, 2, "cloth_dark")
        p(f'M8 7v-3H6V{1 + max(0, pose["settle"])}H4v3h2v3z', "cream")
        r(7, 21 + pose["settle"], 2, 3, "hair")
        r(23, 22 - pose["settle"], 2, 3, "hair")
    elif kind == "knight":
        # A closed curved helmet rear: riveted plate and neck guard, no visor.
        p("M6 13V8h2V5h4V3h9v2h4v3h2v15h-3v2H8v-2H5V13z", "ink")
        p("M7 12V8h3V6h12v2h3v13h-3v3H10v-2H7z", "cloth")
        r(10, 6, 12, 1, "cloth_light")
        r(14, 7, 2, 16, "cloth_dark")
        r(16, 7, 1, 15, "cloth_light")
        r(7, 18, 18, 2, "cloth_dark")
        r(10, 22, 12, 1, "cloth_light")
        r(9, 16, 1, 1, "cloth_light")
        r(22, 16, 1, 1, "cloth_light")
        p(f'M15 5V2h3V{1 + max(0, pose["settle"])}h5v2h-4v2z', "accent")
    elif kind == "wizard":
        # Silver hair at the back, with the plain reverse of the star hat.
        r(8, 19, 2, 4, "hair_light")
        r(22, 19, 2, 4, "hair_light")
        p("M2 12h5V9h2V6h3V3h4V1h6v3h-3v3h3v3h4v2h4v4H2z", "ink")
        p("M4 13h5V9h2V6h3V4h3V2h3v1h-3v4h3v3h3v3h5v2H4z", "cloth")
        r(4, 13, 24, 2, "cloth_dark")
        r(9, 11, 14, 2, "accent")
        r(15, 5, 1, 5, "cloth_light")
    else:
        # A short copper braid rather than a beard visible through the head.
        r(13, 20, 6, 5, "hair_dark")
        r(14, 20, 4, 5, "hair")
        r(14, 22, 2, 1, "hair_light")
        r(16, 24, 2, 1, "hair_light")
        r(14, 25, 4, 1, "gold")
        p("M5 12V8h2V5h4V3h11v2h4v3h1v4z", "ink")
        p("M7 11V8h2V6h4V4h8v2h3v2h1v3z", "cloth")
        r(6, 10, 20, 3, "cloth_dark")
        r(7, 10, 18, 1, "cloth_light")
        for x in (9, 13, 17, 21):
            r(x, 11, 1, 1, "cloth")
        r(15, 5, 1, 5, "cloth_light")
    d.end()
    if kind == "wizard":
        r(3, 24, 2, 13, "ink")
        r(4, 25, 1, 11, "boot_light")
        p("M2 21h4v2h1v3H6v1H2v-1H1v-3h1z", "ink")
        r(2, 23, 4, 3, "potion")
        r(3, 22, 2, 1, "hair_light")
    d.parts.append('</svg>')
    return '\n'.join(d.parts) + '\n'


def draw(kind, pose, skin=None, back=False, profile=False):
    if profile:
        return draw_profile(kind, pose, PALETTE | THEMES[kind] | (skin or {}))
    if back:
        return draw_rear(kind, pose, skin)
    d = Drawing(kind, pose, skin)
    r, p = d.rect, d.path
    draw_limbs(d, pose)
    d.group(pose["lift"])
    p("M10 23h12v2h2v6h-2v5H9v-5H7v-6h3z", "ink")
    p("M10 24h11v2h2v4h-2v5H10v-5H8v-4h2z", "cloth_dark")
    p("M11 24h9v2h2v3h-2v5h-9v-5H9v-3h2z", "cloth")
    r(12, 25, 8, 1, "cloth_light")
    if kind == "elf":
        p("M10 27h3v2h3v2h3v3h-4v-2h-3v-2h-2z", "boot")
        r(18, 29, 4, 5, "ink")
        r(18, 30, 3, 3, "boot_light")
        r(19, 30, 1, 1, "gold")
        p("M12 25l3 1 1 3 2-3 3-1-2 5h-6z", "green_light")
    elif kind == "knight":
        r(10, 27, 12, 6, "cloth_dark")
        r(11, 27, 10, 5, "cloth_light")
        r(12, 28, 8, 4, "cloth")
        r(15, 28, 2, 4, "gold")
        r(13, 29, 6, 1, "gold")
        r(10, 33, 12, 2, "accent")
    elif kind == "wizard":
        p("M10 28h11v4h2v4H8v-3h2z", "cloth_dark")
        p("M11 28h9v5h1v2H10z", "cloth")
        r(15, 26, 2, 9, "gold")
        r(11, 32, 2, 1, "cloth_light")
        r(19, 29, 1, 1, "cream")
    else:
        r(10, 28, 12, 7, "green_dark")
        r(11, 29, 10, 5, "green")
        r(10, 32, 12, 2, "boot")
        r(15, 32, 3, 2, "gold")
    d.end()
    # Heads are full original drawings, not recolored versions of the old pack.
    d.group(pose["lift"])
    p("M11 3h10v2h4v3h2v14h-3v3H8v-3H5V8h2V5h4z", "ink")
    p("M11 4h10v2h3v3h2v12h-3v3H9v-3H6V9h2V6h3z", "hair_dark")
    d.face(pose["blink"], kind == "elf")
    if kind == "elf":
        p("M7 9h5v4h-2v3H7zM12 8h5v3h-2v3h-3zM18 8h4v2h3v4h-3v-2h-4z", "hair")
        r(8, 10, 2, 3, "hair_light")
        p("M5 10V8h2V5h5V3h10V2h6v2h-3v3h-3v3z", "ink")
        p("M7 9V7h5V5h10V3h3v1h-2v3h-3v2z", "cloth")
        r(7, 9, 17, 2, "cloth_dark")
        p(f'M22 7v-3h2V{1 + max(0, pose["settle"])}h2v3h-2v3z', "cream")
        r(21, 9, 2, 2, "gold")
        r(6, 22 + pose["settle"], 2, 3, "hair")
        r(24, 21 - pose["settle"], 2, 3, "hair")
    elif kind == "knight":
        p("M6 13V8h2V5h4V3h9v2h4v3h2v15h-4v-9H9v9H5V13z", "ink")
        p("M7 12V8h3V6h12v2h3v4zM6 14h2v8H6zM24 14h2v8h-2z", "cloth")
        r(10, 6, 12, 1, "cloth_light")
        r(7, 11, 18, 2, "cloth_dark")
        r(14, 6, 3, 6, "cloth_light")
        p(f'M15 5V2h3V{1 + max(0, pose["settle"])}h5v2h-4v2z', "accent")
        r(6, 15, 1, 5, "cloth_light")
        r(24, 15, 1, 5, "cloth_light")
        r(15, 11, 2, 2, "gold")
    elif kind == "wizard":
        p("M6 16h2v6h3v3H7v-2H5v-4h1zM24 16h2v3h1v4h-2v2h-4v-3h3z", "hair")
        p("M12 23h8v2h-2v2h-4v-2h-2z", "hair")
        r(13, 24, 5, 1, "hair_light")
        p("M2 12h5V9h2V6h3V3h4V1h6v3h-3v3h3v3h4v2h4v4H2z", "ink")
        p("M4 13h5V9h2V6h3V4h3V2h3v1h-3v4h3v3h3v3h5v2H4z", "cloth")
        r(4, 13, 24, 2, "cloth_dark")
        r(9, 11, 14, 2, "accent")
        r(15, 6, 1, 4, "cream")
        r(14, 7, 3, 1, "cream")
        r(10, 9, 1, 1, "cloth_light")
    else:
        p("M6 19h3v3h3v1h8v-1h3v-3h3v6h-2v3h-3v3H11v-3H8v-3H6z", "hair_dark")
        p("M8 21h2v3h4v1h4v-1h4v-3h2v4h-3v3h-3v2h-4v-2h-3v-3H8z", "hair")
        r(10, 23, 2, 3, "hair_light")
        r(20, 23, 2, 3, "hair_light")
        r(12, 28, 2, 1, "gold")
        r(19, 28, 2, 1, "gold")
        r(8, 14, 5, 1, "hair_dark")
        r(19, 14, 5, 1, "hair_dark")
        p("M5 12V8h2V5h4V3h11v2h4v3h1v4z", "ink")
        p("M7 11V8h2V6h4V4h8v2h3v2h1v3z", "cloth")
        r(6, 10, 20, 3, "cloth_dark")
        r(7, 10, 18, 1, "cloth_light")
        for x in (9, 13, 17, 21):
            r(x, 11, 1, 1, "cloth")
        r(15, 6, 3, 2, "cloth_light")
    d.end()
    if kind == "wizard":
        r(27, 24, 2, 13, "ink")
        r(27, 25, 1, 11, "boot_light")
        p("M26 21h4v2h1v3h-1v1h-4v-1h-1v-3h1z", "ink")
        r(26, 23, 4, 3, "potion")
        r(27, 22, 2, 1, "hair_light")
        r(26, 23, 1, 2, "cream")
    d.parts.append('</svg>')
    return '\n'.join(d.parts) + '\n'


def main():
    skins = json.loads((OUT / "skin_palettes.json").read_text())
    for kind in THEMES:
        folder = OUT / kind
        folder.mkdir(parents=True, exist_ok=True)
        for view in ("front", "back", "profile"):
            for pose in ALL_POSES:
                name = (view + "_" if view != "front" else "") + pose["name"]
                svg, png = folder / (name + ".svg"), folder / (name + ".png")
                svg.write_text(draw(kind, pose, back=view == "back", profile=view == "profile"))
                subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
        pack_rows(folder, ("idle",), OUT / f"{kind}_idle.png")
        prefixes = ("idle", "walk", "back_idle", "back_walk", "profile_idle", "profile_walk")
        pack_rows(folder, prefixes, OUT / f"{kind}_sheet.png")
        # Bake skin-only variants into atlas rows. Recoloring semantic skin
        # shapes here preserves eyes, outlines, hair, clothing and accessories.
        # Temporary files are intermediates; the palette JSON is the source.
        parent = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
        with tempfile.TemporaryDirectory(prefix="customer-skins-", dir=parent) as temp:
            temp = Path(temp)
            rows = []
            for row, skin in enumerate(skins):
                frames = []
                colors = {key: value for key, value in skin.items() if key != "name"}
                for view in ("front", "back", "profile"):
                    for pose in ALL_POSES:
                        name = (view + "_" if view != "front" else "") + pose["name"]
                        svg, png = temp / (name + ".svg"), temp / (name + ".png")
                        svg.write_text(draw(kind, pose, colors, back=view == "back", profile=view == "profile"))
                        subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
                strip = temp / f"row_{row}.png"
                pack_rows(temp, prefixes, strip)
                rows.append(str(strip))
            subprocess.run(["magick", *rows, "-append", str(OUT / f"{kind}_fantasy.png")], check=True)


if __name__ == "__main__":
    main()
