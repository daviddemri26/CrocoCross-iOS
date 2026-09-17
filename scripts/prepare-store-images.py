#!/usr/bin/env python3
"""Format real XCTest captures and original app art for App Store Connect.
Requires Pillow. Preserves the full real capture, scaled without invented game state.
"""
from pathlib import Path
import json, argparse
from PIL import Image, ImageDraw, ImageFont, ImageOps
ROOT=Path(__file__).resolve().parents[1]; DIST=ROOT/'distribution'
parser=argparse.ArgumentParser();parser.add_argument('--export',type=Path);parser.add_argument('--device',choices=['iphone-6.9','ipad-13']);args=parser.parse_args()
if args.export:
 assert args.device
 dest=DIST/'screenshots/raw'/args.device;dest.mkdir(parents=True,exist_ok=True)
 for group in json.loads((args.export/'manifest.json').read_text()):
  for item in group['attachments']:
   name=item['suggestedHumanReadableName']
   if not name.startswith('appstore-') or item['isAssociatedWithFailure']:continue
   short=name.split('_0_')[0].replace('appstore-','')+'.png'
   im=ImageOps.exif_transpose(Image.open(args.export/item['exportedFileName'])).convert('RGB')
   im.save(dest/short)
icon=Image.open(ROOT/'App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png').convert('RGB')
assert icon.size==(1024,1024)
for size in [1024,180,167,152,120,87,80,76,60,58,40,32]:
 icon.resize((size,size),Image.Resampling.LANCZOS).save(DIST/'icons'/f'CrocoCross-{size}.png')
font_path='/System/Library/Fonts/Supplemental/Avenir Next Condensed.ttc'
body_path='/System/Library/Fonts/Supplemental/Avenir Next.ttc'
def font(size,bold=True):return ImageFont.truetype(font_path if bold else body_path,size,index=9 if bold else 5)
copy={
'en-US':[('01-weekly-ride','FIND YOUR FLOW.','Ride the Canyon. Make every landing count.'),('02-endless-ride','GO A LITTLE FURTHER.','Three lives. An endless trail.'),('03-home','MEET ROCCO.','One crocodile. Two ways to ride.'),('04-controls','TWO THUMBS. ALL YOU.','Accelerate. Balance. Land your flips.'),('05-audio','YOUR RIDE. YOUR SOUND.','Original tracks. Separate volumes. One-tap mute.')],
}
for device,dimensions in [('iphone-6.9',(1320,2868)),('ipad-13',(2752,2064))]:
 raw=DIST/'screenshots/raw'/device
 if not all((raw/(x[0]+'.png')).exists() for x in copy['en-US']):continue
 w,h=dimensions
 for lang,entries in copy.items():
  out=DIST/'screenshots/upload'/lang/device;out.mkdir(parents=True,exist_ok=True)
  for stem,title,subtitle in entries:
   screen=Image.open(raw/(stem+'.png')).convert('RGB');assert screen.size==dimensions,(device,screen.size)
   canvas=Image.new('RGB',dimensions,'#0b1b20');d=ImageDraw.Draw(canvas)
   # Headline and original full screen share the canvas. No fake device frame.
   margin=72 if w<h else 100
   header=430 if w<h else 340
   fs=86 if w<h else 116
   while d.textbbox((0,0),title,font=font(fs))[2]>w-2*margin:fs-=1
   d.text((margin,58 if w<h else 45),'CROCOCROSS',font=font(32),fill='#ff8a42')
   d.text((margin,115 if w<h else 95),title,font=font(fs),fill='#c2fa4c')
   subsize=38 if w<h else 45
   while d.textbbox((0,0),subtitle,font=font(subsize,False))[2]>w-2*margin:subsize-=1
   d.text((margin,230 if w<h else 230),subtitle,font=font(subsize,False),fill='#ecf3e9')
   available=(w-2*margin,h-header-70)
   ratio=min(available[0]/w,available[1]/h)
   size=(round(w*ratio),round(h*ratio));screen=screen.resize(size,Image.Resampling.LANCZOS)
   x=(w-size[0])//2;y=header
   d.rounded_rectangle((x-5,y-5,x+size[0]+5,y+size[1]+5),radius=8,fill='#38524f')
   canvas.paste(screen,(x,y));canvas.save(out/(stem+'.png'),optimize=True)
  thumbs=[]
  for p in sorted(out.glob('*.png')):
   im=Image.open(p);im.thumbnail((264,574));thumbs.append(im)
  sheet=Image.new('RGB',(len(thumbs)*280,max(im.height for im in thumbs)+28),'#172c32')
  for i,im in enumerate(thumbs):sheet.paste(im,(i*280+8,14))
  sheet.save(DIST/f'preview-{lang}-{device}.jpg',quality=90)
print('Icons and available upload sets prepared')
