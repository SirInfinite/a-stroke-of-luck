"""Editable production panel construction: thin stepped rims and translucent ink."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]

def step(draw, box, fill, cut):
    l,t,r,b = box
    draw.polygon([(l+cut,t),(r-cut,t),(r-cut,t+2),(r-2,t+2),(r-2,t+cut),
                  (r,t+cut),(r,b-cut),(r-2,b-cut),(r-2,b-2),(r-cut,b-2),
                  (r-cut,b),(l+cut,b),(l+cut,b-2),(l+2,b-2),(l+2,b-cut),
                  (l,b-cut),(l,t+cut),(l+2,t+cut),(l+2,t+2),(l+cut,t+2)],fill=fill)

def export():
    specs = {
      'panel':('d1cc94',(17,24,27,192)), 'card':('d1cc94',(18,24,25,188)),
      'primary':('eee391',(41,37,21,218)), 'hover':('fff2a2',(43,47,32,214)),
      'pressed':('d6c65d',(29,32,22,230)), 'disabled':('727969',(20,26,28,210)),
      'benefit':('68967a',(18,42,35,155)), 'curse':('9f6870',(48,26,34,160)),
      'focus':('ffe75c',(0,0,0,0)),
      'light':('84744f',(240,232,204,238)), 'light_card':('887955',(248,240,213,240))}
    for name,(rim,fill) in specs.items():
        image=Image.new('RGBA',(40,40)); draw=ImageDraw.Draw(image)
        step(draw,(0,0,39,39),(10,17,23,255),6)
        step(draw,(1,1,38,38),tuple(bytes.fromhex(rim))+(255,),6)
        step(draw,(4,4,35,35),(10,17,23,245),4)
        step(draw,(5,5,34,34),fill,4)
        if name=='focus':
            step(draw,(3,3,36,36),(0,0,0,0),4)
        image.save(ROOT/f'assets/ui/panels/{name}.png')

if __name__=='__main__': export()
