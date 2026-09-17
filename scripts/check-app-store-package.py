#!/usr/bin/env python3
"""Offline validation of the actual App Store delivery files (stdlib only)."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,plistlib,re,struct,sys
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'distribution';checks=[]
def require(ok,label):
 if not ok:raise SystemExit('FAIL: '+label)
 checks.append(label)
def png(path):
 blob=path.read_bytes();require(blob[:8]==b'\x89PNG\r\n\x1a\n',str(path.relative_to(ROOT))+' PNG')
 w,h,depth,color=struct.unpack('>IIBB',blob[16:26]);require(color==2 and depth==8,str(path.relative_to(ROOT))+' opaque 8-bit RGB')
 return w,h
for lang in ['en-US','fr-FR']:
 for field,limit in [('name',30),('subtitle',30),('promotional-text',170),('description',4000),('keywords',100)]:
  value=(D/'metadata'/lang/(field+'.txt')).read_text().strip();count=len(value.encode('utf-8')) if field=='keywords' else len(value)
  require(0<count<=limit,f'{lang} {field}: {count}/{limit}')
 for field in ['support-url','privacy-url','marketing-url']:
  require((D/'metadata'/lang/(field+'.txt')).read_text().startswith('https://'),f'{lang} {field} HTTPS')
 for device,size in [('iphone-6.9',(1320,2868)),('ipad-13',(2752,2064))]:
  paths=sorted((D/'screenshots/upload'/lang/device).glob('*.png'))
  require(len(paths)==5,f'{lang} {device}: five screenshots')
  for p in paths:require(png(p)==size,str(p.relative_to(ROOT))+' dimensions')
require(png(D/'icons/CrocoCross-1024.png')==(1024,1024),'marketing icon 1024')
for p in (D/'icons').glob('*.png'):
 n=int(p.stem.split('-')[-1]);require(png(p)==(n,n),p.name+' icon size')
for f in ['Info.plist','PrivacyInfo.xcprivacy','CrocoCross.entitlements']:
 require((D/'config'/f).read_bytes()==(ROOT/'App'/f).read_bytes(),f+' copy matches app')
info=plistlib.loads((ROOT/'App/Info.plist').read_bytes())
require(info['ITSAppUsesNonExemptEncryption'] is False,'OS-only encryption declaration')
require(info['UISupportedInterfaceOrientations']==['UIInterfaceOrientationPortrait'],'iPhone portrait')
require('UIInterfaceOrientationLandscapeLeft' in info['UISupportedInterfaceOrientations~ipad'],'iPad landscape')
privacy=plistlib.loads((ROOT/'App/PrivacyInfo.xcprivacy').read_bytes())
reasons={x['NSPrivacyAccessedAPIType']:x['NSPrivacyAccessedAPITypeReasons'] for x in privacy['NSPrivacyAccessedAPITypes']}
require(reasons['NSPrivacyAccessedAPICategoryUserDefaults']==['CA92.1'],'UserDefaults reason')
require(reasons['NSPrivacyAccessedAPICategorySystemBootTime']==['35F9.1'],'elapsed-time reason')
require(privacy['NSPrivacyTracking'] is False,'no tracking')
export=plistlib.loads((D/'config/ExportOptions-AppStore.plist').read_bytes())
require(export['method']=='app-store-connect' and export['destination']=='export','local App Store export, no upload')
require(export['manageAppVersionAndBuildNumber'] is False,'preserve build 17')
meta=json.loads((ROOT/'docs/death-sounds.json').read_text())
clip=ROOT/'App/Resources/GameAssets/DeathSounds'/meta['file']
require(hashlib.sha256(clip.read_bytes()).hexdigest()==meta['sha256'],'renamed original audio bytes preserved')
require(not (clip.parent/'gta-death-trimmed.wav').exists(),'generic bundled audio name')
class Links(HTMLParser):
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  for key in ['href','src']:
   v=a.get(key,'')
   if not v or v.startswith(('http:','https:','mailto:','#')):continue
   require((D/'web'/v.split('#')[0]).exists(),'web link exists: '+v)
for p in (D/'web').glob('*.html'):
 s=p.read_text();require(not re.search(r'(?<!\d)(?:\+?1[ .-]*)?(?:\(\d{3}\)|\d{3})[ .-]*\d{3}[ .-]*\d{4}(?!\d)',s),'private phone absent: '+p.name);Links().feed(s)
 require('viewport' in s and '<html lang=' in s,'responsive language metadata: '+p.name)
require('distribution/private/' in (ROOT/'.gitignore').read_text(),'private review contact ignored')
report={'status':'pass','checks':len(checks),'items':checks,'scope':'Local package integrity; not Apple server validation or proof of distribution signing.'}
(D/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(f'{len(checks)} App Store package checks passed')
