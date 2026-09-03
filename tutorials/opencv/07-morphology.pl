%% OPENCV 07 -- morphology: erode, dilate, and the four made from them
%%
%%     ./cocolog run tutorials/opencv/07-morphology.pl main
%%
%% OpenCV's "Eroding and Dilating" and "More Morphology Transformations".
%% A structuring element -- a small rect, ellipse or cross -- slides over
%% a mask; EROSION keeps a pixel only where the whole element fits inside
%% the white, DILATION paints white wherever the element touches it. Every
%% other operation is those two composed: OPEN (erode then dilate) drops
%% specks smaller than the element and keeps the rest to the pixel; CLOSE
%% fills holes; the GRADIENT is the outline; TOPHAT is what open removed.
%%
%%     cv_morph(+Op, +Img, +K, +Shape, +Iterations, -Out)
%%       erode dilate open close gradient tophat blackhat hitmiss
%%       rect | ellipse | cross, K by K
%%     cv_erode/3 cv_dilate/3 cv_open/3 cv_close/3      the shorthands, rect, once

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a 10 by 10 square, a 3 by 3 element~n"),
    cv_new(30, 30, '8u', 0, Sq), cv_rectangle(Sq, [10, 10, 10, 10], 255, -1),
    cv_count_nonzero(Sq, N0), must('the square', N0, 100),
    cv_erode(Sq, 3, Er), cv_count_nonzero(Er, N1), must('erode: one pixel off each side, 8 by 8', N1, 64),
    cv_dilate(Sq, 3, Di), cv_count_nonzero(Di, N2), must('dilate: one pixel on each side, 12 by 12', N2, 144),
    cv_morph(gradient, Sq, 3, rect, 1, Gr), cv_count_nonzero(Gr, N3), must('gradient = dilate - erode: the outline', N3, 80),
    cv_morph(dilate, Sq, 3, rect, 2, Di2), cv_count_nonzero(Di2, N4), must('two iterations: 14 by 14', N4, 196),

    format("~n-- open removes what is smaller than the element; close fills holes~n"),
    cv_clone(Sq, Salted),
    forall(member([R, C], [[2, 3], [25, 5], [5, 26]]), cv_set(Salted, R, C, 255)),
    cv_count_nonzero(Salted, NS), must('three specks added', NS, 103),
    cv_open(Salted, 3, Op), cv_count_nonzero(Op, NOp), must('open: the specks are gone, the square is intact', NOp, 100),
    cv_morph(tophat, Salted, 3, rect, 1, Th), cv_count_nonzero(Th, NTh), must('tophat is exactly what open removed', NTh, 3),
    cv_clone(Sq, Holed), cv_set(Holed, 15, 15, 0),
    cv_count_nonzero(Holed, NH), must('a one-pixel hole', NH, 99),
    cv_close(Holed, 3, Cl), cv_count_nonzero(Cl, NCl), must('close fills it', NCl, 100),
    cv_morph(blackhat, Holed, 3, rect, 1, Bh), cv_count_nonzero(Bh, NBh), must('blackhat is exactly what close filled', NBh, 1),

    format("~n-- the element's shape: dilating one pixel draws the element~n"),
    cv_new(15, 15, '8u', 0, Dot), cv_set(Dot, 7, 7, 255),
    cv_morph(dilate, Dot, 5, rect, 1, Dr), cv_count_nonzero(Dr, NR), must('rect 5: 25 pixels', NR, 25),
    cv_morph(dilate, Dot, 5, cross, 1, Dc), cv_count_nonzero(Dc, NC), must('cross 5: 9 pixels', NC, 9),
    cv_morph(dilate, Dot, 5, ellipse, 1, De), cv_count_nonzero(De, NE), show('ellipse 5', NE),
    ( NE > NC, NE < NR -> Mid = between_cross_and_rect ; Mid = NE ), must('the ellipse is in between', Mid, between_cross_and_rect),

    format("~n-- on the scene: opening a noisy mask cleans it~n"),
    scene(Sc), cv_gray(Sc, G), cv_threshold(G, 60, 255, binary, M),
    cv_noise(M, 90, Mn), cv_threshold(Mn, 128, 255, binary, Mnb),
    cv_open(Mnb, 3, Cleaned), cv_close(Cleaned, 5, Closed),
    cv_absdiff(M, Mnb, D1), cv_count_nonzero(D1, Wrong1),
    cv_absdiff(M, Closed, D2), cv_count_nonzero(D2, Wrong2),
    show('pixels wrong after noise', Wrong1), show('pixels wrong after open and close', Wrong2),
    ( Wrong2 < Wrong1 -> Better = yes ; Better = no ), must('morphology repaired most of it', Better, yes),
    cv_hconcat([M, Mnb, Closed], Row), out('07-morphology.png', Path), cv_imwrite(Path, Row), show('written', Path),

    cv_free_all([Sq, Er, Di, Gr, Di2, Salted, Op, Th, Holed, Cl, Bh, Dot, Dr, Dc, De, Sc, G, M, Mn, Mnb, Cleaned, Closed, D1, D2, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

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
