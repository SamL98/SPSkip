all: 
	gcc -o spskip_reinjector.dylib \
		-l objc \
		-x objective-c \
		-framework Foundation \
		-dynamiclib \
		-install_name spskip_reinjector.dylib \
		reinjector.m macho_editor.m macho_parser.m
