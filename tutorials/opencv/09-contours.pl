%% OPENCV 09 -- contours: shapes as point lists, and what is measured on them
%%
%%     ./cocolog run tutorials/opencv/09-contours.pl main
%%
%% OpenCV's contour lessons in one file: "Finding contours", "Convex
%% Hull", "Bounding boxes and circles", "Image Moments", "Point Polygon
%% Test". A contour is a list of [X, Y] -- a Prolog list, so everything
%% below the finder is a predicate over points, and nothing is a handle.
%%
%%     cv_find_contours(+Mask, +Mode, +Method, -Contours)   external list ccomp tree; none simple
%%     cv_contour_area/2  cv_arc_length/3  cv_bounding_rect/2  cv_min_area_rect/2
%%     cv_min_enclosing_circle/3  cv_approx_poly/4  cv_convex_hull/2  cv_is_convex/1
%%     cv_moments/2  cv_centroid/3  cv_point_polygon_test/4  cv_fit_ellipse/2
%%     cv_draw_contours(+Img, +Contours, +Index, +Color, +Thickness)   ON Img, -1 draws all
%%
%% THE SHAPE CLASSIFIER at the end is the classic: approximate each
%% contour to a polygon and count its corners.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- three shapes on black, three contours~n"),
    cv_new(256, 256, '8u', 0, M),
    cv_circle(M, [72, 80], 40, 255, -1),
    cv_rectangle(M, [140, 40, 80, 80], 255, -1),
    cv_fill_poly(M, [[60, 230], [128, 150], [196, 230]], 255),
    cv_find_contours(M, external, simple, Cs),
    length(Cs, NC), must('external contours', NC, 3),
    cv_find_contours(M, external, none, CsAll), maplist(length, CsAll, LensAll), maplist(length, Cs, Lens),
    sum_list(LensAll, SAll), sum_list(Lens, S),
    show('points with method none (every boundary pixel)', SAll), show('with simple (corners only)', S),
    ( S < SAll -> Fewer = yes ; Fewer = no ), must('simple keeps fewer points', Fewer, yes),

    format("~n-- the square, found by its bounding box~n"),
    member(Sq, Cs), cv_bounding_rect(Sq, [140, 40, 80, 80]), !,
    cv_contour_area(Sq, A), must('area: the pixel polygon is 79 by 79', A, 6241.0),
    cv_arc_length(Sq, true, L), must('perimeter', L, 316.0),
    cv_approx_poly(Sq, 3, true, Poly), length(Poly, NV), must('approximated to a polygon: 4 corners', NV, 4),
    cv_centroid(Sq, Cx, Cy), must('centroid from the moments', [Cx, Cy], [179.5, 79.5]),
    cv_moments(Sq, [M00|_]), must('m00 is the area', M00, 6241.0),
    ( cv_is_convex(Sq) -> Cvx = yes ; Cvx = no ), must('convex', Cvx, yes),
    cv_point_polygon_test(Sq, [180, 80], false, In), must('a point inside: +1', In, 1.0),
    cv_point_polygon_test(Sq, [10, 10], false, Out), must('outside: -1', Out, -1.0),
    cv_point_polygon_test(Sq, [180, 80], true, Dist), must('measuring: the distance to the nearest edge (219 - 180)', Dist, 39.0),
    cv_min_area_rect(Sq, [_, [W, H], _]), show('min area rect [W, H]', [W, H]),

    format("~n-- the disc: the enclosing circle finds the radius~n"),
    member(Disc, Cs), cv_bounding_rect(Disc, [BX, BY, _, _]), BX < 100, BY < 100, !,
    cv_min_enclosing_circle(Disc, [CX, CY], R),
    ( abs(CX - 72) < 1.5, abs(CY - 80) < 1.5, abs(R - 40) < 1.5 -> Circ = found ; Circ = [CX, CY, R] ),
    must('centre (72, 80), radius 40', Circ, found),
    cv_fit_ellipse(Disc, [_, [EA, EB], _]), ( abs(EA - EB) < 3 -> Round = yes ; Round = EA-EB ), must('fits an ellipse with equal axes', Round, yes),

    format("~n-- the classifier: corners after approximation~n"),
    findall(Kind, (member(C, Cs), classify(C, Kind)), Kinds), msort(Kinds, Sorted),
    must('one of each', Sorted, [circle, square, triangle]),

    format("~n-- a concave shape: hull versus contour~n"),
    cv_new(100, 100, '8u', 0, Lm), cv_rectangle(Lm, [10, 10, 30, 80], 255, -1), cv_rectangle(Lm, [10, 60, 80, 30], 255, -1),
    cv_find_contours(Lm, external, simple, [Lc]),
    ( cv_is_convex(Lc) -> LCvx = yes ; LCvx = no ), must('an L is not convex', LCvx, no),
    cv_convex_hull(Lc, Hull), cv_contour_area(Lc, LA), cv_contour_area(Hull, HA),
    ( HA > LA -> Bigger = yes ; Bigger = no ), must('its hull is bigger', Bigger, yes),
    ( cv_is_convex(Hull) -> HCvx = yes ; HCvx = no ), must('and convex', HCvx, yes),

    format("~n-- drawing them back~n"),
    cv_cvt_color(M, gray2bgr, Canvas), cv_draw_contours(Canvas, Cs, -1, red, 2),
    forall(member(C2, Cs), (cv_bounding_rect(C2, Rc), cv_rectangle(Canvas, Rc, green, 1))),
    cv_polylines(Canvas, Hull, true, cyan, 1),
    out('09-contours.png', Path), cv_imwrite(Path, Canvas), show('written', Path),

    cv_free_all([M, Lm, Canvas]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

classify(C, Kind) :-
    cv_arc_length(C, true, P), Eps is 0.03 * P,
    cv_approx_poly(C, Eps, true, Poly), length(Poly, NV),
    (   NV =:= 3 -> Kind = triangle
    ;   NV =:= 4 -> Kind = square
    ;   Kind = circle
    ).

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
