#!/usr/bin/env python3
"""Offline validation of the actual App Store delivery files (stdlib only)."""
from pathlib import Path
from html.parser import HTMLParser
import ast,hashlib,json,plistlib,re,struct,sys,zlib
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'distribution';checks=[]
def require(ok,label):
 if not ok:raise SystemExit('FAIL: '+label)
 checks.append(label)
def png(path):
 blob=path.read_bytes();require(blob[:8]==b'\x89PNG\r\n\x1a\n',str(path.relative_to(ROOT))+' PNG')
 w,h,depth,color=struct.unpack('>IIBB',blob[16:26]);require(color==2 and depth==8,str(path.relative_to(ROOT))+' opaque 8-bit RGB')
 return w,h
# Read version settings without executing the project generator or rewriting it.
app_settings=next(ast.literal_eval(node.value) for node in ast.parse((ROOT/'scripts/generate-project.py').read_text()).body
 if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='app_settings' for t in node.targets))
store=json.loads((D/'metadata/app-information.json').read_text())
readiness=json.loads((D/'release-readiness.json').read_text())
project=(ROOT/'CrocoCross.xcodeproj/project.pbxproj').read_text()
for key,setting in [('version','MARKETING_VERSION'),('build','CURRENT_PROJECT_VERSION')]:
 require(isinstance(store.get(key),str) and bool(store[key]),'release metadata '+key+' is explicit')
 require(store[key]==app_settings[setting],'release metadata '+key+' matches generated project source')
 require(set(re.findall(r'"'+setting+r'"\s*=\s*"([^"]+)"',project))=={store[key]},'all app configurations match release '+key)
 require(readiness.get(key)==store[key],'readiness identity matches candidate '+key)
require(store.get('bundleID')==app_settings['PRODUCT_BUNDLE_IDENTIFIER'],'release metadata bundle ID matches project')
require(store.get('developmentTeam')==app_settings['DEVELOPMENT_TEAM'],'release metadata team matches project')
require(store.get('metadataLocalizations')==['en-US'],'release metadata declares the prepared localization')

# The review contact sheet is not an upload image. Every catalog badge must be
# represented exactly once by its declared filename and byte-accurate manifest.
badges=D/'game-center/achievements'
catalog=json.loads((ROOT/'docs/achievements-game-center.json').read_text())
manifest=json.loads((badges/'manifest.json').read_text())
entries=catalog['achievements'];images=manifest['files']
require(catalog.get('achievementCount')==len(entries)==40,'forty achievement definitions')
require(catalog.get('totalPoints')==sum(e['points'] for e in entries)==1000,'achievement points total is 1000')
require(manifest.get('count')==len(images)==len(entries),'badge manifest covers all achievements')
require(manifest.get('sourceCatalog')=='achievements-game-center.json','badge manifest names its source catalog')
require(len({e['id'] for e in entries})==len(entries),'unique achievement IDs')
require(len({e['id'] for e in images})==len(images),'unique badge manifest IDs')
expected={e['id']:e['proposedImageFilename'] for e in entries}
require({e['id']:e['filename'] for e in images}==expected,'badge IDs and filenames match achievement catalog')
require(len(set(expected.values()))==len(expected),'unique badge filenames')
require({p.name for p in badges.glob('*.png')}==set(expected.values())|{'contact-sheet.png'},'only declared badges and the review contact sheet are present')
require(len({e['sha256'] for e in images})==len(images),'achievement badges have distinct artwork')
for entry in images:
 name=entry['filename']
 require(Path(name).name==name and name.endswith('.png'),'safe badge filename: '+name)
 file=badges/name;label='badge '+name
 require(png(file)==(1024,1024),label+' dimensions')
 blob=file.read_bytes()
 require(hashlib.sha256(blob).hexdigest()==entry.get('sha256'),label+' SHA256 matches manifest')
 require(entry.get('width')==1024 and entry.get('height')==1024 and entry.get('opaque') is True
         and entry.get('colorSpace')=='sRGB' and entry.get('dpi')==72,label+' manifest image metadata')
 offset=8;chunks={};valid=True
 while offset<len(blob):
  if offset+12>len(blob):valid=False;break
  length=struct.unpack('>I',blob[offset:offset+4])[0]
  if offset+12+length>len(blob):valid=False;break
  kind=blob[offset+4:offset+8];payload=blob[offset+8:offset+8+length]
  crc=struct.unpack('>I',blob[offset+8+length:offset+12+length])[0]
  valid=valid and zlib.crc32(kind+payload)&0xffffffff==crc
  chunks.setdefault(kind,[]).append(payload);offset+=length+12
 require(valid and b'IDAT' in chunks and chunks.get(b'IEND')==[b''],label+' PNG chunk integrity')
 require(b'tRNS' not in chunks,label+' has no transparency chunk')
 require(chunks.get(b'sRGB') in [[bytes([i])] for i in range(4)],label+' embedded sRGB color space')
 require(len(chunks.get(b'pHYs',[]))==1 and len(chunks[b'pHYs'][0])==9,label+' resolution metadata exists')
 xppm,yppm,unit=struct.unpack('>IIB',chunks[b'pHYs'][0])
 require(unit==1 and abs(xppm*0.0254-72)<0.1 and abs(yppm*0.0254-72)<0.1,label+' actual resolution is 72 ppi')
require(not (D/'metadata/fr-FR').exists() and not (D/'screenshots/upload/fr-FR').exists(),'English-only store localization')
require(not list((D/'web').glob('*-fr.html')),'English-only public pages')
for lang in ['en-US']:
 for field,limit in [('name',30),('subtitle',30),('promotional-text',170),('description',4000),('keywords',100),('whats-new',4000)]:
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
require(export['manageAppVersionAndBuildNumber'] is False,'preserve the selected build number')
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

if '--submission' in sys.argv:
 readiness=json.loads((D/'release-readiness.json').read_text())
 require(info.get('CrocoGameCenterAchievementsEnabled') is True,'Game Center achievements activated after remote configuration')
 for gate,passed in readiness['submissionGates'].items():
  require(passed is True,'submission gate: '+gate)
 print('Submission prerequisites explicitly confirmed')
