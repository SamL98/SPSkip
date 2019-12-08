#!/bin/sh
python ../common/load_dylib.py \
	--binary /Applications/Spotify.app/Contents/MacOS/Spotify \
	--dylib ~/Library/Developer/Xcode/DerivedData/LibSkipMac-hcztgfssrmyqbyesamdwjunzzspu/Build/Products/Debug/LibSkipMac.framework/LibSkipMac \
	--is64 \
	--disable_aslr
