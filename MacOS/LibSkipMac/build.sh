#!/bin/sh
python ../../common/load_dylib.py \
	--binary /Applications/Spotify.app/Contents/MacOS/Spotify \
	--dylib $(pwd)/skiptracer.dylib \
	--is64 \
	--disable_aslr
