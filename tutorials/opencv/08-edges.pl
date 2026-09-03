%% OPENCV 08 -- edges: Sobel, Laplacian, Canny
%%
%%     ./cocolog run tutorials/opencv/08-edges.pl main
%%
%% OpenCV's "Sobel Derivatives", "Laplace Operator" and "Canny Edge
%% Detector". An edge is where the image changes fast, so the tools are
%% derivatives: Sobel takes one, in x or in y, and answers a signed
%% slope; the Laplacian takes the second and answers zero on anything
%% flat or evenly sloped; Canny turns slopes into a thin, hysteresis-
%% thresholded binary map, which is what everything downstream wants.
%%
%%     cv_sobel(+Gray, +Dx, +Dy, +K, -Out)        64f, signed
%%     cv_laplacian(+Gray, +K, -Out)              64f, signed
%%     cv_abs8u(+Img, -Out)                       |V| saturated into 8u, to look at
%%     cv_canny(+Gray, +T1, +T2, -Edges)          8u, 0 or 255

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a vertical step: the x derivative sees it, the y one does not~n"),
    cv_new(20, 40, '8u', 0, Step), cv_rectangle(Step, [20, 0, 20, 20], 255, -1),
    cv_sobel(Step, 1, 0, 3, Sx), cv_type(Sx, Tx), must('Sobel answers 64f, so the sign survives', Tx, '64f'),
    cv_get(Sx, 10, 19, Gx), must('at the edge: +255 times the kernel weight 4', Gx, 1020.0),
    cv_get(Sx, 10, 5, Flat), must('on the flat: 0', Flat, 0.0),
    cv_sobel(Step, 0, 1, 3, Sy), cv_count_nonzero(Sy, NY), must('dy of a vertical edge: nothing anywhere', NY, 0),
    cv_abs8u(Sx, Ax), cv_get(Ax, 10, 19, Av), must('abs8u saturates 1020 to 255 for viewing', Av, 255),
    cv_new(20, 40, '8u', 0, Rev), cv_rectangle(Rev, [0, 0, 20, 20], 255, -1),
    cv_sobel(Rev, 1, 0, 3, Sr), cv_get(Sr, 10, 19, Gr), must('the same step the other way: negative', Gr, -1020.0),

    format("~n-- the Laplacian is zero where nothing bends~n"),
    cv_new(20, 20, '8u', 77, Const), cv_laplacian(Const, 3, Lc), cv_count_nonzero(Lc, NLc), must('on a constant', NLc, 0),
    ramp(Ramp), cv_laplacian(Ramp, 3, Lr), cv_roi(Lr, [2, 2, 16, 16], LrIn), cv_count_nonzero(LrIn, NLr),
    must('on a straight ramp, away from the border', NLr, 0),
    cv_laplacian(Step, 3, Ls), cv_count_nonzero(Ls, NLs),
    ( NLs > 0 -> Bends = yes ; Bends = no ), must('but it fires at the step', Bends, yes),

    format("~n-- Canny: thin edges, with hysteresis between two thresholds~n"),
    cv_new(60, 60, '8u', 0, Box), cv_rectangle(Box, [20, 20, 20, 20], 255, -1),
    cv_canny(Box, 50, 150, E), cv_count_nonzero(E, NE), show('edge pixels around a 20 by 20 square', NE),
    ( NE > 60, NE < 100 -> Thin = about_the_perimeter ; Thin = NE ), must('one pixel wide, about 4 sides of 20', Thin, about_the_perimeter),
    cv_get(E, 30, 30, Inside), must('nothing inside the square', Inside, 0),
    cv_canny(Const, 50, 150, Ec), cv_count_nonzero(Ec, NEc), must('nothing on a constant', NEc, 0),

    format("~n-- gradient magnitude from the two Sobels, as arithmetic~n"),
    scene(Sc), cv_gray(Sc, G),
    cv_sobel(G, 1, 0, 3, Gx1), cv_sobel(G, 0, 1, 3, Gy1),
    cv_pow(Gx1, 2, Gx2), cv_pow(Gy1, 2, Gy2), cv_add(Gx2, Gy2, Sum), cv_pow(Sum, 0.5, Mag),
    cv_normalize(Mag, 0, 255, minmax, MagN), cv_convert(MagN, '8u', Mag8),
    cv_canny(G, 100, 200, Edges),
    cv_count_nonzero(Edges, NEdges), show('Canny edge pixels in the scene', NEdges),
    cv_hconcat([G, Mag8, Edges], Row), out('08-edges.png', Path), cv_imwrite(Path, Row), show('written: grey, Sobel magnitude, Canny', Path),
    photo(P), cv_imread(P, gray, Pg), cv_gaussian_blur(Pg, 5, 0, Pb), cv_canny(Pb, 60, 160, Pe),
    out('08-photo-canny.png', Path2), cv_imwrite(Path2, Pe), show('and a photograph', Path2),

    cv_free_all([Step, Sx, Sy, Ax, Rev, Sr, Const, Lc, Ramp, Lr, LrIn, Ls, Box, E, Ec, Sc, G, Gx1, Gy1, Gx2, Gy2, Sum, Mag, MagN, Mag8,
                 Edges, Row, Pg, Pb, Pe]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% brightness rising 10 a column: a plane, no curvature
ramp(I) :- cv_new(20, 20, '8u', 0, I), forall(between(0, 19, C), (V is C * 10, cv_rectangle(I, [C, 0, 1, 20], V, -1))).

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

photo('tutorials/tensor/42-detection-1.jpg').
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
