/* cocolog -- modules/ray/gesture_none.c: no trackpad gesture here.
 *
 * The portable half of ray_pinch_scale(): a system that is not macOS
 * has no NSEventTypeMagnify, and raylib's touch API is the touch path.
 * The answer is the same 1.0 the macOS file answers when no gesture is
 * in progress, so the Prolog surface is identical on both.
 */
double ray_pinch_scale(void) { return 1.0; }
