/* cocolog -- modules/ray/gesture_macos.m: a Mac trackpad pinch, as C.
 *
 * RAYLIB'S TOUCH API IS FOR TOUCHSCREENS. A trackpad pinch on macOS is
 * NSEventTypeMagnify, a Cocoa gesture that GLFW never turns into a scroll
 * or a touch point, so GetTouchPointCount() is 0 while two fingers are
 * pinching. This file installs a LOCAL NSEVENT MONITOR for the app: the
 * handler runs on the main thread inside the event loop the game already
 * pumps (raylib's EndDrawing -> glfwPollEvents), accumulates the gesture's
 * magnification into one cumulative scale, and hands it to
 * ray_pinch_scale() when the frame asks.
 *
 * THE PHASE IS THE GESTURE. A macOS magnification gesture begins with
 * NSEventPhaseBegan, sends Changed events while the fingers move, and
 * ends with Ended. The scale is reset on Began and multiplied by
 * (1 + event.magnification) on each event. A gesture that has stopped
 * sending is considered over after 300 ms, and the scale falls back to
 * 1.0 -- which is how the game's `gfx_pinch_scale/1' knows to drop the
 * base zoom it took at the gesture's first frame.
 *
 * THE MONITOR RETURNS THE EVENT UNCHANGED. It is a reader, not a
 * consumer: Chrome's or raylib's own handling, if any, still sees it.
 *
 * THIS FILE IS MACOS ONLY. build.sh compiles gesture_none.c on every
 * other system, whose ray_pinch_scale() is always 1.0.
 */
#import <Cocoa/Cocoa.h>

static id pinch_monitor = nil;
static double pinch_scale = 1.0;
static double pinch_until = 0.0;

static void pinch_install(void) {
    if (pinch_monitor != nil) return;
    if (![NSThread isMainThread]) return;
    pinch_monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMagnify
                                                         handler:^NSEvent *(NSEvent *event) {
        if (event.phase == NSEventPhaseBegan) pinch_scale = 1.0;
        double m = event.magnification;
        if (m != 0.0) {
            pinch_scale *= (1.0 + m);
            if (pinch_scale < 0.1) pinch_scale = 0.1;
            if (pinch_scale > 10.0) pinch_scale = 10.0;
            pinch_until = CFAbsoluteTimeGetCurrent() + 0.30;
        }
        return event;
    }];
}

double ray_pinch_scale(void) {
    pinch_install();
    if (CFAbsoluteTimeGetCurrent() > pinch_until) pinch_scale = 1.0;
    return pinch_scale;
}
