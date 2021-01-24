all: 
	gcc -o spskip_tracer.dylib \
		-l objc \
		-x objective-c \
		-framework Cocoa \
		-dynamiclib \
		-install_name spskip_tracer.dylib \
		-I /usr/local/Cellar/capstone/4.0.1/include \
		-l capstone \
		LibSkipMac.m asman.m skipman.m find_subproc.m hook_address_resolver.m
