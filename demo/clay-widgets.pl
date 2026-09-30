%% cocolog -- demo/clay-widgets.pl: every shape library(clay) lays out, in one
%% window, drawn by library(clay_ray) -- and the WORLD IS CLAUSES.
%%
%%     COCOLOG_LIBRARY=$PWD/library ./cocolog -s demo/clay-widgets.pl
%%     ... -- --seconds 20 --shot /tmp/clay.png     (a bounded run, and a photograph)
%%
%% A menu whose selected item is a fact, cards that light up under the
%% pointer with a tooltip floating beside them, progress bars that are
%% percent sizing, a counter and a toggle switch that change on a click,
%% a table of sample rows in a scroll container the wheel moves, an image
%% that is a canvas drawn once with library(ray), a custom element drawn
%% by a clause of this file, and a status bar that reads the frame count
%% and the mouse. Escape or the window's close box ends it.
%%
%% THERE IS NO CALLBACK ANYWHERE. Every frame the tree is rebuilt from
%% the clauses below, Clay lays it out, clay_ray draws it, and then the
%% loop asks `ray_mouse_pressed(left)' and `clay_over(Id)' and asserts
%% what changed.

:- use_module(library(clay_ray)).
:- use_module(library(main)).

:- dynamic selected/1, count/1, toggled/1, frame/1, canvas/1, tips/1.

%% ---- the sample data, as facts ---------------------------------------------

menu_item(1, 'Dashboard').
menu_item(2, 'Reports').
menu_item(3, 'Knowledge base').
menu_item(4, 'Settings').

card(1, 'Layout',   'Clay computes where every box lands: flex rows and columns, fit, grow, fixed and percent sizing.', skyblue, 'clay_layout/4').
card(2, 'No callbacks', 'A hover is a rule and a click is a clause the loop runs -- nothing calls back into Prolog.', lime, 'clay_over/1').
card(3, 'Render commands', 'The result is a flat list of rect, text, border, image and scissor commands, in draw order.', gold, 'clay_end/1').

bar(1, 'Store', 0.72, green).
bar(2, 'Trail', 0.35, blue).
bar(3, 'Heap',  0.91, orange).

row(1,  'Italy',    59000000, 0.19).
row(2,  'Spain',    48000000, 0.16).
row(3,  'France',   68000000, 0.22).
row(4,  'Germany',  84000000, 0.27).
row(5,  'Portugal', 10000000, 0.03).
row(6,  'Greece',   10000000, 0.03).
row(7,  'Austria',   9000000, 0.03).
row(8,  'Belgium',  12000000, 0.04).
row(9,  'Ireland',   5000000, 0.02).
row(10, 'Norway',    5000000, 0.02).

paragraph('This paragraph wraps at the width of its box, one render command per line, because Clay measured the text with the metrics clay_ray_font registered from raylib -- so the box Clay sized is the box the text fills.').

%% ---- the tree, rebuilt every frame from the facts --------------------------

ui(W, H, Tree) :-
    frame(F), count(C), ( toggled(true) -> On = true ; On = false ),
    ray_mouse(MX, MY),
    format(atom(Status), 'frame ~w   mouse ~w,~w   ~wx~w', [F, MX, MY, W, H]),
    findall(Item, menu_button(Item), Menu),
    findall(Card, a_card(Card), Cards),
    findall(Bar, a_bar(Bar), Bars),
    findall(Row, a_row(Row), Rows),
    paragraph(Para),
    canvas(Tex),
    ( selected(Sel), menu_item(Sel, SelName) -> true ; SelName = 'nothing' ),
    format(atom(Heading), '~w', [SelName]),
    format(atom(CountText), ' ~w ', [C]),
    ( On == true -> Knob = right, TrackColor = green ; Knob = left, TrackColor = gray ),
    pill('new', blue, P1), pill('beta', orange, P2), pill('ok', green, P3), Pills = [P1, P2, P3],
    Tree = box(root, [size(grow), direction(column), bg(raywhite)],
      [ box(topbar, [width(grow), height(56), direction(row), padding(16, 12), gap(16), align(left, center), bg(darkblue)],
            [ text('cocolog', [size(24), color(white)]),
              text('library(clay) -- every widget is a term', [size(14), color(skyblue)]),
              box(spacer, [width(grow)], []),
              text(Status, [size(14), color(lightgray)]) ]),
        box(main, [size(grow), direction(row)],
            [ box(sidebar, [width(210), height(grow), direction(column), padding(12), gap(6), bg(rgb(236, 238, 242))],
                  [ text('MENU', [size(12), color(gray)]) | Menu ]),
              box(content, [size(grow), direction(column), padding(20), gap(14), scroll(false, true)],
                  [ text(Heading, [size(26), color(darkblue)]),
                    box(cards, [width(grow), height(fit), direction(row), gap(12)], Cards),
                    box(section1, [width(grow), height(fit), direction(row), gap(24)],
                        [ box(barsbox, [width(grow), height(fit), direction(column), gap(8), padding(12), bg(white), radius(8), border(lightgray, 1)],
                              [ text('Progress bars: percent sizing', [size(14), color(darkgray)]) | Bars ]),
                          box(controls, [width(fit), height(fit), direction(column), gap(10), padding(12), bg(white), radius(8), border(lightgray, 1)],
                              [ text('Controls: a click is a clause', [size(14), color(darkgray)]),
                                box(counter, [width(fit), height(fit), direction(row), gap(6), align(left, center)],
                                    [ box(minus, [size(32), align(center), radius(6), bg(lightgray), hover([bg(pink)])], [ text('-', [size(20), color(black)]) ]),
                                      box(countbox, [width(48), height(32), align(center), radius(6), border(gray, 1)], [ text(CountText, [size(18), color(black)]) ]),
                                      box(plus, [size(32), align(center), radius(6), bg(lightgray), hover([bg(lime)])], [ text('+', [size(20), color(black)]) ]),
                                      text('counter', [size(13), color(gray)]) ]),
                                box(toggle_row, [width(fit), height(fit), direction(row), gap(8), align(left, center)],
                                    [ box(toggle, [width(52), height(26), radius(13), bg(TrackColor), padding(3), align(Knob, center)],
                                          [ box(knob, [size(20), radius(10), bg(white)], []) ]),
                                      text('toggle switch', [size(13), color(gray)]) ]),
                                box(pills, [width(fit), height(fit), direction(row), gap(6)], Pills) ]) ]),
                    box(section2, [width(grow), height(fit), direction(row), gap(24)],
                        [ box(tablebox, [width(grow), height(fit), direction(column), gap(0), padding(12), bg(white), radius(8), border(lightgray, 1)],
                              [ text('A table: one fact per row, the wheel scrolls the page', [size(14), color(darkgray)]),
                                box(thead, [width(grow), height(28), direction(row), align(left, center), border(gray, 0, 0, 0, 1)],
                                    [ box(th1, [width(120)], [ text('country', [size(13), color(gray)]) ]),
                                      box(th2, [width(110)], [ text('population', [size(13), color(gray)]) ]),
                                      box(th3, [width(grow)], [ text('share', [size(13), color(gray)]) ]) ])
                              | Rows ]),
                          box(media, [width(fit), height(fit), direction(column), gap(10), padding(12), bg(white), radius(8), border(lightgray, 1)],
                              [ text('An image and a custom element', [size(14), color(darkgray)]),
                                box(mediarow, [width(fit), height(fit), direction(row), gap(10)],
                                    [ box(picture, [size(96), radius(8), image(Tex)], []),
                                      box(gauge, [size(96), custom(gauge(C))], []) ]),
                                text('the image is a canvas drawn once', [size(12), color(gray)]),
                                text('the gauge is a clause of this file', [size(12), color(gray)]) ]) ]),
                    box(parabox, [width(grow), height(fit), padding(12), bg(white), radius(8), border(lightgray, 1)],
                        [ text(Para, [size(15), color(darkgray), wrap(words)]) ]),
                    box(tail, [width(grow), height(80), radius(8), bg(rgb(230, 240, 250)), align(center)],
                        [ text('scrolled to the end -- the content is a scroll container', [size(14), color(darkblue)]) ]) ]) ]),
        box(statusbar, [width(grow), height(28), direction(row), padding(12, 0), align(left, center), bg(darkgray)],
            [ text('click the menu, the cards, + and -, the switch; wheel over the page; Esc to quit', [size(12), color(raywhite)]) ]) ]).

menu_button(box(button/N, Opts, [ text(Name, [size(16), color(TextColor)]) ])) :-
    menu_item(N, Name),
    (   selected(N)
    ->  Opts = [width(grow), height(36), padding(10, 8), align(left, center), radius(6), bg(blue)], TextColor = white
    ;   Opts = [width(grow), height(36), padding(10, 8), align(left, center), radius(6), bg(rgb(236, 238, 242)), hover([bg(skyblue)])], TextColor = darkgray
    ).

a_card(box(card/N, [width(grow), height(fit), direction(column), gap(8), padding(12), bg(white), radius(8), border(lightgray, 1), hover([border(Color, 2)])],
                   [ box(cardhead/N, [width(grow), height(fit), direction(row), gap(8), align(left, center)],
                         [ box(swatch/N, [size(14), radius(7), bg(Color)], []),
                           text(Title, [size(18), color(black)]) ]),
                     text(Body, [size(13), color(darkgray), wrap(words)]),
                     Pill
                   | Tip ])) :-
    card(N, Title, Body, Color, Pred),
    pill(Pred, Color, Pill),
    (   clay_over(card/N)
    ->  format(atom(TipText), 'card ~w is under the pointer', [N]),
        Tip = [ box(tooltip/N, [floating([attach(left_top, left_bottom), offset(0, 6), z(10)]), padding(8, 6), radius(4), bg(black)],
                    [ text(TipText, [size(12), color(white)]) ]) ]
    ;   Tip = []
    ).

pill(Text, Color, box(Id, [width(fit), height(fit), padding(8, 3), radius(10), bg(Color)], [ text(Text, [size(11), color(white)]) ])) :-
    atom_concat(pill_, Text, Id).

a_bar(box(barrow/K, [width(grow), height(fit), direction(column), gap(3)],
          [ box(barlabels/K, [width(grow), height(fit), direction(row)],
                [ text(Label, [size(12), color(gray)]), box(sp/K, [width(grow)], []), text(Pct, [size(12), color(gray)]) ]),
            box(track/K, [width(grow), height(12), radius(6), bg(lightgray)],
                [ box(fill/K, [width(percent(Fraction)), height(grow), radius(6), bg(Color)], []) ]) ])) :-
    bar(K, Label, Fraction, Color),
    P is round(Fraction * 100), format(atom(Pct), '~w%', [P]).

a_row(box(row/K, [width(grow), height(26), direction(row), align(left, center), border(rgb(235, 235, 235), 0, 0, 0, 1), hover([bg(rgb(245, 248, 255))])],
          [ box(td1/K, [width(120)], [ text(Name, [size(13), color(black)]) ]),
            box(td2/K, [width(110)], [ text(PopText, [size(13), color(darkgray)]) ]),
            box(td3/K, [width(grow), height(10), radius(5), bg(lightgray)],
                [ box(share/K, [width(percent(Share)), height(grow), radius(5), bg(skyblue)], []) ]) ])) :-
    row(K, Name, Pop, Share),
    M is Pop // 1000000, format(atom(PopText), '~w M', [M]).

%% ---- a custom element: a gauge drawn with ray, from the counter -----------

draw_custom(gauge(N), box(X, Y, W, H)) :-
    CX is round(X + W / 2), CY is round(Y + H / 2), R is min(W, H) / 2 - 4,
    ray_circle(CX, CY, R, lightgray),
    Sides is max(3, min(12, 3 + abs(N))),
    Inner is R - 8,
    ray_poly(CX, CY, Sides, Inner, 0.0, maroon),
    ray_poly_lines(CX, CY, Sides, Inner, 0.0, black),
    format(atom(T), '~w', [Sides]),
    TX is CX - 5, TY is CY - 8,
    ray_text_ex(T, TX, TY, 16, 1, white).

%% ---- the loop: one frame is input, layout, draw, then the clicks ------------

loop(Deadline, Shot) :-
    ray_begin,
    ray_clear(raywhite),
    ray_screen_size(W, H),
    clay_ray_input,
    ui(W, H, Tree),
    clay_layout(W, H, Tree, Commands),
    clay_ray_draw(Commands, draw_custom),
    ray_end,
    retract(frame(F)), F1 is F + 1, assertz(frame(F1)),
    clicks,
    ( Shot \== none, F1 =:= 12 -> ray_screenshot(Shot), format("photographed ~w~n", [Shot]) ; true ),
    ray_time(Now),
    (   ( ray_closing ; ray_key_pressed(escape) ; Now > Deadline )
    ->  true
    ;   loop(Deadline, Shot)
    ).

clicks :-
    (   ray_mouse_pressed(left)
    ->  (   menu_item(N, _), clay_over(button/N) -> retractall(selected(_)), assertz(selected(N))
        ;   clay_over(plus) -> retract(count(C)), C1 is C + 1, assertz(count(C1))
        ;   clay_over(minus) -> retract(count(C)), C1 is C - 1, assertz(count(C1))
        ;   clay_over(toggle) -> retract(toggled(T)), ( T == true -> T1 = false ; T1 = true ), assertz(toggled(T1))
        ;   true
        )
    ;   true
    ).

%% ---- the image: a canvas drawn once, then a texture like any other ---------

make_canvas(Tex) :-
    ray_canvas(96, 96, Tex),
    ray_canvas_begin(Tex),
    ray_clear(darkblue),
    forall(between(0, 7, I), ( X is I * 12, G is 60 + I * 24, ray_rect(X, 0, 12, 96, rgb(30, G, 200)) )),
    ray_circle(48, 48, 28.0, gold),
    ray_poly(48.0, 48.0, 6, 18.0, 30.0, maroon),
    ray_canvas_end.

main(Args) :-
    argv_options(Args, _, Opts),
    ( memberchk(seconds(S), Opts) -> true ; S = 600 ),
    ( memberchk(shot(Shot), Opts) -> true ; Shot = none ),
    ray_log_level(warning),
    ray_open(960, 620, 'cocolog -- library(clay)'),
    ( ray_ready -> true ; format("no window came~n"), fail ),
    ray_fps(60),
    clay_ray_font,
    make_canvas(Tex), assertz(canvas(Tex)),
    assertz(selected(1)), assertz(count(3)), assertz(toggled(true)), assertz(frame(0)),
    ray_time(T0), Deadline is T0 + S,
    loop(Deadline, Shot),
    ray_close,
    frame(F), format("~w frames~n", [F]).
