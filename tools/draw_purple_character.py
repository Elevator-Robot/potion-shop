#!/usr/bin/env python3
"""Draw the original cozy shopkeeper poses and pack their transparent sprite sheet.

Requires ImageMagick for SVG rasterization. No original portrait pixels are warped:
each pose is assembled from pixel-art head, hair, face, arms, clothing and feet.
The generated SVGs are also retained as individually editable frame artwork.
"""

from pathlib import Path
import subprocess
from profile_art import draw_profile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/characters/purple_shopkeeper"
PALETTE = {
    "ink": "#392d46", "hair_dark": "#50366c", "hair": "#8053a5",
    "hair_mid": "#a875c8", "hair_light": "#d3a3e5", "hair_shine": "#edccf0",
    "skin_shadow": "#cf9381", "skin": "#f3c5a6", "skin_light": "#ffdec0",
    "blush": "#ed9ca5", "eye": "#49364e", "iris": "#9874ac",
    "cream": "#fff0cf", "green_dark": "#53694e", "green": "#8cab70",
    "green_light": "#bfd093", "apron_dark": "#415b70", "apron": "#668d9c",
    "apron_light": "#9ab9bc", "boot": "#78564e", "boot_light": "#ac7c61",
    "gold": "#e9be73", "potion": "#bb8fd6",
}


def rect(x, y, w, h, color):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{PALETTE[color]}"/>'


def path(points, color):
    return f'<path d="{points}" fill="{PALETTE[color]}"/>'


def boot(x, y, forward=False):
    # Different silhouettes for the planted/front foot and the lifted/back foot.
    w = 7 if forward else 6
    return (rect(x, y, w, 4, "ink") + rect(x + 1, y, w - 2, 2, "boot")
            + rect(x + 1, y, 3, 1, "boot_light") + rect(x, y + 3, w, 1, "ink"))


def arm(x, y, side):
    return (rect(x, y, 5, 6, "ink") + rect(x + 1, y, 3, 3, "green")
            + rect(x + 1, y, 3, 1, "green_light")
            + rect(x + 1, y + 3, 3, 3, "skin_shadow")
            + rect(x + 1, y + 3, 2, 2, "skin_light")
            + rect(x + (1 if side == "left" else 3), y + 3, 1, 1, "skin"))


def head(dy, blink, curl):
    pieces = [f'<g transform="translate(0 {dy})">']
    # Rounded violet silhouette with a little top tuft and full side curls.
    pieces += [path("M12 1h8v1h4v2h3v4h2v14h1v5h-3v2h-5v-3H9v3H4v-2H2v-5h1V9h2V5h3V3h4z", "ink")]
    pieces += [path("M12 3h8v1h4v2h2v4h1v12h1v3h-3v2h-2v-3H8v3H5v-2H4v-3h1V10h2V6h5z", "hair_dark")]
    pieces += [path("M11 4h10v1h3v3h1v5H7V9h1V6h3z", "hair")]
    # Pointed ears, shaded at their bases; warm skin softens the dark outline.
    pieces += [path("M1 13h5v2h2v5H5v-1H3v-2H1zM26 13h5v4h-2v2h-2v1h-3v-5h2z", "ink")]
    pieces += [path("M2 14h4v2h1v3H5v-2H3v-1H2zM26 14h4v2h-1v1h-2v2h-2v-3h1z", "skin_shadow")]
    pieces += [rect(2, 14, 3, 1, "skin_light"), rect(27, 14, 3, 1, "skin_light")]
    # Broad soft face with round cheeks and chin.
    pieces += [path("M9 9h14v2h2v10h-2v3h-3v1h-9v-1H8v-3H6V12h3z", "skin_shadow")]
    pieces += [path("M10 10h12v2h2v9h-2v2h-3v1h-7v-1H9v-2H7v-8h3z", "skin")]
    pieces += [path("M11 11h9v2h2v7h-2v1H10v-2H8v-5h3z", "skin_light")]
    # Swept bangs are staggered shapes rather than a flat helmet.
    pieces += [path("M7 8h5v5h-2v3H7zM12 6h5v5h-2v4h-3zM17 7h5v2h3v5h-3v-2h-2v-2h-3z", "hair_dark")]
    pieces += [path("M8 8h3v4H9v2H8zM12 7h3v4h-1v2h-2zM18 7h3v2h2v2h-2v-1h-3z", "hair")]
    pieces += [rect(9, 6, 4, 1, "hair_light"), rect(13, 5, 7, 1, "hair_mid"), rect(16, 3, 3, 1, "hair_light"), rect(7, 9, 1, 3, "hair_mid")]
    # Large dark eyes, tiny highlights, rosy cheeks, and a small cat-like smile.
    if blink:
        pieces += [rect(9, 18, 4, 1, "eye"), rect(19, 18, 4, 1, "eye"), rect(9, 17, 1, 1, "eye"), rect(22, 17, 1, 1, "eye")]
    else:
        pieces += [rect(9, 16, 4, 4, "eye"), rect(19, 16, 4, 4, "eye"), rect(10, 19, 2, 1, "iris"), rect(20, 19, 2, 1, "iris"), rect(9, 16, 2, 1, "cream"), rect(19, 16, 2, 1, "cream")]
    pieces += [rect(7, 20, 4, 2, "blush"), rect(21, 20, 4, 2, "blush"), rect(15, 20, 1, 1, "skin_shadow"), rect(14, 22, 1, 1, "skin_shadow"), rect(15, 23, 2, 1, "skin_shadow"), rect(17, 22, 1, 1, "skin_shadow")]
    # Hair curls change position with the pose, and a gold/lilac flower anchors identity.
    pieces += [path(f"M4 18h2v4H5v{3 + curl}H3v-2h1z", "hair"), path(f"M26 18h2v5h1v{3 - curl}h-3v-2h1v-3h-1z", "hair")]
    pieces += [rect(4, 23 + curl, 2, 1, "hair_mid"), rect(26, 24 - curl, 2, 1, "hair_mid")]
    pieces += [rect(24, 8, 2, 5, "hair_light"), rect(22, 10, 6, 1, "hair_light"), rect(24, 10, 2, 1, "gold"), rect(24, 8, 1, 1, "hair_shine")]
    pieces.append('</g>')
    return ''.join(pieces)


def head_back(dy, curl):
    """Rear hair mass, visible ear backs and opposite-side flower; no face."""
    p = [f'<g transform="translate(0 {dy})">']
    p += [path("M12 1h8v1h4v2h3v4h2v14h1v5h-3v2h-5v-3H9v3H4v-2H2v-5h1V9h2V5h3V3h4z", "ink")]
    p += [path("M1 13h5v2h2v5H5v-1H3v-2H1zM26 13h5v4h-2v2h-2v1h-3v-5h2z", "ink")]
    p += [path("M2 14h4v2h1v3H5v-2H3v-1H2zM26 14h4v2h-1v1h-2v2h-2v-3h1z", "skin_shadow")]
    p += [rect(2, 14, 3, 1, "skin"), rect(27, 14, 3, 1, "skin")]
    p += [path("M12 3h8v1h4v2h2v4h1v12h1v3h-3v2h-2v-3H8v3H5v-2H4v-3h1V10h2V6h5z", "hair_dark")]
    p += [path("M11 4h10v2h3v4h1v11h-2v3H10v-2H7V10h1V7h3z", "hair")]
    p += [path("M11 6h9v1h3v3H10v3H8v-3h1V7h2z", "hair_mid")]
    p += [rect(11, 6, 8, 1, "hair_light"), rect(16, 3, 3, 1, "hair_light")]
    p += [path("M15 10h2v4h-1v5h1v5h-3v-6h1zM9 12h1v7H9zM22 12h1v9h-2v-5h1z", "hair_dark")]
    p += [rect(11, 13, 1, 7, "hair_mid"), rect(19, 12, 1, 8, "hair_mid")]
    p += [path(f"M4 18h2v4H5v{3 + curl}H3v-2h1z", "hair"), path(f"M26 18h2v5h1v{3 - curl}h-3v-2h1v-3h-1z", "hair")]
    p += [rect(4, 23 + curl, 2, 1, "hair_mid"), rect(26, 24 - curl, 2, 1, "hair_mid")]
    p += [rect(6, 8, 2, 5, "hair_light"), rect(4, 10, 6, 1, "hair_light"), rect(6, 10, 2, 1, "gold")]
    p += ['</g>']
    return ''.join(p)


# Each frame has its own authored limb placement and expression. The walk is
# contact -> passing -> opposite contact -> passing, not translated copies.
POSES = [
    dict(name="idle_0", head=0, body=0, left=(4, 26), right=(23, 26), feet=((9, 35, False), (18, 35, False)), blink=False, curl=0),
    dict(name="idle_1", head=-1, body=-1, left=(4, 25), right=(23, 25), feet=((9, 35, False), (18, 35, False)), blink=False, curl=1),
    dict(name="idle_2", head=0, body=0, left=(4, 26), right=(23, 26), feet=((9, 35, False), (18, 35, False)), blink=True, curl=0),
    dict(name="idle_3", head=0, body=0, left=(5, 26), right=(22, 26), feet=((9, 35, False), (18, 35, False)), blink=False, curl=-1),
    dict(name="walk_0", head=0, body=0, left=(4, 24), right=(23, 28), feet=((8, 36, True), (18, 34, False)), blink=False, curl=1),
    dict(name="walk_1", head=-1, body=-1, left=(5, 25), right=(22, 26), feet=((10, 35, False), (17, 35, False)), blink=False, curl=0),
    dict(name="walk_2", head=0, body=0, left=(4, 28), right=(23, 24), feet=((10, 34, False), (18, 36, True)), blink=False, curl=-1),
    dict(name="walk_3", head=-1, body=-1, left=(5, 26), right=(22, 25), feet=((10, 35, False), (17, 35, False)), blink=False, curl=0),
]


def draw(pose, back=False):
    p = ['<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40" shape-rendering="crispEdges">']
    p += [f'<title>Purple shopkeeper — {"back_" if back else ""}{pose["name"]}</title>']
    for foot in pose["feet"]:
        p.append(boot(*foot))
    # Little cape, sage sleeves, blue apron, gold fastening and a potion pocket.
    p += [arm(*pose["left"], "left"), arm(*pose["right"], "right")]
    p += [f'<g transform="translate(0 {pose["body"]})">']
    p += [path("M10 23h12v2h2v5h-2v6H9v-6H7v-5h3z", "ink")]
    p += [path("M10 24h11v2h2v4H9v-3H8v-1h2z", "green_dark")]
    p += [path("M11 24h9v2h2v3H9v-2h2z", "green")]
    p += [rect(12, 25, 8, 1, "green_light")]
    p += [path("M10 28h11v3h1v4H10v1H9v-5h1z", "apron_dark")]
    p += [path("M11 28h9v3h1v3H10v-3h1z", "apron")]
    p += [rect(11, 28, 1, 5, "apron_light"), rect(12, 28, 7, 1, "apron_light"), rect(10, 34, 11, 1, "apron_light")]
    if back:
        # Apron ties on the back replace the front pocket and gold clasp.
        p += [rect(10, 29, 11, 1, "cream"), rect(13, 28, 2, 3, "apron_light"), rect(16, 28, 2, 3, "apron_light"), rect(15, 29, 1, 4, "cream")]
    else:
        p += [rect(14, 26, 3, 2, "gold"), rect(15, 26, 1, 1, "cream")]
        p += [rect(17, 30, 3, 4, "apron_dark"), rect(18, 30, 1, 1, "gold"), rect(18, 31, 2, 2, "potion"), rect(18, 31, 1, 1, "cream")]
    p += ['</g>', head_back(pose["head"], pose["curl"]) if back else head(pose["head"], pose["blink"], pose["curl"]), '</svg>']
    return '\n'.join(p) + '\n'


def pack_rows(folder, prefixes, output):
    command = ["magick"]
    for prefix in prefixes:
        command += ["(", *[str(folder / f"{prefix}_{i}.png") for i in range(4)], "+append", ")"]
    subprocess.run([*command, "-append", str(output)], check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for view in ("front", "back", "profile"):
        for pose in POSES:
            name = (view + "_" if view != "front" else "") + pose["name"]
            svg, png = OUT / (name + ".svg"), OUT / (name + ".png")
            svg.write_text(draw_profile("renna", pose, PALETTE) if view == "profile" else draw(pose, view == "back"))
            subprocess.run(["magick", "-background", "none", str(svg), str(png)], check=True)
    pack_rows(OUT, ("idle", "walk", "back_idle", "back_walk", "profile_idle", "profile_walk"), OUT / "sheet.png")


if __name__ == "__main__":
    main()
