%% library(clay) -- a user interface as a term, held to COORDINATES.
%%
%% A LAYOUT ENGINE IS ARITHMETIC, AND ARITHMETIC NEEDS NO WINDOW. Every
%% check below hands `clay_layout/4' a tree and holds what came back --
%% where each box landed, what color it carries, how a text was measured,
%% which command follows which -- to the number, in this process, with no
%% display and no raylib. That is the whole argument for clay's shape:
%% the layout is one thing and the drawing another, so the part that
%% decides can be pinned on any machine.
%%
%% THE DRAWING HALF, library(clay_ray), is a walk over the commands into
%% library(ray), and its windowed check is one section at the end: it
%% SKIPs by name where no glass can be had, exactly as test/ray.pl does,
%% and where there is a window it draws one frame and reads pixels back.
%%
%%     cocolog -s test/clay.pl        from the checkout root
%%
%% SKIPs without library/clay.so -- sh modules/clay/build.sh, which needs
%% nothing but a C compiler.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/clay.so') -> true ; skip('(no library/clay.so -- sh modules/clay/build.sh)') ),
    ( catch(use_module(library(clay)), _, fail) -> true ; skip('(library(clay) will not load)') ),
    the_coco_half,
    a_frame,
    sizing,
    text_and_fonts,
    ids_and_the_pointer,
    scrolling,
    floating_and_data,
    what_goes_wrong,
    (   exists_file('library/ray.so'), catch(use_module(library(clay_ray)), _, fail),
        display_runner(Run), the_glass(Run)
    ->  drawn_with_ray(Run)
    ;   format("     (skipped: library(clay_ray) on glass -- no ray.so, no display, or no window came)~n", [])
    ),
    checks_done.

%% ---- the palette and the specs are clauses ------------------------------

the_coco_half :-
    section('the Coco half: the palette and a color spec'),
    written(clay_color(maroon, R1, G1, B1), R1-G1-B1, X1),
    check('the palette is raylib''s, byte for byte', X1, '190-33-55'),
    written(( findall(N2, clay_color(N2, _, _, _), L2), length(L2, X2) ), X2, G2),
    check('all twenty-five of it', G2, '25'),
    written(clay_rgba(rgb(1, 2, 3), R3, G3, B3, A3), R3-G3-B3-A3, X3),
    check('rgb/3 takes alpha 255', X3, '1-2-3-255'),
    answer(clay_rgba(nosuch, _, _, _, _), ok, X4), ball(X4, B4),
    check('a color nobody named is a domain error', B4, domain_error(clay_color, nosuch)).

%% the shape of a ball with its context taken off: check/3 compares with ==
ball(error(error(E, _)), E) :- !.
ball(error(E), E) :- !.
ball(X, X).

%% ---- one frame, and where things land ------------------------------------

a_frame :-
    section('a frame: a root, a header and a body'),
    Tree = box(root, [size(grow), direction(column), padding(16), gap(8), bg(raywhite)],
               [ box(header, [height(48), width(grow), bg(darkblue)], []),
                 box(body, [size(grow), bg(lightgray)], []) ]),
    answer(clay_layout(640, 360, Tree, Cmds), Cmds, G1),
    (   G1 = [rect(_, box(X1, Y1, W1, H1), rgba(R1, G1a, B1, A1), _),
              rect(_, box(X2, Y2, W2, H2), _, _),
              rect(_, box(X3, Y3, W3, H3), _, _)]
    ->  true
    ;   X1 = G1
    ),
    check('three rectangles, in draw order', X1-Y1-W1-H1, 0.0-0.0-640.0-360.0),
    check('the root carries its color', R1-G1a-B1-A1, 245-245-245-255),
    check('the header is padded in and 48 high', X2-Y2-W2-H2, 16.0-16.0-608.0-48.0),
    check('the body grows to what is left, past the gap', X3-Y3-W3-H3, 16.0-72.0-608.0-272.0),
    answer(( clay_layout(640, 360, Tree, _), clay_box(body, BX, BY, BW, BH) ), BX-BY-BW-BH, G2),
    check('clay_box asks where an element landed', G2, 16.0-72.0-608.0-272.0),
    answer(( clay_layout(200, 100, box(a, [size(grow)], [box(b, [size(10)], [])]), Cs3), length(Cs3, N3) ), N3, G3),
    check('a box with no color draws nothing', G3, 0),
    answer(( clay_layout(200, 100, [ box(a, [size(50), bg(red)], []), box(b, [size(50), bg(blue)], []) ], Cs4),
             Cs4 = [rect(_, box(_, _, _, _), _, _), rect(_, box(X4, _, _, _), _, _)] ), X4, G4),
    check('a list of trees is siblings in a row', G4, 50.0).

%% ---- sizing: fit, grow, fixed, percent, min and max ----------------------

sizing :-
    section('sizing'),
    answer(( clay_layout(300, 100,
                 box(r, [size(grow), direction(row)],
                     [ box(a, [width(100), height(grow), bg(red)], []),
                       box(b, [width(grow), height(grow), bg(blue)], []),
                       box(c, [width(percent(0.25)), height(grow), bg(lime)], []) ]), _),
             clay_box(a, _, _, WA, _), clay_box(b, _, _, WB, _), clay_box(c, _, _, WC, _) ), WA-WB-WC, G1),
    check('fixed, grow and percent share a row', G1, 100.0-125.0-75.0),
    answer(( clay_layout(300, 100,
                 box(r, [size(grow), direction(row), gap(10)],
                     [ box(a, [width(grow(50, 80)), height(grow), bg(red)], []),
                       box(b, [width(grow), height(grow), bg(blue)], []) ]), _),
             clay_box(a, _, _, WA, _), clay_box(b, _, _, WB, _) ), WA-WB, G2),
    check('grow(Min, Max) is capped, and the rest goes to the other', G2, 80.0-210.0),
    answer(( clay_layout(300, 100,
                 box(r, [size(grow), padding(10, 20)],
                     [ box(a, [size(fit), padding(5), bg(red)],
                           [ box(inner, [size(30), bg(blue)], []) ]) ]), _),
             clay_box(a, AX, AY, AW, AH), clay_box(inner, IX, IY, _, _) ), AX-AY-AW-AH-IX-IY, G3),
    check('fit wraps its child plus padding, inside the parent''s', G3, 10.0-20.0-40.0-40.0-15.0-25.0),
    answer(( clay_layout(200, 200,
                 box(r, [size(grow), align(center)], [ box(a, [size(50), bg(red)], []) ]), _),
             clay_box(a, AX, AY, _, _) ), AX-AY, G4),
    check('align(center) centres the child both ways', G4, 75.0-75.0),
    answer(( clay_layout(200, 200,
                 box(r, [size(grow), align(right, bottom)], [ box(a, [size(50), bg(red)], []) ]), _),
             clay_box(a, AX, AY, _, _) ), AX-AY, G5),
    check('align(right, bottom) puts it in the corner', G5, 150.0-150.0),
    answer(( clay_layout(200, 100, box(r, [size(grow), bg(red), radius(8)], []), [rect(_, _, _, corners(TL, TR, BL, BR))]) ),
           TL-TR-BL-BR, G6),
    check('a radius rides on the rectangle', G6, 8.0-8.0-8.0-8.0),
    answer(( clay_layout(200, 100, box(r, [size(grow), border(black, 3)], []), [border(_, box(_, _, W, H), rgba(R, _, _, _), _, widths(L, Rt, T, B, Bw))]) ),
           W-H-R-L-Rt-T-B-Bw, G7),
    check('a border is its own command, with its widths', G7, 200.0-100.0-0-3-3-3-3-0),
    answer(( clay_layout(200, 100, box(r, [width(100), aspect(2.0), bg(red)], []), _),
             clay_box(r, _, _, W, H) ), W-H, G8),
    check('aspect(Ratio) sets the other axis from the one given', G8, 100.0-50.0).

%% ---- text: measured with the default metric, or a registered font --------

text_and_fonts :-
    section('text, measured'),
    %% with no font registered, a glyph is 0.6 of the size wide
    answer(( clay_layout(400, 100, box(r, [size(grow), padding(10)], [ text(hello, [size(20), color(black)]) ]),
                         [text(_, box(X, Y, W, H), Codes, font(F, S, Sp, LH), rgba(R, G, B, A))]) ),
           X-Y-W-H-Codes-F-S-Sp-LH-R-G-B-A, G1),
    check('a text command: its box, its codes, its font and color', G1,
          10.0-10.0-60.0-20.0-[104,101,108,108,111]-0-20-0-0-0-0-0-255),
    answer(( clay_layout(400, 100, box(r, [size(grow)], [ text(abc, [size(10), spacing(2)]) ]),
                         [text(_, box(_, _, W, _), _, font(_, _, Sp, _), _)]) ), W-Sp, G2),
    check('a letter spacing is between glyphs: 3 x 6 + 2 x 2 is 22', G2, 22.0-2),
    %% a font a renderer registered: every glyph 7 wide at base 10
    answer(( findall(7, between(32, 126, _), Adv), clay_font(1, 10, Adv),
             clay_layout(400, 100, box(r, [size(grow)], [ text(abcd, [size(20), font(1)]) ]),
                         [text(_, box(_, _, W, _), _, font(F, _, _, _), _)]) ), W-F, G3),
    check('a registered font measures by its advances, scaled by size/base', G3, 56.0-1),
    answer(( clay_layout(100, 200, box(r, [size(grow)], [ text('one two three four', [size(10), wrap(words)]) ]), Cs),
             findall(Y, member(text(_, box(_, Y, _, _), _, _, _), Cs), Ys) ), Ys, G4),
    check('a text wraps at the box, one command per line', G4, [0.0, 10.0]),
    answer(( clay_layout(100, 200, box(r, [size(grow)], [ text('one two three four', [size(10), wrap(none)]) ]), Cs),
             length(Cs, N) ), N, G5),
    check('wrap(none) is one line however long', G5, 1),
    answer(( clay_layout(100, 200, box(r, [size(grow)], [ text('one two three four', [size(10), wrap(words), align(right)]) ]), Cs),
             findall(X, member(text(_, box(X, _, _, _), _, _, _), Cs), Xs) ), Xs, G6),
    check('align(right) puts each wrapped line at the far edge', G6, [22.0, 76.0]),
    answer(( clay_layout(200, 100, box(r, [size(grow)], [ text("codes too", [size(10)]) ]),
                         [text(_, _, Codes, _, _)]) ), Codes, G7),
    check('a code list is text as well', G7, "codes too").

%% ---- ids, and the pointer ------------------------------------------------

ids_and_the_pointer :-
    section('ids, and what the pointer is over'),
    Tree = box(root, [size(grow), direction(row)],
               [ box(item/1, [size(grow), bg(red)], []),
                 box(item/2, [size(grow), bg(blue), hover([bg(lime)])], []) ]),
    answer(( clay_layout(200, 100, Tree, _), clay_box(item/2, X, _, W, _) ), X-W, G1),
    check('Name/Index ids tell siblings apart', G1, 100.0-100.0),
    %% the pointer is judged against the frame laid out BEFORE it was told,
    %% which in a loop is the previous frame; here it is the layout above
    answer(( clay_pointer(150, 50, false),
             ( clay_over(item/2) -> O = over ; O = not ), ( clay_over(item/1) -> P = over ; P = not ) ), O-P, G2),
    check('clay_over asks about the frame laid out before the pointer was told', G2, over-not),
    answer(( clay_layout(200, 100, Tree, Cs), Cs = [_, rect(_, _, rgba(R, G, B, _), _)] ), R-G-B, G3),
    check('hover(Opts) lays its options over the base ones in the frame that follows', G3, 0-158-47),
    answer(( clay_pointer(10, 10, false), clay_layout(200, 100, Tree, _), clay_layout(200, 100, Tree, Cs),
             Cs = [_, rect(_, _, rgba(R, G, B, _), _)] ), R-G-B, G4),
    check('... and not when it has moved away', G4, 0-121-241),
    answer(( clay_layout(200, 100,
                 box(a, [size(grow)], [ box(local(x), [size(20), bg(red)], []) ]), _),
             clay_layout(200, 100,
                 box(a, [size(grow)], [ box(local(x), [size(20), bg(red)], []) ]), _),
             clay_box(a, _, _, W, _) ), W, G5),
    check('local(Name) is hashed under its parent, and lays out like any id', G5, 200.0),
    answer(( clay_layout(200, 100, box(a, [size(grow), bg(red)], []), _), clay_box(nosuch, _, _, _, _) ), ok, G6),
    check('clay_box of an id nobody laid out fails', G6, failed).

%% ---- a scroll container ----------------------------------------------------

scrolling :-
    section('scrolling: a clip that moves'),
    Tree = box(view, [size(100), scroll],
               [ box(tall, [width(100), height(400), bg(red)], []) ]),
    answer(( clay_layout(100, 100, Tree, Cs), Cs = [scissor_start(_, box(_, _, W, H), clip(CH, CV)), rect(_, box(_, Y, _, _), _, _), scissor_end(_, _)] ),
           W-H-CH-CV-Y, G1),
    check('a scroll box clips, and its child starts at the top', G1, 100.0-100.0-true-true-0.0),
    answer(( clay_layout(100, 100, Tree, _), clay_pointer(50, 50, false), clay_scroll(false, 0, -5, 0.016),
             clay_layout(100, 100, Tree, Cs), Cs = [_, rect(_, box(_, Y, _, _), _, _), _],
             clay_scroll_data(view, SX, SY, VW, VH, CW, CH) ), Y-SX-SY-VW-VH-CW-CH, G2),
    check('a wheel notch moves the content ten pixels a notch, and clay_scroll_data says so', G2,
          (-50.0)-0.0-(-50.0)-100.0-100.0-100.0-400.0),
    answer(( clay_layout(100, 100, Tree, _), clay_pointer(50, 50, false), clay_scroll(false, 0, -100, 0.016),
             clay_layout(100, 100, Tree, _), clay_scroll_data(view, _, SY, _, _, _, _) ), SY, G3),
    check('and stops at the end of the content', G3, -300.0).

%% ---- floating elements, and data that rides through ------------------------

floating_and_data :-
    section('floating elements, images and custom data'),
    answer(( clay_layout(200, 200,
                 box(root, [size(grow)],
                     [ box(anchor, [size(50), bg(red)],
                           [ box(tip, [size(20), bg(blue), floating([attach(left_top, right_bottom), offset(5, 5)])], []) ]) ]), _),
             clay_box(tip, X, Y, _, _) ), X-Y, G1),
    check('a floating element attaches to its parent''s corner, plus an offset', G1, 55.0-55.0),
    answer(( clay_layout(200, 200,
                 box(root, [size(grow)],
                     [ box(pop, [size(10), bg(blue), floating([to(root), attach(center_center, center_center)])], []) ]), _),
             clay_box(pop, X, Y, _, _) ), X-Y, G2),
    check('to(root) floats over the whole frame', G2, 95.0-95.0),
    answer(( clay_layout(200, 200,
                 box(root, [size(grow)],
                     [ box(a, [size(50), bg(red)], []),
                       box(over, [size(20), bg(lime), floating([to(root), z(3)])], []) ]), Cs),
             last(Cs, rect(_, _, rgba(R, G, B, _), _)) ), R-G-B, G3),
    check('a floating element is drawn after everything under it', G3, 0-158-47),
    answer(( clay_layout(200, 200, box(pic, [size(64), image(tex(7))], []), [image(_, box(_, _, W, _), Data, _, _)]) ), W-Data, G4),
    check('an image carries its data through as a term', G4, 64.0-tex(7)),
    answer(( clay_layout(200, 200, box(c, [size(32), custom(chart([1, 2, 3]))], []), [custom(_, _, Data, _, _)]) ), Data, G5),
    check('and so does a custom element', G5, chart([1, 2, 3])).

%% ---- what goes wrong is an error, not a frame with holes -------------------

what_goes_wrong :-
    section('what goes wrong'),
    answer(clay_layout(100, 100, box(a, [size(grow), nosuch(1)], []), _), ok, G1), ball(G1, B1),
    check('an option nobody defined is a domain error', B1, domain_error(clay_option, nosuch(1))),
    answer(clay_layout(100, 100, box(a, [width(nonsense)], []), _), ok, G2), ball(G2, B2),
    check('and so is a sizing', B2, domain_error(clay_sizing, nonsense)),
    answer(clay_layout(100, 100, wat(1), _), ok, G3), ball(G3, B3),
    check('a tree that is no tree is a type error', B3, type_error(clay_tree, wat(1))),
    %% a throw inside the tree leaves no frame open behind it
    answer(( catch(clay_layout(100, 100, box(a, [size(grow)], [wat]), _), _, true),
             clay_layout(100, 100, box(a, [size(grow), bg(red)], []), Cs), length(Cs, N) ), N, G4),
    check('a frame abandoned by a throw is closed, and the next one is clean', G4, 1),
    answer(clay_tree(box(a, [], [])), ok, G5), ball(G5, B5),
    ( B5 = cocolog_error(Why5), sub_atom(Why5, _, _, _, 'outside a frame') -> V5 = refused ; V5 = B5 ),
    check('an element outside a frame is refused by name', V5, refused),
    answer(( clay_capacity(64, 128), clay_layout(100, 100, box(a, [size(grow)], []), _), clay_capacity(8192, 16384) ), ok, G6),
    check('clay_capacity takes effect at the next frame', G6, ok),
    answer(clay_font(99, 10, [1, 2]), ok, G7), ball(G7, B7),
    check('a font id past Clay''s sixteen is a domain error', B7, domain_error(clay_font_id, 99)),
    answer(( clay_debug(true), clay_layout(300, 300, box(a, [size(grow), bg(red)], []), Cs), clay_debug(false), length(Cs, N), N > 1 ), ok, G8),
    check('clay_debug(true) adds Clay''s own debug view to the commands', G8, ok).

%% ---- library(clay_ray): one frame drawn, on whatever glass there is -------
%%
%% The choreography is test/ray.pl's: a child of its own under the display
%% runner, its `answer(...)' read back, and no glass a SKIP with raylib's
%% reason. The frame is drawn TWICE because a raylib photograph is one
%% frame behind on macOS (test/ray.pl found that; CLAUDE.md has the story).

display_runner(Run) :-
    (   getenv('DISPLAY', Dpy), Dpy \== ''
    ->  Run = ''
    ;   sh_exit('command -v xvfb-run >/dev/null 2>&1', 0)
    ->  Run = 'xvfb-run -a '
    ;   fail
    ).

the_glass(Run) :-
    cocolog(C),
    sh_join([Run, C, ' query "use_module(library(ray)), ray_log_level(warning), ray_open(8, 8, probe), ( ray_ready -> write(answer(glass)) ; write(answer(none)) ), nl, ray_close" 2>&1'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    re_first_atom('answer\\(glass\\)', Out, _).

wq(Run, Goal, Got) :-
    cocolog(C),
    sh_join([Run, C, ' query "use_module(library(clay_ray)), ray_log_level(none), ', Goal, '" 2>/dev/null'], Cmd),
    proc_run(Cmd, 90000, Out, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out, A) -> sub_atom(A, 7, _, 1, Got) ; Got = '' ).

drawn_with_ray(Run) :-
    section('library(clay_ray): a frame drawn and read back by the pixel'),
    %% the tree: a raywhite root, a blue rounded box with a text in it, a
    %% maroon body with a black border -- and the pixels say each is where
    %% the layout put it
    sh_join(['ray_open(200, 100, coco), clay_ray_font, T = box(root, [size(grow), padding(10), bg(raywhite)], [box(b, [size(50), radius(8), bg(blue)], [text(hi, [size(20), color(black)])]), box(c, [size(grow), bg(maroon), border(black, 4)], [])]), ',
             'ray_begin, ray_clear(black), clay_ray_frame(T, Cs), ray_end, ray_begin, ray_clear(black), clay_ray_frame(T, _), ray_end, length(Cs, N), ',
             'ray_screen_pixel(30, 30, R1, G1, B1, _), ray_screen_pixel(150, 50, R2, G2, B2, _), ray_screen_pixel(3, 3, R3, G3, B3, _), ray_screen_pixel(65, 12, R4, G4, B4, _), ',
             'ray_close, write(answer(N-[R1,G1,B1]-[R2,G2,B2]-[R3,G3,B3]-[R4,G4,B4])), nl'], G1),
    wq(Run, G1, X1),
    check('five commands drawn: the box is blue, the body maroon, the root raywhite, the border black',
          X1, '5-[0,121,241]-[190,33,55]-[245,245,245]-[0,0,0]'),
    %% the font registered from raylib: a text box is as wide as raylib draws it
    sh_join(['ray_open(200, 100, coco), clay_ray_font, ray_text_width(hello, 20, W0), ',
             'clay_layout(200, 100, box(r, [size(grow)], [text(hello, [size(20), spacing(2)])]), [text(_, box(_, _, W1, _), _, _, _)]), ',
             'ray_close, write(answer(W0-W1)), nl'], G2),
    wq(Run, G2, X2),
    (   atomic_list_concat([A2, B2], '-', X2), atom_number(A2, WA), atom_number(B2, WB), WA =:= WB
    ->  Agree = agree
    ;   Agree = X2
    ),
    check('clay_ray_font makes Clay measure what DrawTextEx draws, to the pixel', Agree, agree).
