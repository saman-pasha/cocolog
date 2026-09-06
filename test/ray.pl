%% library(ray) -- raylib as predicates, held to PIXELS.
%%
%% A GRAPHICS TEST THAT CHECKS EXIT CODES has proved a linker worked.
%% What has to be proved is that what the CLAUSES said appeared on the
%% FRAME -- so every windowed check below ends in `ray_screenshot/1' and
%% the assertions are about the files: a real PNG came out, and two
%% frames the program drew DIFFERENTLY are different files, byte for
%% byte. That is pixel truth with no image decoder in the suite.
%%
%% HEADLESS IS THE ARRANGEMENT UNDER TEST. The suite runs where there is
%% no screen, so when DISPLAY is empty the whole windowed half runs under
%% `xvfb-run' -- a real X server, a real GL context (Mesa's software
%% rasteriser), a real framebuffer; only the glass is missing. No Xvfb
%% and no display SKIPs, loudly, like every other optional dependency.
%%
%% THE FIRST CHECKS NEED NO WINDOW AT ALL, because the Coco half is
%% clauses: the palette is FACTS (`ray_color/4' enumerates what raylib
%% ships as #defines), a color spec resolves by rule, a key name is a
%% row in a table. That half is checked in this process, before any X
%% server exists; each windowed check is a child of its own, because a
%% raylib window is one per process.
%%
%%     cocolog -s test/ray.pl        from the checkout root
%%
%% SKIPs without library/ray.so -- sh modules/ray/build.sh, and it needs
%% a raylib (see that script's header).

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/ray.so') -> true ; skip('(no library/ray.so -- sh modules/ray/build.sh)') ),
    ( catch(use_module(library(ray)), _, fail) -> true ; skip('(library(ray) will not load)') ),
    the_coco_half,
    %% THE WINDOWED HALF IS A SECTION, so no glass SKIPS IT and the case
    %% stays what the clauses-only checks made it: the two guards below
    %% say why and FAIL, and main falls through to checks_done. (They used
    %% to `halt(0)' after saying so, and a halt under -s exits 1 whatever
    %% its code -- cocolog.cicili's session code, not the case's -- so a
    %% Mac with its screen asleep read as a RED ray, five checks at once.)
    (   display_runner(Run), the_glass(Run)
    ->  scratch(D),
        a_frame(Run, D), the_third_dimension(Run, D), the_loop(Run), the_textures(Run, D),
        shl(['rm -rf ', D])
    ;   true
    ),
    checks_done.

%% a real DISPLAY, or xvfb-run to make one; neither says so and fails
display_runner(Run) :-
    (   getenv('DISPLAY', Dpy), Dpy \== ''
    ->  Run = ''
    ;   sh_exit('command -v xvfb-run >/dev/null 2>&1', 0)
    ->  Run = 'xvfb-run -a '
    ;   format("     (skipped: the window -- no DISPLAY and no xvfb-run; apt-get install xvfb)~n", []),
        fail
    ).

the_coco_half :-
    section('the Coco half: clauses, no window'),
    written(ray_color(maroon, R1, G1, B1), R1-G1-B1, X1),
    check('the palette is facts, byte for byte raylib''s', X1, '190-33-55'),
    written(( findall(N2, ray_color(N2, _, _, _), L2), length(L2, X2) ), X2, G2),
    check('and enumerable, which no #define is', G2, '25'),
    written(ray_rgba(blue, R3, G3, B3, A3), R3-G3-B3-A3, X3),
    check('a name resolves to rgba', X3, '0-121-241-255'),
    written(( ray_rgba(rgb(1,2,3), R4, _, _, A4), ray_rgba(rgba(4,5,6,7), R4b, _, _, A4b) ), R4-A4-R4b-A4b, X4),
    check('rgb/3 and rgba/4 terms resolve too', X4, '1-255-4-7'),
    written(ray_keycode(a, C5), C5, X5),
    check('a letter key is its raylib code', X5, '65'),
    written(( ray_keycode(space, C6), ray_keycode(escape, E6) ), C6-E6, X6),
    check('a named key is its table row', X6, '32-256'),
    written(ray_keycode(300, C7), C7, X7),
    check('a bare integer passes through', X7, '300'),
    written(( ray_filter(bilinear, F8), ray_wrap(clamp, W8) ), F8-W8, X8),
    check('a texture filter and a wrap are table rows, raylib.h''s enums', X8, '1-1'),
    written(( findall(F9, ray_filter(F9, _), L9), length(L9, N9) ), N9, X9),
    check('and the filter table is the whole enum', X9, '6').

%% NO GLASS IS A SKIP, NOT A RED. A DISPLAY variable is not a display: on
%% a Mac whose screen has gone to sleep raylib's InitWindow fails at once
%% (`GLFW: Failed to determine Monitor', `SYSTEM: Failed to initialize
%% platform') and every windowed check below would go red in a second,
%% naming the module for what the room did -- which is exactly the
%% finding this suite keeps apart from a broken backend when the server
%% is missing. One probe child opens an 8x8 window; if none comes, the
%% windowed half is skipped with raylib's own reason. (`caffeinate -u'
%% wakes the screen, and on this Mac it went back to sleep 32 s later
%% even under that assertion, mid-run -- so a run you mean to believe
%% wants the screen actually awake.)
the_glass(Run) :-
    cocolog(C),
    sh_join([Run, C, ' query "use_module(library(ray)), ray_log_level(warning), ray_open(8, 8, probe), ( ray_ready -> write(answer(glass)) ; write(answer(none)) ), nl, ray_close" 2>&1'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    (   re_first_atom('answer\\(glass\\)', Out, _)
    ->  true
    ;   ( re_first_atom('(WARNING|ERROR|FATAL): [^\n]*', Out, Why) -> true ; Why = 'no window came, and raylib said nothing' ),
        format("     (skipped: no glass -- ~w)~n", [Why]),
        fail
    ).

%% a windowed goal in a child of its own, under the display runner, its
%% `answer(...)' read back
wq(Run, Goal, Got) :-
    cocolog(C),
    sh_join([Run, C, ' query "use_module(library(ray)), ray_log_level(none), ', Goal, '" 2>/dev/null'], Cmd),
    proc_run(Cmd, 90000, Out, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out, A) -> sub_atom(A, 7, _, 1, Got) ; Got = '' ).

%% is FILE a PNG, by its first four bytes
png_magic(File, Verdict) :-
    (   exists_file(File), read_file_to_codes(File, [137, 80, 78, 71|_]) -> Verdict = png ; Verdict = not_png ).

%% cmp -s: same bytes or not
same_bytes(A, B, V) :-
    (   exists_file(A), exists_file(B), read_file_to_codes(A, Ca), read_file_to_codes(B, Cb), Ca == Cb
    ->  V = same ; V = differ ).

a_frame(Run, D) :-
    section('a frame, drawn and LOOKED AT'),
    %% THE WORLD IS CLAUSES: the boxes are asserted facts and the draw is a
    %% forall over them -- the loop shape the module exists for, in one goal.
    atom_concat(D, '/frame2d.png', Frame),
    sh_join(['ray_open(320, 200, coco), ( ray_ready -> true ; halt(1) ), assertz(box(10, 10, maroon)), assertz(box(60, 40, blue)), ray_begin, ray_clear(raywhite), forall(box(X, Y, Col), ray_rect(X, Y, 32, 32, Col)), ray_text(''drawn from clauses'', 10, 160, 20, darkgray), ray_circle(250, 60, 30.5, lime), ray_poly(160.0, 60.0, 6, 24.0, 30.0, gold), ray_poly_lines(160.0, 60.0, 6, 24.0, 30.0, black), ray_line(0, 199, 319, 199, black), ray_pixel(300, 10, red), ray_end, ( ray_screenshot(''', Frame, ''') -> S = shot ; S = no_shot ), ray_close, write(answer(S)), nl'], G1),
    wq(Run, G1, R1),
    check('a 2D frame of clauses renders and screenshots', R1, shot),
    png_magic(Frame, P1),
    check('and the screenshot is a real PNG', P1, png),
    %% TWO FRAMES THE PROGRAM DREW DIFFERENTLY ARE DIFFERENT FILES. This is
    %% the check that catches a context that silently rendered nothing: a
    %% dead GL gives two identical (black or empty) frames.
    atom_concat(D, '/a.png', A), atom_concat(D, '/b.png', B),
    sh_join(['ray_open(160, 100, coco), ray_begin, ray_clear(maroon), ray_end, ray_screenshot(''', A, '''), ray_begin, ray_clear(blue), ray_end, ray_screenshot(''', B, '''), ray_close, write(answer(two)), nl'], G2),
    wq(Run, G2, R2),
    check('two clears, two screenshots', R2, two),
    same_bytes(A, B, V2),
    check('and the frames really differ', V2, differ).

the_third_dimension(Run, D) :-
    section('the third dimension'),
    atom_concat(D, '/frame3d.png', F3), atom_concat(D, '/blank.png', Blank),
    sh_join(['ray_open(320, 240, coco), ray_begin, ray_clear(raywhite), ray_begin3d(6.0, 6.0, 6.0, 0.0, 0.0, 0.0, 45.0), ray_grid(10, 1.0), ray_cube(0.0, 0.5, 0.0, 1.0, 1.0, 1.0, maroon), ray_cube_wires(0.0, 0.5, 0.0, 1.0, 1.0, 1.0, black), ray_sphere(2.0, 0.5, 0.0, 0.5, blue), ray_end3d, ray_end, ray_screenshot(''', F3, '''), ray_begin, ray_clear(raywhite), ray_end, ray_screenshot(''', Blank, '''), ray_close, write(answer(dimensional)), nl'], G),
    wq(Run, G, R),
    check('a 3D scene renders over a 2D frame', R, dimensional),
    same_bytes(F3, Blank, V),
    check('and differs from a blank of the same clear', V, differ).

the_loop(Run) :-
    section('the loop''s questions answer'),
    wq(Run, 'ray_open(64, 64, coco), ( ray_closing -> X = closing ; X = open ), ray_close, write(answer(X)), nl', R1),
    check('closing is false while nobody asked to close', R1, open),
    wq(Run, 'ray_open(64, 64, coco), ray_fps(60), ray_begin, ray_clear(black), ray_end, ray_frame_time(T), ( ( T >= 0.0 ; T =:= 0 ) -> X = numeric ; X = odd(T) ), ray_close, write(answer(X)), nl', R2),
    check('frame time is a number after a frame', R2, numeric),
    wq(Run, 'ray_open(64, 64, coco), ray_mouse(X, Y), ( integer(X), integer(Y) -> R = ints ; R = odd ), ray_close, write(answer(R)), nl', R3),
    check('the mouse has coordinates, even a virtual one', R3, ints),
    wq(Run, 'ray_open(64, 64, coco), ray_begin, ray_clear(black), ray_end, ( ray_key_down(space) -> X = down ; X = up ), ray_close, write(answer(X)), nl', R4),
    check('an unpressed key is not down', R4, up).

%% A TEXTURE IS HELD TO THE PIXEL, LITERALLY: `ray_screen_pixel/6' reads
%% the framebuffer back as four numbers, so what a clause drew is a check
%% with no image decoder in the suite. The tile is made by the module
%% itself -- a screenshot of a frame that is maroon on the left and blue
%% on the right -- because the suite ships no art, and a PNG the module
%% wrote and then read back through LoadTexture is the round trip anyway.
%%
%% EVERY FRAME IS DRAWN TWICE before a pixel is read or a tile is shot.
%% A raylib photograph is ONE FRAME BEHIND on macOS (CLAUDE.md): a single
%% frame photographs as BLACK, which is exactly what the first run of this
%% section got -- a black tile, and every texture check reading [0,0,0].
twice(Frame, Text) :- sh_join([Frame, ', ', Frame], Text).

the_textures(Run, D) :-
    section('textures: a PNG loaded, drawn, and read back by the pixel'),
    atom_concat(D, '/tile.png', Tile),
    twice('ray_begin, ray_clear(maroon), ray_rect(16, 0, 16, 32, blue), ray_end', Tile2),
    sh_join(['ray_open(32, 32, coco), ', Tile2, ', ( ray_screenshot(''', Tile, ''') -> S = made ; S = not_made ), ray_close, write(answer(S)), nl'], G0),
    wq(Run, G0, R0),
    check('the tile is a screenshot the module took: maroon left, blue right', R0, made),
    %% loaded and drawn whole at 40,20: each half lands where the clause said, and
    %% a pixel off the texture is still the clear
    twice('ray_begin, ray_clear(raywhite), ray_texture(T, 40, 20), ray_end', F1),
    sh_join(['ray_open(96, 64, coco), ray_texture_load(''', Tile, ''', T), ray_texture_size(T, W, H), ', F1, ', ray_screen_pixel(45, 25, R1, G1, B1, A1), ray_screen_pixel(66, 25, R2, G2, B2, _), ray_screen_pixel(5, 5, R3, G3, B3, _), ray_close, write(answer(W-H-[R1,G1,B1,A1]-[R2,G2,B2]-[R3,G3,B3])), nl'], G1),
    wq(Run, G1, X1),
    check('a texture loads with its size and draws where it was put, pixel for pixel', X1, '32-32-[190,33,55,255]-[0,121,241]-[245,245,245]'),
    %% a sprite is a cell of the texture: the right half alone, at the origin
    twice('ray_begin, ray_clear(raywhite), ray_sprite(T, rect(16, 0, 16, 32), 0, 0), ray_end', F2),
    sh_join(['ray_open(64, 64, coco), ray_texture_load(''', Tile, ''', T), ', F2, ', ray_screen_pixel(5, 5, R1, G1, B1, _), ray_screen_pixel(20, 5, R2, G2, B2, _), ray_close, write(answer([R1,G1,B1]-[R2,G2,B2])), nl'], G2),
    wq(Run, G2, X2),
    check('a sprite is one cell of an atlas, and only that cell', X2, '[0,121,241]-[245,245,245]'),
    %% the left half stretched over the whole window
    twice('ray_begin, ray_clear(raywhite), ray_sprite_ex(T, rect(0, 0, 16, 32), rect(0, 0, 64, 64), 0, 0, 0.0, white), ray_end', F3),
    sh_join(['ray_open(64, 64, coco), ray_texture_load(''', Tile, ''', T), ', F3, ', ray_screen_pixel(60, 60, R1, G1, B1, _), ray_close, write(answer([R1,G1,B1])), nl'], G3),
    wq(Run, G3, X3),
    check('ray_sprite_ex fits a cell into a destination rect', X3, '[190,33,55]'),
    %% scaled by two the halves are 32 wide; rotated 90 about its corner the
    %% texture hangs down from x=32 with its left half on top
    twice('ray_begin, ray_clear(raywhite), ray_texture_ex(T, 0, 0, 0.0, 2.0, white), ray_end', F4),
    sh_join(['ray_open(64, 64, coco), ray_texture_load(''', Tile, ''', T), ', F4, ', ray_screen_pixel(10, 10, R1, G1, B1, _), ray_screen_pixel(40, 10, R2, G2, B2, _), ray_close, write(answer([R1,G1,B1]-[R2,G2,B2])), nl'], G4),
    wq(Run, G4, X4),
    check('ray_texture_ex scales', X4, '[190,33,55]-[0,121,241]'),
    twice('ray_begin, ray_clear(raywhite), ray_texture_ex(T, 32, 0, 90.0, 1.0, white), ray_end', F5),
    sh_join(['ray_open(64, 64, coco), ray_texture_load(''', Tile, ''', T), ', F5, ', ray_screen_pixel(10, 5, R1, G1, B1, _), ray_screen_pixel(10, 25, R2, G2, B2, _), ray_close, write(answer([R1,G1,B1]-[R2,G2,B2])), nl'], G5),
    wq(Run, G5, X5),
    check('and rotates, in degrees, about the origin', X5, '[190,33,55]-[0,121,241]'),
    %% a tint multiplies: black blackens, a transparent white draws nothing
    twice('ray_begin, ray_clear(raywhite), ray_texture(T, 0, 0, black), ray_texture(T, 32, 0, rgba(255, 255, 255, 0)), ray_end', F6),
    sh_join(['ray_open(64, 64, coco), ray_texture_load(''', Tile, ''', T), ', F6, ', ray_screen_pixel(5, 5, R1, G1, B1, _), ray_screen_pixel(40, 5, R2, G2, B2, _), ray_close, write(answer([R1,G1,B1]-[R2,G2,B2])), nl'], G6),
    wq(Run, G6, X6),
    check('a tint is a color spec, and alpha 0 is invisible', X6, '[0,0,0]-[245,245,245]'),
    %% A CANVAS DRAWS THE RIGHT WAY UP. Green on top, red below, drawn into
    %% it; whole at the origin, and its two halves as sprites at x=40 --
    %% the bottom half above the top half, so a wrong flip of the sub-rect
    %% would swap them
    twice('ray_begin, ray_clear(raywhite), ray_texture(C, 0, 0), ray_sprite(C, rect(0, 16, 32, 16), 40, 0), ray_sprite(C, rect(0, 0, 32, 16), 40, 20), ray_end', F7),
    sh_join(['ray_open(96, 64, coco), ray_canvas(32, 32, C), ray_canvas_begin(C), ray_clear(red), ray_rect(0, 0, 32, 16, green), ray_canvas_end, ', F7, ', ray_screen_pixel(5, 5, R1, G1, B1, _), ray_screen_pixel(5, 25, R2, G2, B2, _), ray_screen_pixel(45, 5, R3, G3, B3, _), ray_screen_pixel(45, 25, R4, G4, B4, _), ray_texture_size(C, W, H), ray_close, write(answer(W-H-[R1,G1,B1]-[R2,G2,B2]-[R3,G3,B3]-[R4,G4,B4])), nl'], G7),
    wq(Run, G7, X7),
    check('a canvas drawn into is a texture, and it comes out the right way up, sprites too', X7, '32-32-[0,228,48]-[230,41,55]-[230,41,55]-[0,228,48]'),
    twice('ray_begin, ray_clear(raywhite), ray_texture_ex(C, 0, 0, 0.0, 2.0, white), ray_end', F8),
    sh_join(['ray_open(64, 64, coco), ray_canvas(32, 32, C), ray_canvas_begin(C), ray_clear(red), ray_rect(0, 0, 32, 16, green), ray_canvas_end, ', F8, ', ray_screen_pixel(5, 5, R1, G1, B1, _), ray_screen_pixel(5, 50, R2, G2, B2, _), ray_close, write(answer([R1,G1,B1]-[R2,G2,B2])), nl'], G8),
    wq(Run, G8, X8),
    check('and scaled, still the right way up', X8, '[0,228,48]-[230,41,55]'),
    %% the refusals, each by name: no such file, a file that is not an
    %% image, an integer nobody was given, a handle after unload, a texture
    %% that is not a canvas, a pixel outside the window
    atom_concat(D, '/text.txt', Txt),
    fixture(Txt, ['not a png']),
    sh_join(['ray_open(64, 64, coco), catch(ray_texture_load(''/nonexistent/x.png'', _), error(E, _), true), ( ray_texture_load(''', Txt, ''', _) -> Dc = decoded ; Dc = refused ), ( ray_texture(999, 0, 0) -> N = drew ; N = refused ), ray_texture_load(''', Tile, ''', T), ray_texture_unload(T), ( ray_texture_size(T, _, _) -> U = still ; U = gone ), ray_texture_load(''', Tile, ''', T2), ( ray_canvas_begin(T2) -> B = began ; B = refused ), ( ray_screen_pixel(64, 0, _, _, _, _) -> P = answered ; P = refused ), ray_texture_filter(T2, bilinear), ray_texture_wrap(T2, clamp), ray_close, write(answer(E-Dc-N-U-B-P)), nl'], G9),
    wq(Run, G9, X9),
    check('the refusals: existence_error for no file, failure for the rest', X9, 'existence_error(file,/nonexistent/x.png)-refused-refused-gone-refused-refused').
