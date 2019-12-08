PWD=/Users/samlerner/Projects/SPSkip/MacOS/hook_resolver
HBPATH=/usr/local/Cellar

resolver: addr_resolver find_method objc_types find_subproc
	gcc -o libresolver.dylib addr_resolver.o find_subproc.o find_method.o objc_types.o \
		-I$(PWD) -L$(PWD) -lcapstone \
		-dynamiclib -install_name libspresolver.dylib

	cp $(PWD)/libresolver.dylib /usr/local/lib/libspresolver.dylib
	cp $(PWD)/spresolver.h /usr/local/include/spresolver.h

addr_resolver: 
	gcc -g -o addr_resolver.o -c hook_address_resolver.c \
		-I$(PWD)

find_subproc: objc_types
	gcc -g -o find_subproc.o -c find_subproc.c -I$(PWD) -I$(HBPATH)/capstone/4.0.1/include

find_method: objc_types
	gcc -g -o find_method.o -c find_method.c -I$(PWD)

objc_types:
	gcc -g -o objc_types.o -c objc_types.c

clean:
	rm *.o resolver
