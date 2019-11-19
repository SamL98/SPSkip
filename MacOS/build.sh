#!/bin/sh
cp /Applications/Spotify.app/Contents/MacOS/Spotify /Applications/Spotify.app/Contents/MacOS/spbackup
cp /Applications/Spotify.app/Contents/MacOS/spbackup spmod
python ../common/load_dylib.py --binary spmod \
	--dylib ~/Library/Developer/Xcode/DerivedData/LibSkipMac-hcztgfssrmyqbyesamdwjunzzspu/Build/Products/Debug/LibSkipMac.framework/LibSkipMac \
	--is64 \
	--disable_aslr
mv spmod /Applications/Spotify.app/Contents/MacOS/Spotify
