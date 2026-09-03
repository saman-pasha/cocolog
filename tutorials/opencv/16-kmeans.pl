%% OPENCV 16 -- k-means: clustering points, and quantising colours
%%
%%     ./cocolog run tutorials/opencv/16-kmeans.pl main
%%
%% OpenCV's "K-Means Clustering" lessons, both of them: points in the
%% plane sorted into K groups, and an image reduced to its K most
%% representative colours -- the same algorithm, run once on [X, Y] rows
%% and once on [B, G, R] rows.
%%
%%     cv_kmeans_points(+Pts, +K, -Labels, -Centers)
%%     cv_kmeans(+Img, +K, -Quantized)

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out, cv_seed(11),
    format("~n-- three clouds of points~n"),
    cloud(20, 20, 3, A), cloud(100, 30, 3, B), cloud(60, 90, 3, C),
    append([A, B, C], Pts), length(Pts, NP), show('points', NP),
    cv_kmeans_points(Pts, 3, Labels, Centers),
    length(Labels, NL), must('one label per point', NL, NP),
    length(Centers, NC), must('three centres', NC, 3),
    length(A, NA), length(B, NB),
    nth0(0, Labels, LA), nth0(NA, Labels, LB), NAB is NA + NB, nth0(NAB, Labels, LC),
    msort([LA, LB, LC], Distinct), must('the three clouds got three different labels', Distinct, [0, 1, 2]),
    findall(L, (nth0(I, Labels, L), I < NA), LabelsA), sort(LabelsA, OneA), must('and every point of the first cloud the same one', OneA, [LA]),
    msort(Centers, Sorted), show('centres, sorted', Sorted),
    ( Sorted = [[X1, Y1], [X2, Y2], [X3, Y3]], abs(X1 - 20) < 3, abs(Y1 - 20) < 3, abs(X2 - 60) < 3, abs(Y2 - 90) < 3, abs(X3 - 100) < 3, abs(Y3 - 30) < 3
    -> Near = at_the_cloud_centres ; Near = Sorted ),
    must('the centres are where the clouds were made', Near, at_the_cloud_centres),

    format("~n-- colour quantisation: the scene in four colours~n"),
    scene(Sc), cv_noise(Sc, 12, Noisy),
    cv_resize(Noisy, [32, 32], area, Small), cv_to_list(Small, Rows), append(Rows, Pixels), sort(Pixels, DistinctBefore),
    length(DistinctBefore, NBefore), show('distinct colours in a 32 by 32 thumbnail of the noisy scene', NBefore),
    cv_kmeans(Noisy, 4, Q), cv_resize(Q, [32, 32], nearest, QSmall), cv_to_list(QSmall, QRows), append(QRows, QPixels), sort(QPixels, DistinctAfter),
    length(DistinctAfter, NAfter), show('after k-means with K = 4', NAfter),
    ( NAfter =< 4 -> Four = at_most_four ; Four = NAfter ), must('K colours remain', Four, at_most_four),
    cv_shape(Q, QS), must('the same shape', QS, [256, 256, 3]),

    format("~n-- a photograph in six~n"),
    photo(P), cv_imread(P, Ph), cv_resize(Ph, 0.5, Ph2), cv_kmeans(Ph2, 6, Ph6),
    cv_hconcat([Ph2, Ph6], Row), out('16-kmeans.png', Path), cv_imwrite(Path, Row), show('written', Path),
    cv_cvt_color(Noisy, bgr2rgb, _T), cv_free(_T),

    cv_free_all([Sc, Noisy, Small, Q, QSmall, Ph, Ph2, Ph6, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% N by N points on a grid around (Cx, Cy), Step apart: a deterministic cloud
cloud(Cx, Cy, Step, Pts) :-
    findall([X, Y], (between(-2, 2, I), between(-2, 2, J), X is Cx + I * Step, Y is Cy + J * Step), Pts).

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

photo('tutorials/tensor/42-detection-3.jpg').
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
