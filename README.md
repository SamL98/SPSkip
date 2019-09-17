# SPSkip

Libraries for hooking the skip/previous functions in the Spotify iOS and MacOS clients.

## MacOS

The `hook_resolver` directory builds to the library that resolves addresses necessary for hooking.

The `LibSkipMac` directory then uses this library and builds to the final skiptracer that can be inserted into the application binary.

## iOS

The `LibSkipiOS` directory builds to the library that can be used for skiptracing in the iOS application.

The `server` directory contains the code needed to run the server that will listen for skips exfiltrated from the iOS app.

## Commoon

Contains the script `load_dylib.py` that inserts the specified library into the specified binary. It also has the ability to disable ASLR for the binary.
