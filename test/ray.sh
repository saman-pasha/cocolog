#!/bin/sh
# library(ray) -- raylib as predicates, held to PIXELS.
#
# A GRAPHICS TEST THAT CHECKS EXIT CODES has proved a linker worked.
# What has to be proved is that what the CLAUSES said appeared on the
# FRAME -- so every windowed check below ends in `ray_screenshot/1' and
# the assertions are about the files: a real PNG came out, and two
# frames the program drew DIFFERENTLY are different files, byte for
# byte. That is pixel truth with no image decoder in the suite.
#
# HEADLESS IS THE ARRANGEMENT UNDER TEST. The suite runs where there is
# no screen, so when DISPLAY is empty the whole windowed half runs under
# `xvfb-run' -- a real X server, a real GL context (Mesa's software
# rasteriser), a real framebuffer; only the glass is missing. No Xvfb
# and no display SKIPs, loudly, like every other optional dependency.
#
# THE FIRST CHECKS NEED NO WINDOW AT ALL, because the Coco half is
# clauses: the palette is FACTS (`ray_color/4' enumerates what raylib
# ships as #defines), a color spec resolves by rule, a key name is a
# row in a table. That half is checked before any X server exists.
#
# SKIPs without library/ray.so -- sh modules/ray/build.sh, and it needs
# a raylib (see that script's header).

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s %s\n' "$1" "$(echo "$2" | cut -c1-24)"
  else
    printf 'FAIL %-52s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }
[ -f "$ROOT/library/ray.so" ] || {
  echo "SKIP (no library/ray.so -- sh modules/ray/build.sh)"; exit 0; }
if ! timeout 20 "$C" query "use_module(library(ray)), write(ok), nl" 2>/dev/null \
     | grep -aq '\bok\b'; then
  echo "SKIP (library(ray) will not load)"
  exit 0
fi

U="use_module(library(ray))"
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- the Coco half: clauses, no window"
check "the palette is facts, byte for byte raylib's" \
  "$(q "ray_color(maroon, R, G, B), write(answer(R-G-B)), nl")" "190-33-55"
check "and enumerable, which no #define is" \
  "$(q "findall(N, ray_color(N, _, _, _), L), length(L, X), write(answer(X)), nl")" "25"
check "a name resolves to rgba" \
  "$(q "ray_rgba(blue, R, G, B, A), write(answer(R-G-B-A)), nl")" "0-121-241-255"
check "rgb/3 and rgba/4 terms resolve too" \
  "$(q "ray_rgba(rgb(1,2,3), R, G, B, A), ray_rgba(rgba(4,5,6,7), R2, _, _, A2), write(answer(R-A-R2-A2)), nl")" "1-255-4-7"
check "a letter key is its raylib code" \
  "$(q "ray_keycode(a, C), write(answer(C)), nl")" "65"
check "a named key is its table row" \
  "$(q "ray_keycode(space, C), ray_keycode(escape, E), write(answer(C-E)), nl")" "32-256"
check "a bare integer passes through" \
  "$(q "ray_keycode(300, C), write(answer(C)), nl")" "300"

# ---- the windowed half, headless when there is no glass ---------------
RUN=""
if [ -z "${DISPLAY:-}" ]; then
  if command -v xvfb-run >/dev/null 2>&1; then
    RUN="xvfb-run -a"
  else
    echo
    echo "window: SKIP (no DISPLAY and no xvfb-run -- apt-get install xvfb)"
    [ "$failures" -eq 0 ] && { echo "GREEN: 0 failure(s)"; exit 0; }
    echo "RED: $failures failure(s)"; exit 1
  fi
fi

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-ray-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

wq() { timeout 90 $RUN "$C" query "$U, ray_log_level(none), $1" 2>/dev/null \
       | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

png_magic() {  # is FILE a PNG, by its first four bytes
  [ -s "$1" ] && [ "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" = "89504e47" ] \
    && echo png || echo not_png
}

echo
echo "-- a frame, drawn and LOOKED AT"
# THE WORLD IS CLAUSES: the boxes are asserted facts and the draw is a
# forall over them -- the loop shape the module exists for, in one goal.
got=$(wq "ray_open(320, 200, coco), ( ray_ready -> true ; halt(1) ),
          assertz(box(10, 10, maroon)), assertz(box(60, 40, blue)),
          ray_begin, ray_clear(raywhite),
          forall(box(X, Y, Col), ray_rect(X, Y, 32, 32, Col)),
          ray_text('drawn from clauses', 10, 160, 20, darkgray),
          ray_circle(250, 60, 30.5, lime),
          ray_line(0, 199, 319, 199, black),
          ray_pixel(300, 10, red),
          ray_end,
          ( ray_screenshot('$OUT/frame2d.png') -> S = shot ; S = no_shot ),
          ray_close, write(answer(S)), nl")
check "a 2D frame of clauses renders and screenshots" "$got" "shot"
check "and the screenshot is a real PNG" "$(png_magic "$OUT/frame2d.png")" "png"

# TWO FRAMES THE PROGRAM DREW DIFFERENTLY ARE DIFFERENT FILES. This is
# the check that catches a context that silently rendered nothing: a
# dead GL gives two identical (black or empty) frames.
got=$(wq "ray_open(160, 100, coco),
          ray_begin, ray_clear(maroon), ray_end,
          ray_screenshot('$OUT/a.png'),
          ray_begin, ray_clear(blue), ray_end,
          ray_screenshot('$OUT/b.png'),
          ray_close, write(answer(two)), nl")
check "two clears, two screenshots" "$got" "two"
check "and the frames really differ" \
  "$( cmp -s "$OUT/a.png" "$OUT/b.png" && echo same || echo differ )" "differ"

echo
echo "-- the third dimension"
got=$(wq "ray_open(320, 240, coco),
          ray_begin, ray_clear(raywhite),
          ray_begin3d(6.0, 6.0, 6.0, 0.0, 0.0, 0.0, 45.0),
          ray_grid(10, 1.0),
          ray_cube(0.0, 0.5, 0.0, 1.0, 1.0, 1.0, maroon),
          ray_cube_wires(0.0, 0.5, 0.0, 1.0, 1.0, 1.0, black),
          ray_sphere(2.0, 0.5, 0.0, 0.5, blue),
          ray_end3d,
          ray_end,
          ray_screenshot('$OUT/frame3d.png'),
          ray_begin, ray_clear(raywhite), ray_end,
          ray_screenshot('$OUT/blank.png'),
          ray_close, write(answer(dimensional)), nl")
check "a 3D scene renders over a 2D frame" "$got" "dimensional"
check "and differs from a blank of the same clear" \
  "$( cmp -s "$OUT/frame3d.png" "$OUT/blank.png" && echo same || echo differ )" "differ"

echo
echo "-- the loop's questions answer"
check "closing is false while nobody asked to close" \
  "$(wq "ray_open(64, 64, coco), ( ray_closing -> X = closing ; X = open ),
         ray_close, write(answer(X)), nl")" "open"
check "frame time is a number after a frame" \
  "$(wq "ray_open(64, 64, coco), ray_fps(60), ray_begin, ray_clear(black), ray_end,
         ray_frame_time(T), ( ( T >= 0.0 ; T =:= 0 ) -> X = numeric ; X = odd(T) ),
         ray_close, write(answer(X)), nl")" "numeric"
check "the mouse has coordinates, even a virtual one" \
  "$(wq "ray_open(64, 64, coco), ray_mouse(X, Y),
         ( integer(X), integer(Y) -> R = ints ; R = odd ),
         ray_close, write(answer(R)), nl")" "ints"
check "an unpressed key is not down" \
  "$(wq "ray_open(64, 64, coco), ray_begin, ray_clear(black), ray_end,
         ( ray_key_down(space) -> X = down ; X = up ),
         ray_close, write(answer(X)), nl")" "up"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"
  exit 1
fi
