/* cocolog -- modules/ray/gesture.h: the trackpad pinch's C face.
 *
 * Defined in gesture_macos.m (a Cocoa NSEvent monitor) or gesture_none.c
 * (always 1.0). ray.c includes this header so the generated C has the
 * prototype; Cicili's binding only informs its type inference.
 */
#ifndef COCOLOG_RAY_GESTURE_H
#define COCOLOG_RAY_GESTURE_H
double ray_pinch_scale(void);
#endif
