%% OPENCV 06 -- thresholding: from grey to a decision
%%
%%     ./cocolog run tutorials/opencv/06-thresholding.pl main
%%
%% OpenCV's "Basic Thresholding Operations" and its adaptive sequel. A
%% threshold turns a grey image into a mask, and the five plain types
%% differ only in what they do on each side of the line. Otsu's method
%% CHOOSES the line -- the one that best separates a two-humped histogram
%% -- and the adaptive kinds move it from place to place, so uneven light
%% stops mattering.
%%
%%     cv_threshold(+Gray, +T, +Max, +Type, -Out)
%%       binary binary_inv trunc tozero tozero_inv otsu triangle
%%     cv_threshold(+Gray, +T, +Max, +Type, -Out, -Used)     the T otsu chose
%%     cv_adaptive_threshold(+Gray, +Max, +Method, +Type, +Block, +C, -Out)
%%       mean | gaussian; binary | binary_inv

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- the five plain types on one row of values, T = 100~n"),
    cv_from_list([[0, 50, 100, 150, 200, 250]], '8u', V),
    thr(V, binary, B), must('binary: 255 where V > T', B, [0, 0, 0, 255, 255, 255]),
    thr(V, binary_inv, Bi), must('binary_inv: the complement', Bi, [255, 255, 255, 0, 0, 0]),
    thr(V, trunc, Tr), must('trunc: clipped at T', Tr, [0, 50, 100, 100, 100, 100]),
    thr(V, tozero, Tz), must('tozero: zeroed below', Tz, [0, 0, 0, 150, 200, 250]),
    thr(V, tozero_inv, Ti), must('tozero_inv: zeroed above', Ti, [0, 50, 100, 0, 0, 0]),

    format("~n-- Otsu picks the threshold from the histogram~n"),
    cv_new(40, 40, '8u', 60, Two), cv_rectangle(Two, [20, 0, 20, 40], 190, -1),
    cv_noise(Two, 8, TwoN),
    cv_threshold(TwoN, 0, 255, otsu, Ot, Used), show('the T it chose (the given 0 is ignored)', Used),
    ( Used > 60, Used < 190 -> Between = between_the_humps ; Between = Used ),
    must('between 60 and 190', Between, between_the_humps),
    format("   (in the gap between two humps the between-class variance is flat,~n"),
    format("    and OpenCV answers the first maximum, just past the lower hump)~n"),
    cv_count_nonzero(Ot, NOt), must('half the pixels are above it', NOt, 800),
    cv_threshold(TwoN, 0, 255, triangle, Tri, UsedT), show('triangle chose', UsedT), cv_free(Tri),

    format("~n-- uneven light: one threshold cannot do it, the adaptive one can~n"),
    gradient_text(Img),
    cv_threshold(Img, 128, 255, binary, Global),
    cv_adaptive_threshold(Img, 255, gaussian, binary_inv, 21, 10, Local),
    cv_count_nonzero(Global, NG), cv_count_nonzero(Local, NL),
    show('pixels a global threshold keeps', NG),
    show('pixels the adaptive one keeps (the ink)', NL),
    cv_roi(Global, [0, 0, 60, 120], Left), cv_count_nonzero(Left, NLeft),
    must('globally, the dark left third is all background', NLeft, 0),
    cv_roi(Local, [0, 0, 60, 120], LeftL), cv_count_nonzero(LeftL, NLeftL),
    ( NLeftL > 50 -> Ink = ink_found ; Ink = NLeftL ), must('adaptively, the ink on the dark side is found', Ink, ink_found),

    cv_hconcat([Img, Global, Local], Row), out('06-threshold.png', Path), cv_imwrite(Path, Row),
    show('written: the image, global, adaptive', Path),
    cv_free_all([V, Two, TwoN, Ot, Img, Global, Local, Left, LeftL, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

thr(V, Type, Row) :- cv_threshold(V, 100, 255, Type, T), cv_to_list(T, [Row]), cv_free(T).

%% a horizontal light gradient with dark text over it
gradient_text(I) :-
    cv_new(120, 240, '8u', 0, I),
    forall(between(0, 23, K), (X is K * 10, V is 30 + K * 9, cv_rectangle(I, [X, 0, 10, 120], V, -1))),
    cv_put_text(I, 'adaptive', [10, 50], 1.2, 0, 3),
    cv_put_text(I, 'threshold', [10, 100], 1.2, 0, 3).

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
