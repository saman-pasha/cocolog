%% cocolog -- library(clay_ray): Clay's render commands, drawn with library(ray).
%%
%%     :- use_module(library(clay_ray)).
%%
%% A LAYOUT IS A LIST OF COMMANDS AND A RENDERER IS A WALK OVER IT. Clay
%% decides where every box and every line of text lands and says so as
%% `rect(...)', `text(...)', `scissor_start(...)' and the rest; nothing
%% in library(clay) draws. This library is the walk for raylib: one
%% clause per command kind, each a call into library(ray), and the three
%% things a frame needs around it -- the pointer and the wheel handed to
%% Clay before the layout, the default font's metrics registered once so
%% that what Clay measured is what raylib draws, and the frame itself as
%% one goal. A game loop with a user interface in it is therefore
%%
%%     loop :- ray_begin, ray_clear(raywhite),
%%             clay_ray_frame(box(root, [size(grow), padding(16)], [ text(hello) ])),
%%             ray_end,
%%             ( ray_closing -> true ; loop ).
%%
%% and the tree is whatever clauses build it, which is the point: a
%% button is a fact, its color a rule, and `hover(...)' in the tree is
%% how it lights up with no callback anywhere.
%%
%%   clay_ray_font/0                    raylib's default font, registered with clay; after ray_open
%%   clay_ray_input/0                   the pointer, the left button and the wheel, into clay
%%   clay_ray_input(+Drag)              ... and whether a pointer drag scrolls (true for touch)
%%   clay_ray_draw(+Commands)           every command drawn; a custom element is skipped
%%   clay_ray_draw(+Commands, +Custom)  ... a custom one calls call(Custom, Data, box(X, Y, W, H))
%%   clay_ray_frame(+Tree)              input, a layout at the window's size, drawn
%%   clay_ray_frame(+Tree, -Commands)   ... and the commands kept, for a program that asks clay_over/1
%%
%% THE FONT IS MEASURED FROM raylib ITSELF, not typed in. `ray_text_width'
%% of one character at the default font's base size, 10, is that glyph's
%% advance, and `clay_font(0, 10, Advances)' hands the ninety-five
%% printable ASCII advances to Clay, which measures a text of size S as
%% their sum scaled by S/10 with one spacing between glyphs -- exactly
%% the arithmetic of DrawTextEx, so a box Clay sized to its text is the
%% box the text fills. Any other glyph takes the mean advance, which is
%% what a byte past 127 of a UTF-8 text gets: near enough for a layout,
%% and stated. Font ids other than 0 are the program's to register with
%% `clay_font/3' before it lays out, and are DRAWN with the default font
%% here, because library(ray) draws one font.
%%
%% A ROUNDED RECTANGLE IS RAYLIB'S OWN, which rounds all four corners
%% alike: Clay's largest corner radius becomes the roundness raylib
%% takes, a fraction of the short side, and a box with no radius is a
%% plain `ray_rect'. A BORDER IS FOUR RECTANGLES, one per side at its own
%% width; the corners are square, and the border Clay draws BETWEEN
%% children arrives as rectangles of its own, so nothing is lost. AN
%% IMAGE'S DATA IS A TEXTURE HANDLE from `ray_texture_load/2', stretched
%% into its box with `ray_sprite_ex'; a tint of rgba(0,0,0,0), which is
%% what a box with no `bg' carries, draws the texture as loaded.
%%
%% NOTHING HERE OPENS A WINDOW: `ray_open' is the program's, as is
%% `ray_begin'/`ray_end' round the frame, and a clip box is raylib's
%% scissor, which needs the frame open.

:- use_module(library(clay)).
:- use_module(library(ray)).

%% ---- the font, once, after the window is open ---------------------------

clay_ray_font :-
    findall(A, ( between(32, 126, C), atom_codes(Ch, [C]), ray_text_width(Ch, 10, A) ), Advances),
    clay_font(0, 10, Advances).

%% ---- input: what Clay is told before it lays out -----------------------

clay_ray_input :- clay_ray_input(false).

clay_ray_input(Drag) :-
    ray_mouse(X, Y),
    ( ray_mouse_down(left) -> Down = true ; Down = false ),
    clay_pointer(X, Y, Down),
    ray_mouse_wheel(WX, WY),
    ray_frame_time(Dt),
    clay_scroll(Drag, WX, WY, Dt).

%% ---- the frame ----------------------------------------------------------

clay_ray_frame(Tree) :- clay_ray_frame(Tree, _).

clay_ray_frame(Tree, Commands) :-
    ray_screen_size(W, H),
    clay_ray_input,
    clay_layout(W, H, Tree, Commands),
    clay_ray_draw(Commands).

%% ---- the walk -----------------------------------------------------------

clay_ray_draw(Commands) :- clay_ray_draw(Commands, clay_ray_no_custom).

clay_ray_draw([], _).
clay_ray_draw([C|Cs], Custom) :-
    clay_ray_command(C, Custom),
    clay_ray_draw(Cs, Custom).

clay_ray_no_custom(_, _).

clay_ray_command(rect(_, box(X, Y, W, H), Rgba, corners(TL, TR, BL, BR)), _) :- !,
    clay_ray_color(Rgba, C),
    (   TL =:= 0, TR =:= 0, BL =:= 0, BR =:= 0
    ->  clay_ray_int(X, XI), clay_ray_int(Y, YI), clay_ray_int(W, WI), clay_ray_int(H, HI),
        ray_rect(XI, YI, WI, HI, C)
    ;   clay_ray_roundness(W, H, [TL, TR, BL, BR], Rd),
        ray_rect_rounded(X, Y, W, H, Rd, 8, C)
    ).
clay_ray_command(border(_, box(X, Y, W, H), Rgba, _, widths(L, R, T, B, _)), _) :- !,
    clay_ray_color(Rgba, C),
    clay_ray_int(X, XI), clay_ray_int(Y, YI), clay_ray_int(W, WI), clay_ray_int(H, HI),
    clay_ray_int(L, LI), clay_ray_int(R, RI), clay_ray_int(T, TI), clay_ray_int(B, BI),
    ( LI > 0 -> ray_rect(XI, YI, LI, HI, C) ; true ),
    ( RI > 0 -> XR is XI + WI - RI, ray_rect(XR, YI, RI, HI, C) ; true ),
    ( TI > 0 -> ray_rect(XI, YI, WI, TI, C) ; true ),
    ( BI > 0 -> YB is YI + HI - BI, ray_rect(XI, YB, WI, BI, C) ; true ).
clay_ray_command(text(_, box(X, Y, _, _), Codes, font(_, Size, Spacing, _), Rgba), _) :- !,
    clay_ray_color(Rgba, C),
    ray_text_ex(Codes, X, Y, Size, Spacing, C).
clay_ray_command(scissor_start(_, box(X, Y, W, H), _), _) :- !,
    clay_ray_int(X, XI), clay_ray_int(Y, YI), clay_ray_int(W, WI), clay_ray_int(H, HI),
    ray_scissor_begin(XI, YI, WI, HI).
clay_ray_command(scissor_end(_, _), _) :- !,
    ray_scissor_end.
clay_ray_command(image(_, box(X, Y, W, H), Tex, Rgba, _), _) :- !,
    (   integer(Tex), ray_texture_size(Tex, TW, TH)
    ->  clay_ray_tint(Rgba, Tint),
        ray_sprite_ex(Tex, rect(0, 0, TW, TH), rect(X, Y, W, H), 0, 0, 0.0, Tint)
    ;   throw(error(domain_error(ray_texture, Tex), clay_ray_draw/1))
    ).
clay_ray_command(custom(_, Box, Data, _, _), Custom) :- !,
    call(Custom, Data, Box).
clay_ray_command(C, _) :-
    throw(error(domain_error(clay_command, C), clay_ray_draw/1)).

%% ---- the small helpers --------------------------------------------------

clay_ray_color(rgba(R, G, B, A), rgba(R, G, B, A)).

%% no tint is white: raylib multiplies by the tint, and white is as loaded
clay_ray_tint(rgba(0, 0, 0, 0), white) :- !.
clay_ray_tint(Rgba, Rgba).

clay_ray_int(N, I) :- I is round(N).

%% raylib's roundness is a fraction of half the short side; Clay's radius
%% is in pixels, and the largest of the four corners stands for all
clay_ray_roundness(W, H, Corners, Rd) :-
    max_list(Corners, R),
    Short is min(W, H),
    (   Short =< 0
    ->  Rd = 0.0
    ;   Rd0 is 2 * R / Short,
        Rd is min(1.0, Rd0)
    ).
