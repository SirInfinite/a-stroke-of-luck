"""Export original illustrated trims. Reference crops are never production input."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/world/source/material_rims.png'
BIOMES = ['meadow', 'desert', 'autumn', 'snow', 'swamp', 'volcanic']

def export():
    image = Image.open(SOURCE).convert('RGB')
    # Explicit art-board crops reviewed against the original generated source.
    rows = [(55,197),(230,380),(424,580),(624,776),(820,979),(1023,1182)]
    records = []
    for biome, (top, bottom) in zip(BIOMES, rows):
        bounds = (32, top, 1223, bottom)
        trim = image.crop(bounds).resize((96,12), Image.Resampling.NEAREST)
        # A mirrored companion guarantees a seam without changing edge pixels.
        pair = Image.new('RGB', (192,12))
        pair.paste(trim, (0,0))
        pair.paste(trim.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (96,0))
        path = ROOT / f'assets/world/terrain/{biome}_rim.png'
        pair.save(path)
        records.append(dict(file=str(path.relative_to(ROOT)), crop=bounds, size=pair.size))
    (ROOT/'assets/world/source/material_rims.json').write_text(json.dumps({
        'creator':'OpenAI imagegen, directed and exported by Codex, 2026-09-24',
        'source':'assets/world/source/material_rims.png',
        'reference_role':'Visual construction only; no reference pixels in exports',
        'brief':'Six original continuous material bands: grass, sandstone, autumn earth, snow, wet moss, ember basalt. Bright lip, crafted middle, dark recess. Hard pixel clusters; no framed individual tiles.',
        'exports':records}, indent=2)+'\n', encoding='utf-8')

if __name__ == '__main__':
    export()
