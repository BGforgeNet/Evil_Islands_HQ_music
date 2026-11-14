#!/usr/bin/env bash
# Packages res/ and stream/ into the release zip and the installer; writes their names to $GITHUB_OUTPUT as `zip`
# and `exe`. A tag build is named after the tag, any other build `nightly-<short commit>`. Needs 7z and podman.
set -euo pipefail

# The Inno Setup 6 compiler under Wine, pinned by digest.
readonly INNO=docker.io/amake/innosetup@sha256:ca648314001a18d66b7b4a3c62205bcae6a6406506df896885bbe12bafb4f1b6

if [[ "${REF_TYPE:?}" = tag ]]; then
	version="${REF_NAME:?}"
else
	version="nightly-${GITHUB_SHA:?}"
	version="${version:0:15}"
fi
name="evil_islands_hq_music_${version}"

# The compiler runs as the image's own user: it writes into a world-writable folder outside the tree, and the
# installer is copied out of it.
out="${RUNNER_TEMP:?}/inno"
mkdir -p "$out"
chmod 777 "$out"
podman run --rm --network none -v "$PWD:/work/src:ro" -v "$out:/out" "$INNO" \
	/work/src/installer/setup.iss "/DVersion=$version" '/OZ:\out'
cp "$out/$name.exe" .

# music.ini is the editable source of music.reg; the game reads only the .reg.
rm -f res/music.ini
7z a -r "$name.zip" res stream
{
	echo "zip=$name.zip"
	echo "exe=$name.exe"
} >>"${GITHUB_OUTPUT:?}"
