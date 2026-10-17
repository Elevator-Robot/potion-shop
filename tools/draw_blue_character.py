#!/usr/bin/env python3
"""Draw eight cozy animation poses based on the original blue witch portrait."""

from pathlib import Path
import subprocess

from draw_purple_character import PALETTE, POSES

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/characters/blue_witch"
COLORS = PALETTE | {
    "hair": "#986c50", "hair_dark": "#684a42", "hair_light": "#c69768",
    "hat": "#64516e", "hat_dark": "#493a55", "hat_light": "#967d9e",
    "coat": "#567a99", "coat_dark": "#3d526e", "coat_light": "#83a5b6",
    "iris": "#7194ae",
}


def rect(x, y, w, h, color):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{COLORS[color]}"/>'


def path(data, color):
    return f'<path d="{data}" fill="{COLORS[color]}"/>'


def boot(x, y, forward):
    width = 7 if forward else 6
    return (rect(x, y, width, 4, "ink") + rect(x + 1, y, width - 2, 3, "boot")
            + rect(x + 1, y, 3, 1, "boot_light"))


def arm(x, y):
    return (rect(x, y, 5, 7, "ink") + rect(x + 1, y, 3, 4, "coat")
            + rect(x + 1, y, 2, 1, "coat_light") + rect(x + 1, y + 3, 3, 1, "coat_dark")
            + rect(x + 1, y + 4, 3, 2, "skin_shadow") + rect(x + 1, y + 4, 2, 1, "skin_light"))


def head(pose):
    p = [f'<g transform="translate(0 {pose["head"]})">']
    # Chestnut hair under the hat, with warm highlights and separate moving ends.
    p += [path("M8 11h16v2h3v12h-2v4h-5v-2H10v2H5v-3H3v-8h2v-5h3z", "ink")]
    p += [path("M8 12h15v2h3v10h-3v4h-2v-3H9v3H6v-4H4v-5h2v-5h2z", "hair_dark")]
    p += [rect(5, 17, 3, 6, "hair"), rect(24, 17, 2, 7, "hair")]
    p += [path("M10 13h12v2h3v8h-2v2h-3v1h-8v-1H9v-2H7v-8h3z", "skin_shadow")]
    p += [path("M10 14h12v2h2v7h-2v1h-3v1h-6v-1h-3v-1H8v-7h2z", "skin")]
    p += [path("M12 15h8v1h3v6h-3v1h-9v-1H9v-5h3z", "skin_light")]
    # Side-swept fringe from the reference, softened into chibi proportions.
    p += [path("M7 13h13v2h-4v2h-3v2H9v2H7zM22 13h3v5h-2v-2h-1z", "hair_dark")]
    p += [path("M8 13h10v1h-3v2h-3v2H9v1H8zM23 14h1v3h-1z", "hair")]
    p += [rect(10, 14, 4, 1, "hair_light")]
    if pose["blink"]:
        p += [rect(9, 20, 4, 1, "eye"), rect(19, 20, 4, 1, "eye"), rect(9, 19, 1, 1, "eye"), rect(22, 19, 1, 1, "eye")]
    else:
        for x in (9, 19):
            p += [rect(x, 18, 4, 4, "eye"), rect(x + 1, 21, 2, 1, "iris"), rect(x, 18, 2, 1, "cream")]
    p += [rect(7, 22, 4, 2, "blush"), rect(21, 22, 4, 2, "blush"), rect(15, 22, 1, 1, "skin_shadow"), rect(14, 24, 1, 1, "skin_shadow"), rect(15, 25, 2, 1, "skin_shadow"), rect(17, 24, 1, 1, "skin_shadow")]
    p += [path(f'M5 23h2v{3 + pose["curl"]}h3v2H6v-2H5z', "hair"), path(f'M24 23h2v{3 - pose["curl"]}h-2v2h-3v-2h3z', "hair")]
    p += [rect(6, 24, 1, 3, "hair_light"), rect(24, 24, 1, 2, "hair_light")]
    # Wide, upturned brim and bent cone: unmistakably the original witch hat.
    p += [path("M1 11h5V9h3V6h2V3h3V1h9v2h-3v3h2v4h5v1h4v4h-3v1H4v-1H1z", "ink")]
    p += [path("M3 12h5v-2h3V7h2V4h3V2h5v1h-3v3h2v4h3v2h6v2h-3v1H6v-1H3z", "hat_dark")]
    p += [path("M11 10V7h2V4h3V2h3v1h-2v4h2v3z", "hat")]
    p += [path("M13 7V5h2V3h2v1h-1v3z", "hat_light")]
    p += [path("M4 12h6v-1h12v1h6v1h-5v1H9v-1H4z", "hat")]
    p += [rect(7, 12, 3, 1, "hat_light"), rect(23, 12, 4, 1, "hat_light")]
    p += [rect(10, 10, 13, 2, "coat_dark"), rect(11, 10, 11, 1, "coat"), rect(10, 9, 12, 1, "gold"), rect(11, 9, 3, 1, "cream")]
    p.append('</g>')
    return ''.join(p)


def draw(pose):
    p = ['<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40" shape-rendering="crispEdges">',
         f'<title>Blue witch — {pose["name"]}</title>']
    p += [boot(*foot) for foot in pose["feet"]]
    p += [arm(*pose["left"]), arm(*pose["right"])]
    p += [f'<g transform="translate(0 {pose["body"]})">']
    p += [path("M10 25h12v2h2v5h1v4H8v-4H7v-5h3z", "ink")]
    p += [path("M11 26h10v2h2v4h1v3H9v-3H8v-4h3z", "coat_dark")]
    p += [path("M11 27h9v1h2v3h-1v3H10v-3H9v-3h2z", "coat")]
    p += [rect(10, 28, 2, 3, "coat_light"), rect(10, 34, 4, 1, "coat_light"), rect(17, 33, 1, 2, "coat_light")]
    p += [path("M11 26h3l2 3 2-3h3l-2 4h-6z", "coat_light")]
    p += [rect(9, 31, 14, 2, "boot"), rect(14, 31, 4, 2, "gold"), rect(15, 31, 2, 1, "ink")]
    p += [rect(20, 31, 4, 4, "ink"), rect(20, 32, 3, 2, "boot_light"), rect(21, 32, 1, 1, "gold")]
    p += ['</g>', head(pose), '</svg>']
    return '\n'.join(p) + '\n'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for pose in POSES:
        svg = OUT / (pose["name"] + ".svg")
        png = OUT / (pose["name"] + ".png")
        svg.write_text(draw(pose))
        subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
    subprocess.run(["magick", "(", *[str(OUT / f"idle_{i}.png") for i in range(4)], "+append", ")", "(", *[str(OUT / f"walk_{i}.png") for i in range(4)], "+append", ")", "-append", str(OUT / "sheet.png")], check=True)


if __name__ == "__main__":
    main()
