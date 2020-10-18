#!/bin/sh
cp client/Spotify spmod
cp ~/Library/Developer/Xcode/DerivedData/SkipTracer-ecfucjjhxjcyzzgyizjsbjjdblju/Build/Products/Debug-iphoneos/SkipTracer.framework/SkipTracer Payload/Spotify.app/Frameworks/libskip.dylib 
python ../common/load_dylib.py --binary spmod \
	--dylib @rpath/libskip.dylib
cp spmod Payload/Spotify.app/Spotify
rm -rf Payload/Spotify.app/_CodeSignature
codesign -f -s "$IOS_IDENTITY" --entitlements entitlements.plist Payload/Spotify.app/Spotify
codesign -f -s "$IOS_IDENTITY" --entitlements entitlements.plist Payload/Spotify.app/Frameworks/*
zip -qr Spotify-resigned.ipa Payload
