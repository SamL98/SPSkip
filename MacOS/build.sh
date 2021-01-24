#!/bin/sh
#cp /Applications/Spotify.app/Contents/MacOS/Spotify /Applications/Spotify.app/Contents/MacOS/spbackup
cp /Applications/Spotify.app/Contents/MacOS/spbackup spmod

python ../common/load_dylib.py \
    --binary spmod \
	--is64 \
	--disable_aslr \
    --text_maxprot 7 \
    $(pwd)/LibSkipMac/spskip_tracer.dylib $(pwd)/reinjector/spskip_reinjector.dylib

mv spmod /Applications/Spotify.app/Contents/MacOS/Spotify
