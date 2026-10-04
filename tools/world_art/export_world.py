"""Export production world art from preserved original illustration sources.

Raster assembly, palette families and measured crops only; no gameplay data.
Run from any working directory with Python and Pillow.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/world'
SLICE = ROOT / 'assets/reference_slice/world'
SOURCE = OUT / 'source'
records = []

def save(image, relative, source, crop=None):
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    records.append(dict(file=relative, source=str(source), crop=crop, size=list(image.size),
                        sha256=hashlib.sha256(target.read_bytes()).hexdigest()))

def clean(image):
    image = image.convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda n: 255 if n >= 140 else 0))
    image.paste((0,0,0,0), mask=image.getchannel('A').point(lambda n:255-n))
    return image

def palette(image, colors, source_colors=None):
    source = image.convert('RGBA')
    shades = sorted(set(source.getdata()), key=lambda p:p[0]*.3+p[1]*.59+p[2]*.11)
    shades = [p for p in shades if p[3]]
    ramp = [tuple(bytes.fromhex(c))+(255,) for c in colors]
    if source_colors:
        # Quiet and illustrated variants share the SAME material ramp. Ranking
        # only colors present in one image turns a calm base into a different
        # value when the illustration introduces a highlight or shadow.
        reference = [tuple(bytes.fromhex(c)) for c in source_colors]
        mapping = {p:ramp[min(range(len(reference)), key=lambda i:
                     sum((p[channel]-reference[i][channel])**2 for channel in range(3)))]
                   for p in shades}
    else:
        mapping = {p:ramp[round(i*(len(ramp)-1)/max(1,len(shades)-1))] for i,p in enumerate(shades)}
    result = source.copy()
    result.putdata([mapping.get(p,(0,0,0,0)) for p in source.getdata()])
    return result

ramps = {
 'desert':['66533d','8d724a','a88a57','bc9d68','d4b881','ead399'],
 'autumn':['474531','66613a','827449','9b8951','bca260','d3bc79'],
 'snow':['253b4d','344e65','4b687f','6a899f','9bb7c7','c9dde0'],
 'swamp':['1c3936','2b4c42','395c48','496e54','69835a','8b9c6a'],
}
source_ramps = {
 'fairway_a':['233f37','315846','3a7052','478461','65925d','97b675'],
 'fairway_b':['213b34','2c5141','366749','376b51','598755','8aa768'],
 'green_a':['183b35','204c42','295d4b','31674f','477952','69955c'],
 'green_b':['193930','22483b','29573e','306248','44764f','678b55'],
}
biomes = ['meadow','desert','autumn','snow','swamp','volcanic']
for biome in biomes:
    for material in ['fairway','green']:
        for variant in ['a','b']:
            for quiet in ['', '_quiet']:
                original = ('basalt' if material=='fairway' else 'basalt_green') if biome=='volcanic' else material
                source = SLICE / f'd48/terrain/{original}_{variant}{quiet}.png'
                im = Image.open(source)
                if biome in ramps:
                    colors = ramps[biome]
                    if variant=='b': colors=['%02x%02x%02x'%tuple(round(v*.88) for v in bytes.fromhex(c)) for c in colors]
                    if material=='green': colors=['%02x%02x%02x'%tuple(round(v*.83) for v in bytes.fromhex(c)) for c in colors]
                    im = palette(im,colors,source_ramps[f'{material}_{variant}'])
                if quiet:
                    # A truly calm variant avoids isolated bright edge pixels
                    # repeating as seam ticks. The original source is preserved.
                    base = Counter(im.convert('RGBA').getdata()).most_common(1)[0][0]
                    im = Image.new('RGBA',im.size,base)
                save(im,f'terrain/{biome}_{material}_{variant}{quiet}.png',source.relative_to(ROOT))
    source = SLICE/f'd48/terrain/wall_{"volcanic" if biome=="volcanic" else "meadow"}.png'
    im = Image.open(source)
    if biome in ramps:
        stone = {'desert':['5c3c31','845944','ad7951','c99463','dcb980','f4d79a'],
                 'autumn':['3a3835','585342','797057','9c8c6c','bfb58e','ded3a5'],
                 'snow':['273d51','425d71','648399','8daab9','b3d0d5','e2e9da'],
                 'swamp':['203532','34483d','4c6048','697753','8a9465','b3b984']}[biome]
        im = palette(im,stone)
    save(im,f'terrain/{biome}_wall.png',source.relative_to(ROOT))

for kind in ['water','sand','lava']:
    for frame in ['a','b']:
        source=SLICE/f'd48/terrain/{kind}_{frame}.png'
        save(Image.open(source),f'terrain/{kind}_{frame}.png',source.relative_to(ROOT))
for name in ['pendulum','bearing','chain','willow','basalt_columns','pad','ball','coin']:
    source=SLICE/f'd48/props/{name}.png'
    save(Image.open(source),f'objects/{name}.png',source.relative_to(ROOT))

# The approved earlier sheet has TWO tees. Use only its left object, preserving
# the original source and explicitly recording the seat origin for the renderer.
tee_source=ROOT/'assets/pixel_correction/props/tee.png'
tee=clean(Image.open(tee_source).crop((0,0,21,32)))
tee=tee.resize((11,16),Image.Resampling.NEAREST)
save(tee,'objects/tee.png',tee_source.relative_to(ROOT),[0,0,21,32])
# Flag crops omit the baked cup; native LevelBuilder remains the cup owner.
for frame in ['a','b']:
    source=ROOT/f'assets/pixel_correction/props/flag_{frame}.png'
    im=clean(Image.open(source))
    im=im.crop((0,0,im.width,35))
    save(im,f'objects/flag_{frame}.png',source.relative_to(ROOT),[0,0,im.width,35])

objects=Image.open(SOURCE/'biome_objects.png')
spec=[('cactus',[15,35,365,612],90),('maple',[373,35,795,612],100),
      ('spruce',[803,30,1169,612],100),('cypress',[1180,35,1532,612],100),
      ('ice_block',[38,635,338,941],48),('fire_rod',[372,730,837,868],144),
      ('direction',[880,663,1128,920],48),('flowers',[1210,689,1489,934],42)]
for name,bounds,extent in spec:
    im=clean(objects.crop(bounds))
    im=im.crop(im.getbbox())
    factor=extent/max(im.size)
    im=clean(im.resize(tuple(max(1,round(n*factor)) for n in im.size),Image.Resampling.NEAREST))
    save(im,f'objects/{name}.png','assets/world/source/biome_objects.png',bounds)
direction=Image.open(OUT/'objects/direction.png').convert('RGBA')
arrow=direction.crop((9,9,39,39))
arrow.putalpha(arrow.convert('L').point(lambda value:255 if value>147 else 0))
save(clean(arrow),'objects/direction_arrow.png','assets/world/source/biome_objects.png',[880,663,1128,920])
plate=direction.copy()
plate.paste(direction.getpixel((10,10)),(8,8,40,40))
save(plate,'objects/direction_plate.png','assets/world/source/biome_objects.png',[880,663,1128,920])
rough=Image.open(SLICE/'d48/terrain/fairway_a.png').convert('RGBA')
base=Counter(rough.getdata()).most_common(1)[0][0]
rough.putdata([p if sum(abs(p[i]-base[i]) for i in range(3))>46 else (0,0,0,0) for p in rough.getdata()])
save(clean(rough),'terrain/rough.png','assets/reference_slice/world/d48/terrain/fairway_a.png')
# Material face comes from the original ice illustration, without the object rim.
ice=Image.open(OUT/'objects/ice_block.png').crop((5,5,43,43)).resize((48,48),Image.Resampling.NEAREST)
ice.putalpha(255)
save(ice,'terrain/ice_a.png','assets/world/source/biome_objects.png',[70,675,300,905])

panos=Image.open(SOURCE/'biome_panoramas.png')
for biome in biomes:
    if biome == 'meadow' and (SOURCE/'meadow_reconstruction.png').exists():
        source=SOURCE/'meadow_reconstruction.png'
        im=Image.open(source).convert('RGB').resize((384,216),Image.Resampling.NEAREST)
        im=im.quantize(colors=32).convert('RGBA').resize((768,432),Image.Resampling.NEAREST)
        origin=str(source.relative_to(ROOT));bounds=None
    elif biome in ['meadow','volcanic']:
        source=SLICE/f'backgrounds/{biome}.png'
        im=Image.open(source).convert('RGBA')
        origin=str(source.relative_to(ROOT));bounds=None
    else:
        index=['desert','autumn','snow','swamp'].index(biome)
        x=index%2;y=index//2
        bounds=[x*836,y*470,(x+1)*836,470 if y==0 else 941]
        im=panos.crop(bounds).resize((768,432),Image.Resampling.NEAREST).convert('RGBA')
        origin='assets/world/source/biome_panoramas.png'
    save(im,f'backgrounds/{biome}.png',origin,bounds)
    # A mirrored pair joins cleanly under continuous camera-relative scrolling.
    mirrored=Image.new('RGBA',(1536,432))
    mirrored.paste(im,(0,0));mirrored.paste(im.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(768,0))
    save(mirrored,f'backgrounds/{biome}_distance.png',origin,bounds)
    middle=im.copy()
    middle.putdata([(r,g,b,190 if y>=285 else 100) if y>=205 and r*.3+g*.59+b*.11<142 else (0,0,0,0)
                    for y in range(im.height) for r,g,b,a in [im.getpixel((x,y)) for x in range(im.width)]])
    pair=Image.new('RGBA',(1536,432));pair.paste(middle,(0,0));pair.paste(middle.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(768,0))
    save(pair,f'backgrounds/{biome}_middle.png',origin,bounds)

(OUT/'manifest.json').write_text(json.dumps({'density':48,'tee_seat_pixel':[5.5,3],
 'exports':records},indent=2)+'\n')
print(f'Exported {len(records)} production world images.')

from export_rims import export as export_rims
export_rims()
