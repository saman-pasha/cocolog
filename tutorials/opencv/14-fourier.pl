%% OPENCV 14 -- the Fourier transform: an image as frequencies
%%
%%     ./cocolog run tutorials/opencv/14-fourier.pl main
%%
%% OpenCV's "Discrete Fourier Transform" lesson. The DFT rewrites an
%% image as a sum of sinusoids; its answer is complex, two channels of
%% 32f, and the picture everybody draws is the log of the magnitude with
%% the zero frequency moved to the centre -- cv_spectrum/2 does exactly
%% that. Where the spectrum is bright says what repeats, and how often.
%%
%%     cv_dft(+Img, -Complex)          32fc2, the raw transform
%%     cv_spectrum(+Img, -Img2)        log(1 + |F|), quadrants swapped, normalised to [0, 1], 32f

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a constant image is all DC~n"),
    cv_new(8, 8, '8u', 3, Flat), cv_dft(Flat, F),
    cv_shape(F, FS), must('the transform has two channels: real and imaginary', FS, [8, 8, 2]),
    cv_type(F, FT), must('as 32fc2', FT, '32fc2'),
    cv_get(F, 0, 0, [Re0, Im0]), must('the zero frequency is the sum of the pixels, 64 times 3', Re0, 192.0),
    must('and has no imaginary part', Im0, 0.0),
    cv_get(F, 3, 5, [Re1, _]), ( abs(Re1) < 0.001 -> Zero = about_zero ; Zero = Re1 ), must('every other coefficient is 0', Zero, about_zero),

    format("~n-- vertical stripes with period 16: energy at horizontal frequency 8~n"),
    cv_new(128, 128, '8u', 0, Stripes),
    forall((between(0, 7, K), X is K * 16), cv_rectangle(Stripes, [X, 0, 8, 128], 255, -1)),
    cv_spectrum(Stripes, Sp), cv_shape(Sp, SpS), must('the spectrum is one channel', SpS, [128, 128, 1]),
    cv_type(Sp, SpT), must('32f in [0, 1]', SpT, '32f'),
    cv_minmax(Sp, _, _, _, Peak), must('the brightest point is the centre, the DC term', Peak, [64, 64]),
    cv_get(Sp, 64, 72, AtFreq), cv_get(Sp, 64, 70, Beside), cv_get(Sp, 72, 64, Vertical),
    show('at (64 + 8, 64), the stripe frequency', AtFreq), show('two columns over', Beside), show('the same distance vertically', Vertical),
    ( AtFreq > Beside, AtFreq > Vertical -> Peaked = yes ; Peaked = no ), must('the spectrum peaks at the stripe frequency, horizontally', Peaked, yes),

    format("~n-- blurring removes high frequencies~n"),
    scene(Sc), cv_gray(Sc, G), cv_spectrum(G, SpG),
    cv_gaussian_blur(G, 15, 0, Gb), cv_spectrum(Gb, SpB),
    cv_roi(SpG, [0, 0, 20, 20], CornerG), cv_roi(SpB, [0, 0, 20, 20], CornerB),
    cv_mean(CornerG, [HighG]), cv_mean(CornerB, [HighB]),
    show('mean of the far corner (high frequencies), sharp', HighG), show('blurred', HighB),
    ( HighB < HighG -> Less = yes ; Less = no ), must('the blurred image has less there', Less, yes),

    format("~n-- the pictures~n"),
    cv_scale(Sp, 255, Sp255), cv_convert(Sp255, '8u', Sp8),
    cv_scale(SpG, 255, SpG255), cv_convert(SpG255, '8u', SpG8), cv_resize(SpG8, [128, 128], SpG8s),
    cv_resize(G, [128, 128], Gs),
    cv_hconcat([Stripes, Sp8, Gs, SpG8s], Row), out('14-fourier.png', Path), cv_imwrite(Path, Row),
    show('written: stripes and their spectrum, the scene and its spectrum', Path),

    cv_free_all([Flat, F, Stripes, Sp, Sc, G, SpG, Gb, SpB, CornerG, CornerB, Sp255, Sp8, SpG255, SpG8, SpG8s, Gs, Row]),
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
