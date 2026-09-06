%% LIBRARY 29 -- library(ray): a game window, 2D, 3D and textures, from clauses
%%
%%     ./cocolog run tutorials/library/29-ray.pl main
%%
%% TIER 2: `use_module(library(ray))', a `.so' from `modules/ray'. It
%% needs a raylib: `sh modules/ray/build.sh' (its header says where a
%% raylib comes from).
%%
%% WHY raylib, of every engine there is: the CALLER owns the loop. Input
%% is polled, a frame is whatever happens between ray_begin and ray_end,
%% and nothing ever calls back into your code -- which is the one shape
%% a Prolog program can drive. So a game here is a predicate:
%%
%%     loop :-
%%         ray_begin,
%%         ray_clear(raywhite),
%%         forall(box(X, Y, C), ray_rect(X, Y, 32, 32, C)),
%%         ray_end,
%%         ( ray_closing -> true ; loop ).
%%
%% and the WORLD IS THE KNOWLEDGE BASE: the boxes are facts, the draw is
%% a forall over them, moving a thing is retract and assert. Everything
%% this project proves about clauses -- freeze/thaw, a shared store,
%% deterministic replay -- now applies to a game state.
%%
%% THE SURFACE:
%%
%%     ray_open(+W, +H, +Title)   ray_close      ray_closing   ray_ready
%%     ray_fps(+N)                ray_begin      ray_end
%%     ray_clear(+Color)
%%     ray_rect(+X, +Y, +W, +H, +Color)      ray_circle(+X, +Y, +Rad, +Color)
%%     ray_line(+X1, +Y1, +X2, +Y2, +Color)  ray_pixel(+X, +Y, +Color)
%%     ray_poly(+X, +Y, +Sides, +Radius, +Rot, +Color)   filled regular
%%     ray_poly_lines(...same...)             polygon -- six sides and
%%                                            rotation 30 is a pointy hex
%%     ray_text(+Text, +X, +Y, +Size, +Color)  ray_draw_fps(+X, +Y)
%%     ray_begin3d(+PX, +PY, +PZ, +TX, +TY, +TZ, +Fov)  ray_end3d
%%     ray_cube(+X, +Y, +Z, +W, +H, +L, +Color)  ray_cube_wires(...same...)
%%     ray_sphere(+X, +Y, +Z, +Rad, +Color)      ray_grid(+Slices, +Spacing)
%%     ray_key_down(+Key)  ray_key_pressed(+Key)
%%     ray_mouse(-X, -Y)   ray_mouse_down(+Button)
%%     ray_frame_time(-Seconds)  ray_time(-Seconds)
%%     ray_screenshot(+Path)     ray_screen_pixel(+X, +Y, -R, -G, -B, -A)
%%     ray_log_level(+Level)
%%     ray_texture_load(+Path, -Tex)   ray_texture_unload(+Tex)   ray_texture_size(+Tex, -W, -H)
%%     ray_texture(+Tex, +X, +Y)       ray_texture(+Tex, +X, +Y, +Tint)
%%     ray_texture_ex(+Tex, +X, +Y, +Rotation, +Scale, +Tint)
%%     ray_sprite(+Tex, +Source, +X, +Y)          Source is rect(X, Y, W, H):
%%     ray_sprite(+Tex, +Source, +X, +Y, +Tint)   one cell of an atlas
%%     ray_sprite_ex(+Tex, +Source, +Dest, +OX, +OY, +Rotation, +Tint)
%%     ray_texture_filter(+Tex, +Filter)   ray_texture_wrap(+Tex, +Wrap)
%%     ray_canvas(+W, +H, -Tex)   ray_canvas_begin(+Tex)   ray_canvas_end
%%
%% A TEXTURE is a handle -- an index into the library's own table, the
%% way a socket is in library(tcp) -- and a SPRITE is a rectangle of one,
%% which is what an atlas is: one PNG of tiles, and one fact per tile
%% naming its cell. A CANVAS is a texture you draw INTO, between
%% ray_canvas_begin and ray_canvas_end, and then draw like any other:
%% a map of a thousand hexes drawn once, and blitted every frame. raylib
%% hands such a texture back upside down (a framebuffer's first row is
%% its bottom); the library knows which of its handles is a canvas and
%% turns it the right way up, so a program never writes the flip.
%%
%% A COLOR is a name from raylib's own palette (`maroon', `raywhite'),
%% or `rgb(R,G,B)', or `rgba(R,G,B,A)'. A KEY is a name (`space', `up')
%% or a single letter, or a raw code. Those resolvers are CLAUSES, which
%% is why this file can test them:
%%
%% THIS FILE OPENS NO WINDOW. A tutorial the suite runs cannot assume a
%% display any more than the curl lesson can assume a network -- and the
%% half of the library that needs no window is exactly the half that is
%% clauses, which a lesson can hold to `must/3'. The windowed half is
%% proved, to the PIXEL, by test/ray.pl under Xvfb: it draws frames,
%% compares the PNGs and reads pixels back. Run this file's loop where there is
%% glass; the header above is the whole program.

:- use_module(library(ray)).

main :-
    format("~n-- the palette is facts, raylib's own bytes~n"),
    ray_color(maroon, MR, MG, MB),
    must('ray_color(maroon)', MR-MG-MB, 190-33-55),
    ray_color(raywhite, WR, _, _),
    must('ray_color(raywhite) red byte', WR, 245),
    findall(N, ray_color(N, _, _, _), Names),
    length(Names, Count),
    must('the palette enumerates', Count, 25),
    show('colors', Names),

    format("~n-- a color spec is a name, rgb/3 or rgba/4~n"),
    ray_rgba(blue, BR, BG, BB, BA),
    must('a name fills rgba', BR-BG-BB-BA, 0-121-241-255),
    ray_rgba(rgb(10, 20, 30), R1, _, _, A1),
    must('rgb/3 gets alpha 255', R1-A1, 10-255),
    ray_rgba(rgba(1, 2, 3, 4), _, _, _, A2),
    must('rgba/4 keeps its alpha', A2, 4),

    format("~n-- keys are names, letters, or raw codes~n"),
    ray_keycode(space, SC),
    must('a named key', SC, 32),
    ray_keycode(escape, EC),
    must('escape', EC, 256),
    ray_keycode(a, AC),
    must('a letter is its raylib code', AC, 65),
    ray_keycode(300, RC),
    must('a raw code passes through', RC, 300),

    format("~n-- buttons and log levels, the same shape~n"),
    ray_button(left, LB),
    must('the left button', LB, 0),
    ray_level(none, NL),
    must('log level none', NL, 7),

    format("~n-- texture filters and wraps: raylib.h's enums as rows~n"),
    ray_filter(point, FP),
    must('point is raylib''s default filter, 0', FP, 0),
    ray_filter(bilinear, FB),
    must('bilinear', FB, 1),
    findall(F, ray_filter(F, _), Filters),
    show('filters', Filters),
    ray_wrap(clamp, WC),
    must('clamp', WC, 1),
    findall(W, ray_wrap(W, _), Wraps),
    show('wraps', Wraps),

    format("~n-- what a window session looks like (not run here):~n"),
    format("     ?- ray_open(640, 360, 'coco'), ray_fps(60).~n"),
    format("     ?- ray_begin, ray_clear(raywhite),~n"),
    format("        ray_rect(10, 10, 64, 64, maroon),~n"),
    format("        ray_text('the world is clauses', 10, 100, 20, darkgray),~n"),
    format("        ray_end.~n"),
    format("     ?- ray_screenshot('frame.png'), ray_close.~n"),
    format("~n-- and with an atlas of tiles, and a canvas (not run here):~n"),
    format("     ?- ray_texture_load('tiles.png', Atlas),~n"),
    format("        assertz(tile(grass, rect(0, 0, 32, 32))),~n"),
    format("        assertz(tile(water, rect(32, 0, 32, 32))).~n"),
    format("     ?- ray_canvas(640, 360, Map),                 % drawn ONCE ...~n"),
    format("        ray_canvas_begin(Map),~n"),
    format("        forall(( hex(Q, R, Kind), tile(Kind, Cell), hex_pixel(Q, R, X, Y) ),~n"),
    format("               ray_sprite(Atlas, Cell, X, Y)),~n"),
    format("        ray_canvas_end.~n"),
    format("     ?- ray_begin, ray_texture(Map, 0, 0), ray_end.   % ... and blitted every frame~n"),

    format("~ndone~n").

show(What, Value) :- format("     ~w: ~w~n", [What, Value]).

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~w~n", [What, Got])
    ;   format("     FAILED: ~w~n        got  ~w~n        want ~w~n", [What, Got, Want]),
        halt(1)
    ).
