%% OPENCV 17 -- features: corners, keypoints, descriptors, matching, homography
%%
%%     ./cocolog run tutorials/opencv/17-features.pl main
%%
%% OpenCV's features2d lessons in one: "Harris corner detector",
%% "Shi-Tomasi corner detector", "Feature Detection", "Feature
%% Description", "Feature Matching with FLANN" (brute force here) and
%% "Features2D + Homography to find a known object". The idea underneath
%% all of them: find points that are easy to find again, describe the
%% patch around each as a vector, and match vectors between pictures.
%%
%%     cv_corner_harris(+Gray, +Block, +K, +Kappa, -Response)      32f
%%     cv_good_features(+Gray, +Max, +Quality, +MinDist, -Pts)       Shi-Tomasi
%%     cv_features(+Kind, +Img, -Keypoints, -Descriptors)            orb | sift | akaze
%%       a keypoint is [X, Y, Size, Angle, Response]; descriptors are one row per keypoint
%%     cv_match(+D1, +D2, +Norm, -[[Q, T, Dist] ...])                hamming for orb/akaze, l2 for sift
%%     cv_knn_match(+D1, +D2, +Norm, +K, -Matches)                   K per query, for the ratio test
%%     cv_draw_keypoints(+Img, +Keypoints, +Color, -Out)
%%     cv_find_homography(+Src, +Dst, +Threshold, -M)                RANSAC; fails when none
%%     cv_find_homography(+Src, +Dst, +Threshold, -M, -Inliers)

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- corners of a square: Harris responds at four places~n"),
    cv_new(100, 100, '8u', 0, Sq), cv_rectangle(Sq, [30, 30, 40, 40], 255, -1),
    cv_corner_harris(Sq, 2, 3, 0.04, H), cv_type(H, HT), must('the response is 32f', HT, '32f'),
    cv_minmax(H, _, HMax, _, _), Cut is 0.5 * HMax, cv_threshold(H, Cut, 255, binary, Hp32), cv_convert(Hp32, '8u', Hp),
    cv_connected_components(Hp, NPeaks, _L), must('four peaks in the response (plus the background)', NPeaks, 5),
    cv_good_features(Sq, 10, 0.01, 10, Pts), length(Pts, NP), must('Shi-Tomasi finds the same four', NP, 4),
    findall([RX, RY], (member([FX, FY], Pts), RX is round(FX), RY is round(FY)), Rounded), msort(Rounded, Sorted),
    ( Sorted = [[A, B], [C, D], [E, F], [G, I]], near(A, 30), near(B, 30), near(C, 30), near(D, 69), near(E, 69), near(F, 30), near(G, 69), near(I, 69)
    -> Where = at_the_four_corners ; Where = Sorted ),
    must('within a pixel of (30, 30), (30, 69), (69, 30), (69, 69)', Where, at_the_four_corners),

    format("~n-- keypoints and descriptors, three detectors~n"),
    photo(P), cv_imread(P, Ph),
    cv_features(orb, Ph, Ko, Do), length(Ko, NKo), cv_shape(Do, [NKo, 32, 1]), cv_type(Do, To),
    must('ORB: 32-byte binary descriptors, one row per keypoint', To, '8u'), show('ORB keypoints', NKo),
    cv_features(sift, Ph, Ks, Ds), length(Ks, NKs), cv_shape(Ds, [NKs, 128, 1]), cv_type(Ds, Ts),
    must('SIFT: 128 floats', Ts, '32f'), show('SIFT keypoints', NKs),
    cv_features(akaze, Ph, Ka, Da), length(Ka, NKa), cv_shape(Da, [NKa, 61, 1]), show('AKAZE keypoints, 61-byte descriptors', NKa),
    Ko = [[KX, KY, KSize, KAngle, KResp]|_], show('a keypoint: [X, Y, Size, Angle, Response]', [KX, KY, KSize, KAngle, KResp]),

    format("~n-- matching a picture against a warped copy of itself~n"),
    cv_shape(Ph, [PH, PW, _]), PW1 is PW - 1, PH1 is PH - 1, PWa is PW - 40, PHa is PH - 20, PWb is PW - 20, PHb is PH - 50,
    cv_perspective_transform([[0, 0], [PW1, 0], [PW1, PH1], [0, PH1]], [[30, 20], [PWa, 40], [PWb, PHa], [10, PHb]], Mtrue),
    cv_warp_perspective(Ph, Mtrue, [PW, PH], Warped),
    cv_features(orb, Warped, Kw, Dw),
    cv_match(Do, Dw, hamming, Ms), length(Ms, NM), show('brute-force matches', NM),
    Ms = [[_, _, Best]|_], last(Ms, [_, _, Worst]), ( Best =< Worst -> Ord = ascending ; Ord = Best-Worst ),
    must('sorted by distance, best first', Ord, ascending),
    cv_knn_match(Do, Dw, hamming, 2, Knn),
    findall(Q-T, (member([[Q, T, D1], [_, _, D2]], Knn), D1 < 0.75 * D2), Good), length(Good, NGood),
    show('matches surviving the ratio test (0.75)', NGood),
    ( NGood >= 20 -> Enough = yes ; Enough = NGood ), must('enough to fit a homography', Enough, yes),

    format("~n-- the homography from the good matches recovers the warp~n"),
    findall([SX, SY], (member(Q1-_, Good), nth0(Q1, Ko, [SX, SY|_])), Src),
    findall([DX, DY], (member(_-T1, Good), nth0(T1, Kw, [DX, DY|_])), Dst),
    cv_find_homography(Src, Dst, 3.0, Mest, Inliers), sum_list(Inliers, NIn), show('RANSAC inliers', NIn),
    cv_transform_points([[100, 100], [400, 300]], Mtrue, TruePts),
    cv_transform_points([[100, 100], [400, 300]], Mest, EstPts),
    show('two points under the true warp', TruePts), show('under the estimated one', EstPts),
    ( maplist(close_pt, TruePts, EstPts) -> Agree = within_three_pixels ; Agree = EstPts ),
    must('the estimate agrees with the truth', Agree, within_three_pixels),

    format("~n-- four pairs always fit exactly; it is the fifth that judges~n"),
    cv_find_homography([[0, 0], [1, 0], [0, 1], [1, 1], [5, 5]], [[3, 7], [90, 2], [1, 60], [40, 40], [77, 12]], 1.0, _, Inl5),
    sum_list(Inl5, NIn5), show('inliers among five random pairs', NIn5),
    ( NIn5 < 5 -> Judged = an_outlier_was_found ; Judged = NIn5 ), must('not all five can be inliers of one map', Judged, an_outlier_was_found),

    format("~n-- the picture~n"),
    cv_draw_keypoints(Ph, Ko, green, Drawn), cv_draw_keypoints(Warped, Kw, cyan, DrawnW),
    cv_hconcat([Drawn, DrawnW], Row), out('17-features.png', Path), cv_imwrite(Path, Row), show('written', Path),

    cv_free_all([Sq, H, Hp32, Hp, _L, Ph, Do, Ds, Da, Warped, Dw, Drawn, DrawnW, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

near(A, B) :- abs(A - B) =< 1.
close_pt([X1, Y1], [X2, Y2]) :- abs(X1 - X2) < 3, abs(Y1 - Y2) < 3.

photo('tutorials/tensor/42-detection-2.jpg').
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
