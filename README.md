# Evil Islands HQ music

This mod for Evil Islands: Curse of the Lost Soul provides lossless FLAC music for most tracks.

It also restores several tracks that are present in the game, but never used.

The FLAC tracks come from the lossless soundtrack release and follow the game's tracks:

- Same length and loop points as the game's tracks.
- Same loudness: each file carries an `EIX_GAIN` tag with the game track's level, applied at playback.
- The soundtrack release fades several tracks out; the fades are undone. Where the game's track ends differently (a
  held note or a blend into the loop), its last seconds come from the game's own track.

## Requirements

- [eix](https://github.com/BGforgeNet/eix) PENDING-eix-version or later, which plays FLAC music and reads `EIX_GAIN`.
  Without eix, the game plays its own MP3 tracks.

## Installation

Download the latest release, extract into main game directory.
