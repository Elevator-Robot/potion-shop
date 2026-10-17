"""Nine original cabinet silhouettes with contrasting wood and ingredient art.

Three-quarter/side views are drawn with side panels, projected tops and sloping
shelf planes; no upright cabinet is rotated as a flat object in the game.
"""
import random

# cavity, shadow wood, body wood, end grain, edge highlight, hardware
WOODS = [
    ("#211f30", "#352737", "#614151", "#85596b", "#c08a89", "#d8b571"),  # walnut
    ("#291d2b", "#562934", "#8e4146", "#b6655e", "#e6a284", "#e9c78a"),  # cherry
    ("#162c36", "#214d55", "#36777b", "#619c96", "#a6d1b6", "#d8b975"),  # teal wash
    ("#281e31", "#4b2d43", "#7d4255", "#ad6870", "#e0a094", "#c9a66c"),  # mahogany
    ("#302d32", "#776451", "#b29b77", "#d8c49a", "#f6e7be", "#627b85"),  # birch
    ("#1f243d", "#344265", "#526a91", "#7a94b6", "#bfd2d4", "#d5b77e"),  # indigo stain
    ("#1f2d2b", "#3c5549", "#69806a", "#96ab83", "#cbd7a1", "#c7a574"),  # moss oak
    ("#31272b", "#77604d", "#b6926e", "#d8b98b", "#f2dbab", "#5f6e78"),  # pine
    ("#34313a", "#817a70", "#c4bcb0", "#e0d8bd", "#fff0cf", "#728c9a"),  # cream paint
]


def ingredient(a, x, y, kind, phase):
    """Small independent objects, placed by their bottom anchor."""
    r, p, e = a.rect, a.path, a.ellipse
    if kind in (0, 14, 16):
        # Fern, berry sprig, or blue flowers. Stems, tied roots and varied leaves.
        r(x + 4, y - 12, 1, 12, "#456b58")
        for side, dy in [(-1, -10), (1, -8), (-1, -5)]:
            p(f'M{x+4} {y+dy}l{side*4} -3v3l{-side*4} 2z', "#88bd78")
        if kind == 14:
            for dx, dy in [(1, -8), (5, -6), (3, -3)]:
                r(x + dx, y + dy, 3, 3, "#d66c91")
                r(x + dx, y + dy, 1, 1, "#f6bfbb")
        elif kind == 16:
            for dx in [1, 5]:
                r(x + dx, y - 13 + phase % 2, 3, 3, "#83cbe2")
                r(x + dx + 1, y - 12 + phase % 2, 1, 1, "#f3d882")
        r(x + 2, y - 2, 5, 1, "#e4c58e")
    elif kind == 1:
        # Red/ochre mushrooms in a shallow basket.
        for dx, dy, color in [(0, -7, "#db765d"), (4, -9, "#edb565"), (7, -5, "#ba5368")]:
            r(x + dx + 1, y + dy + 2, 2, 5, "#e0c8a7")
            p(f'M{x+dx} {y+dy+3}v-3h1v-1h3v1h1v3z', "#573442")
            r(x + dx + 1, y + dy, 3, 2, color)
            r(x + dx + 1, y + dy, 1, 1, "#fff1cb")
        r(x, y - 2, 11, 2, "#b48a59")
    elif kind == 2:
        # Crystals, never confused with a rectangular bottle silhouette.
        p(f'M{x} {y}v-6l2-3 2 4 2-9 3 4-1 10z', "#3c657d")
        p(f'M{x+1} {y-1}v-5l1-1 2 4 2-8 1 2v8z', "#7cccd5")
        r(x + 6, y - 10, 1, 6, "#c8f2e2")
        if phase in (1, 3):
            r(x + 9, y - 9, 1, 3, "#fff2c8")
    elif kind == 3:
        for dx in [1, 4, 7]:
            p(f'M{x+dx} {y}v-4h-1v-4h1v-3h1v4h1v4h-1v3z', "#bc966b")
            r(x + dx, y - 9, 1, 3, "#e3cba1")
        r(x, y - 5, 9, 1, "#715047")
    elif kind in (4, 12, 17):
        # Fat glass ingredient jar: honey, luminous spores or pearls.
        r(x + 1, y - 12, 7, 2, "#bd9a6a")
        r(x, y - 10, 9, 10, "#263b49")
        r(x + 1, y - 10, 7, 9, ["#d9ac58", "#7ebbaa", "#bcadc9"][(4, 12, 17).index(kind)])
        for dx, dy in [(2, -7), (5, -5), (3, -3)]:
            r(x + dx, y + dy, 2, 2, "#f1e6bb" if kind != 12 else "#bcf0c9")
        r(x + 1, y - 10, 1, 5, "#edf2dc")
        r(x + 2, y - 6, 5, 3, "#e5cf9e")
        r(x + 4, y - 5, 1, 1, "#7d604e")
    elif kind in (5, 6, 8):
        color = {5: "#7fa5da", 6: "#e47f87", 8: "#b391d4"}[kind]
        r(x + 3, y - 13, 3, 2, "#c1996e")
        r(x + 3, y - 11, 3, 4, "#b8cfcb")
        e(x + 4, y - 4, 4, 4, "#2a354a")
        e(x + 4, y - 4, 3, 3, color)
        r(x + 2, y - 6, 1, 3, "#fff0d9")
        r(x + 3, y - 2, 4, 1, "#eee0c1", .6)
        if kind == 8:
            r(x + 3, y - 12, 3, 2, "#b8647a")
    elif kind == 7:
        e(x + 5, y - 3, 6, 3, "#4c637b")
        r(x, y - 3, 10, 2, "#879fa7")
        p(f'M{x+2} {y-4}v-5h3v1h-2v3h3v1z', "#efe0af")
        r(x + 6, y - 5, 3, 2, "#d3c7cc")
    elif kind == 9:
        p(f'M{x} {y-8}h9v6h-2v2H{x}z', "#ae956f")
        r(x + 1, y - 8, 7, 6, "#e2cda4")
        r(x + 1, y - 6, 5, 1, "#9c795d")
        r(x + 5, y - 8, 1, 8, "#8d6370")
    elif kind == 10:
        p(f'M{x} {y}v-7l3-4h4l3 4v7z', "#735741")
        p(f'M{x+1} {y-1}v-6l2-3h4l2 3v6z', "#ccb585")
        r(x + 3, y - 10, 4, 1, "#eee0b4")
        r(x + 4, y - 9, 1, 4, "#86644a")
    elif kind == 11:
        for dx, height, color in [(0, 11, "#618c88"), (4, 13, "#996684"), (8, 9, "#b39266")]:
            p(f'M{x+dx} {y}l-1-{height}h3l2 {height}z', color)
            r(x + dx, y - height + 2, 2, 1, "#e6d2ac")
    elif kind == 13:
        p(f'M{x+3} {y-4}l4-9 2 1-4 9z', "#bbc0b4")
        e(x + 5, y - 3, 5, 3, "#3c4b5b")
        e(x + 5, y - 4, 5, 2, "#9ba9a5")
        r(x + 1, y - 3, 8, 2, "#6d8589")
    else:
        p(f'M{x+1} {y-2}v-6h2v-2h4v2h2v6H{x+6}v2H{x+3}v-2z', "#dfd4b8")
        r(x + 2, y - 6, 2, 2, "#726668")
        r(x + 6, y - 6, 2, 2, "#726668")


def cabinet_face(a, variant, frame, top=6, rows=(24, 43, 62)):
    cavity, dark, wood, grain, light, metal = WOODS[variant]
    rng = random.Random(900 + variant)
    a.rect(4, top, 56, 64 - top, "#242332")
    a.rect(8, top + 5, 48, 59 - top, cavity)
    # Backboards with muted grain, and deep shadows immediately below each ledge.
    for x in range(9, 56, 9):
        a.rect(x, top + 5, 1, 55 - top, dark)
        a.rect(x + 2, top + 7, 1, 8, wood, .28)
    for x in (3, 56):
        a.rect(x, top + 2, 5, 66 - top, dark)
        a.rect(x, top + 2, 2, 64 - top, wood)
        a.rect(x, top + 3, 1, 60 - top, light)
        for y in range(top + 7, 64, 11):
            a.rect(x + 1, y, 2, 1, grain)
        for y in (top + 4, 63):
            a.rect(x + 1, y, 2, 2, metal)
    a.rect(2, top, 60, 4, dark)
    a.rect(3, top, 58, 2, wood)
    a.rect(5, top, 54, 1, light)
    a.rect(6, top - 2, 52, 2, grain)
    for row, y in enumerate(rows):
        a.rect(8, y + 3, 48, 3, "#171e2b", .7)
        a.rect(6, y, 52, 4, dark)
        a.rect(7, y, 50, 2, wood)
        a.rect(8, y, 48, 1, light)
        for _ in range(5):
            a.rect(rng.randrange(9, 48), y + 1, 4, 1, grain)
        # Distinct stock silhouettes: leaves, mushrooms, crystals, roots,
        # specimen jars, spices, scrolls, shells, books and mortar/pestle.
        stock = [
            [0, 4, 14, 9], [1, 6, 10, 11], [2, 5, 16, 17],
            [3, 8, 13, 0], [1, 10, 15, 6], [16, 7, 5, 12],
            [0, 14, 3, 10], [1, 4, 6, 9], [17, 2, 12, 13],
        ][variant]
        for column, x in enumerate([9, 21, 34, 45]):
            kind = stock[(column + row) % 4]
            bump = 1 if frame in (1, 2) and column == variant % 4 and row == 0 else 0
            ingredient(a, x, y - bump, kind, frame)
    # Cabinet base, drawer or carved trim; every material has a distinct grain.
    a.rect(6, 65, 52, 4, wood)
    a.rect(7, 65, 50, 1, light)
    a.rect(6, 69, 52, 1, dark)
    a.rect(7, 70, 5, 2, dark)
    a.rect(52, 70, 5, 2, dark)
    for x in [13, 27, 41]:
        a.rect(x, 66, 10, 1, grain)
    if variant in (1, 5, 8):
        for x in [10, 26, 42]:
            a.rect(x, 56, 13, 8, dark)
            a.rect(x + 1, 57, 11, 6, wood)
            a.rect(x + 1, 57, 11, 1, light)
            a.rect(x + 5, 59, 2, 2, metal)
    else:
        a.rect(27, 65, 10, 4, metal)
        a.rect(29, 66, 6, 2, dark)


def draw_shelf(Art, variant, frame):
    a = Art(64, 72)
    cavity, dark, wood, grain, light, metal = WOODS[variant]
    a.ellipse(32, 69, 30, 3, "#131d2b", .65)
    if variant in (2, 3, 6):
        # Two three-quarter directions with a visible top plane and deep side.
        if variant == 3:
            a.parts.append('<g transform="translate(64 0) scale(-1 1)">')
        a.path('M2 18l45-14 13 9-45 14z', grain)
        a.path('M9 18l36-11 1 1-36 11z', light)
        a.path('M13 21l34-10 1 1-34 10z', wood)
        a.path('M2 18l13 9v42L2 58z', dark)
        a.path('M3 20l10 7v38L3 57z', wood)
        for y in [27, 37, 48, 56]:
            a.path(f'M4 {y}l7 4v1l-7-4z', grain)
        a.parts.append('<g transform="matrix(.8 -.25 0 1 12 2)">')
        cabinet_face(a, variant, frame, 26 if variant != 6 else 35, (44, 62) if variant != 6 else (62,))
        if variant == 6:
            for x in (12, 24, 36, 46):
                ingredient(a, x, 36, 0 if x % 3 else 14, frame)
        a.parts.append('</g>')
        if variant == 3:
            a.parts.append('</g>')
    elif variant == 4:
        # Narrow side-on birch cabinet, opening toward the left aisle.
        a.path('M20 6l25 11v37L34 70 18 61z', dark)
        a.path('M35 18l9 1v34l-9 14z', wood)
        for y in [22, 32, 43, 54]:
            a.rect(37, y, 5, 1, grain)
        a.parts.append('<g transform="matrix(.34 .18 0 1 16 -8)">')
        cabinet_face(a, variant, frame, 14, (32, 48, 62))
        a.parts.append('</g>')
        a.path('M18 5l16 10 11 2-15-11z', light)
    elif variant == 7:
        # Low open sorting bins: no tall cupboard silhouette.
        a.path('M6 44h48l6 14H4z', grain)
        a.rect(5, 57, 54, 13, dark)
        a.rect(7, 59, 50, 9, wood)
        a.rect(7, 59, 50, 1, light)
        for x in [7, 24, 41]:
            a.rect(x, 46, 15, 10, cavity)
            ingredient(a, x + 2, 56, [1, 10, 4][(x // 17) % 3], frame)
            a.rect(x, 56, 15, 2, light)
            a.rect(x + 6, 62, 3, 2, metal)
        a.rect(8, 70, 5, 2, dark)
        a.rect(51, 70, 5, 2, dark)
    else:
        top = 6 if variant == 0 else (12 if variant == 1 else 28)
        rows = (24, 43, 62) if variant == 0 else ((31, 51) if variant == 1 else (48,))
        cabinet_face(a, variant, frame, top, rows)
        if variant == 0:
            # Carved arch crown and bundles of dried herbs over the cupboard.
            a.path('M12 5V3h6V1h28v2h6v2z', wood)
            a.rect(20, 1, 24, 1, light)
            # Small bundles fit inside the atlas cell, unlike full-height jars.
            for x in (11, 14, 17):
                a.rect(x, 1, 1, 5, "#7ca46a")
                a.rect(x - 1, 1 + frame % 2, 3, 2, "#b6d293")
            for x in (44, 47, 50):
                a.rect(x, 1, 1, 5, "#c9aa7f")
            a.rect(43, 4, 9, 1, dark)
        elif variant == 1:
            ingredient(a, 12, 12, 1, frame)
            ingredient(a, 40, 13, 11, frame)
        elif variant == 5:
            ingredient(a, 11, 28, 5, frame)
            ingredient(a, 27, 28, 7, frame)
            ingredient(a, 43, 28, 16, frame)
        else:
            ingredient(a, 10, 28, 12, frame)
            ingredient(a, 27, 28, 13, frame)
            ingredient(a, 43, 28, 2, frame)
    return a
