%% OPENCV 02 -- drawing: lines, shapes and text ON an image
%%
%%     ./cocolog run tutorials/opencv/02-drawing.pl main
%%
%% OpenCV's "Basic Drawing" and "Random generator and text" lessons. The
%% drawing predicates are the ones that MUTATE: they draw on the image
%% they are given and answer nothing, because that is what a canvas is.
%% Everything else in this library answers a new image.
%%
%%     cv_line(+Img, +P1, +P2, +Color, +Thickness)
%%     cv_rectangle(+Img, +[X, Y, W, H], +Color, +Thickness)      -1 fills
%%     cv_circle(+Img, +Center, +Radius, +Color, +Thickness)
%%     cv_ellipse(+Img, +Center, +[A, B], +Angle, +Start, +End, +Color, +Thickness)
%%     cv_polylines(+Img, +Points, +Closed, +Color, +Thickness)
%%     cv_fill_poly(+Img, +Points, +Color)
%%     cv_put_text(+Img, +Text, +Origin, +Scale, +Color, +Thickness)
%%     cv_text_size(+Text, +Scale, +Thickness, -[W, H])
%%
%% A POINT is [X, Y] -- column first, then row, the way OpenCV has it and
%% the opposite of cv_get/4's (Row, Col). A COLOR is [B, G, R] or a name.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a canvas, and the primitives~n"),
    cv_new(300, 400, '8uc3', [30, 30, 30], I),
    cv_line(I, [20, 20], [380, 20], white, 2),
    cv_rectangle(I, [20, 40, 100, 60], green, -1),
    cv_rectangle(I, [140, 40, 100, 60], green, 2),
    cv_circle(I, [320, 70], 30, red, -1),
    cv_ellipse(I, [80, 180], [60, 30], 30, 0, 360, cyan, 2),
    cv_ellipse(I, [200, 180], [50, 50], 0, 0, 180, magenta, -1),
    cv_polylines(I, [[300, 130], [380, 150], [360, 230], [290, 210]], true, yellow, 2),
    cv_fill_poly(I, [[40, 280], [120, 240], [200, 280]], blue),
    cv_put_text(I, 'cocolog + OpenCV', [220, 280], 0.7, white, 2),

    format("~n-- what the pixels say afterwards~n"),
    cv_get(I, 70, 70, Filled), must('inside the filled rectangle: green as [B, G, R]', Filled, [0, 255, 0]),
    cv_get(I, 70, 190, Hollow), must('inside the hollow one: still the ground', Hollow, [30, 30, 30]),
    cv_get(I, 70, 320, Disc), must('the disc centre is red', Disc, [0, 0, 255]),
    cv_get(I, 200, 200, Half), must('the half ellipse, filled downwards, covers (200, 200)', Half, [255, 0, 255]),
    cv_get(I, 160, 200, Above), must('and not the row above its centre', Above, [30, 30, 30]),
    cv_get(I, 270, 120, Tri), must('the triangle is blue', Tri, [255, 0, 0]),

    format("~n-- text has a size before it is drawn~n"),
    cv_text_size('cocolog + OpenCV', 0.7, 2, [TW, TH]),
    ( TW > 100, TH > 5 -> Fits = plausible ; Fits = TW-TH ),
    must('cv_text_size/4 answers [W, H] in pixels', Fits, plausible),
    show('text size', [TW, TH]),

    format("~n-- thickness -1 fills; the count of touched pixels says so~n"),
    cv_new(50, 50, '8u', 0, A), cv_rectangle(A, [10, 10, 20, 20], 255, -1),
    cv_count_nonzero(A, NA), must('a filled 20 by 20 is 400 pixels', NA, 400),
    cv_new(50, 50, '8u', 0, B), cv_rectangle(B, [10, 10, 20, 20], 255, 1),
    cv_count_nonzero(B, NB), show('the same outline, one pixel thick', NB),
    ( NB < NA -> Less = yes ; Less = no ), must('an outline is fewer pixels than a fill', Less, yes),

    out('02-drawing.png', Path), cv_imwrite(Path, I), show('written', Path),
    cv_free_all([I, A, B]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

out_dir('/tmp/cocolog-opencv').
out(File, Path) :- out_dir(D), atom_concat(D, '/', D1), atom_concat(D1, File, Path).
ensure_out :- out_dir(D), atom_concat('mkdir -p ', D, Cmd), sh(Cmd, _).

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
