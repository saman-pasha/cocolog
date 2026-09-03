/* A shim of Pillow's libImaging/Imaging.h: exactly what Resample.c reads, and
 * nothing of Python. Resample.c beside it is Pillow 11.3.0's, unchanged (its
 * licence is LICENSE here); pil-resample.c supplies the functions declared
 * below and the one entry cocolog's library(opencv) calls, pil_resample_8u.
 *
 * Why it exists: Pillow's antialiased resize (a triangle, box, cubic or
 * Lanczos filter whose support scales with the reduction) has no equivalent
 * flag in OpenCV, and tutorial 42's figures were measured on its pixels. */
#ifndef COCO_PIL_IMAGING_H
#define COCO_PIL_IMAGING_H

#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define INT8 int8_t
#define UINT8 uint8_t
#define INT16 int16_t
#define UINT16 uint16_t
#define INT32 int32_t
#define UINT32 uint32_t
#define FLOAT32 float

/* from ImagingUtils.h, the one macro Resample.c takes from it */
#define CLIP8(v) ((v) <= 0 ? 0 : (v) < 256 ? (v) : 255)

#ifdef WORDS_BIGENDIAN
#define MAKE_UINT32(u0, u1, u2, u3) \
    ((UINT32)(u3) | ((UINT32)(u2) << 8) | ((UINT32)(u1) << 16) | ((UINT32)(u0) << 24))
#else
#define MAKE_UINT32(u0, u1, u2, u3) \
    ((UINT32)(u0) | ((UINT32)(u1) << 8) | ((UINT32)(u2) << 16) | ((UINT32)(u3) << 24))
#endif

#define IMAGING_TYPE_UINT8 0
#define IMAGING_TYPE_INT32 1
#define IMAGING_TYPE_FLOAT32 2
#define IMAGING_TYPE_SPECIAL 3

#define IMAGING_MODE_LENGTH (6 + 1)

typedef struct ImagingMemoryInstance *Imaging;

struct ImagingMemoryInstance {
    char mode[IMAGING_MODE_LENGTH]; /* "L", "LA", "RGB", "RGBA" */
    int type;                       /* IMAGING_TYPE_UINT8 here, always */
    int bands;                      /* 1, 2, 3 or 4 */
    int xsize;
    int ysize;
    UINT8 **image8;                 /* set when pixelsize is 1 */
    INT32 **image32;                /* set when pixelsize is 4 */
    char **image;                   /* the lines, either way */
    char *block;                    /* one allocation holding every line */
    int pixelsize;                  /* 1 or 4 */
    int linesize;                   /* xsize * pixelsize */
};

#define IMAGING_PIXEL_I(im, x, y) ((im)->image32[(y)][(x)])
#define IMAGING_PIXEL_F(im, x, y) (((FLOAT32 *)(im)->image32[y])[x])

typedef void *ImagingSectionCookie;
extern void ImagingSectionEnter(ImagingSectionCookie *cookie);
extern void ImagingSectionLeave(ImagingSectionCookie *cookie);

extern Imaging ImagingNewDirty(const char *mode, int xsize, int ysize);
extern Imaging ImagingCopy(Imaging im);
extern void ImagingDelete(Imaging im);

extern void *ImagingError_MemoryError(void);
extern void *ImagingError_ModeError(void);
extern void *ImagingError_ValueError(const char *message);

#define IMAGING_TRANSFORM_NEAREST 0
#define IMAGING_TRANSFORM_BOX 4
#define IMAGING_TRANSFORM_BILINEAR 2
#define IMAGING_TRANSFORM_HAMMING 5
#define IMAGING_TRANSFORM_BICUBIC 3
#define IMAGING_TRANSFORM_LANCZOS 1

extern Imaging ImagingResample(Imaging imIn, int xsize, int ysize, int filter, float box[4]);

/* The entry library(opencv) calls: `src' is h rows of w pixels of `channels'
 * bytes (1, 3 or 4), `step' bytes apart; `dst' receives outh rows of outw
 * pixels of the same shape, `dststep' apart; `filter' is an
 * IMAGING_TRANSFORM_* other than NEAREST. Answers NULL, or the message. */
extern const char *pil_resample_8u(const unsigned char *src, int w, int h, int channels, size_t step,
                                   int outw, int outh, int filter,
                                   unsigned char *dst, size_t dststep);

#endif
