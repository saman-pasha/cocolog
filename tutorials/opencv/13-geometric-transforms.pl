%% OPENCV 13 -- geometry: resize, rotate, affine, perspective, borders, pyramids
%%
%%     ./cocolog run tutorials/opencv/13-geometric-transforms.pl main
%%
%% OpenCV's "Affine Transformations", "Image Pyramids", "Adding borders",
%% and "Making your own linear filters" (filter2D) together, because they
%% are all one idea: a new image whose every pixel is looked up somewhere
%% in the old one. A 2 by 3 MATRIX is an affine map, a 3 by 3 a
%% perspective one, and both are plain lists of rows.
%%
%%     cv_resize(+Img, +[W, H] | +Factor, -Out)   cv_resize(..., +Interp, -Out)
%%     cv_resample(+Img, +[W, H], +Filter, -Out)   box bilinear hamming bicubic lanczos -- Pillow's antialiased resize
%%     cv_rotation_matrix(+Center, +Angle, +Scale, -M)   cv_warp_affine(+Img, +M, +[W, H], -Out)
%%     cv_affine_transform(+Src3, +Dst3, -M)
%%     cv_perspective_transform(+Src4, +Dst4, -M)   cv_warp_perspective(+Img, +M, +[W, H], -Out)
%%     cv_transform_points(+Pts, +M, -Pts2)
%%     cv_make_border(+Img, +T, +B, +L, +R, +Type, +Color, -Out)   constant replicate reflect wrap reflect101
%%     cv_pyr_down/2  cv_pyr_up/2   cv_filter2d(+Img, +Kernel, -Out)   cv_sharpen/2

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- resize: a size, or a factor; the interpolation decides the in-betweens~n"),
    cv_from_list([[0, 255], [255, 0]], '8u', Chk),
    cv_resize(Chk, [8, 8], nearest, Near), cv_shape(Near, NS), must('to [W, H] = [8, 8]', NS, [8, 8, 1]),
    cv_get(Near, 3, 3, Nv), must('nearest: a pixel is a copy, 0 or 255', Nv, 0),
    cv_resize(Chk, 4, linear, Lin), cv_get(Lin, 3, 4, Lv),
    ( Lv > 0, Lv < 255 -> Between = yes ; Between = Lv ), must('linear: the seam is blended', Between, yes),
    scene(Sc), cv_resize(Sc, 0.5, Half), cv_shape(Half, HS), must('factor 0.5', HS, [128, 128, 3]),

    format("~n-- resample: Pillow's filters, whose support grows with the reduction~n"),
    format("   (OpenCV's linear, cubic and lanczos sample a fixed neighbourhood, so a big~n"),
    format("    reduction aliases; area averages a box. Pillow's resize widens the filter to~n"),
    format("    the scale -- a triangle for bilinear -- and library(opencv) carries that code.)~n"),
    cv_from_list([[0, 0, 255, 255]], '8u', Strip),
    cv_resample(Strip, [2, 1], box, SB), cv_to_list(SB, [RBL]), must('box halves the row to its two means', RBL, [0, 255]),
    cv_resample(Strip, [2, 1], bilinear, SL), cv_to_list(SL, [RLL]), must('bilinear: a triangle two pixels wide, so the edge bleeds', RLL, [36, 219]),
    cv_resample(Sc, [96, 96], lanczos, Small), cv_shape(Small, SmS), must('a scene to 96 by 96', SmS, [96, 96, 3]),
    cv_free_all([Strip, SB, SL, Small]),

    format("~n-- rotation about the centre, as an affine warp~n"),
    cv_from_list([[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]], '8u', Sq),
    cv_rotation_matrix([1.5, 1.5], 90, 1.0, M90), show('the 2 by 3 for 90 degrees about (1.5, 1.5)', M90),
    cv_warp_affine(Sq, M90, [4, 4], W90), cv_to_list(W90, W90L),
    cv_rotate(Sq, 270, R270), cv_to_list(R270, R270L),
    must('a positive angle turns counter-clockwise: the same as cv_rotate 270', W90L, R270L),
    cv_rotation_matrix([1.5, 1.5], 0, 2.0, M2), cv_warp_affine(Sq, M2, [4, 4], Zoom), cv_get(Zoom, 2, 2, Zv),
    show('scale 2 about the centre: the centre pixel', Zv),

    format("~n-- an affine map from three point pairs~n"),
    cv_affine_transform([[0, 0], [10, 0], [0, 10]], [[5, 3], [15, 3], [5, 13]], Mt),
    must('a pure translation by (5, 3)', Mt, [[1.0, 0.0, 5.0], [0.0, 1.0, 3.0]]),
    cv_affine_transform([[0, 0], [10, 0], [0, 10]], [[0, 0], [20, 0], [0, 10]], Ms),
    must('a stretch of x by 2', Ms, [[2.0, 0.0, 0.0], [0.0, 1.0, 0.0]]),

    format("~n-- a perspective map from four~n"),
    cv_perspective_transform([[0, 0], [100, 0], [100, 100], [0, 100]], [[0, 0], [200, 0], [200, 200], [0, 200]], Mp),
    cv_transform_points([[50, 50], [10, 20]], Mp, Pts), must('doubling: points double', Pts, [[100.0, 100.0], [20.0, 40.0]]),
    cv_perspective_transform([[0, 0], [255, 0], [255, 255], [0, 255]], [[40, 0], [215, 0], [255, 255], [0, 255]], Mk),
    cv_warp_perspective(Sc, Mk, [256, 256], Keystone),
    cv_get(Keystone, 0, 10, TopLeft), must('the top edge pulled in: the corner is now empty (black)', TopLeft, [0, 0, 0]),
    cv_get(Keystone, 250, 10, BotLeft), must('the bottom edge stayed: the ground colour', BotLeft, [40, 40, 40]),

    format("~n-- borders~n"),
    cv_from_list([[1, 2], [3, 4]], '8u', Two),
    cv_make_border(Two, 1, 1, 1, 1, constant, 9, Bc), cv_to_list(Bc, BcL),
    must('constant', BcL, [[9, 9, 9, 9], [9, 1, 2, 9], [9, 3, 4, 9], [9, 9, 9, 9]]),
    cv_make_border(Two, 1, 1, 1, 1, replicate, 0, Br), cv_to_list(Br, BrL),
    must('replicate repeats the edge', BrL, [[1, 1, 2, 2], [1, 1, 2, 2], [3, 3, 4, 4], [3, 3, 4, 4]]),
    cv_make_border(Two, 0, 0, 2, 0, wrap, 0, Bw), cv_to_list(Bw, BwL),
    must('wrap comes round from the other side', BwL, [[1, 2, 1, 2], [3, 4, 3, 4]]),

    format("~n-- pyramids halve and double~n"),
    cv_pyr_down(Sc, Down), cv_shape(Down, DS), must('pyr_down', DS, [128, 128, 3]),
    cv_pyr_up(Down, Up), cv_shape(Up, US), must('pyr_up', US, [256, 256, 3]),
    cv_absdiff(Sc, Up, Lost), cv_mean(Lost, LostM), show('what a round trip loses, mean |difference| per channel', LostM),

    format("~n-- a kernel of your own~n"),
    cv_filter2d(Sq, [[0, 0, 0], [0, 1, 0], [0, 0, 0]], Same), cv_to_list(Same, SameL), cv_to_list(Sq, SqL),
    must('the identity kernel changes nothing', SameL, SqL),
    cv_filter2d(Sq, [[0, 0, 0], [0, 2, 0], [0, 0, 0]], Twice), cv_get(Twice, 1, 1, Tv), must('twice the centre weight', Tv, 12),
    cv_sharpen(Sc, Sharp), cv_absdiff(Sc, Sharp, Dif), cv_count_nonzero_any(Dif, Changed), show('pixels cv_sharpen touched', Changed),

    cv_hconcat([Sc, Keystone, Sharp], Row), out('13-geometry.png', Path), cv_imwrite(Path, Row),
    show('written: the scene, keystoned, sharpened', Path),
    cv_free_all([Chk, Near, Lin, Sc, Half, Sq, W90, R270, Zoom, Keystone, Two, Bc, Br, Bw, Down, Up, Lost, Same, Twice, Sharp, Dif, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% nonzero over any channel: the grey of the difference
cv_count_nonzero_any(Img, N) :- cv_gray(Img, G), cv_count_nonzero(G, N), cv_free(G).

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
