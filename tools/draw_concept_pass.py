#!/usr/bin/env python3
"""Reference-led atmosphere pass. Originals in the concept folder are read-only.

Derives animated cutout trees from supplied transparent references; draws new
pixel mushrooms, layered terrain, violet windows, rugs and decorated shelf views.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import subprocess
from draw_shop_interior import Art
from draw_cottage import floor_points

ROOT=Path(__file__).resolve().parents[1]
CONCEPT=Path("/home/aphexlog/Google Drive/Game Dev/Potion Shop/potion-shop/concept")
OUT=ROOT/"assets/atmosphere"
MIRROR=[False,False,True,False,True,True,True,False,False]
SIDE=[False,True,False,False,True,False,False,True,False]


def export(folder,name,art):
    folder.mkdir(parents=True,exist_ok=True)
    svg,png=folder/f"{name}.svg",folder/f"{name}.png"
    svg.write_text(art.svg())
    subprocess.run(["magick","-background","none",str(svg),str(png)],check=True)
    return str(png)


def pack(folder,name,rows):
    command=["magick"]
    for row,frames in enumerate(rows):
        paths=[export(folder,f"{name}_{row}_{i}",art) for i,art in enumerate(frames)]
        command += ["(",*paths,"+append",")"]
    subprocess.run([*command,"-append",str(folder/f"{name}.png")],check=True)


def trees():
    folder=OUT/"trees"
    folder.mkdir(parents=True,exist_ok=True)
    provenance=[]
    for name,source in [("guardian","tree1.png"),("willow","tree6.png"),("spirit_willow","tree6.png")]:
        path=CONCEPT/"exterior"/source
        raw=bytearray(subprocess.run(["magick",str(path),"-trim","+repage","-filter","point","-resize","128x160","-background","none","-gravity","south","-extent","128x160","-depth","8","rgba:-"],check=True,stdout=subprocess.PIPE).stdout)
        # Remove isolated cutout crumbs while preserving disconnected large wisps.
        active={i for i in range(128*160) if raw[i*4+3]>8}
        while active:
            seed=active.pop(); component=[seed]; todo=[seed]
            while todo:
                pixel=todo.pop(); x,y=pixel%128,pixel//128
                for dy in [-1,0,1]:
                    for dx in [-1,0,1]:
                        nx,ny=x+dx,y+dy
                        if 0<=nx<128 and 0<=ny<160 and ny*128+nx in active:
                            neighbor=ny*128+nx; active.remove(neighbor); component.append(neighbor); todo.append(neighbor)
            if len(component)<=3:
                for pixel in component: raw[pixel*4+3]=0
        paths=[]
        for frame in range(4):
            pixels=bytearray(len(raw))
            sway=[0,1,0,-1][frame]
            for y in range(160):
                shift=round(sway*2.0*max(0,1-y/100)**2)
                for x in range(128):
                    sx=x-shift
                    if not 0<=sx<128: continue
                    src=(y*128+sx)*4
                    dst=(y*128+x)*4
                    r,g,b,a=raw[src:src+4]
                    # Soft root-edge alpha blends the supplied ground island
                    # into our terrain; trunks and roots stay fixed in the wind.
                    if y>145: a=round(a*(160-y)/15)
                    if name=="guardian" and r>150 and r>g*1.5:
                        factor=[.92,1.02,1.12,1.0][frame]
                        r,g,b=[min(255,round(c*factor)) for c in (r,g,b)]
                    if name=="spirit_willow":
                        r=min(255,round(r*1.06)); b=min(255,round(b*1.17))
                        distance=((x-65)/4)**2+((y-96)/7)**2
                        if distance<1 and a>80:
                            glow=(1-distance)*[.65,.85,1.0,.8][frame]
                            r,g,b=[round(c*(1-glow)+target*glow) for c,target in zip((r,g,b),(180,110,240))]
                    pixels[dst:dst+4]=bytes((r,g,b,a))
            png=folder/f"{name}_{frame}.png"
            subprocess.run(["magick","-size","128x160","-depth","8","rgba:-",str(png)],input=pixels,check=True)
            paths.append(str(png))
        subprocess.run(["magick",*paths,"+append",str(folder/f"{name}.png")],check=True)
        provenance.append({"asset":name,"source":str(path),"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"changes":"trim/resize, canopy-only pixel sway, root alpha feather; guardian ember pulse or spirit hollow glow"})
    (folder/"sources.json").write_text(json.dumps(provenance,indent=2)+"\n")


def mushroom(kind,frame):
    a=Art(32,40)
    colors=[("#447e9b","#81d9e3"),("#745391","#c49bdd"),("#9d4b68","#e497ba"),("#859387","#d9e3ba")]
    dark,light=colors[kind]
    for i,(x,y,size) in enumerate([(15,17,12),(6,28,7),(25,30,6)]):
        a.path(f'M{x-2} {y}h4l2 {37-y}h-7z',"#31303f")
        a.rect(x-1,y+2,2,34-y,"#a8aba1")
        a.ellipse(x,y,size,5 if kind==2 else 3,"#211f32")
        if kind==0:
            a.path(f'M{x-size} {y}l3-7 {size-3}-4 {size-3} 4 3 7z',dark)
        else:
            a.ellipse(x,y-2,size-1,5 if kind==2 else 3,dark)
        a.path(f'M{x-size+2} {y-3}l3-4h{size*2-10}l3 4z',light)
        for dx in [-4,0,4]:
            a.rect(x+dx,y-5,2,1,"#e0e7ce")
        a.rect(x-size+3,y+2,size*2-6,1,light)
        a.rect(x+((frame+i)%3-1)*3,y-10-frame%2,1,1,light)
    return a


def floor():
    a=Art(320,218)
    points=" ".join(f"{x/2},{(y+20)/2}" for x,y in floor_points())
    a.parts += [f'<defs><clipPath id="floor"><polygon points="{points}"/></clipPath></defs>','<g clip-path="url(#floor)">']
    a.rect(0,0,320,218,"#241f2e")
    rng=random.Random(872)
    for col,x in enumerate(range(0,320,12)):
        for y in range(-48+(col%3)*16,218,48):
            a.rect(x+1,y+1,10,46,rng.choice(["#493744","#514047","#574149","#453541"]))
            a.rect(x+1,y+2,1,44,"#82656a")
            a.rect(x+10,y+2,1,44,"#2e2634")
            for _ in range(6):
                a.rect(x+rng.randrange(3,9),y+rng.randrange(4,32),1,rng.randrange(5,12),rng.choice(["#6b505a","#392d3a"]))
            a.rect(x+3,y+3,1,1,"#a28a79")
    a.parts.append('</g>')
    return a


def terrain():
    a=Art(424,332)
    a.rect(0,0,424,332,"#171f2c")
    rng=random.Random(952)
    for _ in range(1800):
        x,y=rng.randrange(424),rng.randrange(332)
        a.rect(x,y,rng.randrange(1,5),rng.randrange(1,3),rng.choice(["#203438","#2e3537","#2b2637","#36433a"]))
    for y in range(0,65,7):
        x=212+round(math.sin(y*.15)*5)
        for dx in [-7,1,8]:
            a.ellipse(x+dx,y,5,3,"#414d55")
            a.rect(x+dx-2,y-2,4,1,"#6b7b7c")
    return a


def window(frame):
    a=Art(48,64)
    a.path('M3 62V26l4-12 8-9 9-4 9 4 8 10 4 11v36z',"#292336")
    a.path('M6 59V26l4-11 7-7 7-4 8 5 6 8 4 10v32z',"#68556f")
    a.path('M10 55V27l4-9 10-9 10 9 4 9v28z',"#5a3b87")
    glow=["#a074db","#af83e4","#b88bea","#aa7ddf"][frame]
    a.path('M13 52V28l4-8 7-6 7 6 4 8v24z',glow)
    a.rect(22,13,4,42,"#352c4b")
    for y in [28,40,52]: a.rect(10,y,28,3,"#352c4b")
    for x,y in [(15,31),(28,43),(17,22)]: a.rect(x,y,3,2,"#dfbbf0")
    a.rect(2,59,44,4,"#4d3c51")
    a.rect(4,59,40,1,"#a58b8e")
    return a


def rays(frame):
    a=Art(96,112)
    a.parts += ['<defs><clipPath id="beam"><path d="M28 0h40l26 112H1z"/></clipPath></defs>','<g clip-path="url(#beam)">']
    for y in range(0,112,8):
        a.rect(0,y,96,8,"#b68ad6",(.23+frame*.005)*(1-y/112))
    for x in [39,54]: a.path(f'M{x} 0h3l12 112h-8z',"#211f36",.22)
    for y in [25,55,85]: a.rect(0,y,96,4,"#211f36",.18)
    a.parts.append('</g>')
    return a


def rug(kind):
    a=Art(96,64)
    base,edge,thread=[("#392b52","#8d7caf","#b9a16f"),("#4f2a40","#ad855e","#dfbf85"),("#244449","#81aaa0","#bba573")][kind]
    a.rect(2,3,92,58,"#1e2130")
    a.rect(4,5,88,54,base)
    for y in [6,55]:
        a.rect(5,y,86,3,edge)
        for x in range(8,89,6): a.path(f'M{x} {y}l2 2-2 2-2-2z',thread)
    for x in [5,87]:
        a.rect(x,8,3,47,edge)
        for y in range(12,52,6): a.rect(x+1,y,1,2,thread)
    for x in range(14,84,10):
        for y in range(16,52,10):
            a.path(f'M{x} {y-3}l3 3-3 3-3-3z',edge)
            a.rect(x,y,1,1,thread)
    a.path('M48 13l8 12 15 7-15 7-8 12-8-12-15-7 15-7z',thread)
    a.path('M48 17l6 11 11 4-11 4-6 11-6-11-11-4 11-4z',base)
    for x in range(7,91,4):
        a.rect(x,1,1,3,edge)
        a.rect(x,60,1,3,edge)
    return a


def project_group(a,v):
    if MIRROR[v]: a.parts.append('<g transform="translate(80 0) scale(-1 1)">')
    side=SIDE[v]
    a.parts.append(f'<g transform="matrix({.55 if side else .82} {.16 if side else .12} 0 1 {18 if side else 10} {-8 if side else -6})">')

def shelf(v,f,decor=False):
    a=Art(80,128)
    dark,wood,edge=[("#282332","#55404b","#9b7874"),("#2e2634","#665149","#b19279"),("#242b33","#4e645d","#93ad94")][v%3]
    top=60 if v in [5,8] else (58 if v==7 else [30,34,32,28,34,30,30,30,30][v])
    if not decor:
        a.ellipse(42,125,32,3,"#111624",.7)
        if MIRROR[v]: a.parts.append('<g transform="translate(80 0) scale(-1 1)">')
        sx,sy,ox,oy=(.55,.16,18,-8) if SIDE[v] else (.82,.12,10,-6)
        left=(8*sx+ox,top-2+8*sy+oy)
        right=(70*sx+ox,top-2+70*sy+oy)
        bottom=(70*sx+ox,125+70*sy+oy)
        a.path(f'M{right[0]} {right[1]}l12-18V{bottom[1]-18}l-12 18z',dark)
        for y in range(int(right[1])+6,int(bottom[1])-4,9):
            a.path(f'M{right[0]+2} {y}l7-10v1l-7 10z',edge,.35)
        a.path(f'M{left[0]} {left[1]}L{right[0]} {right[1]}l12-18L{left[0]+12} {left[1]-18}z',wood)
        if MIRROR[v]: a.parts.append('</g>')
    project_group(a,v)
    if not decor:
        a.rect(9,top,60,116-top,"#1c1b2a")
        a.rect(13,top+6,52,108-top,"#2a2332")
        for x in range(16,65,8):
            a.rect(x,top+7,1,103-top,dark)
            a.rect(x+2,top+10,1,12,wood,.3)
        for x in [8,65]:
            a.rect(x,top,4,124-top,wood)
            a.rect(x,top+1,1,123-top,edge)
            for y in range(top+12,121,14): a.rect(x+1,y,2,1,edge,.5)
        a.rect(7,top-2,63,5,dark)
        a.rect(9,top-2,59,1,edge)
        rows=[86,116] if v in [5,8] else ([74,116] if v==7 else [42,78,116])
        for y in rows:
            a.rect(11,y,56,5,dark)
            a.rect(12,y,54,2,wood)
            a.rect(13,y,52,1,edge)
            for x in [18,32,49]: a.rect(x,y+1,10,1,edge,.35)
        a.rect(10,122,6,4,dark)
        a.rect(60,122,6,4,dark)
    else:
        # Non-stock witchy decoration: books, scrolls, charms and tiny candles.
        # Display racks keep their board centers free for independently stocked bottles.
        rows=[top] if v in [5,8] else [top,42,78,116]
        for row,y in enumerate(rows):
            if row%2==0:
                for i,x in enumerate([15,21,27]):
                    h=11+i*3
                    a.path(f'M{x} {y}l-2-{h}h5l2 {h}z',["#805e76","#607e7a","#ae9068"][i])
                    a.rect(x,y-h+2,2,1,"#dbc09c")
            else:
                a.rect(16,y-7,17,7,"#a39579")
                a.rect(18,y-6,13,1,"#e0d2ad")
                a.rect(23,y-7,2,7,"#775267")
            a.rect(52,y-9,3,9,"#d6c4a3")
            a.path(f'M52 {y-10}v-3l2-{2+f%2} 1 3v2z',"#f2c580")
            a.rect(48,y-2,11,2,"#74654e")
        a.rect(62,top+4,1,18,"#a79780")
        a.path(f'M60 {top+20}h5v5h-5z',"#b3a7c1")
        a.rect(61,top+21,1,1,"#352b45")
        if v not in [5,8]:
            a.path(f'M35 {top-2}v-13h3v3h4v4h-3v6z',"#6d8b76")
            a.rect(35,top-6,4,1,"#c0cf9f")
        # Carved lunar crowns, drying herbs, chains and star charms distinguish
        # these decorations from the independently stocked potion sprites.
        a.path(f'M32 {top-3}v-5l7-7 7 7v5z',wood)
        a.ellipse(39,top-8,4,4,"#c4ae81")
        a.ellipse(41,top-9,3,3,wood)
        for y in range(top+8,116,12):
            x=8 if v%2 else 67
            a.rect(x,y,1,12,"#69846c")
            a.path(f'M{x} {y+2}l-4-2v4l4 2 4-3v-3z',"#829d7e")
            a.rect(x-2,y+1,2,1,"#bdc49b")
        if v not in [5,8]:
            for x in [40,47,54]:
                y=49+(x%3)*3
                a.rect(x,y,1,12,"#af957c")
                a.path(f'M{x} {y+9}l-3 6 3-1 3 1z',"#769781")
            a.rect(34,108,12,7,"#b59b83")
            a.rect(36,110,2,2,"#3b3045")
            a.rect(42,110,2,2,"#3b3045")
            a.rect(39,114,2,2,"#3b3045")
        a.rect(11,top+6,1,23,"#bba476")
        a.path(f'M11 {top+27}l2 4 4 1-3 2 1 4-4-2-4 2 1-4-3-2 4-1z',"#d6bc82")
    a.parts.append('</g>')
    if MIRROR[v]: a.parts.append('</g>')
    return a

def thought(frame):
    a=Art(48,64)
    a.path('M8 8h6V4h14v3h8v4h7v8h4v20h-4v8h-8v4H12v-4H5v-7H1V20h3v-8h4z',"#756580")
    a.path('M9 10h7V6h11v3h8v4h6v8h4v16h-4v8h-8v4H13v-4H7v-7H3V21h3v-7h3z',"#ded9e6")
    a.path('M10 12h7V8h9v3h8v4h6v6h3v4h-4v-5h-7v-5H16v3H8v-3h2z',"#f5edf0")
    a.ellipse(29,55,4,3,"#756580")
    a.ellipse(29,54,3,2,"#ded9e6")
    a.ellipse(26,61,2,2,"#c8bed6")
    if frame in [1,2]: a.rect(1,26,2,9,"#ded9e6")
    if frame in [2,3]: a.rect(44,28,3,8,"#ded9e6")
    return a

def glow():
    a=Art(128,128)
    a.parts.append('<defs><radialGradient id="g"><stop offset="0" stop-color="#ffffff" stop-opacity=".65"/><stop offset=".45" stop-color="#ffffff" stop-opacity=".2"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient></defs>')
    a.parts.append('<circle cx="64" cy="64" r="64" fill="url(#g)"/>')
    return a


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    trees()
    pack(OUT,"mushrooms",[[mushroom(k,f) for f in range(4)] for k in range(4)])
    export(OUT,"floor",floor()); export(OUT,"terrain",terrain())
    export(OUT,"glow",glow())
    pack(OUT,"windows",[[window(f) for f in range(4)]])
    pack(OUT,"rays",[[rays(f) for f in range(4)]])
    pack(OUT,"thought",[[thought(f) for f in range(4)]])
    for i in range(3): export(OUT,f"rug_{i}",rug(i))
    pack(OUT,"shelves",[[shelf(v,f) for f in range(4)] for v in range(9)])
    pack(OUT,"shelf_decor",[[shelf(v,f,True) for f in range(4)] for v in range(9)])

if __name__ == "__main__":
    main()
