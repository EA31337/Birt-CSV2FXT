CC=winegcc

DEFS=-DWIN32 -D_DEBUG -D_USRDLL -D_WINDOWS

all:
	$(CC) $(CFLAGS) $(DEFS) -x c -c -O0 -W -mno-cygwin -I/usr/include/wine/msvcrt/ CsvReader.cpp dllmain.cpp
	$(CC) -shared exports.spec -mno-cygwin -o csvreader.dll CsvReader.o dllmain.o

clean:
	rm dllmain.o CsvReader.o csvreader.dll.so
