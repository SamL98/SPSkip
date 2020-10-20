#!/bin/sh
#cp /Applications/Spotify.app/Contents/MacOS/Spotify /Applications/Spotify.app/Contents/MacOS/spbackup
cp /Applications/Spotify.app/Contents/MacOS/spbackup spmod

python ../common/load_dylib.py \
    --binary spmod \
	--is64 \
	--disable_aslr \
    --text_maxprot 7 \
    $(pwd)/LibSkipMac/skiptracer.dylib $(pwd)/persistence_ensurer/persistence_ensurer.dylib

mv spmod /Applications/Spotify.app/Contents/MacOS/Spotify
