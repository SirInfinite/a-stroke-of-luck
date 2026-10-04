"""Timestamped temporal frames for the world specialist's direct media review."""
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
VIDEO = ROOT / 'assets/references/Screen Recording 2026-09-24 143837.mp4'
OUT = ROOT / 'artifacts/reference_review/world'
for name, start in [('trail_contact', 2.2), ('water_rebound', 21.8)]:
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-ss',str(start),'-i',str(VIDEO),
                    '-t','0.8','-vf','fps=15','-y',str(folder/'frame_%02d.png')],check=True)
    sheet = Image.new('RGB',(1440,960),'#15232b')
    draw=ImageDraw.Draw(sheet)
    draw.text((10,6),'REFERENCE ONLY / Grandpa Golf / '+VIDEO.name+' / 15 Hz temporal review',fill='#fff1ce')
    for index,path in enumerate(sorted(folder.glob('frame_*.png'))):
        image=Image.open(path)
        image.thumbnail((470,265),Image.Resampling.NEAREST)
        x,y=8+(index%3)*480,35+(index//3)*229
        # Maintain all visible content, including ball and trail.
        image=image.resize((400,224),Image.Resampling.NEAREST)
        sheet.paste(image,(x,y))
        draw.text((x+405,y+10),f'{start+index/15:.3f}s',fill='#fff1ce')
    sheet.save(OUT/(name+'_temporal.jpg'),quality=94)
print('Saved two 12-frame temporal sheets; extracted footage is analysis only.')
