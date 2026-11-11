/* cocolog -- modules/ray/window.h: the window's full-screen mode, where
 * raylib's own is the wrong one. See window_macos.m for why; every other
 * system answers "not here" (window_none.c) and raylib is asked.
 */
#ifndef COCOLOG_RAY_WINDOW_H
#define COCOLOG_RAY_WINDOW_H

/* 1: the mode was set here, the display's own video mode untouched.
 * -1: this system has no such mode -- ask raylib's ToggleFullscreen.
 * 0: there is no window to do it to. */
int ray_window_fullscreen(int on);

/* A size asked for WHILE the mode above is on is the size to return to,
 * not a size for the screen-filling window. 1: taken as that; 0: the mode
 * is off (or this system has none), so the caller resizes the window. */
int ray_window_restore_size(int width, int height);

#endif
