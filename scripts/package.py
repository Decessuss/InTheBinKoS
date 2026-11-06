"""Create client-specific, installable ZIPs without including developer/account data."""
import argparse
from pathlib import Path
import re
import zipfile

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--version',default='0.5.9')
args=parser.parse_args()
version=args.version.removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?',version):
    raise SystemExit('Version must look like 0.5.0 or 0.5.1-beta.1')
files=['Core.lua','Locations.lua','Sightings.lua','Guilds.lua','Personal.lua','Presence.lua','UI.lua','README.md','Media/GuildBackground.tga','Media/EnemySpotted.mp3','Media/CREDITS.txt']
files += ['docs/FULL-GUIDE.md','docs/ForeverKoS-ForeverAura-import.txt']
for file in files:
    if not (ROOT/file).is_file(): raise SystemExit('Missing release file: '+file)
core=(ROOT/'Core.lua').read_text(encoding='utf-8')
if 'key("Decshock")' in core or 'MEMBER_ONLY = true' in core:
    raise SystemExit('A test-only permission override must not ship.')
toc=(ROOT/'InTheBinKoS.toc').read_text(encoding='utf-8')
if re.search(r'^## (?:Dependencies|RequiredDeps):',toc,re.M):
    raise SystemExit('The release must be standalone.')
dist=ROOT/'dist';dist.mkdir(exist_ok=True)
for flavor,interface,suffix in [('forever','16001','-forever')]:
    content=re.sub(r'^## Interface:.*$',f'## Interface: {interface}',toc,flags=re.M)
    content=re.sub(r'^## Version:.*$',f'## Version: {version}',content,flags=re.M)
    path=dist/f'InTheBinKoS-v{version}{suffix}.zip'
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('InTheBinKoS/InTheBinKoS.toc',content)
        for file in files: archive.write(ROOT/file,'InTheBinKoS/'+file)
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        assert all(n.startswith('InTheBinKoS/') for n in archive.namelist())
        assert all(module in archive.read('InTheBinKoS/InTheBinKoS.toc').decode() for module in ('Guilds.lua','Personal.lua','Presence.lua'))
    print(path.name)
