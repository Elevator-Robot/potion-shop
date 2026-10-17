#!/usr/bin/env python3
"""Original pixel-by-pixel woodland sprites. No source images or resampling.

Shapes are authored on an integer grid; PNGs use only the chosen palette.
SVG run-length sources and this drawing program retain the editable artwork.
"""
from pathlib import Path
import json
import struct
import zlib

OUT = Path(__file__).resolve().parents[1] / "assets/atmosphere"


class Pixels:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[None for _ in range(w)] for _ in range(h)]

    def rect(self, x, y, w, h, color):
        for yy in range(max(0, y), min(self.h, y+h)):
            for xx in range(max(0, x), min(self.w, x+w)):
                self.p[yy][xx] = color

    def poly(self, points, color):
        for y in range(max(0, min(p[1] for p in points)), min(self.h, max(p[1] for p in points)+1)):
            hits = []
            for a,b in zip(points, points[1:]+points[:1]):
                if min(a[1],b[1]) <= y+.5 < max(a[1],b[1]):
                    hits.append(a[0]+(y+.5-a[1])*(b[0]-a[0])/(b[1]-a[1]))
            hits.sort()
            for i in range(0, len(hits)-1, 2):
                for x in range(max(0, round(hits[i])), min(self.w, round(hits[i+1]))):
                    self.p[y][x] = color

    def line(self, points, color, width=1):
        for a,b in zip(points, points[1:]):
            steps = max(abs(a[0]-b[0]),abs(a[1]-b[1]),1)
            for i in range(steps+1):
                x = round(a[0]+(b[0]-a[0])*i/steps)
                y = round(a[1]+(b[1]-a[1])*i/steps)
                self.rect(x-width//2,y-width//2,width,width,color)

    def save(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        def chunk(kind,data):
            return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data))
        rows = bytearray()
        svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" shape-rendering="crispEdges">']
        for y,row in enumerate(self.p):
            rows.append(0)
            for c in row:
                rows.extend(bytes.fromhex(c[1:])+b'\xff' if c else b'\0\0\0\0')
            x=0
            while x<self.w:
                c=row[x]; end=x+1
                while end<self.w and row[end]==c: end+=1
                if c: svg.append(f'<rect x="{x}" y="{y}" width="{end-x}" height="1" fill="{c}"/>')
                x=end
        path.with_suffix('.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(rows,9))+chunk(b'IEND',b''))
        path.with_suffix('.svg').write_text('\n'.join(svg+['</svg>']))


INK="#242334"
BARK="#51414a"
WOOD="#806355"
LIGHT="#b38b68"
MOSS="#68816a"


def leaves(a,x,y,w,h,palette):
    # Stepped, overlapping leaf masses with deliberate light-facing clusters.
    points=[(x+w//3,y),(x+w//2+3,y),(x+w//2+3,y+2),(x+w-7,y+2),(x+w-7,y+5),(x+w-2,y+5),(x+w-2,y+h//2),(x+w,y+h//2),(x+w,y+h-7),(x+w-3,y+h-7),(x+w-3,y+h-3),(x+w-9,y+h-3),(x+w-9,y+h),(x+w//2,y+h),(x+w//2,y+h-2),(x+7,y+h-2),(x+7,y+h-5),(x+2,y+h-5),(x+2,y+h//2),(x,y+h//2),(x,y+6),(x+5,y+6),(x+5,y+3),(x+w//3,y+3)]
    a.poly(points,INK)
    cx,cy=x+w//2,y+h//2
    a.poly([(px+(1 if px<cx else -1),py+(1 if py<cy else -1)) for px,py in points],palette[0])
    for dx,dy,span in [(w//3,3,w//3),(5,h//3,w//3),(w//2,h//3+3,w//3),(w//3,h*2//3,w//3)]:
        px,py=x+dx,y+dy
        a.poly([(px,py+3),(px+3,py),(px+span-3,py),(px+span,py+3),(px+span-2,py+6),(px+span//2,py+5),(px+3,py+7)],palette[1])
        a.line([(px+2,py+2),(px+4,py+1),(px+span-4,py+1)],palette[2])
        a.rect(px+span//2,py+5,2,2,palette[0])


def trunk(a,kind):
    # Root flare, twisted stem, split crown: silhouette and bark are drawn apart.
    shape=[(49,149),(28,153),(30,149),(43,141),(50,126),(48,110),(53,91),(48,73),(39,59),(42,51),(56,65),(62,81),(68,62),(79,45),(85,48),(76,71),(73,92),(78,115),(75,136),(89,145),(107,149),(110,154),(86,154),(70,147),(68,158),(60,158),(57,146),(45,156),(35,157)]
    a.poly(shape,INK)
    a.poly([(49,149),(36,150),(48,140),(55,124),(53,110),(58,91),(53,72),(44,58),(55,68),(64,89),(73,67),(80,53),(72,77),(69,96),(74,118),(70,139),(93,150),(84,150),(66,141),(64,154),(61,154),(60,139)],BARK if kind!=2 else "#716d7b")
    a.line([(40,150),(52,139),(59,122),(57,108),(62,93),(57,76),(49,63)],WOOD,3)
    a.line([(62,151),(65,133),(65,112),(66,97),(70,77),(77,63)],LIGHT if kind==2 else WOOD,2)
    a.line([(88,150),(71,140),(69,128)],WOOD,2)
    for x,y in [(57,102),(61,129),(68,115),(53,78),(72,138)]:
        a.line([(x,y),(x+2,y+5),(x,y+10)],INK)
        a.line([(x+3,y+1),(x+4,y+5)],LIGHT)
    a.poly([(56,111),(60,106),(66,106),(70,112),(69,124),(65,129),(59,127),(55,120)],INK)
    a.line([(56,112),(59,108),(64,108)],WOOD)
    a.poly([(60,115),(63,111),(66,115),(66,123),(62,125),(59,122)],"#332c43")
    for x,y in [(43,145),(69,135),(50,124)]:
        a.rect(x,y,7,2,MOSS)
        a.rect(x+2,y-1,3,1,"#a5ae82")


def tree(kind,frame):
    a=Pixels(128,160)
    sway=[0,1,0,-1][frame]
    # Branches have fixed attachments and animated tips, never translated roots.
    branches=[[(58,88),(43,73),(28,69),(16,57),(12+sway,43)],[(69,90),(84,74),(101,70),(113+sway,54)],[(53,76),(49,49),(34+sway,37),(30+sway,20)],[(69,71),(72,42),(88+sway,24),(91+sway,13)]]
    if kind==0:
        branches += [[(43,73),(29,79),(14,76),(8+sway,67)],[(83,75),(96,88),(113+sway,86)],[(48,49),(58+sway,30),(55+sway,15)],[(100,70),(108,42),(119+sway,33)]]
    for branch in branches:
        a.line(branch,INK,7)
        a.line(branch,WOOD,3)
        a.line([(x-1,y-1) for x,y in branch],LIGHT)
        tx,ty=branch[-1]
        a.line([(tx,ty),(tx-3,ty-5),(tx-2,ty-10)],INK,3)
        a.line([(tx,ty),(tx+5,ty-4),(tx+7,ty-4)],INK,2)
        a.line([(tx,ty),(tx-2,ty-5)],WOOD)
    trunk(a,kind)
    if kind==0:
        # Hollow elder: sleepy amber eyes, a crooked smile, small mossy boughs.
        palette=["#3c514e","#5b7160","#8c9a76"]
        for x,y,w,h in [(7,38,25,17),(85,23,31,18),(18,67,24,17),(88,77,30,15)]:
            leaves(a,x+sway,y,w,h,palette)
        for x in [54,68]:
            a.rect(x,96,9,6,INK)
            a.rect(x+2,98,5,2,["#d0a765","#e7c283","#edce97","#d7b174"][frame])
        a.line([(56,106),(59,109),(65,110),(71,107)],INK,2)
        # Hanging lantern: four genuinely different flame silhouettes.
        a.line([(23+sway,76),(23+sway,91)],"#9f8c71")
        a.poly([(18+sway,93),(23+sway,89),(28+sway,93),(28+sway,105),(23+sway,109),(18+sway,105)],INK)
        a.rect(20+sway,94,6,10,"#637f94")
        a.poly([(22+sway,103),(21+sway,99),(23+sway,95-frame%2),(25+sway,100),(24+sway,104)],"#c4e9dc")
    elif kind==1:
        palette=["#304c4d","#4a6b61","#77917b"]
        for x,y,w,h in [(30,12,43,31),(57,17,44,34),(11,34,44,33),(37,29,49,37),(76,40,42,32),(19,59,38,28),(50,52,41,30),(77,65,31,24)]:
            leaves(a,x+sway,y,w,h,palette)
        for index,(x,y,length) in enumerate([(15,62,30),(27,80,29),(41,78,20),(84,76,33),(99,69,25),(111,58,30)]):
            tip=[0,1,2,-1][frame] * (1 if index%2 else -1)
            a.line([(x+sway,y),(x+sway,y+length//2),(x+tip,y+length)],palette[0],3)
            for dy in range(2,length,5):
                a.rect(x+sway-2,y+dy,4,2,palette[1])
                a.rect(x+sway-1,y+dy,1,1,palette[2])
    else:
        palette=["#45445e","#68617e","#a095a3"]
        for x,y,w,h in [(29,12,38,26),(61,25,43,29),(14,40,37,26),(47,48,40,27),(83,62,35,24)]:
            leaves(a,x+sway,y,w,h,palette)
        # Shelf fungi growing directly from the pale trunk.
        for x,y,w in [(71,103,13),(48,126,14),(73,138,10)]:
            a.rect(x,y,w,4,INK)
            a.rect(x+1,y-2,w-2,3,"#9c6488")
            a.rect(x+3,y-3,w-6,2,"#d6a0b3")
            a.rect(x+2,y+2,w-4,1,"#e9c9b5")
        a.rect(61,115,4,8,["#797997","#a2a1bb","#c8bfd4","#9695b2"][frame])
    return a


def fern(a,x,y,flip=1):
    a.line([(x,y),(x+flip*2,y-6),(x+flip*1,y-13)],"#738368")
    for dx,dy in [(-5,-4),(5,-5),(-4,-8),(4,-9),(-2,-12)]:
        a.line([(x,y+dy+3),(x+dx*flip,y+dy),(x+(dx+(-2 if dx<0 else 2))*flip,y+dy)],"#4f6b59",2)
        a.rect(x+dx*flip,y+dy,2,1,"#8b9c72")


def rock(a,x,y,w=12):
    a.poly([(x,y),(x+3,y-5),(x+w-4,y-7),(x+w,y-3),(x+w+1,y+2),(x+w-3,y+5),(x+1,y+4)],"#232b37")
    a.poly([(x+1,y),(x+4,y-4),(x+w-4,y-5),(x+w-1,y-2),(x+w-2,y+1),(x+3,y+2)],"#52616a")
    a.line([(x+4,y-4),(x+w-5,y-5),(x+w-2,y-3)],"#8a9690")
    a.rect(x+2,y+1,4,2,"#556b58")


def terrain():
    a=Pixels(424,332)
    a.rect(0,0,424,332,"#26383a")
    # Large connected earthen shapes, with carved edge bands, not random noise.
    patches=[[(0,37),(32,29),(67,42),(83,70),(69,109),(38,134),(0,127)],[(337,0),(424,0),(424,131),(387,120),(359,83)],[(0,217),(43,205),(85,243),(93,301),(143,332),(0,332)],[(333,232),(374,213),(424,235),(424,332),(302,332),(319,291)],[(112,0),(285,0),(297,31),(253,51),(181,49),(135,26)]]
    for points in patches:
        a.poly(points,"#202e34")
        # Grass breaks up the soil boundary in little stepped clumps.
        for start,end in zip(points,points[1:]+points[:1]):
            length=max(abs(end[0]-start[0]),abs(end[1]-start[1]))
            for t in range(0,length,9):
                x=round(start[0]+(end[0]-start[0])*t/max(1,length))
                y=round(start[1]+(end[1]-start[1])*t/max(1,length))
                a.poly([(x-3,y+2),(x-4,y-2),(x-1,y),(x,y-4),(x+2,y),(x+4,y-2),(x+3,y+3)],"#354d40")
                a.rect(x,y-2,1,3,"#52644d")
    # Meandering entrance path with hand-laid irregular stepping stones.
    a.poly([(197,0),(225,0),(221,18),(236,40),(229,62),(202,62),(209,39),(198,20)],"#514747")
    a.line([(197,0),(198,20),(209,39),(202,62)],"#766357",2)
    for x,y,w in [(203,9,12),(211,21,14),(216,36,12),(209,50,17),(211,61,14)]: rock(a,x,y,w)
    # Roots, boulder groups, ferns and leaf clusters composed around the border.
    for x,y in [(18,45),(53,21),(377,34),(404,85),(17,157),(392,181),(34,280),(104,314),(292,314),(384,285)]:
        a.line([(x-12,y+8),(x-4,y+3),(x,y-7),(x+7,y-12)],"#1c2931",5)
        a.line([(x-12,y+7),(x-4,y+2),(x,y-8),(x+7,y-13)],"#64554c",2)
        a.line([(x-3,y+1),(x+8,y+5),(x+15,y+4)],"#64554c",2)
        fern(a,x-8,y+15)
        fern(a,x+16,y-3,-1)
        rock(a,x+10,y+20,10)
        rock(a,x+20,y+25,7)
        # Curled fallen leaves form small beds around roots, not screen noise.
        for dx,dy in [(-13,11),(-17,6),(-8,19),(7,12),(2,17),(17,9)]:
            a.poly([(x+dx,y+dy),(x+dx+3,y+dy-2),(x+dx+6,y+dy),(x+dx+3,y+dy+2)],"#796754")
            a.rect(x+dx+2,y+dy,3,1,"#a18a64")
    for x,y in [(8,92),(38,83),(64,51),(352,18),(384,66),(410,140),(6,199),(34,237),(55,306),(156,316),(250,324),(344,303),(404,240)]:
        leaves(a,x,y,19,12,["#344d43","#4e6550","#7f8963"])
        for dx,dy in [(2,16),(9,20),(16,15)]:
            a.line([(x+dx,y+dy),(x+dx-2,y+dy-4)],"#7a8260")
            a.rect(x+dx-3,y+dy-4,3,2,"#a0966f")
    # A mossy footing follows the cottage's actual outline, tying walls to soil.
    from draw_cottage import floor_points
    points=[(round((x+112)/2),round((y+144)/2)) for x,y in floor_points()]
    a.line(points+[points[0]],"#182831",8)
    a.line(points+[points[0]],"#455548",4)
    for i,(x,y) in enumerate(points):
        if i%2==0: fern(a,x-4,y+5)
    return a


def main():
    names=["guardian","willow","spirit_willow"]
    for kind,name in enumerate(names):
        sheet=Pixels(512,160)
        for frame in range(4):
            art=tree(kind,frame)
            art.save(OUT/"trees"/f"{name}_{frame}")
            for y,row in enumerate(art.p): sheet.p[y][frame*128:(frame+1)*128]=row
        sheet.save(OUT/"trees"/name)
    terrain().save(OUT/"terrain")
    (OUT/"trees/sources.json").write_text(json.dumps({"authoring":"Original integer-grid pixel drawings; no image sampling or resizing", "generator":"tools/draw_pixel_woods.py", "references":"User concept/exterior folder: mood and gnarled silhouettes only", "frames":"four 128x160 frames per tree; fixed trunks, changing branch tips, leaf tassels, lantern flame and hollow light", "assets":names},indent=2)+"\n")


if __name__ == "__main__":
    main()
