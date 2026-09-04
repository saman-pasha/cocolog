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
    (   getenv('DISPLAY', Dpy), Dpy \== ''
    ->  Run = ''
    ;   sh_exit('command -v xvfb-run >/dev/null 2>&1', 0)
    ->  Run = 'xvfb-run -a '
    ;   format("     (skipped: the window -- no DISPLAY and no xvfb-run; apt-get install xvfb)~n", []),
        checks_done, halt(0)
    ),
    scratch(D),
    a_frame(Run, D), the_third_dimension(Run, D), the_loop(Run),
    shl(['rm -rf ', D]),
    checks_done.

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
    check('a bare integer passes through', X7, '300').

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
