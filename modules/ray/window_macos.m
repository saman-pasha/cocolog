/* cocolog -- modules/ray/window_macos.m: full screen on a Mac, as C.
 *
 * RAYLIB'S ToggleFullscreen IS THE WRONG MODE ON A RETINA MAC. It asks
 * GLFW for an exclusive full screen at the desktop's size, and GLFW picks
 * from the video modes CGDisplayCopyAllDisplayModes lists -- which leaves
 * out the scaled HiDPI mode a Retina desktop is normally in. So the
 * request can never be met by the mode already showing, and the DISPLAY
 * IS SWITCHED to the nearest one that is listed. MEASURED, on a 16-inch
 * MacBook Pro at "More Space" (2048 x 1280 points, 4096 x 2560 pixels):
 *
 *     ToggleFullscreen    mode 2304 x 1440, pixels 2304 x 1440
 *
 * -- a NON-Retina mode, with the fade a mode switch costs, every other
 * application's windows rearranged, and the desktop left in that mode if
 * the process is killed before it restores it. And a second window
 * opened in the same process after the first was closed in that mode
 * came up with a 2048 x 1280 viewport in a 2304 x 1440 drawable: the
 * picture in the bottom-left of the screen and black round it, which is
 * what a game downstream reported for a day as "does not fit".
 *
 * THE MODE HERE CHANGES NO VIDEO MODE. The window loses its title bar,
 * takes its screen's frame, and the application hides the Dock and the
 * menu bar for as long as it is the active one:
 *
 *     borderless          mode 2048 x 1280, pixels 4096 x 2560 (unchanged)
 *                         window 0,0 2048 x 1280, viewport 2048 x 1280
 *
 * The resize arrives through the same windowDidResize GLFW already
 * handles, so raylib's screen size, render size and viewport are right
 * by the time this returns -- ray_screen_size/2 is the truth the frame
 * after, with nothing to wait for. Leaving puts back the style, the
 * frame and the presentation options exactly as they were.
 *
 * THE PRESENTATION OPTIONS ARE THE APPLICATION'S, NOT THE WINDOW'S, and
 * that is why they are used rather than a window level above the menu
 * bar: switch to another application and the Dock and the menu come
 * back by themselves and this window goes behind the others, where a
 * window raised above the menu bar would stay on top of everything.
 *
 * A SIZE ASKED FOR IN THIS MODE is the size to return to. SetWindowSize
 * on the screen-filling window would shrink it to a borderless rectangle
 * in a corner, so ray_window_restore_size() moves the remembered frame
 * instead and the live window is left alone.
 *
 * THIS FILE IS MACOS ONLY. build.sh compiles window_none.c on every
 * other system, where both functions answer "not here" and raylib's own
 * full screen is used as before.
 */
#import <Cocoa/Cocoa.h>
#include "raylib.h"
#include "window.h"

static void *fs_window = NULL;              /* the window the mode is on */
static NSRect fs_frame;                     /* its frame before */
static NSUInteger fs_style = 0;             /* its style mask before */
static NSApplicationPresentationOptions fs_options = 0;

static NSWindow *ray_ns_window(void) {
    if (![NSThread isMainThread]) return nil;
    if (!IsWindowReady()) return nil;
    return (__bridge NSWindow *)GetWindowHandle();
}

int ray_window_fullscreen(int on) {
    NSWindow *w = ray_ns_window();
    if (w == nil) { fs_window = NULL; return 0; }
    /* a mode remembered for a window that has since been closed is not
     * this window's: the new one starts out of it */
    if (fs_window != NULL && fs_window != (__bridge void *)w) fs_window = NULL;
    if (on && fs_window == NULL) {
        NSScreen *s = [w screen];
        if (s == nil) s = [NSScreen mainScreen];
        if (s == nil) return 0;
        fs_frame = [w frame];
        fs_style = [w styleMask];
        fs_options = [NSApp presentationOptions];
        [NSApp setPresentationOptions:(NSApplicationPresentationHideDock |
                                       NSApplicationPresentationHideMenuBar)];
        [w setStyleMask:NSWindowStyleMaskBorderless];
        [w setFrame:[s frame] display:YES];
        [w makeFirstResponder:[w contentView]];
        [w makeKeyAndOrderFront:nil];
        fs_window = (__bridge void *)w;
    } else if (!on && fs_window != NULL) {
        [NSApp setPresentationOptions:fs_options];
        [w setStyleMask:fs_style];
        [w setFrame:fs_frame display:YES];
        [w makeFirstResponder:[w contentView]];
        fs_window = NULL;
    }
    return 1;
}

int ray_window_restore_size(int width, int height) {
    NSWindow *w = ray_ns_window();
    if (w == nil || fs_window == NULL || fs_window != (__bridge void *)w) return 0;
    if (width <= 0 || height <= 0) return 1;
    /* the same arithmetic GLFW's own resize does: the top-left corner
     * stays where it was */
    NSRect content = [NSWindow contentRectForFrameRect:fs_frame styleMask:fs_style];
    content.origin.y += content.size.height - height;
    content.size = NSMakeSize(width, height);
    fs_frame = [NSWindow frameRectForContentRect:content styleMask:fs_style];
    return 1;
}
