#!/usr/bin/env bash
# Packages res/ and stream/ into the release zip; writes its name to $GITHUB_OUTPUT as `zip`.
# A tag build is named after the tag, any other build `nightly-<short commit>`.
set -euo pipefail

if [[ "${REF_TYPE:?}" = tag ]]; then
	version="${REF_NAME:?}"
else
	version="nightly-${GITHUB_SHA:?}"
	version="${version:0:15}"
fi
zip="evil_islands_hq_music_${version}.zip"
# music.ini is the editable source of music.reg; the game reads only the .reg.
rm -f res/music.ini
7z a -r "$zip" res stream
echo "zip=$zip" >>"${GITHUB_OUTPUT:?}"
