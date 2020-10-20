# SPSkip

Libraries for hooking the skip/previous functions in the Spotify iOS and MacOS clients.

For more information on the basic MacOS functionality, see the following blog post: [https://medium.com/@lerner98/skiptracing-reversing-spotify-app-3a6df367287d]

For information on the iOS functionality: [https://medium.com/@lerner98/skiptracing-part-2-ios-3c610205858b]

On the automatic hooking for MacOS: [https://medium.com/swlh/skiptracing-automated-hook-resolution-74eda756533d]

## MacOS

The `persistence_ensurer` directory builds to a library that a) observes automatic Spotify updates and b) reinjects itself and the skiptracer library into the downloaded executable.

The `LibSkipMac` directory builds to the final skiptracer that can be inserted into the application binary. It also performs the automatic hook resolution.

## iOS

The `LibSkipiOS` directory builds to the library that can be used for skiptracing in the iOS application.

The `server` directory contains the code needed to run the server that will listen for skips exfiltrated from the iOS app.

## Common

Contains the script `load_dylib.py` that inserts the specified library into the specified binary. It also has the ability to disable ASLR for the binary and set the max protection value for the `__TEXT` segment.
