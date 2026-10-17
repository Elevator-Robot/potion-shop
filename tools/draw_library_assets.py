#!/usr/bin/env python3
"""Empty grounded shelves and a standalone violet/jade animated cauldron."""
from pathlib import Path
import subprocess
from draw_shop_interior import Art

ROOT = Path(__file__).resolve().parents[1]
SHELVES = ROOT / "assets/furniture/library"
POT = ROOT / "assets/props/cauldron"
ROWS = [[28,50,72],[32,52,72],[32,52,72],[30,51,72],[32,52,72],[48,72],[30,51,72],[48,72],[48,72]]


def shelf(variant, frame):
    a = Art(64, 80)
    palettes = [
        ("#352a30", "#6d5044", "#aa8161"), ("#3e2d35", "#79514c", "#b78870"),
        ("#403a36", "#877360", "#c7af8b"), ("#302a34", "#624b49", "#a08370"),
        ("#3b342c", "#80694e", "#bfa16f"), ("#30282d", "#60473f", "#a78061"),
        ("#303730", "#65674e", "#a5a17a"), ("#45392f", "#8d7758", "#c5b18a"),
        ("#282b35", "#50565d", "#939995"),
    ]
    dark, wood, edge = palettes[variant]
    top = [4,8,8,6,8,24,6,24,24][variant]
    # Full feet and a contact shadow touch the same bottom baseline in every view.
    a.ellipse(32, 78, 30, 2, "#111925", .7)
    a.rect(3, top + 3, 58, 74 - top, "#201e2b")
    a.rect(8, top + 6, 48, 67 - top, "#282430")
    for x in range(9, 56, 8):
        a.rect(x, top + 6, 1, 65 - top, dark)
        a.rect(x + 2, top + 9, 1, 10, wood, .25)
    for x in [3, 57]:
        a.rect(x, top + 2, 4, 78 - top, dark)
        a.rect(x, top + 3, 2, 74 - top, wood)
        a.rect(x, top + 4, 1, 72 - top, edge)
        for y in range(top + 12, 73, 16):
            a.rect(x + 1, y, 2, 1, edge)
        a.rect(x, 77, 5, 3, dark)
        a.rect(x, 77, 4, 1, edge)
    a.rect(2, top, 60, 4, dark)
    a.rect(3, top, 58, 2, wood)
    a.rect(5, top, 54, 1, edge)
    for y in ROWS[variant]:
        a.rect(7, y, 50, 4, dark)
        a.rect(8, y, 48, 2, wood)
        a.rect(8, y, 48, 1, edge)
        a.rect(8, y + 4, 48, 2, "#161d28", .5)
        for x in [13,27,43]:
            a.rect(x, y + 1, 7, 1, edge, .45)
    # Variety belongs to the empty furniture: arches, dividers, peg holes, trim.
    if variant in [0,3,6]:
        a.path(f'M8 {top}v-2h8v-2h32v2h8v2z', wood)
        a.rect(18, top - 3, 28, 1, edge)
    if variant in [1,4,8]:
        for y in ROWS[variant]:
            for x in [23,41]:
                a.rect(x, y - 15, 2, 15, dark)
                a.rect(x, y - 14, 1, 14, wood)
    if variant == 7:
        for x in [8,26,44]:
            a.rect(x, 64, 13, 8, wood)
            a.rect(x + 1, 64, 11, 1, edge)
    a.rect(8, 76, 48, 2, wood)
    a.rect(9, 76, 46, 1, edge)
    a.rect(29, 76, 6, 2, "#a99771" if frame in (1,2) else "#7b745f")
    return a


def cauldron(state, frame, liquid=False):
    a = Art(64, 72)
    if liquid:
        a.ellipse(32, 31, 20, 5, "#c5e5d2")
        a.ellipse(30, 30, 16, 3, "#edf1d6")
        for i,x in enumerate([20,28,38,44]):
            y = 32 - (frame + i * 2) % 5
            a.rect(x,y,2,2,"#ffffff",.8)
        if state > 0:
            for x in [24,38]:
                y = 21 - (frame * 2 + x) % 12
                a.rect(x,y,2,4,"#ccf3df",.35)
                a.rect(x+1,y-2,2,2,"#e5d4f4",.25)
        return a
    a.ellipse(32,69,29,3,"#101a25",.65)
    a.ellipse(32,65,24,5,"#436255",.45)
    for x in [13,45]:
        a.path(f'M{x} 57h6v10l-2 3h-6v-3h2z', "#272239")
        a.rect(x+2,59,2,7,"#6e6885")
        a.rect(x-1,67,5,1,"#8bbca6")
    a.path('M10 29h44v21l-5 10-8 4H22l-8-5-4-10z', "#211e32")
    a.path('M13 31h38v18l-5 9-7 3H24l-7-5-4-9z', "#42364f")
    a.path('M16 35h5v14l4 8-5-2-4-8z', "#837393")
    a.path('M44 34h5v14l-4 9-6 3 5-12z', "#302a43")
    a.ellipse(32,29,25,8,"#25263a")
    a.ellipse(32,28,24,6,"#8a809b")
    a.ellipse(32,30,21,5,"#315648")
    for x in [3,55]:
        a.rect(x,31,6,15,"#25263a")
        a.rect(x+1,32,4,3,"#a49bb4")
        a.rect(x+2,35,2,8,"#5a5172")
    glow = ["#619f8a", "#82c7a4", "#a5e5b9", "#7dbba2"][frame]
    for x in [23,31,39]:
        a.path(f'M{x} 43l3-3 3 3-3 5z', "#26363d")
        a.path(f'M{x+1} 43l2-2 2 2-2 3z', glow)
    a.rect(22,53,20,1,glow,.55)
    if state > 0:
        for i,x in enumerate([23,32,40]):
            y = 65 - (frame + i) % 3
            a.path(f'M{x} {y}v-5l2-3 2 4v4z', "#9276b7")
            a.rect(x+1,y-3,2,2,"#bae5bb")
    if state == 2:
        for x,y in [(8,19),(52,15)]:
            a.rect(x,y+frame%2,1,5,"#d7f4c8")
            a.rect(x-1,y+2+frame%2,3,1,"#d7f4c8")
    return a


def sheet(folder, name, rows):
    folder.mkdir(parents=True, exist_ok=True)
    command = ["magick"]
    for row, frames in enumerate(rows):
        paths=[]
        for i,art in enumerate(frames):
            svg,png=folder/f"{name}_{row}_{i}.svg",folder/f"{name}_{row}_{i}.png"
            svg.write_text(art.svg())
            subprocess.run(["magick","-background","none",str(svg),str(png)],check=True)
            paths.append(str(png))
        command += ["(",*paths,"+append",")"]
    subprocess.run([*command,"-append",str(folder/f"{name}.png")],check=True)

def main():
    sheet(SHELVES,"shelves",[[shelf(v,f) for f in range(4)] for v in range(9)])
    for name,liquid in [("cauldron",False),("liquid",True)]:
        sheet(POT,name,[[cauldron(s,f,liquid) for f in range(4)] for s in range(3)])
    # Floor clutter contains only furniture/books, never baked ingredient art.
    for variant in range(3):
        a = Art(48,32)
        a.ellipse(24,29,22,3,"#131b27",.45)
        if variant == 1:
            for x,y,w,color in [(8,21,26,"#66566b"),(13,16,25,"#6e8074"),(5,10,27,"#8e715b")]:
                a.rect(x,y,w,7,"#292331")
                a.rect(x+1,y+1,w-2,5,color)
                a.rect(x+2,y+3,w-4,2,"#d8c4a1")
        else:
            a.path('M4 9h34l6 6v13H8L4 22z',"#382c30")
            a.rect(7,11,28,10,"#201f29")
            a.rect(7,11,28,1,"#b69b73")
            a.rect(8,21,32,7,"#77604a")
            for y in [22,25]:
                a.rect(9,y,30,1,"#ab8e68")
            for x in [10,36]:
                a.rect(x,20,2,8,"#544238")
        svg,png=SHELVES/f"clutter_{variant}.svg",SHELVES/f"clutter_{variant}.png"
        svg.write_text(a.svg())
        subprocess.run(["magick","-background","none",str(svg),str(png)],check=True)

if __name__ == "__main__":
    main()
