%% OPENCV 21 -- calibration: a chessboard, its corners, and the view that made it
%%
%%     ./cocolog run tutorials/opencv/21-calibration.pl main
%%
%% The first half of OpenCV's "Camera calibration": finding the inner
%% corners of a chessboard to sub-pixel precision. There is no camera
%% here, so the second half -- solving for the lens from many views -- is
%% replaced by the one thing a single view CAN give: the homography
%% between the board and the picture, from which the board is straightened.
%%
%%     cv_find_chessboard(+Img, +[Cols, Rows], -Corners)    inner corners; fails when not found
%%     cv_draw_chessboard(+Img, +[Cols, Rows], +Corners)    ON Img
%%
%% [Cols, Rows] counts INNER corners: a board of 10 by 8 squares has 9 by 7.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a drawn board, its 9 by 7 inner corners~n"),
    board(B),
    cv_find_chessboard(B, [9, 7], Cs), length(Cs, NC), must('63 corners', NC, 63),
    Cs = [[X0, Y0]|_], show('the first, sub-pixel', [X0, Y0]),
    ( abs(X0 - 49.5) < 0.5, abs(Y0 - 39.5) < 0.5 -> First = at_the_first_inner_corner ; First = [X0, Y0] ),
    must('at (49.5, 39.5), between the pixels', First, at_the_first_inner_corner),
    nth0(1, Cs, [X1, Y1]), ( abs(X1 - X0 - 20) < 0.5, abs(Y1 - Y0) < 0.5 -> Step = twenty_pixels_along ; Step = [X1, Y1] ),
    must('the next is one square to the right', Step, twenty_pixels_along),
    nth0(9, Cs, [X9, Y9]), ( abs(X9 - X0) < 0.5, abs(Y9 - Y0 - 20) < 0.5 -> Down = twenty_pixels_down ; Down = [X9, Y9] ),
    must('and the tenth one square down: row-major order', Down, twenty_pixels_down),
    ( cv_find_chessboard(B, [9, 8], _) -> Wrong = found ; Wrong = failed ), must('asked for the wrong size, it fails', Wrong, failed),

    format("~n-- the board seen at an angle~n"),
    cv_perspective_transform([[0, 0], [259, 0], [259, 199], [0, 199]], [[40, 30], [230, 10], [250, 190], [20, 170]], Mview),
    cv_warp_perspective(B, Mview, [260, 200], View),
    cv_find_chessboard(View, [9, 7], Cv), length(Cv, NCv), must('still all 63', NCv, 63),

    format("~n-- the homography from the ideal grid to the view, and back~n"),
    findall([GX, GY], (between(0, 6, R), between(0, 8, C), GX is 49.5 + 20 * C, GY is 39.5 + 20 * R), Grid),
    cv_find_homography(Grid, Cv, 2.0, Hest, Inliers), sum_list(Inliers, NIn), show('RANSAC inliers of 63', NIn),
    ( NIn >= 60 -> Most = nearly_all ; Most = NIn ), must('nearly all of them', Most, nearly_all),
    cv_transform_points([[49.5, 39.5], [209.5, 159.5]], Mview, ByTruth),
    cv_transform_points([[49.5, 39.5], [209.5, 159.5]], Hest, ByEstimate),
    show('two grid points through the true view matrix', ByTruth), show('through the estimated one', ByEstimate),
    ( maplist(close_pt, ByTruth, ByEstimate) -> Agree = within_a_pixel ; Agree = ByEstimate ), must('they agree', Agree, within_a_pixel),
    cv_find_homography(Cv, Grid, 2.0, Hback), cv_warp_perspective(View, Hback, [260, 200], Straight),
    cv_find_chessboard(Straight, [9, 7], Cst), Cst = [[SX, SY]|_],
    ( abs(SX - 49.5) < 1, abs(SY - 39.5) < 1 -> Back = at_the_first_inner_corner_again ; Back = [SX, SY] ),
    must('straightened by the inverse, the first corner is home', Back, at_the_first_inner_corner_again),

    format("~n-- the pictures~n"),
    cv_cvt_color(View, gray2bgr, ViewC), cv_draw_chessboard(ViewC, [9, 7], Cv),
    cv_cvt_color(Straight, gray2bgr, StraightC), cv_draw_chessboard(StraightC, [9, 7], Cst),
    cv_hconcat([ViewC, StraightC], Row), out('21-chessboard.png', Path), cv_imwrite(Path, Row), show('written', Path),

    cv_free_all([B, View, Straight, ViewC, StraightC, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% 10 by 8 squares of 20 pixels, from (30, 20), on white, with a margin
board(I) :-
    cv_new(200, 260, '8u', 255, I),
    forall((between(0, 7, R), between(0, 9, C), 0 =:= (R + C) mod 2),
           (X is 30 + C * 20, Y is 20 + R * 20, cv_rectangle(I, [X, Y, 20, 20], 0, -1))).

close_pt([X1, Y1], [X2, Y2]) :- abs(X1 - X2) < 1, abs(Y1 - Y2) < 1.

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
