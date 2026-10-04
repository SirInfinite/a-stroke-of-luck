"""Read-only reference inventory and labelled analysis sheets (never production art)."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "assets/references"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', default='artifacts/reference_review')
parser.add_argument('--reconstruct', action='store_true', help='PTS-indexed dense sequences and component crops')
args = parser.parse_args()
OUT = ROOT / args.output
OUT.mkdir(parents=True, exist_ok=True)
FONT = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 17)
sources = []
images = []
for path in sorted(REF.rglob("*")):
    if not path.is_file() or path.suffix.lower() in {".import", ".uid", ".ini", ".db"}:
        continue
    entry = {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
             "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    try:
        with Image.open(path) as im:
            entry.update(type="image", width=im.width, height=im.height)
            images.append((path, im.convert("RGB")))
    except Exception:
        result = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)], capture_output=True, text=True)
        if result.returncode == 0:
            meta = json.loads(result.stdout)
            entry.update(type="recording", metadata=meta)
        else:
            entry.update(type="unreadable", error=result.stderr)
    sources.append(entry)
(OUT / "source_inventory.json").write_text(json.dumps(sources, indent=2), encoding="utf-8")

def sheet(items, name, cols=3, width=600, height=370):
    result = Image.new("RGB", (cols * width, ((len(items)+cols-1)//cols)*height), "#101b25")
    draw = ImageDraw.Draw(result)
    for n, (label, im) in enumerate(items):
        x, y = (n % cols)*width, (n//cols)*height
        im = im.copy()
        im.thumbnail((width-12, height-45))
        result.paste(im, (x+6, y+5))
        draw.text((x+8, y+height-38), label, font=FONT, fill="#fff0cb")
        draw.text((x+8, y+height-19), "REFERENCE ONLY - Grandpa Golf", font=FONT, fill="#b0c1bc")
    result.save(OUT / name)

for start in range(0, len(images), 8):
    sheet([(p.name[:19], im) for p, im in images[start:start+8]], f"screenshots_{start//8+1}.jpg", cols=2, width=960, height=585)

for entry in sources:
    if entry["type"] != "recording":
        continue
    video = ROOT / entry["path"]
    frames = OUT / "video_frames"
    frames.mkdir(exist_ok=True)
    timing = json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_frames','-show_entries','frame=best_effort_timestamp_time,pkt_duration_time','-of','json',str(video)],text=True))['frames']
    pts = [float(f['best_effort_timestamp_time']) for f in timing]
    (OUT/'video_timestamps.json').write_text(json.dumps(timing,indent=2))
    selected = sorted(set(min(range(len(pts)), key=lambda i: abs(pts[i]-second)) for second in range(int(pts[-1])+1)))
    selection = '+'.join('eq(n,%d)'%n for n in selected)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(video),'-vf',f"select='{selection}'",'-fps_mode','vfr','-y',str(frames/'second_%03d.png')],check=True)
    shots = [(f"PTS {pts[selected[n]]:.3f}s | REFERENCE", Image.open(p).convert("RGB")) for n,p in enumerate(sorted(frames.glob("*.png")))]
    for start in range(0,len(shots),12):
        sheet(shots[start:start+12], f"recording_{start//12+1}.jpg")
    if args.reconstruct:
        intervals={'travel':(2.0,4.6),'cup_early':(6.4,8.8),'shop':(11.7,12.9),'selection':(19.9,21.1),'result':(24.3,27.1),'camera_continuous':(18.066667,19.066667),'release':(14.7,15.3)}
        dense_index={}
        for name,(start,end) in intervals.items():
            dest=OUT/name;dest.mkdir(exist_ok=True)
            chosen=[i for i,t in enumerate(pts) if start<=t<=end]
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(video),'-vf',f"select='between(n,{chosen[0]},{chosen[-1]})'",'-fps_mode','vfr','-y',str(dest/'frame_%04d.png')],check=True)
            paths=sorted(dest.glob('frame_*.png'))
            assert len(paths)==len(chosen),(name,len(paths),len(chosen))
            dense_index[name]=[{'file':p.relative_to(OUT).as_posix(),'pts':pts[i]} for p,i in zip(paths,chosen)]
            for page in range(0,len(paths),20):
                items=[(f'PTS {pts[chosen[n]]:.3f}s',Image.open(paths[n]).convert('RGB')) for n in range(page,min(page+20,len(paths)))]
                sheet(items,f'{name}_{page//20+1}.jpg',cols=4,width=420,height=278)
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-ss',str(start),'-i',str(video),'-t',str(end-start),'-vn','-c:a','pcm_s16le','-y',str(OUT/f'REFERENCE_ONLY_{name}_{start}-{end}.wav')],check=True)
        (OUT/'dense_index.json').write_text(json.dumps(dense_index,indent=2))
        subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(video),'-vn','-c:a','pcm_s16le','-y',str(OUT/'REFERENCE_ONLY_full_audio.wav')],check=True)

if args.reconstruct:
    crops={
      'shop_offer':('67b19',(760,330,1085,824)), 'item_details':('67b19',(0,245,540,934)),
      'primary_action':('67b19',(825,665,1020,790)), 'ordinary_label':('67b19',(867,330,978,367)),
      'power_meter':('67b19',(697,970,1210,1054)), 'inventory_items':('d2ca',(735,180,1705,924)),
      'jar_sprite':('d2ca',(755,185,900,330)), 'club_sprite':('d2ca',(735,365,911,540)),
      'large_number':('850b',(0,45,216,170)), 'grass_rim':('850b',(395,705,1460,960)),
      'wall_corner':('d346',(750,115,1110,425)), 'background_layers':('850b',(340,100,1610,710)),
      'water_material':('508f',(722,185,1340,585)), 'panel_corner':('67b19',(750,330,835,417)),
    }
    crop_index={}
    for name,(prefix,box) in crops.items():
        source=next(p for p,_ in images if p.name.startswith('ss_'+prefix))
        crop=Image.open(source).crop(box)
        crop.save(OUT/f'REFERENCE_ONLY_{name}.png')
        crop.resize((crop.width*2,crop.height*2),Image.Resampling.NEAREST).save(OUT/f'REFERENCE_ONLY_{name}_2x.png')
        crop_index[name]={'source':source.relative_to(ROOT).as_posix(),'box_ltrb':box,'size':crop.size}
    (OUT/'crop_index.json').write_text(json.dumps(crop_index,indent=2))

# Pre-edit inventory includes dirty and untracked production sources; generated engine cache is excluded.
preserved = {}
for folder in ["scripts", "scenes", "assets", "tests", "tools/pixel_sample", "tools/pixel_correction"]:
    for p in (ROOT/folder).rglob("*"):
        if p.is_file() and p.suffix not in {".import", ".uid", ".pyc"}:
            preserved[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
for name in ["project.godot", "export_presets.cfg"]:
    preserved[name] = hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
baseline = OUT / "pre_edit_hashes.json"
if not baseline.exists():
    baseline.write_text(json.dumps(preserved, indent=2), encoding="utf-8")
print(json.dumps({'output':str(OUT),'sources':len(sources),'images':len(images),'unreadable':[s['path'] for s in sources if s['type']=='unreadable']},indent=2))
