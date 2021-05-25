/*
 * dzx7b - LZ77/LZSS backwards decompressor.
 *
 * Copyright (c) 2015 Einar Saukas. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * The name of its author may not be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * SPDX-FileCopyrightText: Copyright (c) 2015 Einar Saukas. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * SPDX-LicenseComments: License's text equals to one from https://directory.fsf.org/wiki/License:BSD-3-Clause
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROGRAM "dzx7b"
#define DESCRIPTION "LZ77/LZSS backwards decompressor."
#define VERSION "1.0 (2015)"
#define COPYRIGHT "Copyright (c) 2015 Einar Saukas. All rights reserved."
#define LICENSE "Distributed under BSD 3-clause license."
#define HOMEPAGE "https://github.com/antoniovillena/zx7b/"

FILE *ifp;
FILE *ofp;
char *input_name;
char *output_name;
unsigned char *input_data;
unsigned char *output_data;
size_t input_index;
size_t output_index;
size_t input_size;
size_t output_size;
size_t partial_counter;
size_t total_counter;
int bit_mask;
int bit_value;

int read_byte() {
    return input_data[input_index++];
}

int read_bit() {
    bit_mask >>= 1;
    if (bit_mask == 0) {
        bit_mask = 128;
        bit_value = read_byte();
    }
    return bit_value & bit_mask ? 1 : 0;
}

int read_elias_gamma() {
    int i;
    int value;

    value = 1;
    while (!read_bit()) {
        value = value << 1 | read_bit();
    }
    if( (value&255)==255 )
      value= -1;
    return value;
}

int read_offset() {
    int value;
    int i;

    value = read_byte();
    if (value < 128) {
        return value;
    } else {
        i = read_bit();
        i = i << 1 | read_bit();
        i = i << 1 | read_bit();
        i = i << 1 | read_bit();
        return (value & 127 | i << 7) + 128;
    }
}

void write_byte(int value) {
    output_data[output_index++] = value;
}

void write_bytes(int offset, int length) {
    if (offset > output_size+output_index) {
        fprintf(stderr, "Error: Invalid data in input file %s\n", input_name);
        exit(1);
    }
    while (length-- > 0) {
        write_byte(output_data[output_index-offset]);
    }
}

void decompress() {
    int length,i;

    input_index = 0;
    partial_counter = 0;
    output_index = 0;
    bit_mask = 0;

    write_byte(read_byte());
    while (1) {
        if (!read_bit()) {
            write_byte(read_byte());
        } else {
            length = read_elias_gamma()+1;
            if (length == 0) {
                return;
            }
            write_bytes(read_offset()+1, length);
        }
    }
}

void show_help() {
    printf(
        PROGRAM " version " VERSION " - " DESCRIPTION "\n"
        COPYRIGHT "\n"
        LICENSE "\n"
        "Home page: " HOMEPAGE "\n"
        "\n"
        "Usage:\n"
        "  " PROGRAM " [-f] input.zx7 [output]\n"
        "\n"
        "  -f       Force overwrite of output file\n"
        "  output   Decompressed output file\n"
    );
}

int main(int argc, char *argv[]) {
    int forced_mode = 0;
    int i;

    /* process hidden optional parameters */
    for (i = 1; i < argc && *argv[i] == '-'; i++) {
        if (!strcmp(argv[i], "-f")) {
            forced_mode = 1;
        } else {
            fprintf(stderr, "Error: Invalid parameter `%s\'\n", argv[i]);
            exit(1);
        }
    }

    /* determine output filename */
    if (argc == i+1) {
        input_name = argv[i];
        input_size = strlen(input_name);
        if (input_size > 4 && !strcmp(input_name+input_size-4, ".zx7")) {
            output_name = (char *)malloc(input_size);
            strcpy(output_name, input_name);
            output_name[input_size-4] = '\0';
        } else {
            fprintf(stderr, "Error: Cannot infer output filename\n");
            exit(1);
        }
    } else if (argc == i+2) {
        input_name = argv[i];
        output_name = argv[i+1];
    } else {
        show_help();
        exit(1);
    }

    /* open input file */
    ifp = fopen(input_name, "rb");
    if (!ifp) {
        fprintf(stderr, "Error: Cannot access input file %s\n", input_name);
        exit(1);
    }

    /* determine input size */
    fseek(ifp, 0L, SEEK_END);
    input_size = ftell(ifp);
    fseek(ifp, 0L, SEEK_SET);
    if (!input_size) {
        fprintf(stderr, "Error: Empty input file %s\n", argv[1]);
        exit(1);
    }

    /* allocate input buffer */
    input_data = (unsigned char *)malloc(input_size);
    if (!input_data) {
        fprintf(stderr, "Error: Insufficient memory\n");
        exit(1);
    }

    /* read input file */
    total_counter = 0;
    do {
        partial_counter = fread(input_data+total_counter, sizeof(char), input_size-total_counter, ifp);
        total_counter += partial_counter;
    } while ( partial_counter > 0 );

    if (total_counter != input_size) {
        fprintf(stderr, "Error: Cannot read input file %s\n", argv[1]);
        exit(1);
    }

    /* check output file */
    if (!forced_mode && fopen(output_name, "rb") != NULL) {
        fprintf(stderr, "Error: Already existing output file %s\n", output_name);
        exit(1);
    }

    /* create output file */
    ofp = fopen(output_name, "wb");
    if (!ofp) {
        fprintf(stderr, "Error: Cannot create output file %s\n", output_name);
        exit(1);
    }

    /* reverse input data */
    for ( i= 0; i<input_size>>1; i++ ){
        partial_counter = input_data[i];
        input_data[i] = input_data[input_size-1-i];
        input_data[input_size-1-i] = partial_counter;
    }

    /* calculate output file size and allocate memory */
    output_size = 1;
    read_byte();
    while (1) {
        if (!read_bit()) {
            output_size++;
            read_byte();
        } else {
            i = read_elias_gamma()+1;
            if (i == 0) {
                break;
            }
            read_offset();
            output_size+= i;
        }
    }
    output_data = (unsigned char *)malloc(output_size);
    if (!output_data) {
        fprintf(stderr, "Error: Insufficient memory\n");
        exit(1);
    }

    /* decompress */
    decompress();

    /* reverse output data */
    for ( i= 0; i<output_size>>1; i++ ) {
      partial_counter= output_data[i];
      output_data[i]= output_data[output_size-1-i];
      output_data[output_size-1-i]= partial_counter;
    }

    /* write output file */
    if (fwrite(output_data, sizeof(char), output_size, ofp) != output_size) {
      fprintf(stderr, "Error: Cannot write output file %s\n", output_name);
      exit(1);
    }

    /* close input file */
    fclose(ifp);

    /* close output file */
    fclose(ofp);

    /* done! */
    printf("File `%s' converted from %lu to %lu bytes!\n",
        output_name, (unsigned long)input_size, (unsigned long)output_size);

    return 0;
}
