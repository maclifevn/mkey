#!/usr/bin/env python3
"""Verify release signatures, metadata and rejection of one-byte tampering."""
import argparse
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

SPARKLE = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'


def verify(feed, archive, notes, signer, account):
    def signature_check(path, signature=None, *, valid=True):
        command = [str(signer), '--verify', '--account', account, str(path)]
        if signature is not None:
            command.append(signature)
        result = subprocess.run(command, capture_output=True, text=True)
        if (result.returncode == 0) != valid:
            raise ValueError(f'Unexpected signature verification result for {path.name}')

    signature_check(feed)
    matching = [item for item in ET.parse(feed).findall('./channel/item')
                if item.find('enclosure') is not None
                and item.find('enclosure').get('url', '').endswith('/' + archive.name)]
    if len(matching) != 1:
        raise ValueError('Expected exactly one entry for the update archive')
    item = matching[0]
    enclosure = item.find('enclosure')
    release_notes = item.find(SPARKLE + 'releaseNotesLink')
    if int(enclosure.get('length', '-1')) != archive.stat().st_size:
        raise ValueError('Archive size does not match the feed')
    if release_notes is None or not (release_notes.text or '').endswith('/' + notes.name):
        raise ValueError('Release notes URL does not match the supplied file')
    archive_sig = enclosure.get(SPARKLE + 'edSignature')
    notes_sig = release_notes.get(SPARKLE + 'edSignature')
    if not archive_sig or not notes_sig:
        raise ValueError('Missing archive or release notes signature')
    for url in (enclosure.get('url'), release_notes.text):
        if not url.startswith('https://github.com/maclifevn/mkey/releases/download/v'):
            raise ValueError('Unexpected release asset URL')
    signature_check(archive, archive_sig)
    signature_check(notes, notes_sig)
    with tempfile.TemporaryDirectory(prefix='mkey-tamper-') as directory:
        for original, signature in ((feed, None), (archive, archive_sig), (notes, notes_sig)):
            contents = bytearray(original.read_bytes())
            if original == feed:
                # Preserve valid XML and change signed content, not the signature.
                index = contents.index(b'<title>') + len(b'<title>')
            else:
                index = len(contents) // 2
            contents[index] ^= 1
            tampered = Path(directory) / original.name
            tampered.write_bytes(contents)
            signature_check(tampered, signature, valid=False)
    print('PASS: archive, feed, release notes signatures and tamper rejection')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('feed', 'archive', 'notes', 'signer'):
        parser.add_argument(name, type=Path)
    parser.add_argument('--account', default='vn.mkey.app')
    args = parser.parse_args()
    verify(args.feed, args.archive, args.notes, args.signer, args.account)
