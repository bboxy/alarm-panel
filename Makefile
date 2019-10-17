CFLAGS = -Wall -O3
CC = gcc

.PHONY: all clean

all: cheap_ocr

cheap_ocr: cheap_ocr.c
	$(CC) $< -o $@ $(CFLAGS) -ltiff

clean:
	-rm cheap_ocr
