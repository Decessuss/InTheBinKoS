import importlib.util
from pathlib import Path
from tempfile import TemporaryDirectory
spec=importlib.util.spec_from_file_location('upload',Path('scripts/upload_curseforge.py'))
upload=importlib.util.module_from_spec(spec);spec.loader.exec_module(upload)
versions=[{'id':123,'name':'1.60.1','gameVersionTypeID':88568},
          {'id':999,'name':'1.60.1','gameVersionTypeID':1}]
info=upload.metadata('v0.5.3',versions,'Changes')
assert info['gameVersions']==[123] and info['releaseType']=='beta'
assert not info['isMarkedForManualRelease']
assert upload.metadata('v0.5.3-alpha.1',versions,'Changes')['releaseType']=='alpha'
for tag,values in [('bad',versions),('v0.5.3',[]),('v0.5.3',versions+versions)]:
    try:upload.metadata(tag,values,'Changes')
    except ValueError:pass
    else:raise AssertionError('Ambiguous or invalid release accepted')
class Archive:
    name='addon.zip'
    def read_bytes(self):return b'ZIP-CONTENT'
body=upload.multipart(info,Archive(),'boundary')
assert b'name="metadata"' in body and b'name="file"; filename="addon.zip"' in body
assert b'ZIP-CONTENT' in body and body.endswith(b'--boundary--\r\n')
print('PASS: CurseForge release metadata, Forever-only version selection and multipart upload body.')
