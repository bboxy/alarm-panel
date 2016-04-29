CFLAGS = -Wall -O3
CC = gcc

.PHONY: all clean

all: cheap_ocr fms_decoder

cheap_ocr: cheap_ocr.c
	$(CC) $< -o $@ $(CFLAGS) -ltiff

fms_decoder: fms_decoder.c
	$(CC) $< -o $@ $(CFLAGS) -lm

clean:
	-rm cheap_ocr fms_decoder
