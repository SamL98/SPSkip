all: skiptracer asman skipman
	gcc -o skiptracer.dylib \
		-l objc \
		-x objective-c \
		-framework Cocoa \
		-dynamiclib \
		-install_name skiptracer.dylib \
		-I /usr/local/Cellar/capstone/4.0.1/include \
		-l capstone \
		LibSkipMac.m asman.m skipman.m find_subproc.m hook_address_resolver.m

skiptracer:
	gcc -o skiptracer.o \
		-x objective-c \
		-c LibSkipMac.m

asman:
	gcc -o asman.o \
		-x objective-c \
		-c asman.m

skipman:
	gcc -o skipman.o \
		-x objective-c \
		-c skipman.m
