/* What Resample.c needs of libImaging, in a page: images are one block of
 * lines, a pixel is one byte ("L") or four ("LA", "RGB", "RGBA" -- Pillow
 * keeps three-band pixels in four bytes), sections are nothing without a
 * GIL, and an error is a message kept for the caller. Then the entry
 * library(opencv) calls, which lays a Mat's bytes into that shape and takes
 * the resampled ones back. Resample.c itself is Pillow's, unchanged. */
#include "Imaging.h"

static const char *pil_error = NULL;

void ImagingSectionEnter(ImagingSectionCookie *cookie) { (void)cookie; }
void ImagingSectionLeave(ImagingSectionCookie *cookie) { (void)cookie; }

void *ImagingError_MemoryError(void) { pil_error = "out of memory"; return NULL; }
void *ImagingError_ModeError(void) { pil_error = "unsupported image mode"; return NULL; }
void *ImagingError_ValueError(const char *message) { pil_error = message; return NULL; }

Imaging
ImagingNewDirty(const char *mode, int xsize, int ysize) {
    Imaging im;
    int y;
    if (xsize < 0 || ysize < 0 || strlen(mode) >= IMAGING_MODE_LENGTH) {
        return (Imaging)ImagingError_ValueError("bad image size or mode");
    }
    im = (Imaging)calloc(1, sizeof(struct ImagingMemoryInstance));
    if (!im) {
        return (Imaging)ImagingError_MemoryError();
    }
    strcpy(im->mode, mode);
    im->type = IMAGING_TYPE_UINT8;
    im->bands = (int)strlen(mode);          /* L 1, LA 2, RGB 3, RGBA 4 */
    im->pixelsize = im->bands == 1 ? 1 : 4;
    im->xsize = xsize;
    im->ysize = ysize;
    im->linesize = xsize * im->pixelsize;
    im->block = (char *)calloc(ysize > 0 ? (size_t)ysize : 1, im->linesize > 0 ? (size_t)im->linesize : 1);
    im->image = (char **)calloc(ysize > 0 ? (size_t)ysize : 1, sizeof(char *));
    if (!im->block || !im->image) {
        ImagingDelete(im);
        return (Imaging)ImagingError_MemoryError();
    }
    for (y = 0; y < ysize; y++) {
        im->image[y] = im->block + (size_t)y * (size_t)im->linesize;
    }
    if (im->pixelsize == 1) {
        im->image8 = (UINT8 **)im->image;
    } else {
        im->image32 = (INT32 **)im->image;
    }
    return im;
}

Imaging
ImagingCopy(Imaging im) {
    Imaging out = ImagingNewDirty(im->mode, im->xsize, im->ysize);
    if (out && im->ysize > 0 && im->linesize > 0) {
        memcpy(out->block, im->block, (size_t)im->ysize * (size_t)im->linesize);
    }
    return out;
}

void
ImagingDelete(Imaging im) {
    if (!im) {
        return;
    }
    free(im->block);
    free(im->image);
    free(im);
}

const char *
pil_resample_8u(const unsigned char *src, int w, int h, int channels, size_t step,
                int outw, int outh, int filter,
                unsigned char *dst, size_t dststep) {
    const char *mode = channels == 1 ? "L" : channels == 3 ? "RGB" : channels == 4 ? "RGBA" : NULL;
    Imaging in, out;
    float box[4];
    int x, y, c;
    if (!mode) {
        return "cv_resample: 1, 3 or 4 channels of 8 bits";
    }
    if (outw < 1 || outh < 1) {
        return "cv_resample: the size must be positive";
    }
    pil_error = NULL;
    in = ImagingNewDirty(mode, w, h);
    if (!in) {
        return pil_error ? pil_error : "cv_resample: out of memory";
    }
    for (y = 0; y < h; y++) {
        const unsigned char *s = src + (size_t)y * step;
        if (channels == 1) {
            memcpy(in->image8[y], s, (size_t)w);
        } else {
            unsigned char *d = (unsigned char *)in->image[y];
            for (x = 0; x < w; x++) {
                for (c = 0; c < channels; c++) {
                    d[x * 4 + c] = s[x * channels + c];
                }
            }
        }
    }
    box[0] = 0; box[1] = 0; box[2] = (float)w; box[3] = (float)h;
    out = ImagingResample(in, outw, outh, filter, box);
    ImagingDelete(in);
    if (!out) {
        return pil_error ? pil_error : "cv_resample: resampling failed";
    }
    for (y = 0; y < outh; y++) {
        unsigned char *d = dst + (size_t)y * dststep;
        if (channels == 1) {
            memcpy(d, out->image8[y], (size_t)outw);
        } else {
            const unsigned char *s = (const unsigned char *)out->image[y];
            for (x = 0; x < outw; x++) {
                for (c = 0; c < channels; c++) {
                    d[x * channels + c] = s[x * 4 + c];
                }
            }
        }
    }
    ImagingDelete(out);
    return NULL;
}
