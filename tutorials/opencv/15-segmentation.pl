%% OPENCV 15 -- segmentation: distance transform, watershed, components, flood fill, GrabCut
%%
%%     ./cocolog run tutorials/opencv/15-segmentation.pl main
%%
%% OpenCV's "Image Segmentation with Distance Transform and Watershed"
%% and "Interactive Foreground Extraction using GrabCut". The watershed
%% recipe is the classic: threshold, take the distance transform so the
%% middles of touching objects stand out as peaks, threshold THOSE into
%% markers, label them, and let the watershed grow every marker until
%% they meet. The markers image is modified in place and afterwards holds
%% a label per pixel and -1 on the boundaries.
%%
%%     cv_distance_transform(+Mask, -Out)       32f, L2 distance to the nearest zero
%%     cv_connected_components(+Mask, -N, -Labels)   N counts the background too; Labels is 32s
%%     cv_watershed(+Img, +Markers)             ON Markers, a 32s image
%%     cv_flood_fill(+Img, +Seed, +Color)       ON Img
%%     cv_grabcut(+Img, +Rect, +Iterations, -Mask)

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- the distance transform: how deep inside the white each pixel is~n"),
    cv_new(40, 40, '8u', 0, Sq), cv_rectangle(Sq, [10, 10, 21, 21], 255, -1),
    cv_distance_transform(Sq, Dt), cv_type(Dt, DtT), must('32f', DtT, '32f'),
    cv_minmax(Dt, _, Deepest, _, At), must('the deepest point is the middle of the square', At, [20, 20]),
    ( abs(Deepest - 11) < 0.6 -> Depth = about_eleven ; Depth = Deepest ), must('eleven pixels from the nearest black', Depth, about_eleven),
    cv_get(Dt, 5, 5, Outside), must('outside the white: 0', Outside, 0.0),

    format("~n-- connected components label the blobs~n"),
    cv_new(100, 100, '8u', 0, Blobs),
    cv_circle(Blobs, [25, 25], 12, 255, -1), cv_circle(Blobs, [70, 30], 10, 255, -1), cv_rectangle(Blobs, [20, 65, 60, 20], 255, -1),
    cv_connected_components(Blobs, NComp, Labels), must('three blobs plus the background', NComp, 4),
    cv_type(Labels, LT), must('labels are 32s', LT, '32s'),
    cv_get(Labels, 25, 25, L1), cv_get(Labels, 30, 70, L2), cv_get(Labels, 75, 50, L3), cv_get(Labels, 5, 5, L0),
    must('the background is label 0', L0, 0),
    msort([L1, L2, L3], Ls), must('the blobs are 1, 2, 3 in raster order', Ls, [1, 2, 3]),

    format("~n-- two touching discs, separated by the watershed~n"),
    cv_new(120, 160, '8uc3', black, Img),
    cv_circle(Img, [55, 60], 35, [200, 180, 160], -1), cv_circle(Img, [105, 60], 35, [200, 180, 160], -1),
    cv_gray(Img, Gr), cv_threshold(Gr, 50, 255, binary, Mask),
    cv_connected_components(Mask, NBefore, _Lb), must('as one blob they are one component', NBefore, 2),
    cv_distance_transform(Mask, Dist), cv_minmax(Dist, _, DMax, _, _),
    Cut is 0.8 * DMax, cv_threshold(Dist, Cut, 255, binary, Peaks32), cv_convert(Peaks32, '8u', Peaks),
    cv_connected_components(Peaks, NPeaks, Markers), must('the distance peaks are two markers (plus background)', NPeaks, 3),
    cv_watershed(Img, Markers),
    cv_get(Markers, 60, 40, Left), cv_get(Markers, 60, 120, Right), cv_get(Markers, 60, 80, Seam),
    show('label at the left disc', Left), show('label at the right disc', Right), show('on the seam between them', Seam),
    ( Left =\= Right, Left > 0, Right > 0 -> Split = yes ; Split = no ), must('two regions', Split, yes),
    must('the boundary is -1', Seam, -1),

    format("~n-- flood fill paints a connected region~n"),
    scene(Sc), cv_clone(Sc, Fl), cv_flood_fill(Fl, [5, 5], [200, 120, 0]),
    cv_get(Fl, 5, 5, Seed), must('the seed took the colour', Seed, [200, 120, 0]),
    cv_get(Fl, 5, 200, Far), must('and so did the far end of the same ground', Far, [200, 120, 0]),
    cv_get(Fl, 80, 72, Disc), must('the disc did not: it was another colour', Disc, [0, 0, 255]),

    format("~n-- GrabCut: a rectangle around the object, the model does the rest~n"),
    photo(P), cv_imread(P, Ph), cv_grabcut(Ph, [78, 31, 146, 294], 5, Fg), cv_count_nonzero(Fg, NFg),
    show('foreground pixels inside a 146 by 294 rectangle around a walker', NFg),
    ( NFg > 4000, NFg < 40000 -> Cut2 = part_of_the_rectangle ; Cut2 = NFg ), must('some of it, not all of it', Cut2, part_of_the_rectangle),
    cv_roi(Fg, [0, 0, 70, 451], LeftOf), cv_count_nonzero(LeftOf, NLeft), must('nothing outside the rectangle', NLeft, 0),
    format("   (GrabCut fits colour models to the inside and the outside of the~n"),
    format("    rectangle; a flat synthetic scene gives it nothing to fit, a photograph does)~n"),

    format("~n-- the pictures~n"),
    cv_convert(Markers, '8u', 40, 40, Mk8), cv_colormap(Mk8, jet, MkC),
    cv_normalize(Dist, 0, 255, minmax, Dn), cv_convert(Dn, '8u', Dn8), cv_cvt_color(Dn8, gray2bgr, DnC),
    cv_hconcat([Img, DnC, MkC], Row), out('15-watershed.png', Path), cv_imwrite(Path, Row),
    show('written: the discs, the distance transform, the watershed labels', Path),
    cv_cvt_color(Fg, gray2bgr, Fg3), cv_and(Ph, Fg3, CutOut), cv_resize(Fl, [309, 451], FlS), cv_hconcat([FlS, CutOut], Row2),
    out('15-floodfill-grabcut.png', Path2), cv_imwrite(Path2, Row2), show('and flood fill beside GrabCut', Path2),

    cv_free_all([Sq, Dt, Blobs, Labels, Img, Gr, Mask, _Lb, Dist, Peaks32, Peaks, Markers, Sc, Fl, Ph, Fg, LeftOf, Mk8, MkC, Dn, Dn8, DnC, Row, Fg3, CutOut, FlS, Row2]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

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
