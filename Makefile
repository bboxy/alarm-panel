CLIBS = -ltiff
CFLAGS = -Wall -O3
CC = gcc

.PHONY: all clean

all: cheap_ocr

cheap_ocr: cheap_ocr.c
	$(CC) $< -o $@ $(CFLAGS) $(CLIBS)

clean:
	-rm cheap_ocr
