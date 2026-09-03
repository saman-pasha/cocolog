%% OPENCV 05 -- smoothing: four blurs, and what each one keeps
%%
%%     ./cocolog run tutorials/opencv/05-smoothing.pl main
%%
%% OpenCV's "Smoothing Images" lesson. Every filter here trades detail
%% for calm, and they differ in what they count as detail: the box and
%% Gaussian blurs average everything, the median throws away outliers
%% (salt and pepper) and keeps edges sharp, and the bilateral filter
%% averages only among pixels of similar colour, so an edge survives it.
%%
%%     cv_blur(+Img, +K, -Out)                         box, K by K
%%     cv_gaussian_blur(+Img, +K, +Sigma, -Out)        Sigma 0 derives it from K
%%     cv_median_blur(+Img, +K, -Out)
%%     cv_bilateral(+Img, +D, +SigmaColor, +SigmaSpace, -Out)
%%     cv_seed(+N)  cv_noise(+Img, +Sigma, -Noisy)     Gaussian noise, saturating
%%
%% The claims are made with numbers: the mean absolute difference from
%% the clean picture before and after.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out, cv_seed(42),
    format("~n-- a constant image is a fixed point of every blur~n"),
    cv_new(20, 20, '8u', 100, Flat),
    cv_blur(Flat, 5, Fb), cv_get(Fb, 10, 10, V1), must('box blur', V1, 100),
    cv_gaussian_blur(Flat, 5, 0, Fg), cv_get(Fg, 10, 10, V2), must('gaussian blur', V2, 100),
    cv_median_blur(Flat, 5, Fm), cv_get(Fm, 10, 10, V3), must('median blur', V3, 100),
    cv_bilateral(Flat, 9, 75, 75, Fbi), cv_get(Fbi, 10, 10, V4), must('bilateral filter', V4, 100),

    format("~n-- a step edge: the Gaussian smears it, the bilateral keeps it~n"),
    cv_new(20, 40, '8u', 0, Step), cv_rectangle(Step, [20, 0, 20, 20], 255, -1),
    cv_gaussian_blur(Step, 7, 0, Sg), cv_get(Sg, 10, 19, Gv),
    ( Gv > 0, Gv < 255 -> Smeared = yes ; Smeared = Gv ), must('the pixel beside the edge is now in between', Smeared, yes),
    cv_bilateral(Step, 9, 50, 50, Sb), cv_get(Sb, 10, 19, Bv), must('the bilateral filter leaves it at 0', Bv, 0),
    cv_get(Sb, 10, 20, Bv2), must('and the other side at 255', Bv2, 255),
    cv_median_blur(Step, 5, Sm), cv_get(Sm, 10, 19, Mv), must('the median keeps the edge too', Mv, 0),

    format("~n-- salt: single bright pixels, which the median alone removes~n"),
    cv_new(30, 30, '8u', 50, Salt),
    forall(member(P, [[3, 4], [10, 20], [15, 15], [22, 7], [27, 28]]), (P = [R, C], cv_set(Salt, R, C, 255))),
    cv_count_nonzero(Salt, NAll), must('every pixel is nonzero, the ground is 50', NAll, 900),
    cv_median_blur(Salt, 3, Sm3), cv_minmax(Sm3, _, MaxM, _, _), must('median 3: the maximum is the ground again', MaxM, 50.0),
    cv_gaussian_blur(Salt, 3, 0, Sg3), cv_minmax(Sg3, _, MaxG, _, _),
    ( MaxG > 50 -> Left = something_brighter ; Left = MaxG ), must('gaussian 3: the salt is spread, not removed', Left, something_brighter),

    format("~n-- Gaussian noise on the scene, and how much each filter takes back~n"),
    scene(Clean), cv_noise(Clean, 25, Noisy),
    error(Clean, Noisy, E0), show('mean |noisy - clean|', E0),
    cv_blur(Noisy, 5, B5), error(Clean, B5, Eb), show('after box 5', Eb),
    cv_gaussian_blur(Noisy, 5, 0, G5), error(Clean, G5, Eg), show('after gaussian 5', Eg),
    cv_median_blur(Noisy, 5, M5), error(Clean, M5, Em), show('after median 5', Em),
    cv_bilateral(Noisy, 9, 60, 60, Bi), error(Clean, Bi, Ebi), show('after bilateral 9', Ebi),
    ( Eb < E0, Eg < E0, Em < E0, Ebi < E0 -> All = every_filter_helped ; All = some_did_not ),
    must('each is closer to the clean picture than the noise was', All, every_filter_helped),

    cv_hconcat([Noisy, G5, M5, Bi], Row), out('05-smoothing.png', Path), cv_imwrite(Path, Row),
    show('written: noisy, gaussian, median, bilateral', Path),
    cv_free_all([Flat, Fb, Fg, Fm, Fbi, Step, Sg, Sb, Sm, Salt, Sm3, Sg3, Clean, Noisy, B5, G5, M5, Bi, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% mean absolute difference over all channels, one number
error(A, B, E) :-
    cv_absdiff(A, B, D), cv_mean(D, Ms), cv_free(D),
    sum_list(Ms, S), length(Ms, L), E is S / L.

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
