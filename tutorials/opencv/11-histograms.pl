%% OPENCV 11 -- histograms: counting, comparing, equalising
%%
%%     ./cocolog run tutorials/opencv/11-histograms.pl main
%%
%% OpenCV's "Histogram Calculation", "Histogram Comparison" and
%% "Histogram Equalization" (with CLAHE). A histogram is a list of counts
%% here, so it can be summed, compared and drawn with the predicates you
%% already have; equalisation is the one operation that answers an image.
%%
%%     cv_hist(+Img, +Channel, +Bins, -Counts)              over [0, 256)
%%     cv_hist(+Img, +Channel, +Bins, +Lo, +Hi, -Counts)
%%     cv_compare_hist(+H1, +H2, +Method, -D)               correl chisqr intersect bhattacharyya
%%     cv_equalize_hist(+Gray, -Out)
%%     cv_clahe(+Gray, +Clip, +Tiles, -Out)                 contrast limited, per tile

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- counts~n"),
    cv_from_list([[0, 10, 200, 255], [0, 0, 128, 250]], '8u', A),
    cv_hist(A, 0, 4, H4), must('four bins of 64: [0..63], [64..127], [128..191], [192..255]', H4, [4, 0, 1, 3]),
    sum_list(H4, Total), must('the counts sum to the pixels', Total, 8),
    cv_hist(A, 0, 2, 0, 128, H2), must('a range: two bins over [0, 128) -- 0, 10, 0, 0 and none in [64, 128)', H2, [4, 0]),
    cv_new(3, 3, '8uc3', [10, 100, 200], K),
    cv_hist(K, 2, 4, HR), must('channel 2 is red: all nine pixels in the last bin', HR, [0, 0, 0, 9]),

    format("~n-- comparing: correlation is 1 for a histogram against itself~n"),
    scene(Sc), cv_gray(Sc, G), cv_hist(G, 0, 32, HG),
    cv_compare_hist(HG, HG, correl, Self), must('correl, self', Self, 1.0),
    cv_compare_hist(HG, HG, bhattacharyya, SelfB), ( SelfB < 0.001 -> Zero = about_zero ; Zero = SelfB ), must('bhattacharyya, self: a distance, so 0', Zero, about_zero),
    cv_not(G, Gi), cv_hist(Gi, 0, 32, HGi),
    cv_compare_hist(HG, HGi, correl, Inv), show('correl against the inverted image', Inv),
    ( Inv < 0.9 -> Less = yes ; Less = no ), must('lower than self', Less, yes),
    cv_compare_hist(HG, HGi, intersect, Isec), cv_compare_hist(HG, HG, intersect, IsecSelf),
    ( Isec < IsecSelf -> Ls = yes ; Ls = no ), must('intersect: less overlap than with itself', Ls, yes),

    format("~n-- equalisation stretches a cramped histogram over the whole range~n"),
    cv_seed(3), cv_rand(64, 64, '8u', 90, 140, Dull), cv_gaussian_blur(Dull, 7, 0, Dull2),
    cv_minmax(Dull2, Lo, Hi, _, _), show('a dull image spans', Lo-Hi),
    cv_equalize_hist(Dull2, Eq), cv_minmax(Eq, ELo, EHi, _, _),
    must('after equalize_hist it spans 0..255', ELo-EHi, 0.0-255.0),
    cv_hist(Eq, 0, 8, HEq), show('its histogram in 8 bins', HEq),
    cv_clahe(Dull2, 2.0, 8, Cl), cv_minmax(Cl, CLo, CHi, _, _), show('CLAHE spans', CLo-CHi),
    ( CHi - CLo > Hi - Lo -> Wider = yes ; Wider = no ), must('CLAHE widened it too', Wider, yes),

    format("~n-- drawing a histogram with the drawing predicates~n"),
    photo(P), cv_imread(P, gray, Pg), cv_hist(Pg, 0, 64, HP), max_list(HP, Max),
    cv_new(200, 256, '8uc3', black, Chart),
    forall((nth0(I, HP, Cnt), X is I * 4, Hgt is round(180 * Cnt / Max), Y is 199 - Hgt),
           cv_rectangle(Chart, [X, Y, 4, Hgt], [200, 200, 200], -1)),
    cv_equalize_hist(Pg, Peq), cv_hist(Peq, 0, 64, HPe), max_list(HPe, Maxe),
    cv_new(200, 256, '8uc3', black, Chart2),
    forall((nth0(I2, HPe, Cnt2), X2 is I2 * 4, Hgt2 is round(180 * Cnt2 / Maxe), Y2 is 199 - Hgt2),
           cv_rectangle(Chart2, [X2, Y2, 4, Hgt2], [120, 200, 120], -1)),
    cv_hconcat([Chart, Chart2], Charts), out('11-histograms.png', Path), cv_imwrite(Path, Charts),
    show('written: the photo histogram, before and after equalisation', Path),
    cv_hconcat([Pg, Peq], Pics), out('11-equalized.png', Path2), cv_imwrite(Path2, Pics), show('and the pictures', Path2),

    cv_free_all([A, K, Sc, G, Gi, Dull, Dull2, Eq, Cl, Pg, Chart, Peq, Chart2, Charts, Pics]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

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
