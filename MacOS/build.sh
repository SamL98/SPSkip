#!/bin/sh
cp /Applications/Spotify.app/Contents/MacOS/spbackup spmod
python ../common/load_dylib.py --binary spmod \
	--dylib ~/Library/Developer/Xcode/DerivedData/LibSkipMac-gxlndsfkluwapjavdyfjsegrxbwv/Build/Products/Debug/LibSkipMac.framework/LibSkipMac \
	--is64
mv spmod /Applications/Spotify.app/Contents/MacOS/Spotify
