%% OPENCV 10 -- Hough transforms: lines and circles by voting
%%
%%     ./cocolog run tutorials/opencv/10-hough.pl main
%%
%% OpenCV's "Hough Line Transform" and "Hough Circle Transform". Every
%% edge pixel votes for every line (or circle) it could lie on; the
%% shapes with the most votes are the ones that are really there. The
%% standard transform answers lines as [Rho, Theta] -- the distance from
%% the origin and the angle of the normal -- and the probabilistic one as
%% segments [X1, Y1, X2, Y2], which is usually what you wanted.
%%
%%     cv_hough_lines(+Edges, +Rho, +Theta, +Threshold, -[[Rho, Theta] ...])
%%     cv_hough_lines_p(+Edges, +Rho, +Theta, +Threshold, +MinLen, +MaxGap, -[[X1, Y1, X2, Y2] ...])
%%     cv_hough_circles(+Gray, +Dp, +MinDist, +P1, +P2, +MinR, +MaxR, -[[X, Y, R] ...])
%%
%% Theta is in radians; pi / 180 is one degree of resolution. The vote
%% THRESHOLD is the knob that matters: a 200-pixel line casts 200 votes
%% for its own cell and a few dozen for the cells a degree either side,
%% so a threshold well above those keeps one line per line.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    Deg is pi / 180,
    format("~n-- two lines, standard transform: [Rho, Theta]~n"),
    cv_new(200, 200, '8u', 0, E),
    cv_line(E, [0, 50], [199, 50], 255, 1),
    cv_line(E, [120, 0], [120, 199], 255, 1),
    cv_hough_lines(E, 1, Deg, 190, Ls), length(Ls, NL), must('lines with 190 votes or more, out of 200 pixels each', NL, 2),
    ( member([Rh, Th], Ls), abs(Rh - 50) < 1.5, abs(Th - pi / 2) < 0.02 -> Hz = found ; Hz = Ls ),
    must('the horizontal one: rho 50, theta pi/2', Hz, found),
    ( member([Rv, Tv], Ls), abs(Rv - 120) < 1.5, abs(Tv) < 0.02 -> Vt = found ; Vt = Ls ),
    must('the vertical one: rho 120, theta 0', Vt, found),

    format("~n-- the probabilistic transform answers segments~n"),
    cv_hough_lines_p(E, 1, Deg, 150, 100, 5, Segs), length(Segs, NS), show('segments (probabilistic: the count varies, the lines do not)', NS),
    ( forall(member([X1, Y1, X2, Y2], Segs), (abs(Y1 - 50) =< 1, abs(Y2 - 50) =< 1 ; abs(X1 - 120) =< 1, abs(X2 - 120) =< 1)) -> OnLines = all ; OnLines = Segs ),
    must('every segment lies within a pixel of y = 50 or of x = 120', OnLines, all),
    ( member([X5, Y5, X6, _], Segs), abs(Y5 - 50) =< 1, abs(X6 - X5) > 150 -> Seg = found ; Seg = Segs ),
    must('one runs along y = 50 for most of the width', Seg, found),
    ( member([X7, _, _, _], Segs), abs(X7 - 120) =< 1 -> SegV = found ; SegV = Segs ),
    must('and one down x = 120', SegV, found),
    format("   (cv_line draws anti-aliased, so a one-pixel line is three shades wide,~n"),
    format("    and the transform sees its neighbours too)~n"),

    format("~n-- a broken line: MaxGap decides whether the break is bridged~n"),
    cv_new(100, 200, '8u', 0, B),
    cv_line(B, [10, 50], [90, 50], 255, 1), cv_line(B, [110, 50], [190, 50], 255, 1),
    cv_hough_lines_p(B, 1, Deg, 70, 50, 5, Two), length(Two, N2), show('gap 5: segments', N2),
    ( forall(member([A1, _, A2, _], Two), (A2 =< 95 ; A1 >= 105)) -> Unbridged = yes ; Unbridged = Two ),
    must('none crosses the 20-pixel gap', Unbridged, yes),
    cv_hough_lines_p(B, 1, Deg, 70, 50, 30, One),
    ( member([B1, _, B2, _], One), B1 < 95, B2 > 105 -> Bridged = yes ; Bridged = One ),
    must('gap 30: a segment spans the break', Bridged, yes),

    format("~n-- circles~n"),
    cv_new(200, 200, '8u', 20, C),
    cv_circle(C, [60, 70], 30, 220, 3), cv_circle(C, [140, 120], 45, 220, 3),
    cv_gaussian_blur(C, 5, 0, Cb),
    cv_hough_circles(Cb, 1, 40, 100, 20, 20, 60, Circles), length(Circles, NCirc), show('circles', NCirc),
    ( member([Cx, Cy, Cr], Circles), abs(Cx - 60) < 3, abs(Cy - 70) < 3, abs(Cr - 30) < 5 -> C1 = found ; C1 = Circles ),
    must('the small one: (60, 70) r 30, within a few pixels', C1, found),
    ( member([Dx, Dy, Dr], Circles), abs(Dx - 140) < 3, abs(Dy - 120) < 3, abs(Dr - 45) < 5 -> C2 = found ; C2 = Circles ),
    must('the big one: (140, 120) r 45', C2, found),
    format("   (the rings are three pixels thick and blurred, so the radius lands on~n"),
    format("    the inner or outer edge, a few pixels off)~n"),

    format("~n-- the picture: what was found, drawn over the edges~n"),
    cv_cvt_color(E, gray2bgr, Ec),
    forall(member([A1, A2, A3, A4], Segs), cv_line(Ec, [A1, A2], [A3, A4], red, 2)),
    cv_cvt_color(C, gray2bgr, Cc),
    forall(member([Fx, Fy, Fr], Circles), (Ix is round(Fx), Iy is round(Fy), Ir is round(Fr), cv_circle(Cc, [Ix, Iy], Ir, green, 2))),
    cv_hconcat([Ec, Cc], Row), out('10-hough.png', Path), cv_imwrite(Path, Row), show('written', Path),

    cv_free_all([E, B, C, Cb, Ec, Cc, Row]),
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
