"""Original right-facing profile drawings shared by the six character generators.

The side silhouette, single visible eye, nose, near/far limbs and accessories are
drawn independently of the front artwork. Godot mirrors these for left-facing art.
"""


def draw_profile(kind, pose, palette):
    colors = dict(palette)
    if kind == "renna":
        colors |= dict(cloth=colors["green"], cloth_dark=colors["green_dark"], cloth_light=colors["green_light"])
    elif kind == "aaron":
        colors |= dict(cloth=colors["coat"], cloth_dark=colors["coat_dark"], cloth_light=colors["coat_light"])
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40" shape-rendering="crispEdges">',
           f'<title>{kind} — profile_{pose["name"]}</title>']

    def r(x, y, w, h, color):
        out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{colors[color]}"/>')

    def p(data, color):
        out.append(f'<path d="{data}" fill="{colors[color]}"/>')

    walking = pose["name"].startswith("walk_")
    phase = int(pose["name"][-1])
    lift = pose.get("head", pose.get("lift", 0))
    settle = pose.get("curl", pose.get("settle", 0))
    # Each contact/passing pose has its own stride and opposing arm position.
    far, near = ((12, 35), (17, 35))
    hand = (19, 28 + (1 if phase == 3 else 0) + lift)
    if walking:
        far, near, hand = [
            ((9, 34), (20, 36), (12, 28)),
            ((15, 34), (16, 35), (17, 27)),
            ((21, 34), (10, 36), (23, 27)),
            ((15, 35), (16, 34), (20, 26)),
        ][phase]
    for index, (x, y) in enumerate((far, near)):
        p(f'M14 31h6v2l{x + 4 - 20} {y - 32}h-4z', "cloth_dark")
        r(x, y, 7, 4, "ink")
        r(x + 1, y, 5, 3, "boot" if index else "hair_dark")
        if index:
            r(x + 2, y, 4, 1, "boot_light")
    # Far arm is behind the torso and swings opposite the near arm.
    far_hand_x = 34 - hand[0]
    r(far_hand_x, hand[1] - 1, 4, 5, "ink")
    r(far_hand_x + 1, hand[1], 2, 3, "skin_shadow")
    out.append(f'<g transform="translate(0 {lift})">')
    p("M13 23h9v3h2v8h-2v2H11v-3h-1v-7h3z", "ink")
    p("M14 24h7v3h2v6h-2v2H12v-3h-1v-5h3z", "cloth_dark")
    p("M15 25h6v3h1v6h-9v-6h2z", "cloth")
    r(19, 26, 2, 6, "cloth_light")
    if kind == "renna":
        p("M20 27h3v5h1v3H13v-3h7z", "apron_dark")
        p("M21 28h1v5h1v1h-9v-1h7z", "apron")
        r(21, 29, 1, 5, "apron_light")
        r(21, 31, 2, 2, "potion")
        r(12, 29, 3, 1, "cream")
    elif kind == "aaron":
        r(11, 31, 12, 2, "boot")
        r(17, 31, 5, 4, "ink")
        r(18, 32, 3, 2, "boot_light")
        r(19, 32, 1, 1, "gold")
    elif kind == "elf":
        p("M12 24h3v5l-3 6H9v-3h1v-6z", "cloth_dark")
        p("M12 25h2v4l-3 4H10z", "cloth_light")
        r(17, 30, 5, 5, "ink")
        r(18, 31, 3, 3, "boot_light")
        r(19, 31, 1, 1, "gold")
    elif kind == "knight":
        r(19, 26, 4, 6, "cloth_light")
        r(20, 27, 2, 4, "cloth")
        r(11, 33, 12, 2, "accent")
        r(13, 29, 6, 1, "cloth_dark")
    elif kind == "wizard":
        p("M12 27h10v6h2v3H10v-3h2z", "cloth_dark")
        p("M14 28h7v6h1v1H12v-2h2z", "cloth")
        r(21, 28, 1, 7, "gold")
        r(12, 35, 11, 1, "gold")
    elif kind == "dwarf":
        r(20, 28, 3, 7, "green_dark")
        r(21, 29, 1, 5, "green_light")
        r(11, 32, 12, 2, "boot")
        r(21, 32, 2, 2, "gold")
    out.append('</g>')
    # Visible near arm crosses the torso rather than remaining front-facing.
    hx, hy = hand
    p(f'M16 {25 + lift}h4v3l{hx + 3 - 20} {hy - 26 - lift}v3h-4v-3l{17 - hx} {-hy + 27 + lift}z', "ink")
    p(f'M17 {26 + lift}h2v2l{hx + 2 - 19} {hy - 27 - lift}h-2z', "cloth")
    r(hx, hy, 4, 4, "ink")
    r(hx + 1, hy, 2, 3, "skin")
    r(hx + 1, hy, 2, 1, "skin_light")

    out.append(f'<g transform="translate(0 {lift})">')
    # Profile skull and jaw: one eye, a projected nose and the far side hidden.
    if kind in ("aaron", "wizard"):
        # Hair starts below the brim; a full rounded skull would protrude through
        # the narrow cone and look like hair growing out of the pointed hat.
        p("M10 12h14v4h5v4h-3v3h-3v3H13v-2H9v-3H6v-6h4z", "ink")
        p("M10 13h13v2h2v5h-3v4h-8v-2H9v-2H7v-5h3z", "hair_dark")
    else:
        p("M12 3h9v2h3v4h2v7h3v4h-3v3h-3v3H13v-2H9v-3H6V10h2V6h4z", "ink")
        p("M12 4h9v2h2v4h2v10h-3v4h-8v-2H9v-2H7V11h2V7h3z", "hair_dark")
    p("M17 10h6v2h2v5h3v2h-3v3h-3v3h-6v-2h-2v-9h3z", "skin_shadow")
    p("M18 11h4v2h2v5h3v1h-3v3h-3v2h-4v-2h-2v-7h3z", "skin")
    p("M19 13h3v1h1v4h2v1h-2v2h-5v-4h1z", "skin_light")
    if pose["blink"]:
        r(21, 18, 3, 1, "eye")
        r(23, 17, 1, 1, "eye")
    else:
        r(21, 16, 3, 4, "eye")
        r(22, 19, 2, 1, "iris")
        r(21, 16, 2, 1, "cream")
    r(19, 20, 4, 2, "blush")
    r(24, 22, 1, 1, "skin_shadow")
    r(23, 23, 1, 1, "skin_shadow")

    if kind == "renna":
        # Long hair fills the rear silhouette, with bangs over the temple.
        p("M11 2h8v2h4v3h2v6h-3v-2h-3v2h-3v9h-2v5H9v2H5v-3H4V12h2V7h2V4h3z", "hair_dark")
        p("M11 4h8v2h3v3h1v2h-4v-1h-4v3h-2v9h-2v4H8v1H6v-3H5V13h2V8h2V5h2z", "hair")
        r(10, 6, 9, 1, "hair_mid")
        r(11, 5, 6, 1, "hair_light")
        p("M8 12h2v10H8zM12 11h1v7h-1z", "hair_mid")
        p(f'M5 21h2v{4 + settle}h3v2H6v-2H5z', "hair")
        # The visible pointed ear breaks the rear hair contour.
        p("M7 15h6v2h2v4h-3v-1h-2v-2H7z", "ink")
        p("M8 16h4v2h2v2h-2v-1h-2v-2H8z", "skin")
        r(8, 16, 3, 1, "skin_light")
        r(14, 8, 2, 5, "hair_light")
        r(12, 10, 6, 1, "hair_light")
        r(14, 10, 2, 1, "gold")
    elif kind == "aaron":
        p("M9 11h12v2h-3v3h-3v8h-2v4H8v-3H6V15h3z", "hair_dark")
        p("M10 12h8v2h-2v2h-2v8h-3v2H9v-2H7v-8h3z", "hair")
        r(10, 16, 1, 8, "hair_light")
        r(14, 13, 3, 1, "hair_light")
        p(f'M8 23h2v{3 + settle}h3v2H9v-2H8z', "hair")
        p("M3 11h5V8h3V5h3V2h5V1h5v2h-4v3h1v4h5v1h5v4h-4v1H6v-1H3z", "ink")
        p("M5 12h5V9h3V6h3V3h6v1h-4v3h2v4h6v1h3v2H6z", "hat_dark")
        p("M12 10V8h2V5h3V3h3v1h-3v3h1v3z", "hat")
        r(15, 5, 1, 3, "hat_light")
        r(5, 12, 24, 2, "hat")
        r(10, 10, 15, 2, "coat_dark")
        r(11, 10, 13, 1, "coat")
        r(11, 9, 12, 1, "gold")
        r(12, 9, 3, 1, "cream")
    elif kind == "elf":
        p("M9 10h12v2h-4v3h-3v8h-4v2H7V14h2z", "hair")
        r(10, 12, 2, 9, "hair_light")
        p("M7 15h7v2h2v4h-3v-1h-2v-2H7z", "ink")
        p("M8 16h5v2h2v2h-2v-1h-2v-2H8z", "skin")
        r(8, 16, 4, 1, "skin_light")
        p("M6 10V7h3V4h6V2h9v2h-3v3h2v3z", "ink")
        p("M8 9V7h3V5h6V3h5v1h-3v3h2v2z", "cloth")
        r(7, 9, 17, 2, "cloth_dark")
        p(f'M10 8V4H8V{1 + max(0, settle)}H6v3h2v4z', "cream")
        r(10, 9, 2, 2, "gold")
    elif kind == "knight":
        # Helmet cheek guard behind the visible eye, no second frontal eye slit.
        p("M8 6h4V3h9v2h4v3h2v6h-5v-2h-7v12h-5v-2H7V10h1z", "ink")
        p("M9 8h4V5h8v2h3v3h1v2h-4v-1h-8v12h-2v-2H8V11h1z", "cloth")
        r(13, 5, 8, 1, "cloth_light")
        r(9, 10, 4, 1, "cloth_dark")
        r(10, 12, 2, 9, "cloth_light")
        r(12, 16, 1, 1, "gold")
        p(f'M15 5V2h3V{1 + max(0, settle)}h6v2h-4v2z', "accent")
    elif kind == "wizard":
        p("M8 14h5v5h-1v5H9v-2H7v-5h1z", "hair")
        r(8, 18, 1, 4, "hair_light")
        p("M19 23h6v2h-2v3h-4v-2h-2v-2h2z", "hair")
        r(20, 24, 3, 1, "hair_light")
        p("M4 12h5V8h3V5h3V2h6v3h-2v3h3v3h5v1h4v4H4z", "ink")
        p("M6 13h5V9h3V6h3V3h2v1h-2v4h3v4h7v1h2v2H6z", "cloth")
        r(6, 13, 23, 2, "cloth_dark")
        r(11, 11, 15, 2, "accent")
        r(16, 6, 1, 4, "cream")
        r(15, 7, 3, 1, "cream")
    elif kind == "dwarf":
        p("M9 11h9v2h-3v5h-3v3H9z", "hair")
        p("M14 20h3v3h5v-2h3v4h2v3h-3v3h-6v-2h-3v-3h-2z", "hair_dark")
        p("M15 22h2v3h6v-2h1v3h1v1h-3v3h-3v-2h-3z", "hair")
        r(17, 25, 1, 3, "hair_light")
        r(22, 26, 1, 2, "hair_light")
        r(19, 29, 3, 1, "gold")
        p("M7 12V8h2V5h4V3h9v2h3v3h1v5z", "ink")
        p("M9 11V8h2V6h4V4h6v2h2v3h1v2z", "cloth")
        r(8, 10, 18, 3, "cloth_dark")
        r(9, 10, 16, 1, "cloth_light")
        for x in (10, 14, 18, 22):
            r(x, 11, 1, 1, "cloth")
    out.append('</g>')
    if kind == "wizard":
        r(28, 25, 2, 13, "ink")
        r(28, 26, 1, 11, "boot_light")
        p("M27 22h3v1h1v4h-4v-1h-1v-3h1z", "ink")
        r(27, 23, 3, 3, "potion")
        r(27, 23, 1, 2, "cream")
    out.append('</svg>')
    return '\n'.join(out) + '\n'
