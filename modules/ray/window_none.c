/* cocolog -- modules/ray/window_none.c: no full-screen mode of our own.
 *
 * The portable half of window.h. On every system but macOS raylib's
 * ToggleFullscreen is the full-screen mode, so both answers say "not
 * here" and ray_p_fullscreen / ray_p_window_size fall through to raylib
 * exactly as they did before window_macos.m existed.
 */
#include "window.h"

int ray_window_fullscreen(int on) { (void)on; return -1; }
int ray_window_restore_size(int width, int height) { (void)width; (void)height; return 0; }
