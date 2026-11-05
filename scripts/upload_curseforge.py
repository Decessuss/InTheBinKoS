"""Publish the packaged addon through CurseForge's author Upload API.
The token comes only from CF_API_TOKEN; it is never printed or saved.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request
import uuid

API = 'https://wow.curseforge.com/api'
PROJECT = 1784566
GAME_VERSION = '1.60.1'
GAME_TYPE = 88568  # WoW Forever, not Classic Era or TBC.


def metadata(tag, versions, changelog):
    if not re.fullmatch(r'v\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?', tag):
        raise ValueError('Expected a version tag such as v0.5.3 or v0.5.3-beta.1')
    matches = [v['id'] for v in versions
               if v.get('name') == GAME_VERSION and v.get('gameVersionTypeID') == GAME_TYPE]
    if len(matches) != 1:
        raise ValueError('Could not uniquely identify WoW Forever 1.60.1; refusing to guess.')
    return dict(displayName=tag.removeprefix('v'), gameVersions=matches,
                releaseType='alpha' if '-alpha' in tag else 'beta',
                changelog=changelog, changelogType='markdown', isMarkedForManualRelease=False)


def multipart(info, archive, boundary):
    marker = boundary.encode('ascii')
    return (b'--' + marker + b'\r\nContent-Disposition: form-data; name="metadata"\r\n'
            b'Content-Type: application/json\r\n\r\n' + json.dumps(info).encode() +
            b'\r\n--' + marker + b'\r\nContent-Disposition: form-data; name="file"; filename="' +
            archive.name.encode('ascii') + b'"\r\nContent-Type: application/zip\r\n\r\n' +
            archive.read_bytes() + b'\r\n--' + marker + b'--\r\n')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward the upload credential to another host.
        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tag', required=True)
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    token = os.environ.get('CF_API_TOKEN', '').strip()
    if not token:
        raise ValueError('Missing GitHub Actions secret CF_API_TOKEN. GitHub downloads remain available.')
    if any(ord(c) < 33 or ord(c) > 126 for c in token):
        raise ValueError('Upload token contains invalid characters.')
    opener = urllib.request.build_opener(NoRedirect)

    def request(path, data=None, content_type=None):
        headers = {'X-Api-Token': token, 'User-Agent': 'InTheBinKoS-release/1.0'}
        if content_type:
            headers['Content-Type'] = content_type
        req = urllib.request.Request(API + path, data=data, headers=headers)
        with opener.open(req, timeout=120) as response:
            return json.load(response)

    versions = request('/game/versions')
    info = metadata(args.tag, versions,
                    f'Changes for {args.tag}:\n\nhttps://github.com/Decessuss/InTheBinKoS/releases/tag/{args.tag}\n\n'
                    'All participating guild members should use the same addon version. '
                    'Beta build: in-game testing is ongoing.')
    if args.check_only:
        print('CurseForge token and WoW Forever version lookup succeeded. No file uploaded.')
        return
    archive = Path(__file__).resolve().parents[1] / 'dist' / f'InTheBinKoS-{args.tag}-forever.zip'
    if not archive.is_file():
        raise ValueError('Expected packaged addon ZIP is missing.')
    boundary = 'InTheBinKoS' + uuid.uuid4().hex
    # Do not automatically retry POSTs: a timeout can occur after CurseForge has accepted a file.
    result = request(f'/projects/{PROJECT}/upload-file', multipart(info, archive, boundary),
                     f'multipart/form-data; boundary={boundary}')
    file_id = result.get('id')
    if not isinstance(file_id, int) or file_id <= 0:
        raise ValueError('CurseForge did not return a valid file ID; check its dashboard before retrying.')
    print(f'CurseForge accepted file {file_id}; moderation still applies.')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a', encoding='utf-8') as out:
            out.write(f'CurseForge beta uploaded: file **{file_id}**. Awaiting processing/review.\n')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as exc:
        print(f'CurseForge API returned HTTP {exc.code}. Check token/access and dashboard before retrying.', file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError:
        print('CurseForge connection failed. Check the dashboard before retrying an upload.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
