/*
 * fontconv - converter between a PNG image and a binary font file.
 *
 * Copyright (C) 2021 Ivan Tatarinov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: Copyright (C) 2021 Ivan Tatarinov
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <stdarg.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lodepng.h"

#define PROGRAM "fontconv"
#define DESCRIPTION "PNG image <=> binary font file converter."
#define VERSION "0.1"
#define COPYRIGHT "Copyright (C) 2021 Ivan Tatarinov"
#define LICENSE                                                              \
"This program is free software: you can redistribute it and/or modify\n"     \
"it under the terms of the GNU General Public License as published by\n"     \
"the Free Software Foundation, either version 3 of the License, or\n"        \
"(at your option) any later version."
#define HOMEPAGE "<https://github.com/zxdos/zxuno/>"
#define THIRDPARTY                                                           \
"LodePNG library: <https://github.com/lvandeve/lodepng/>\n"                  \
"License: Zlib. Copyright (c) 2005-2021 Lode Vandevenne"

#define HELP_HINT                                                            \
"Use \"-h\" to get help."

/* Options */
const char *opt_fi = NULL;  /* filename (input) */
const char *opt_fo = NULL;  /* filename (output) */
unsigned opt_cwi = 8; /* character width (input) */
unsigned opt_chi = 8; /* character height (input) */
unsigned opt_cwo = 0; /* character width (output) - same as input by default */
unsigned opt_cho = 0; /* character height (output) - same as input by default */
unsigned opt_cpl = 16;  /* characters per line count (output) */
bool opt_help = false;
bool opt_decode = false;
bool opt_vertical = false;
bool opt_verbose = true;

/* Type of image */
#define IMGT_RAW 0
#define IMGT_PNG 1

struct image_t {
  unsigned type;
  unsigned char *data;  /* image data */
  size_t size;  /* image data size */
  unsigned w;   /* image width */
  unsigned h;   /* image height */
  char *filename;
};

struct font_t {
  unsigned char *data;  /* font data */
  size_t size;  /* font data size */
  unsigned cw;  /* character width */
  unsigned ch;  /* character height */
  char *filename;
};

void show_usage () {
  printf (
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
  );
  printf (
    "Third-party software used:\n"
    THIRDPARTY "\n"
  );
  printf (
    "\n"
    "Usage:\n"
    "  " PROGRAM " [options ...] input output\n"
  );
  printf (
    "\n"
    "Options:\n"
    "  -h      Show this help\n"
    "  -q      Quiet output (default is verbose output)\n"
    "  -d      Decode binary font file into an image (default is encode mode)\n"
    "  -r      Rotate input characters for vertical output\n"
    "  -f WxH  Input character size: W=width, H=height (default is %ux%u)\n"
    "  -t WxH  Output character size: W=width, H=height (defaults to \"-f\")\n"
    "  -c N    Output N characters per line in output image (default is %u)\n",
    opt_cwi,
    opt_chi,
    opt_cpl
  );
  printf (
    "\n"
    "  input   Input PNG image file (or binary font file in \"-d\" mode)\n"
    "  output  Output binary font file (or PNG image in \"-d\" mode)\n"
  );
  printf (
    "\n"
    "Input image width must be a multiple of input character's width.\n"
    "Input image height must be a multiple of input character's height.\n"
    "Input and output color for background is pure black (i.e. R=G=B=0).\n"
    "Input ink color is any other. Output ink color is pure white.\n"
  );
}

void error (const char *format, ...) {
  va_list ap;

  va_start (ap, format);
  fprintf (stderr, PROGRAM ": ERROR: ");
  vfprintf (stderr, format, ap);
  fprintf (stderr, "\n");
  va_end (ap);
}

void error_missing_arg (const char *name, unsigned index) {
  error ("Missing parameter for \"%s\" (argument %u).", name, index);
}

void error_bad_arg (const char *name, unsigned index) {
  error ("Bad parameter value for \"%s\" (argument %u).", name, index);
}

void error_malloc (size_t size) {
  error ("Failed to allocate %lu bytes of memory", size);
}

/* Returns 0 on success, -1 on error */
int parse_arg_long (long *a, const char *arg) {
  long _a;
  char *endptr;

  _a = strtol (arg, &endptr, 10);
  if (errno || !endptr) return -1;

  *a = _a;
  return 0;
}

/* Returns 0 on success, -1 on error */
int parse_arg_long_x_long (long *a, long *b, const char *arg) {
  long _a, _b;
  char *xptr, *endptr;

  xptr = strchr (arg, 'x');
  if (!xptr || (xptr == arg)) return -1;

  _a = strtol (arg, &endptr, 10);
  if (errno || (endptr != xptr)) return -1;

  _b = strtol (xptr + 1, &endptr, 10);
  if (errno || !endptr) return -1;

  *a = _a;
  *b = _b;
  return 0;
}

/* Returns 0 on success, -1 on error, 1 if no arguments */
int parse_args (int argc, char *argv[]) {
  int i, f;

  if (argc == 1) return 1;

  i = 1;
  f = 0;
  while (i < argc) {
    if (argv[i][0] == '-') {
      if (strcmp (&argv[i][1], "h") == 0) opt_help = true;
      else if (strcmp (&argv[i][1], "q") == 0) opt_verbose = false;
      else if (strcmp (&argv[i][1], "d") == 0) opt_decode = true;
      else if (strcmp (&argv[i][1], "r") == 0) opt_vertical = true;
      else if (strcmp (&argv[i][1], "f") == 0) {
        long a, b;
        if (i + 1 == argc) error_missing_arg (argv[i], i);

        if (parse_arg_long_x_long (&a, &b, argv[i + 1])
        ||  (a <= 0) || (b <= 0)) {
          error_bad_arg (argv[i], i);
          return -1;
        }

        opt_cwi = a;
        opt_chi = b;
        i++;

      } else if (strcmp (&argv[i][1], "t") == 0) {
        long a, b;
        if (i + 1 == argc) error_missing_arg (argv[i], i);

        if (parse_arg_long_x_long (&a, &b, argv[i + 1])
        ||  (a < 0) || (b < 0)) {
          error_bad_arg (argv[i], i);
          return -1;
        }

        if (a) opt_cwo = a;
        if (b) opt_cho = b;
        i++;

      } else if (strcmp (&argv[i][1], "c") == 0) {
        long a;
        if (i + 1 == argc) error_missing_arg (argv[i], i);

        if (parse_arg_long (&a, argv[i + 1])
        ||  (a <= 0)) {
          error_bad_arg (argv[i], i);
          return -1;
        }

        opt_cpl = a;
        i++;

      } else {
        error ("Unknown option \"%s\" (argument %u)", argv[i], i);
        return -1;
      }

    } else {
      switch (f++) {
        case 0: opt_fi = argv[i]; break;
        case 1: opt_fo = argv[i]; break;
        default:
          error ("Extra parameter \"%s\" given (argument %u)", argv[i], i);
          return -1;
      }
    }
    i++;
  }

  return 0;
}

/* Miscellaneous */

/* Returns 0 on success, -1 on error */
int str_dup (char **dest, const char *src) {
  bool differs = *dest && src && strcmp (*dest, src);

  if ((*dest && !src) || differs) {
    free (*dest);
    *dest = NULL;
  }

  if ((!*dest && src) || differs) {
    unsigned len = strlen (src);
    *dest = malloc (len + 1);
    if (!*dest) {
      error_malloc (len + 1);
      return -1;
    }
    if (len)
      memcpy (*dest, src, len);
    (*dest)[len] = '\0';
  }

  return 0;
}

/* Returns 0 on success, -1 on error */
int file_load (unsigned char **out_data, size_t *out_size, const char *filename) {
  FILE *f;
  unsigned char *data = NULL;
  size_t size;

  f = fopen (filename, "rb");
  if (!f) {
    error ("Failed to open file \"%s\"", filename);
    goto error_exit;
  }

  if (fseek (f, 0, SEEK_END)) {
    error ("Failed to seek in file \"%s\"", filename);
    goto error_exit;
  }

  size = ftell (f);
  if (errno) {
    error ("Failed to get file \"%s\" size", filename);
    goto error_exit;
  }

  if (size) {
    data = malloc (size);
    if (!data) {
      error_malloc (size);
      goto error_exit;
    }

    rewind (f);

    if (!fread (data, size, 1, f)) {
      error ("Failed to read file \"%s\"", filename);
      goto error_exit;
    }
  }

  fclose (f);

  *out_data = data;
  *out_size = size;
  return 0;

error_exit:
  if (f) fclose (f);
  if (data) free (data);
  return -1;
}

/* Returns 0 on success, -1 on error */
int file_save (unsigned char *data, size_t size, const char *filename) {
  FILE *f;
  int err;

  f = fopen (filename, "w+b");
  if (!f) {
    error ("Failed to create file \"%s\"", filename);
    return -1;
  }

  if (size && !fwrite (data, size, 1, f)) {
    error ("Failed to write file \"%s\"", filename);
    err = -1;
  } else
    err = 0;

  fclose (f);
  return err;
}

/* Image */

struct image_t *image_new () {
  struct image_t *self = calloc (sizeof (struct image_t), 1);
  if (!self) error_malloc (sizeof (struct image_t));
  return self;
}

void image_free (struct image_t *self) {
  if (self->filename) {
    free (self->filename);
    self->filename = NULL;
  }
  if (self->data) {
    free (self->data);
    self->data = NULL;
  }
}

void image_dispose (struct image_t **self) {
  if (*self) {
    image_free (*self);
    free (*self);
    *self = NULL;
  }
}

/* Returns 0 on success, -1 on error */
int image_set_filename (struct image_t *self, const char *filename) {
  return str_dup (&self->filename, filename);
}

/* Returns 0 on success, -1 on error */
int image_import_png (struct image_t *self, const char *filename) {
  unsigned err;

  if (image_set_filename (self, filename)) return -1;

  err = lodepng_decode_file (&self->data, &self->w, &self->h, filename, LCT_GREY, 8);
  if (err) {
    error ("Failed to load file \"%s\" (PNG loader error %u: %s)",
      filename, err, lodepng_error_text (err));
    return -1;
  }

  self->type = IMGT_RAW;
  self->size = self->w * self->h;
  return 0;
}

/* Returns 0 on success, -1 on error */
int image_check_data (struct image_t *self) {
  if ((self->type == IMGT_RAW) && self->data && self->size)
    return 0;
  else {
    if (self->filename)
      error ("Bad image's \"%s\" data", self->filename);
    else
      error ("Bad image's data");
    return -1;
  }
}

/* Returns 0 on success, -1 on error */
int image_check_char_size (struct image_t *self, unsigned cw, unsigned ch) {
  if (cw && ch)
    return 0;
  else {
    if (self->filename)
      error ("Bad image's \"%s\" character size", self->filename);
    else
      error ("Bad image's character size");
    return -1;
  }
}

/* Returns 0 on success, -1 on error */
int image_check_params (struct image_t *self, unsigned cw, unsigned ch) {
  if (self->w && self->h && cw && ch
  &&  ((self->w % cw) == 0)
  &&  ((self->h % ch) == 0))
    return 0;
  else {
    if (self->filename)
      error ("Bad image's \"%s\" size or character's size", self->filename);
    else
      error ("Bad image's size or character's size");
    return -1;
  }
}

int font_check_data (struct font_t *self);
int font_check_char_size (struct font_t *self);

/* Returns 0 on success, -1 on error */
int image_convert_from_font (struct image_t *self,
  unsigned cwo, unsigned cho, unsigned wco, bool rotate, struct font_t *font) {

  unsigned ls, cs, c, w, hc, s, cw, ch, n, y;
  unsigned dmax, kmax, dj0, dj;
  unsigned char *p, *src;

  if (font_check_data (font)
  ||  font_check_char_size (font)
  ||  image_check_char_size (self, cwo, cho))
    return -1;

  if (!rotate) {
    /* input character line size (horizontal) in bytes */
    ls = (font->cw + 7) >> 3;
    /* input character size in bytes */
    cs = ls * font->ch;
  } else {
    /* width and height are swapped */
    ls = (font->ch + 7) >> 3;
    cs = ls * font->cw;
  }
  /* input characters count */
  c = font->size / cs;
  if ((font->size % cs) || (c % wco)) {
    error ("Bad font or character size");
    return -1;
  }

  /* output image width in pixels */
  w = cwo * wco;
  /* output image height in characters */
  hc = c / wco;
  /* output image size in bytes */
  s = w * cho * hc;
  p = calloc (s, 1);
  if (!p) {
    error_malloc (s);
    return -1;
  }

  /* input character width to convert into output */
  cw = font->cw;
  if (cw > cwo) cw = cwo;
  /* input character height to convert into output */
  ch = font->ch;
  if (ch > cho) ch = cho;

  src = font->data;

  if (!rotate) {
    dmax = ch;
    kmax = cw;
    dj0 = w;
    dj = 1;
  } else {
    /* width and height are swapped */
    dmax = cw;
    kmax = ch;
    dj0 = 1;
    dj = w;
  }

  /* current character offset */
  n = 0;
  for (y = 0; y < hc; y++) {
    unsigned x;

    for (x = 0; x < wco; x++) {
      unsigned i0 = n;
      unsigned j0 = w * cho * y + cwo * x;
      unsigned d;

      for (d = 0; d < dmax; d++) {
        unsigned i = i0;
        unsigned j = j0;
        unsigned k = kmax;

        /* Convert whole bytes */
        while (k >= 8) {
          unsigned char a = src[i++];
          unsigned char l = 8;
          do {
            p[j] = (a & 128) ? 255 : 0;
            j += dj;
            a <<= 1;
            l--;
          } while (a && l);
          if (l)  /* skip the rest if any */
            j += dj * l;
          k -= 8;
        }

        /* Partially convert last byte */
        if (k) {
          unsigned char a = src[i++];
          do {
            p[j] = (a & 128) ? 255 : 0;
            j += dj;
            a <<= 1;
            k--;
          } while (a && k);
        }

        i0 += ls;
        j0 += dj0;
      }

      n += cs;
    }
  }

  self->type = IMGT_RAW;
  self->data = p;
  self->size = s;
  self->w = w;
  self->h = cho * hc;
  return 0;
}

/* Returns 0 on success, -1 on error */
int image_convert_to_png (struct image_t *self, struct image_t *image) {
  unsigned err;

  if (image_check_data (image)) return -1;

  err = lodepng_encode_memory (&self->data, &self->size,
    image->data, image->w, image->h, LCT_GREY, 8);

  if (err) {
    error ("Failed to encode image data (PNG encoder error %u: %s)",
      err, lodepng_error_text (err));
    return -1;
  }

  self->type = IMGT_PNG;
  return 0;
}

/* Returns 0 on success, -1 on error */
int image_save (struct image_t *self, const char *filename) {
  if (image_set_filename (self, filename)) return -1;
  return file_save (self->data, self->size, filename);
}

/* Font */

struct font_t *font_new () {
  struct font_t *self = calloc (sizeof (struct font_t), 1);
  if (!self) error_malloc (sizeof (struct font_t));
  return self;
}

void font_free (struct font_t *self) {
  if (self->filename) {
    free (self->filename);
    self->filename = NULL;
  }
  if (self->data) {
    free (self->data);
    self->data = NULL;
  }
}

void font_dispose (struct font_t **self) {
  if (*self) {
    font_free (*self);
    free (*self);
    *self = NULL;
  }
}

/* Returns 0 on success, -1 on error */
int font_set_filename (struct font_t *self, const char *filename) {
  return str_dup (&self->filename, filename);
}

/* Returns 0 on success, -1 on error */
int font_load (struct font_t *self, const char *filename) {
  if (font_set_filename (self, filename)) return -1;
  return file_load (&self->data, &self->size, filename);
}

/* Returns 0 on success, -1 on error */
int font_save (struct font_t *self, const char *filename) {
  if (font_set_filename (self, filename)) return -1;
  return file_save (self->data, self->size, filename);
}

/* Returns 0 on success, -1 on error */
int font_check_data (struct font_t *self) {
  if (self->data && self->size)
    return 0;
  else {
    if (self->filename)
      error ("Bad font's \"%s\" data", self->filename);
    else
      error ("Bad font's data");
    return -1;
  }
}

/* Returns 0 on success, -1 on error */
int font_check_char_size (struct font_t *self) {
  if (self->cw && self->ch)
    return 0;
  else {
    if (self->filename)
      error ("Bad font's \"%s\" character size", self->filename);
    else
      error ("Bad font's character size");
    return -1;
  }
}

/* Set the values of "cw" and "ch" members of "self" structure before call */
/* Returns 0 on success, -1 on error */
int font_convert_from_image (struct font_t *self,
  struct image_t *image, unsigned cwi, unsigned chi, bool rotate) {

  unsigned wc, hc, c, ls, cs, s, cw, ch, n, y;
  unsigned dmax, kmax, dj0, dj;
  unsigned char *p, *src;

  if (image_check_data (image)
  ||  image_check_params (image, cwi, chi)
  ||  font_check_char_size (self))
    return -1;

  /* input image width in characters */
  wc = image->w / cwi;
  /* input image height in characters */
  hc = image->h / chi;
  /* input characters count */
  c = wc * hc;

  if (!rotate) {
    /* output character line size (horizontal) in bytes */
    ls = (self->cw + 7) >> 3;
    /* output character size in bytes */
    cs = ls * self->ch;
  } else {
    /* width and height are swapped */
    ls = (self->ch + 7) >> 3;
    cs = ls * self->cw;
  }
  /* output font size in bytes */
  s = cs * c;
  p = calloc (s, 1);
  if (!p) { error_malloc (s); return -1; }

  /* input character width to convert into output */
  cw = cwi;
  if (cw > self->cw) cw = self->cw;
  /* input character height to convert into output */
  ch = chi;
  if (ch > self->ch) ch = self->ch;

  src = image->data;

  if (!rotate) {
    dmax = ch;
    kmax = cw;
    dj0 = image->w;
    dj = 1;
  } else {
    /* width and height are swapped */
    dmax = cw;
    kmax = ch;
    dj0 = 1;
    dj = image->w;
  }

  /* current character offset */
  n = 0;
  for (y = 0; y < hc; y++) {
    unsigned x;

    for (x = 0; x < wc; x++) {
      unsigned i0 = n;
      unsigned j0 = image->w * chi * y + cwi * x;
      unsigned d;

      for (d = 0; d < dmax; d++) {
        unsigned i = i0, j = j0, k = kmax;

        /* Convert whole bytes */
        while (k >= 8) {
          unsigned char a = 0, l = 8;
          do {
            a = (a << 1) | (src[j] ? 1 : 0);
            j += dj;
          } while (--l);
          p[i++] = a;
          k -= 8;
        }

        /* Partially convert last byte */
        if (k) {
          unsigned char a = 0, l = 8 - k;
          do {
            a = (a << 1) | (src[j] ? 1 : 0);
            j += dj;
          } while (--k);
          p[i++] = a << l;
        }

        i0 += ls;
        j0 += dj0;
      }

      n += cs;
    }
  }

  self->data = p;
  self->size = s;
  return 0;
}

/* import_png => "image" => encode => "font" => save */
/* Returns 0 on success, -1 on error */
int encode () {
  struct image_t *image = NULL;
  struct font_t *font = NULL;

  image = image_new ();
  if (!image) goto error_exit;

  if (image_import_png (image, opt_fi)) goto error_exit;

  font = font_new ();
  if (!font) goto error_exit;

  font->cw = opt_cwo;
  font->ch = opt_cho;

  if (font_set_filename (font, opt_fo)) goto error_exit;

  if (font_convert_from_image (font, image, opt_cwi, opt_chi, opt_vertical))
    goto error_exit;

  image_dispose (&image);

  if (font_save (font, font->filename)) goto error_exit;

  font_dispose (&font);

  if (opt_verbose)
    printf ("Converted %s \"%s\" into %s \"%s\"\n",
      "image file", opt_fi, "binary font file", opt_fo);
  return 0;

error_exit:
  image_dispose (&image);
  font_dispose (&font);
  return -1;
}

/* load => "font" => decode => "image" => convert_to_png => "png" => save */
/* Returns 0 on success, -1 on error */
int decode () {
  struct font_t *font = NULL;
  struct image_t *image = NULL;
  struct image_t *png = NULL;

  font = font_new ();
  if (!font) goto error_exit;

  font->cw = opt_cwi;
  font->ch = opt_chi;

  if (font_load (font, opt_fi)) goto error_exit;

  image = image_new ();
  if (!image) goto error_exit;

  if (image_set_filename (image, opt_fo)) goto error_exit;

  if (image_convert_from_font (image,
    opt_cwo, opt_cho, opt_cpl, opt_vertical, font)) goto error_exit;

  font_dispose (&font);

  png = image_new ();
  if (!png) goto error_exit;

  if (image_set_filename (png, opt_fo)) goto error_exit;

  if (image_convert_to_png (png, image)) goto error_exit;

  image_dispose (&image);

  if (image_save (png, png->filename)) goto error_exit;

  image_dispose (&png);

  if (opt_verbose)
    printf ("Converted %s \"%s\" into %s \"%s\"\n",
      "binary font file", opt_fi, "image file", opt_fo);
  return 0;

error_exit:
  font_dispose (&font);
  image_dispose (&image);
  image_dispose (&png);
  return -1;
}

int main (int argc, char **argv) {
  int err;

  err = parse_args (argc, argv);
  switch (err) {
    case 0: break;
    case 1:
      error ("No parameters. " HELP_HINT);
      return 0;
    default:
      return -1;
  }

  if (opt_help) {
    show_usage ();
    return 0;
  }

  if (!opt_fi) {
    error ("No %s specified", "input filename");
    return -1;
  }
  if (!opt_fo) {
    error ("No %s specified", "output filename");
    return -1;
  }

  if (!opt_cwo) opt_cwo = opt_cwi;
  if (!opt_cho) opt_cho = opt_chi;

  if (opt_decode) {
    if (decode ()) return -1;
  } else {
    if (encode ()) return -1;
  }

  return 0;
}
