"""Crop, palette-grade and export original imagegen artwork at two review densities.

No reference media is used as source art. No random texture or gameplay data is
generated here. Original full-size sheets and prompts remain beside the exports.
"""
from pathlib import Path
import hashlib
import json
import statistics
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'assets/reference_slice/world'
SOURCE = ASSETS / 'source'
OUT = ROOT / 'artifacts/reference_review/world'
OUT.mkdir(parents=True, exist_ok=True)
records = []


def save(image, relative, source, crop=None):
    path = ASSETS / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    records.append({'file': relative, 'source': source, 'crop': crop,
                    'size': list(image.size), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})


def opaque(image):
    image = image.convert('RGBA')
    image.putalpha(255)
    return image


def hard_alpha(image):
    image = image.convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda value: 255 if value >= 140 else 0))
    image.paste((0, 0, 0, 0), mask=image.getchannel('A').point(lambda value: 255 - value))
    return image


def grade(image, palette):
    """Map the authored material shades to a shared, quiet six-color ramp."""
    palette = [tuple(bytes.fromhex(color)) + (255,) for color in palette]
    pixels = list(image.convert('RGB').getdata())
    light = [round(r * .3 + g * .59 + b * .11) for r, g, b in pixels]
    middle = statistics.median(light)
    # Suppress generated low-amplitude grain; preserve authored tuft/crack form.
    boundaries = [-35, -22, -18, 24, 48]
    result = Image.new('RGBA', image.size)
    result.putdata([palette[sum(value - middle > bound for bound in boundaries)] for value in light])
    return result


def calm_crop(image):
    """Select an existing low-contrast patch; never synthesize noise or paint."""
    sample=image.convert('RGB').resize((64,64),Image.Resampling.NEAREST)
    choice=None
    for y in range(4,45,8):
        for x in range(4,45,8):
            patch=sample.crop((x,y,x+16,y+16)).convert('L')
            score=statistics.pvariance(patch.getdata())
            if choice is None or score<choice[0]: choice=(score,x,y)
    _,x,y=choice
    return [round(x*image.width/64),round(y*image.height/64),round((x+16)*image.width/64),round((y+16)*image.height/64)]


RAMPS = {
 'fairway_a': ['233f37','315846','3a7052','478461','65925d','97b675'],
 'fairway_b': ['213b34','2c5141','366749','376b51','598755','8aa768'],
 'green_a': ['183b35','204c42','295d4b','31674f','477952','69955c'],
 'green_b': ['193930','22483b','29573e','306248','44764f','678b55'],
 'basalt_a': ['242735','30343f','3b3f4a','494956','595763','6e6670'],
 'basalt_b': ['222431','2c303d','373b45','414450','52515e','645c68'],
 'basalt_green_a': ['1f2630','27303b','303944','36434c','45505a','59606c'],
 'basalt_green_b': ['1c232d','242c37','2d3540','343d47','424a53','535b66'],
}

terrain = Image.open(SOURCE / 'terrain_sheet.png').convert('RGBA')
xs = [0, 313, 627, 940, 1254]
ys = [0, 312, 626, 914, 1254]
names = ['fairway_a','fairway_b','green_a','green_b',
         'water_a','water_b','sand_a','sand_b',
         'basalt_a','basalt_b','basalt_green_a','basalt_green_b',
         'lava_a','lava_b','wall_meadow','wall_volcanic']
for density in (48, 32):
    for index, name in enumerate(names):
        col, row = index % 4, index // 4
        bounds = [xs[col] + 3, ys[row] + 3, xs[col+1] - 3, ys[row+1] - 3]
        tile = opaque(terrain.crop(bounds).resize((density, density), Image.Resampling.NEAREST))
        if name in RAMPS:
            tile = grade(tile, RAMPS[name])
            # The first capture showed six repeated tufts or cracks per cell.
            # Export a clean, actual source-material patch and one isolated
            # motif; runtime selects that motif on fewer than one cell in ten.
            selected=calm_crop(terrain.crop(bounds))
            quiet_bounds = [bounds[0]+selected[0],bounds[1]+selected[1],bounds[0]+selected[2],bounds[1]+selected[3]]
            quiet = opaque(terrain.crop(quiet_bounds).resize((density,density),Image.Resampling.NEAREST))
            quiet = grade(quiet, RAMPS[name])
            save(quiet, f'd{density}/terrain/{name}_quiet.png','terrain_sheet.png',quiet_bounds)
            decorated = quiet.copy()
            ratio=density/48
            motif_box=(0,0,round((24 if name.startswith('basalt') else 16)*ratio),round((25 if name.startswith('basalt') else 17)*ratio))
            motif=tile.crop(motif_box)
            decorated.paste(motif,(round(8*ratio),round(17*ratio)))
            tile=decorated
        else:
            tile = tile.quantize(colors=18, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert('RGBA')
            tile.putalpha(255)
        save(tile, f'd{density}/terrain/{name}.png', 'terrain_sheet.png', bounds)

    # Refinement 2: the reference has a calm water body with sparse glints.
    # Reuse two hand-selected wave clusters from the original generated water,
    # on a quiet patch; pose B dims those same clusters rather than teleporting.
    water_bounds=[3,315,310,623]
    water_source=terrain.crop(water_bounds)
    water_ramp=['16434f','205968','286e7f','2e8191','66b1bc','b2e8df']
    water_full=grade(opaque(water_source.resize((48,48),Image.Resampling.NEAREST)),water_ramp)
    selected=calm_crop(water_source)
    water_quiet=grade(opaque(water_source.crop(selected).resize((48,48),Image.Resampling.NEAREST)),water_ramp)
    # A residual clipped wave at the crop boundary would create false atlas
    # seams. Use this source patch's dominant body shade behind isolated art.
    body_shade=max(water_quiet.getcolors(48*48),key=lambda pair:pair[0])[1]
    water_quiet.paste(body_shade,(0,0,48,48))
    water_a=water_quiet.copy()
    for source_box,at in [((4,7,29,14),(4,12)),((1,35,20,45),(25,33))]:
        water_a.paste(water_full.crop(source_box),at)
    water_b=Image.blend(water_quiet,water_a,.38)
    for frame,asset in [('a',water_a),('b',water_b)]:
        save(asset.resize((density,density),Image.Resampling.NEAREST),
             f'd{density}/terrain/water_{frame}.png','terrain_sheet.png',water_bounds)

objects = Image.open(SOURCE / 'object_sheet.png').convert('RGBA')
objects_spec = [
 ('pendulum', [5, 5, 505, 496], 44),
 ('bearing', [528, 35, 1001, 448], 28),
 ('chain', [1110, 16, 1467, 478], 13),
 ('willow', [18, 500, 485, 1018], 112),
 ('basalt_columns', [553, 500, 998, 984], 112),
 ('pad', [1042, 512, 1520, 986], 34),
]
for density in (48, 32):
    for name, bounds, extent in objects_spec:
        asset = hard_alpha(objects.crop(bounds))
        asset = asset.crop(asset.getbbox())
        extent = max(6, round(extent * density / 48))
        scale = extent / max(asset.size)
        target_size = tuple(max(1, round(size * scale)) for size in asset.size)
        asset = asset.resize(target_size, Image.Resampling.NEAREST)
        asset = hard_alpha(asset)
        save(asset, f'd{density}/props/{name}.png', 'object_sheet.png', bounds)
    # The existing original ball and flag illustrations are preserved and reused.
    for name, extent in [('ball', 12),('flag_a', 40),('flag_b', 40),('tee', 25),('coin', 16)]:
        path = ROOT / f'assets/pixel_correction/props/{name}.png'
        asset = hard_alpha(Image.open(path))
        asset = asset.crop(asset.getbbox())
        scale = max(6, round(extent * density / 48)) / max(asset.size)
        asset = asset.resize(tuple(max(1, round(size * scale)) for size in asset.size), Image.Resampling.NEAREST)
        save(asset, f'd{density}/props/{name}.png', f'assets/pixel_correction/props/{name}.png')

effects = Image.open(SOURCE / 'effects_sheet.png').convert('RGBA')
for density in (48, 32):
    for row, kind in enumerate(['strike', 'dust', 'water']):
        # Preserve the common frame center and the relative expansion of poses.
        for frame in range(4):
            bounds = [round(frame * effects.width / 4), round(row * effects.height / 3),
                      round((frame + 1) * effects.width / 4), round((row + 1) * effects.height / 3)]
            asset = hard_alpha(effects.crop(bounds)).resize((density, density), Image.Resampling.NEAREST)
            save(asset, f'd{density}/fx/{kind}_{frame}.png', 'effects_sheet.png', bounds)

for biome in ('meadow', 'volcanic'):
    source = Image.open(SOURCE / f'{biome}_background.png')
    background = opaque(source.resize((768, 432), Image.Resampling.NEAREST))
    save(background, f'backgrounds/{biome}.png', f'{biome}_background.png')

sources = [{'file': p.name, 'size': list(Image.open(p).size),
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in SOURCE.glob('*.png')]
# Refinement outputs replace earlier exports under the same owned path.
records=list({entry['file']:entry for entry in records}.values())
(ASSETS / 'export_manifest.json').write_text(json.dumps({'sources': sources, 'exports': records}, indent=2) + '\n')

# A clearly labelled production-asset contact sheet; references stay separate.
sheet = Image.new('RGB', (1200, 730), '#18262d')
draw = ImageDraw.Draw(sheet)
draw.text((20, 15), 'ORIGINAL PRODUCTION ASSETS / 48 source pixels per cell', fill='#fff1cd')
for index, name in enumerate(names):
    asset = Image.open(ASSETS / f'd48/terrain/{name}.png')
    col, row = index % 8, index // 8
    at = (20 + col * 148, 48 + row * 148)
    sheet.paste(asset.resize((112,112), Image.Resampling.NEAREST), at)
    draw.text((at[0], at[1] + 118), name, fill='#d3decf')
for index, (name, _bounds, _extent) in enumerate(objects_spec):
    asset = Image.open(ASSETS / f'd48/props/{name}.png')
    scale = min(160 / max(asset.size), 3)
    asset = asset.resize(tuple(round(v * scale) for v in asset.size), Image.Resampling.NEAREST)
    at = (22 + index * 195, 385)
    sheet.paste(asset, at, asset)
    draw.text((at[0], 560), name, fill='#d3decf')
for index, kind in enumerate(['strike','dust','water']):
    for frame in range(4):
        asset = Image.open(ASSETS / f'd48/fx/{kind}_{frame}.png')
        at=(20+index*385+frame*80,620)
        sheet.paste(asset.resize((72,72),Image.Resampling.NEAREST),at,asset.resize((72,72),Image.Resampling.NEAREST))
    draw.text((20+index*385,700),kind+' / 4 poses',fill='#d3decf')
sheet.save(OUT / 'production_assets_48.png')
print(f'Exported {len(records)} original world assets at 48 and 32 source pixels per cell.')
