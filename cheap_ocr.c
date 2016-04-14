#include "tiffio.h"
#include <stdlib.h>
#include <locale.h>
#include <stdio.h>
#include <wchar.h>
#include <string.h>

// Achieve UTF-8 output
const static wchar_t char_tab[] = L"abcdefghijklmnopqrstuvwxyzäöüß.:-/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ (){}";
const static int font_size = 78;

// Char dimensions
#define CHAR_WIDTH	21
#define CHAR_HEIGHT	32

#define PWIDTH		1724
#define PHEIGHT		2438

#define X_START		0
#define Y_START		45

typedef struct {
    int y_offset;
    int x_offset;
    int width;
    int height;
} letter;

int find_best_char(char* font, char* fax, unsigned fwidth, unsigned width, int x, int y) {
    int fax_pos = x + y * width;
    int x_, y_;

    int best_index = -1;
    int best_err = -1;

    int index;
    int err;

    for (index = 0; index < font_size; index++) {
    	err = 0;
        for (y_ = 0; y_ < CHAR_HEIGHT; y_++) {
            for (x_ = 0; x_ < CHAR_WIDTH; x_++) {
                err += abs(fax[fax_pos + x_ + y_ * width] - font[index * CHAR_WIDTH + x_ + y_ * fwidth]);
            }
            if (best_err > 0 && err >= best_err) break;
        }

        if (best_err < 0 || err < best_err) {
            best_err = err;
            best_index = index;
        }

        // Perfect match, no need to seek further
        if (err == 0) break;
    }
    return best_index;
}

int main(int argc, char* argv[]) {
    int xoffset = 0;
    int yoffset = 0;
    unsigned fwidth;
    unsigned fheight;
    unsigned fpixels;
    unsigned* fdata;

    unsigned width;
    unsigned height;
    unsigned pixels;
    unsigned* data;

    TIFF* font = NULL;
    TIFF* fax = NULL;

    char* output_name = NULL;
    char* fax_name = NULL;
    char* font_name = NULL;

    FILE* fw = NULL;

    int x, y;
    int best_index;
    int i;

    char* font_data;
    char* fax_data;

    int page;
    int pheight;

    letter font_sym[font_size];

    setlocale(LC_ALL, "");

    if (argc != 6) {
        fprintf(stderr, "Usage: %s -f [font.tif] -o [output file] [file.tif]\n", *argv);
        exit (2);
    }
    while (++argv, --argc) {
        if (argc >= 2 && !strcmp(*argv, "-o")) {
            output_name = *++argv;
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-f")) {
            font_name = *++argv;
            argc--;
        } else {
            break;
        }
    }

    fax_name = *argv;

    // Fetch our charset
    font = TIFFOpen(font_name, "r");
    if (!font) {
        exit (2);
    }

    TIFFGetField(font, TIFFTAG_IMAGEWIDTH, &fwidth);
    TIFFGetField(font, TIFFTAG_IMAGELENGTH, &fheight);
    fpixels = fwidth*fheight;
    fdata = (unsigned int*) _TIFFmalloc(fpixels *sizeof(unsigned int));
    font_data = (char*) malloc(fpixels *sizeof(char));
    TIFFReadRGBAImage(font, fwidth, fheight, fdata, 0);

    // Reduce pixeldepth and copy to array for faster access later on
    for (y = 0; y <fheight; y++) {
        for (x = 0; x < fwidth; x++) {
            //also mirror in y
            font_data[x + y * fwidth] = (TIFFGetG(fdata[x + (fheight - y - 1) * fwidth]) == 0);
        }
    }

    _TIFFfree(fdata);
    TIFFClose(font);

    for (i = 0; i < font_size; i++) {
        font_sym[i].y_offset = 0;
        font_sym[i].x_offset = 0;

        for (y = 0; y < CHAR_HEIGHT; y++) {
            for (x = 0; x < CHAR_WIDTH; x++) {
                if (font_data[i * CHAR_WIDTH + x + y * fwidth]) break;
            }
            if (x != CHAR_WIDTH) break;
            else font_sym[i].y_offset++;
        }

        for (x = 0; x < CHAR_WIDTH; x++) {
            for (y = 0; y < CHAR_HEIGHT; y++) {
                if (font_data[i * CHAR_WIDTH + x + y * fwidth]) break;
            }
            if (y != CHAR_HEIGHT) break;
            else font_sym[i].x_offset++;
        }

        font_sym[i].height = CHAR_HEIGHT - font_sym[i].y_offset;
        font_sym[i].width  = CHAR_WIDTH  - font_sym[i].x_offset;

        for (y = CHAR_HEIGHT - 1; y >= 0; y--) {
            for (x = 0; x < CHAR_WIDTH; x++) {
                if (font_data[i * CHAR_WIDTH + x + y * fwidth]) break;
            }
            if (x != CHAR_HEIGHT) break;
            else font_sym[i].height--;
        }

        for (x = CHAR_WIDTH - 1; x >= 0; x--) {
            for (y = 0; y < CHAR_HEIGHT; y++) {
                if (font_data[i * CHAR_WIDTH + x + y * fwidth]) break;
            }
            if (y != CHAR_HEIGHT) break;
            else font_sym[i].width--;
        }
//        wprintf(L"%lc  x: %d y: %d w: %d h: %d\n", char_tab[i], font_sym[i].x_offset, font_sym[i].y_offset, font_sym[i].width, font_sym[i].height);
    }

    // Fetch fax tif
    fax = TIFFOpen(fax_name, "r");
    if (!fax) {
        exit (2);
    }
    TIFFGetField(fax, TIFFTAG_IMAGEWIDTH, &width);
    TIFFGetField(fax, TIFFTAG_IMAGELENGTH, &height);
    pixels = width*height;
    data = (unsigned int*) _TIFFmalloc(pixels *sizeof(unsigned int));
    fax_data = (char*) malloc(pixels *sizeof(char));
    TIFFReadRGBAImage(fax, width, height, data, 0);

    // Transfer tif to own dataset and mirror in y
    for (y = 0; y <height; y++) {
        for (x = 0; x < width; x++) {
            fax_data[x + y * width] = (TIFFGetG(data[x + (height - y - 1) * width]) == 0);
        }
    }

    _TIFFfree(data);
    TIFFClose(fax);

    fw = fopen(output_name, "w");

    for (page = 0; page < height; page += PHEIGHT) {
        if (page + PHEIGHT < height) pheight = page + PHEIGHT;
	else pheight = height;

        // Find first line that contains set pixels
        for (y = Y_START + page; y < pheight; y++) {
            for (x = X_START; x < width; x++) {
                if (fax_data[x + y * width]) break;
            }
            if (x != width) {
                yoffset = y - 3;
                break;
            }
        }

        // Find first column that contains set pixels
        for (x = X_START; x < width; x++) {
            for (y = page + Y_START; y < pheight; y++) {
                if (fax_data[x + y * width]) break;
            }
            if (y != pheight) {
                xoffset = 63;//x - 4 + CHAR_WIDTH;
                break;
            }
        }
        wprintf(L"first chars @ y=%d x=%d\n",yoffset,xoffset);

        // Now match all chars against each cell in grid and emit matches
        for (y = yoffset; y < pheight - CHAR_HEIGHT; y += CHAR_HEIGHT) {
            for (x = xoffset; x < width; x += CHAR_WIDTH) {
                best_index = find_best_char(font_data, fax_data, fwidth, width, x, y);
                fwprintf(fw, L"%lc", char_tab[best_index]);
                wprintf(L"%lc", char_tab[best_index]);
            }
            fwprintf(fw, L"\n");
            wprintf(L"\n");
        }
    }
    fclose(fw);

    free(font_data),
    free(fax_data);

    return 0;
}
