%% LIBRARY 47 -- library(clay): a user interface as a term, laid out by Clay
%%
%%     ./cocolog run tutorials/library/47-clay.pl main
%%
%% TIER 2: `use_module(library(clay))', a `.so' from `modules/clay'. It
%% needs nothing but a C compiler: `sh modules/clay/build.sh'. Clay is
%% Nic Barker's single-header flex-box layout engine (zlib), vendored as
%% modules/clay/clay.h.
%%
%% A SCREEN IS A TREE OF BOXES, AND THE TREE IS A TERM. Clay takes the
%% tree -- every box with its sizing, padding, direction and color --
%% works out where each one lands, and answers a flat list of RENDER
%% COMMANDS in draw order: a rectangle here, a text there, clip to this
%% box until further notice. It opens no window and draws nothing; what
%% a program does with the commands is its own affair. library(clay_ray)
%% draws them with library(ray); this lesson holds them to numbers.
%%
%% THE SURFACE:
%%
%%     clay_layout(+W, +H, +Tree, -Commands)      one frame, start to finish
%%     clay_begin(+W, +H)  clay_tree(+Tree)  clay_end(-Commands)   or by hand
%%     clay_box(+Id, -X, -Y, -W, -H)             where an element landed
%%     clay_over(+Id)   clay_hovered              the pointer, last frame
%%     clay_pointer(+X, +Y, +Down)               told before a frame
%%     clay_scroll(+Drag, +DX, +DY, +Dt)         the wheel, before a frame
%%     clay_scroll_data(+Id, -SX, -SY, -W, -H, -CW, -CH)
%%     clay_font(+Id, +Base, +Advances)          a font's metrics, from a renderer
%%     clay_capacity(+Elements, +Words)  clay_debug(+Bool)
%%     clay_color(?Name, ?R, ?G, ?B)  clay_rgba(+Color, -R, -G, -B, -A)
%%
%% A TREE is box(Id, Opts, Children), box(Opts, Children), text(Text),
%% text(Text, Opts), or a list of trees. An Id is an atom, Name/Index
%% for the Nth of a kind, or local(Name). A box's Opts are among
%%
%%     width(S) height(S) size(S) size(W, H)    S: fit grow fixed(N) N
%%                                              percent(P) fit(Min, Max) grow(Min, Max)
%%     padding(N) padding(X, Y) padding(L, R, T, B)   gap(N)
%%     direction(row | column)   align(X, Y) align(center)
%%     bg(Color)  radius(N)  border(Color, N)   clip  scroll
%%     aspect(Ratio)  image(Data)  custom(Data)
%%     floating([offset(X, Y), attach(Element, Parent), to(root), z(N), ...])
%%     hover(Opts)     laid over the rest while the pointer is on this Id
%%
%% and a text's among size(N) color(C) font(Id) spacing(N) line_height(N)
%% wrap(words | newlines | none) align(left | center | right).
%%
%% A COMMAND is rect(Id, box(X, Y, W, H), rgba(R, G, B, A), corners(...)),
%% border(...), text(Id, box(...), Codes, font(Font, Size, Spacing, LH),
%% rgba(...)), image(Id, box(...), Data, ...), custom(...),
%% scissor_start(Id, box(...), clip(H, V)) and scissor_end(Id, box(...)).
%%
%% WHY THIS SHAPE. Every user-interface library there is wants a callback
%% -- a function to call when the button is pressed -- and a Prolog
%% program has no function to give. Clay wants nothing: the program
%% tells it where the pointer is, lays out the frame, and asks
%% `clay_over/1' or reads `hover(...)' in the tree. A button is then a
%% fact, whether it is lit is a rule over the pointer, and what pressing
%% it does is a clause the LOOP runs when `ray_mouse_pressed(left)' and
%% `clay_over(button)' hold together. The world is the knowledge base,
%% exactly as it is for library(ray)'s games.
%%
%% THIS FILE OPENS NO WINDOW, and needs none: a layout engine is
%% arithmetic. The drawn half is library(clay_ray), one goal in a raylib
%% loop -- shown at the end, not run -- and test/clay.pl draws it where
%% there is glass and reads the pixels back.

:- use_module(library(clay)).

main :-
    format("~n-- one frame: a root, a header and a body~n"),
    Tree = box(root, [size(grow), direction(column), padding(16), gap(8), bg(raywhite)],
               [ box(header, [height(48), width(grow), bg(darkblue)],
                     [ text('cocolog', [size(24), color(white)]) ]),
                 box(body, [size(grow), bg(lightgray)], []) ]),
    clay_layout(640, 360, Tree, Commands),
    length(Commands, N),
    must('four commands: three rectangles and a text', N, 4),
    Commands = [rect(_, box(RX, RY, RW, RH), rgba(RR, RG, RB, RA), _) | _],
    must('the root fills the frame', RX-RY-RW-RH, 0.0-0.0-640.0-360.0),
    must('and carries raywhite', RR-RG-RB-RA, 245-245-245-255),
    clay_box(header, HX, HY, HW, HH),
    must('the header is inside the padding, 48 high', HX-HY-HW-HH, 16.0-16.0-608.0-48.0),
    clay_box(body, BX, BY, BW, BH),
    must('the body grows to what is left, past the gap', BX-BY-BW-BH, 16.0-72.0-608.0-272.0),
    show('commands', Commands),

    format("~n-- sizing: fixed, grow and percent share a row~n"),
    clay_layout(300, 100,
        box(r, [size(grow), direction(row)],
            [ box(a, [width(100), height(grow), bg(red)], []),
              box(b, [width(grow), height(grow), bg(blue)], []),
              box(c, [width(percent(0.25)), height(grow), bg(lime)], []) ]), _),
    clay_box(a, _, _, WA, _), clay_box(b, _, _, WB, _), clay_box(c, _, _, WC, _),
    must('100 fixed, a quarter, and grow takes the rest', WA-WB-WC, 100.0-125.0-75.0),
    clay_layout(200, 200, box(r, [size(grow), align(center)], [ box(dot, [size(50), bg(red)], []) ]), _),
    clay_box(dot, DX, DY, _, _),
    must('align(center) centres a child', DX-DY, 75.0-75.0),

    format("~n-- text is measured, so a box can fit it~n"),
    %% with no font registered a glyph is 0.6 of the size: deterministic
    %% on every machine, which is what a lesson and a test want
    clay_layout(400, 100, box(r, [size(fit), padding(10)], [ text(hello, [size(20)]) ]), [text(_, box(TX, TY, TW, TH), Codes, _, _)]),
    must('a text of five glyphs at 20 is 60 wide', TX-TY-TW-TH, 10.0-10.0-60.0-20.0),
    must('its content comes back as codes', Codes, "hello"),
    clay_box(r, _, _, FW, FH),
    must('and the fit box wraps it plus its padding', FW-FH, 80.0-40.0),
    %% a renderer registers real metrics: every glyph 7 wide at base 10
    findall(7, between(32, 126, _), Advances),
    clay_font(1, 10, Advances),
    clay_layout(400, 100, box(r, [size(grow)], [ text(abcd, [size(20), font(1)]) ]), [text(_, box(_, _, MW, _), _, _, _)]),
    must('a registered font measures by its advances, scaled by the size', MW, 56.0),
    clay_layout(100, 200, box(r, [size(grow)], [ text('one two three four', [size(10), wrap(words)]) ]), Wrapped),
    length(Wrapped, Lines),
    must('a text wraps at its box, one command per line', Lines, 2),

    format("~n-- the pointer: hover is a rule, not a callback~n"),
    Buttons = box(bar, [size(grow), direction(row)],
                  [ box(button/1, [size(grow), bg(gray), hover([bg(lime)])], []),
                    box(button/2, [size(grow), bg(gray), hover([bg(lime)])], []) ]),
    %% THE ORDER IS THE LOOP'S: a frame is laid out, then the pointer is
    %% told, judged against that frame, then the next frame reads it
    clay_layout(200, 100, Buttons, _),
    clay_pointer(150, 50, false),
    ( clay_over(button/2) -> Over = button/2 ; Over = none ),
    must('the pointer, told after a frame, is over what that frame laid out', Over, button/2),
    clay_layout(200, 100, Buttons, [_, rect(_, _, rgba(LR, LG, LB, _), _)]),
    must('and hover([bg(lime)]) lights it in the frame that follows', LR-LG-LB, 0-158-47),
    clay_pointer(10, 10, false),
    clay_layout(200, 100, Buttons, _),
    clay_layout(200, 100, Buttons, [_, rect(_, _, rgba(GR, _, _, _), _)]),
    must('... and it goes back to gray when the pointer leaves', GR, 130),

    format("~n-- scrolling: a clip that moves by the wheel~n"),
    View = box(view, [size(100), scroll], [ box(tall, [width(100), height(400), bg(red)], []) ]),
    clay_layout(100, 100, View, [scissor_start(_, box(_, _, SW, SH), _), _, scissor_end(_, _)]),
    must('a scroll box clips its content', SW-SH, 100.0-100.0),
    clay_pointer(50, 50, false),
    clay_scroll(false, 0, -3, 0.016),
    clay_layout(100, 100, View, [_, rect(_, box(_, ScrollY, _, _), _, _), _]),
    must('three notches down move the content thirty pixels up', ScrollY, -30.0),
    clay_scroll_data(view, _, SY, _, _, _, ContentH),
    must('clay_scroll_data says where it is and how tall the content is', SY-ContentH, (-30.0)-400.0),

    format("~n-- what goes wrong is an error, not a frame with holes~n"),
    catch(clay_layout(100, 100, box(a, [size(grow), nosuch(1)], []), _), error(E1, _), true),
    must('an option nobody defined', E1, domain_error(clay_option, nosuch(1))),
    catch(clay_layout(100, 100, box(a, [size(grow)], [wat]), _), error(E2, _), true),
    must('a tree that is no tree', E2, type_error(clay_tree, wat)),
    clay_layout(100, 100, box(a, [size(grow), bg(red)], []), After),
    length(After, NA),
    must('and the frame after a throw is clean', NA, 1),

    format("~n-- drawn with raylib, in a loop (not run here):~n"),
    format("     :- use_module(library(clay_ray)).~n"),
    format("     loop :- ray_begin, ray_clear(raywhite),~n"),
    format("             clay_ray_frame(box(root, [size(grow), padding(16)], [ text(hello) ])),~n"),
    format("             ray_end,~n"),
    format("             ( ray_closing -> true ; loop ).~n"),
    format("     ?- ray_open(640, 360, coco), clay_ray_font, loop.~n"),
    format("~n     clay_ray_frame/1 hands Clay the mouse and the wheel, lays out at the~n"),
    format("     window's size and walks the commands into ray_rect, ray_text_ex,~n"),
    format("     ray_scissor_begin and the rest; clay_ray_font registers raylib's~n"),
    format("     default font so what Clay measured is what raylib draws.~n"),

    format("~ndone~n").

show(What, Value) :- format("     ~w: ~q~n", [What, Value]).

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
