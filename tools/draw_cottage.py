#!/usr/bin/env python3
"""Crooked woodland cottage kit: nine tall cases, twelve walls, woods and emotes."""
from pathlib import Path
import random
import re
import subprocess
import tempfile
from draw_shop_interior import Art

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/cottage"
WALL_NAMES = ["fieldstone", "oak_post", "cracked_plaster", "mossy_boards", "log_wall", "cross_brace", "ivy_stone", "lantern", "round_glass", "arched_glass", "shadow_niche", "root_pillar"]
ROWS = [[36,69,103],[38,70,103],[38,70,103],[36,69,103],[40,72,103],[72,103],[36,69,103],[72,103],[38,70,103]]


def floor_points():
    source = (ROOT / "network/cottage_layout.gd").read_text().split("const FLOOR_POINTS := [", 1)[1].split("]", 1)[0]
    return [(float(x), float(y)) for x,y in re.findall(r"Vector2\(([-\d.]+),\s*([-\d.]+)\)", source)]


def floor():
    a = Art(400,272)
    points = " ".join(f"{x/2},{(y+24)/2}" for x,y in floor_points())
    a.parts += [f'<defs><clipPath id="room"><polygon points="{points}"/></clipPath></defs>', '<g clip-path="url(#room)">']
    a.rect(0,0,400,272,"#30272c")
    rng = random.Random(717)
    for row,y in enumerate(range(0,272,12)):
        for x in range(-48+(row%3)*16,400,48):
            a.rect(x+1,y+1,46,10,rng.choice(["#765744","#6d5141","#80614a","#795e4b"]))
            a.rect(x+2,y+1,44,1,"#a58a63")
            a.rect(x+2,y+10,44,1,"#4b3831")
            for _ in range(4):
                a.rect(x+rng.randrange(4,32),y+rng.randrange(3,9),rng.randrange(4,12),1,rng.choice(["#927353","#604735"]))
            if rng.random()<.3:
                a.ellipse(x+25,y+6,4,2,"#5e4637")
                a.rect(x+24,y+6,3,1,"#3d3030")
            a.rect(x+3,y+3,1,1,"#c1a579")
    a.parts.append('</g>')
    return a


def shelf(v,f):
    a=Art(64,112)
    palettes=[("#3c2c36","#705044","#bb9371"),("#392c35","#765547","#c0a075"),("#2b3632","#5b6b51","#a8b080"),("#3c2939","#76505c","#bd8e88"),("#3a3230","#89745a","#c9b18b"),("#272a34","#515d65","#95a4a2"),("#30382e","#667453","#afba83"),("#45382f","#957b5b","#d2bb8c"),("#312c3c","#6a576f","#b39aaa")]
    dark,wood,edge=palettes[v]
    top=[8,12,9,5,14,52,5,56,7][v]
    a.ellipse(32,110,30,2,"#101922",.7)
    def box(x,y,w,h):
        a.rect(x,y,w,h,dark)
        a.rect(x+3,y+3,w-6,h-6,"#20202c")
        a.rect(x,y,w,2,wood)
        a.rect(x+1,y,w-2,1,edge)
        a.rect(x,y+2,2,h-2,wood)
        a.rect(x,y+h-3,w,2,wood)
        a.rect(x+2,y+h-3,w-4,1,edge)
        a.rect(x+w-3,y+2,1,h-3,edge,.65)
        for gx in range(x+8,x+w-4,9):
            a.rect(gx,y+4,1,h-9,dark)
    if v==1:
        # A precarious tower of mismatched open cubbies, not one tall rectangle.
        a.path('M12 108l8-84h10l12 84z',dark)
        for x,y,w,h in [(12,8,33,23),(3,31,48,26),(17,57,44,25),(5,82,51,27)]:
            box(x,y,w,h)
        a.path('M11 8l6-5h23l7 5z',wood)
        a.rect(7,108,7,4,dark)
        a.rect(48,108,7,4,dark)
        a.rect(36,35,2,18,wood)
        a.rect(27,86,3,19,wood)
        return a
    if v in [2,6]:
        # Living-wood stand: split trunks and uneven shelves, open to the room.
        a.path('M11 111l12-19-3-20 7-20-4-24 7-23h7l-2 24 6 21-7 23 5 22 13 16H37l-5-13-8 13z',dark)
        a.path('M18 108l10-16-3-19 7-21-4-24 5-21h2l-2 23 5 20-7 23 5 22 8 13h-4l-8-14-11 14z',wood)
        shelves=[(3,29,43),(19,52,43),(3,77,51),(12,101,42)] if v==2 else [(14,24,46),(2,48,40),(17,74,44),(4,101,48)]
        for i,(x,y,w) in enumerate(shelves):
            a.path(f'M{x} {y}h{w}l-2 5H{x+2}z',dark)
            a.rect(x+1,y,w-2,2,wood)
            a.rect(x+2,y,w-4,1,edge)
            a.path(f'M30 {y+11}l{x-28} -7h{max(w-4,1)}l{30-x-w+2} 7z',dark)
            a.rect(x+3,y-8,2,8,wood)
            a.rect(x+w-6,y-12,2,12,wood)
        a.path('M23 19L9 9H4l13 16 9 4zM37 27l14-15h9L44 32z',wood)
        for x,y in [(27,42),(30,68),(32,91)]:
            a.ellipse(x,y,3,5,"#252b2a")
            a.rect(x-1,y-2,1,4,edge)
        return a
    if v==3:
        a.path('M5 15l9-11h29l12 10-3 31 9 25-7 38H7L3 75l9-28z',dark)
        for x,y,w,h in [(7,13,45,29),(15,44,45,29),(4,75,49,33)]:
            box(x,y,w,h)
        a.path('M9 13l8-7h22l11 7z',wood)
        a.rect(21,5,17,2,edge)
        a.rect(8,108,8,4,dark)
        a.rect(45,108,8,4,dark)
        return a
    if v==5:
        # Domed bottle hutch, with open arched bays and stout claw feet.
        a.path('M3 106V72l5-12 10-7h28l11 8 5 11v34z',dark)
        a.path('M7 103V73l5-11 8-5h24l10 6 4 10v30z',wood)
        a.path('M11 98V73l5-10h14v35zM34 98V63h11l9 10v25z',"#20222e")
        a.rect(10,82,45,4,dark)
        a.rect(11,82,43,1,edge)
        a.rect(29,61,5,41,dark)
        a.rect(30,62,1,39,edge)
        a.rect(7,105,8,7,dark)
        a.rect(49,105,8,7,dark)
        return a
    if v==7:
        a.path('M5 104V72l6-11 12-7h18l13 8 6 12v30l-10 5H15z',dark)
        a.path('M9 101V73l6-9 9-6h16l10 7 6 10v26z',wood)
        a.path('M14 96V75l5-9h25l7 10v20z',"#24222b")
        for x in [14,30,46]:
            a.rect(x,68,3,33,dark)
            a.rect(x,70,1,29,edge)
        a.rect(9,84,47,4,dark)
        a.rect(10,84,44,1,edge)
        a.rect(10,107,8,5,dark)
        a.rect(47,107,8,5,dark)
        return a
    if v==4:
        a.parts.append('<g transform="matrix(.65 0 .12 1 5 0)">')
    # Uneven structural posts: bowed, leaning and branch-like, with planted feet.
    bends=[(-2,2),(3,-2),(-3,-1),(1,3),(-1,-3),(0,0),(-3,3),(0,0),(2,-2)][v]
    a.path(f'M7 {top+4}h49l{bends[1]} 29-1 34 2 {38-top}H6l2-36 {bends[0]}-30z',"#231e2a")
    a.rect(12,top+9,40,94-top,"#24222d")
    for x in [15,25,36,46]:
        a.rect(x,top+10,1,87-top,dark)
    for x,bend in [(4,bends[0]),(54,bends[1])]:
        a.path(f'M{x} {top+3}h5l{bend} 28-1 37 2 {40-top}h-6l-1-{39-top} 1-36z',dark)
        a.path(f'M{x+1} {top+4}h2l{bend} 28-1 36 2 {38-top}h-2l-2-{38-top} 1-36z',wood)
        a.rect(x,106,6,6,dark)
        a.rect(x,106,5,1,edge)
    # Each crown and silhouette is deliberately different.
    if v in [0,3,8]:
        a.path(f'M4 {top+4}l9-3 5-6h27l4 5 11 2v5H4z',wood)
        a.path(f'M10 {top+2}l9-4h26l7 3v1H10z',edge)
        a.ellipse(32,top+1,4,3,dark)
        a.rect(31,top,2,2,"#b6b587")
    elif v in [2,6]:
        a.path(f'M2 {top+6}l11-5 4-5 5 3 10-3 11 3 7-2 5 5 7 2v5H3z',dark)
        a.path(f'M5 {top+5}l12-5 8 3 10-3 14 4 10 1v2H5z',wood)
        for x in [10,27,49]:
            a.rect(x,top+3,2,4,edge)
    else:
        a.path(f'M3 {top}h55l4 6H2z',dark)
        a.rect(5,top+1,51,2,wood)
        a.rect(7,top+1,46,1,edge)
    for i,y in enumerate(ROWS[v]):
        shift=(-2 if i%2 else 1) if v in [1,4,6] else 0
        a.path(f'M{6+shift} {y}h51l3 4H{5+shift}z',dark)
        a.rect(7+shift,y,49,2,wood)
        a.rect(8+shift,y,47,1,edge)
        a.rect(9,y+4,44,3,"#141b24",.5)
        for x in [13,30,44]:
            a.rect(x,y+1,7,1,edge,.35)
        if v in [1,8] and i<2:
            a.rect(28+i*6,y-18,3,18,wood)
    # Small ladders, carved spirals, claw feet and mismatched drawer hardware.
    if v in [0,4]:
        a.path('M45 108l6-48h2l-6 48zM56 108l4-48h2l-4 48z',edge)
        for y in [69,80,91,102]:
            a.rect(49-(y-69)//15,y,10,2,wood)
    if v in [2,6]:
        a.path('M4 103l-3 6h8l3-5h-3zM55 103l6 7h-9v-3z',wood)
    a.rect(11,107,42,3,wood)
    a.rect(12,107,40,1,edge)
    a.rect(29,108,6,2,"#9e9271" if f in [0,3] else "#cac18d")
    if v==8:
        a.path('M10 18V9l5 3 5-9 5 8 7-10 7 10 5-8 5 9 5-3v9z',wood)
        a.ellipse(32,15,5,5,dark)
        a.path('M33 11h2v2h-2v4h2v2h-4v-2h-2v-4h2v-2z',edge)
        for y in [38,70,103]:
            a.path(f'M11 {y-4}v-9l4 6v3zM53 {y-4}v-9l-4 6v3z',wood)
    if v==4:
        a.parts.append('</g>')
    return a


def wall(v,f):
    a=Art(64,64)
    a.rect(0,0,64,64,"#332e35")
    stone=v in [0,1,6,7,8,9,10,11]
    if stone:
        for row,y in enumerate(range(0,64,12)):
            for x in range(-12 if row%2 else 0,64,24):
                a.path(f'M{x+2} {y+1}h19l2 2v7l-2 1H{x+1}V{y+3}z',"#69726c")
                a.rect(x+3,y+2,16,1,"#9b9c85")
                a.rect(x+5,y+6,8,1,"#798478")
                a.rect(x+2,y+10,18,1,"#48554f")
    else:
        a.rect(0,0,64,64,"#918879" if v in [2,5] else "#655945")
        for y in range(2,64,8):
            a.rect(2,y,60,1,"#b0a08b" if v in [2,5] else "#9c8662")
            a.rect(4,y+5,54,1,"#716653" if v in [2,5] else "#493f35")
    a.rect(0,0,64,5,"#3d302e")
    a.rect(0,1,64,1,"#9c7b56")
    a.rect(0,58,64,6,"#392c2c")
    a.rect(0,58,64,1,"#897254")
    if v in [1,2,3,5,11]:
        a.path('M8 0h8l-2 20 4 22-3 22H7l3-22-4-22z',"#392c2e")
        a.path('M10 0h3l-1 20 4 22-3 22h-2l2-22-4-22z',"#85654a")
        a.path('M48 0h7l-2 23 4 41h-8l-3-40z',"#48352e")
    if v in [2,5]:
        a.path('M12 7l4-3 38 44-4 4z',"#564035")
        a.path('M14 8l1-1 36 42-1 1z',"#ac8a5c")
        a.path('M33 13v9h-3v6h2v7h-1v-6h-3v-8h3v-8z',"#605f56")
    if v in [3,6,11]:
        for x in [4,18,42,59]:
            a.path(f'M{x} 5v13h2v9h-2v12h2v13h-3V39h-1V25h1V14h-1V5z',"#455a43")
            for y in [12,23,36,47]:
                a.rect(x-2,y,5,3,"#829567")
                a.rect(x,y,2,1,"#b0b585")
    if v==4:
        for y in range(7,58,10):
            a.rect(1,y,62,8,"#746044")
            a.rect(2,y+1,60,1,"#ae9162")
            a.ellipse(11,y+4,4,3,"#534333")
            a.rect(10,y+4,3,1,"#ac8b59")
    if v in [8,9,10]:
        a.path('M18 53V25l3-10 11-7 11 7 3 10v28z',"#342d38")
        a.path('M21 50V26l3-9 8-5 8 5 3 9v24z',"#151f2b")
        if v!=10:
            colors=["#9ebfb0","#aa91b9","#d7ba79","#729cae"]
            for y in [25,35,45]:
                for x in [24,32,40]:
                    a.path(f'M{x} {y-5}l4 5-4 5-4-5z',colors[(x//8+y//10)%4])
            a.rect(24+f*4,26,1,3,"#eee0b5")
        else:
            a.rect(20,38,24,3,"#91714f")
        a.rect(16,52,32,4,"#89765d")
        a.rect(17,52,30,1,"#b8aa83")
    if v==7:
        a.rect(31,8,2,11,"#b09d74")
        a.path('M24 19l8-5 8 5v22l-8 4-8-4z',"#272b32")
        a.rect(27,22,10,17,["#d9ad65","#e8c47d","#d3a861","#edc483"][f])
        a.rect(30,23,4,15,"#f7dd9f")
        a.rect(31,20,2,22,"#4b4339")
    return a


def woods():
    a=Art(512,416)
    a.rect(0,0,512,416,"#14242a")
    rng=random.Random(881)
    for _ in range(1200):
        x,y=rng.randrange(512),rng.randrange(416)
        a.rect(x,y,rng.randrange(1,5),1,rng.choice(["#20372f","#293a37","#28323f","#344239"]))
    for wx,wy in [(-56,80),(-64,280),(-20,540),(112,588),(304,596),(580,600),(820,536),(844,320),(840,120),(120,-96),(620,-104),(784,-64)]:
        x,y=int((wx+112)/2),int((wy+160)/2)
        h=rng.randrange(48,84)
        a.path(f'M{x-5} {y}l3-{h//2}-4-{h//2}h8l2 {h//2} 2 {h//2} 10 5-14-3-13 4z',"#1b1926")
        a.path(f'M{x-2} {y-1}l2-{h//2}-3-{h//2}h3l2 {h//2}-1 {h//2}z',"#454337")
        for side,dy in [(-1,15),(1,29),(-1,40)]:
            a.path(f'M{x} {y-h+dy}l{side*18} -12 {side*8} 3 {-side*22} 14z',"#242a2b")
            for i in range(3):
                a.ellipse(x+side*(10+i*5),y-h+dy-9+i*2,12-i*2,6,"#294235")
                a.rect(x+side*(10+i*5)-4,y-h+dy-12+i*2,8,1,"#4e6246")
        for mx in [x-12,x+9]:
            a.rect(mx,y-2,1,5,"#677a6b")
            a.ellipse(mx,y-3,3,2,"#8e7d9b")
            a.rect(mx-1,y-4,2,1,"#c4bdc9")
    for _ in range(55):
        x,y=rng.randrange(512),rng.randrange(416)
        a.rect(x,y,1,1,"#9dbb92",.55)
    return a


def emote(kind,f):
    a=Art(20,20)
    lift=[0,-1,0,1][f]
    a.parts.append(f'<g transform="translate(0 {lift})">')
    if kind==0:
        a.path('M2 6l3-3h3l2 3 2-3h3l3 3v4l-8 8-8-8z',"#55334c")
        a.path('M4 6l2-1h1l3 4 3-4h1l2 1v3l-6 6-6-6z',"#ed9eb7")
        a.rect(5,6,2,2,"#ffe2d7")
    elif kind==1:
        a.path('M5 5V3h9v2h2v5h-3v3H9v-5h3V6H8v1H5zM9 15h4v3H9z',"#e5cf91")
    elif kind==2:
        a.path('M3 4h14v10H9l-4 3v-3H3z',"#a6b9bc")
        for i,x in enumerate([6,10,14]):
            a.rect(x,8-(1 if i==f%3 else 0),2,2,"#364451")
    elif kind==3:
        a.path('M9 1h2l2 6 6 2v2l-6 2-2 6H9l-2-6-6-2V9l6-2z',"#9ad6b1")
        a.rect(8,8,4,4,"#f2efc2")
    else:
        a.rect(8,3,4,10,"#f1bd7b")
        a.rect(8,15,4,3,"#f1bd7b")
    a.parts.append('</g>')
    return a


def export(folder,name,art):
    folder.mkdir(parents=True,exist_ok=True)
    svg,png=folder/f"{name}.svg",folder/f"{name}.png"
    svg.write_text(art.svg())
    subprocess.run(["magick","-background","none",str(svg),str(png)],check=True)
    return str(png)

def sheets(folder,name,rows):
    command=["magick"]
    for row,frames in enumerate(rows):
        paths=[export(folder,f"{name}_{row}_{i}",art) for i,art in enumerate(frames)]
        command += ["(",*paths,"+append",")"]
    subprocess.run([*command,"-append",str(folder/f"{name}.png")],check=True)

def main():
    export(OUT,"floor",floor())
    export(OUT,"woods",woods())
    sheets(OUT,"shelves",[[shelf(v,f) for f in range(4)] for v in range(9)])
    for v,name in enumerate(WALL_NAMES):
        sheets(OUT/"walls",name,[[wall(v,f) for f in range(4)]])
    sheets(OUT,"emotes",[[emote(k,f) for f in range(4)] for k in range(5)])

if __name__ == "__main__":
    main()
