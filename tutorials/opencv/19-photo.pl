%% OPENCV 19 -- computational photography: denoise, inpaint, HDR, NPR
%%
%%     ./cocolog run tutorials/opencv/19-photo.pl main
%%
%% OpenCV's photo module: "Denoising" (non-local means), "Inpainting",
%% "High Dynamic Range Imaging" (exposure fusion, the part that needs no
%% camera data) and "Non-Photorealistic Rendering". Each answers a new
%% image, and each claim below is a number: the mean difference from the
%% original before and after.
%%
%%     cv_denoise(+Img, +H, -Out)                 colour or grey by the channels
%%     cv_inpaint(+Img, +Mask, +Radius, -Out)     paints over what the mask marks
%%     cv_merge_mertens(+Imgs, -Out)              exposure fusion, 32f, about [0, 1]
%%     cv_detail_enhance/2  cv_stylize/2  cv_pencil_sketch(+Img, -Gray, -Color)

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out, cv_seed(9),
    photo(P), cv_imread(P, Ph), cv_resize(Ph, 0.5, Img),
    format("~n-- non-local means denoising~n"),
    cv_noise(Img, 20, Noisy), error(Img, Noisy, E0), show('mean |noisy - original|', E0),
    cv_denoise(Noisy, 10, Den), error(Img, Den, E1), show('after cv_denoise 10', E1),
    ( E1 < 0.8 * E0 -> Better = yes ; Better = E1 ), must('a good part of the noise is gone (the rest is texture it kept)', Better, yes),
    cv_gray(Img, G), cv_noise(G, 20, Gn), cv_denoise(Gn, 10, Gd), error(G, Gd, E2), error(G, Gn, E3),
    ( E2 < E3 -> Grey = yes ; Grey = no ), must('grey works too (the module picks the grey variant)', Grey, yes),

    format("~n-- inpainting a scratch~n"),
    cv_clone(Img, Scratched), cv_line(Scratched, [20, 20], [250, 200], white, 4),
    cv_new(226, 272, '8u', 0, Mask), cv_line(Mask, [20, 20], [250, 200], 255, 6),
    error(Img, Scratched, ES), show('mean error with the scratch', ES),
    cv_inpaint(Scratched, Mask, 3, Fixed), error(Img, Fixed, EF), show('after inpainting under the mask', EF),
    ( EF < ES / 3 -> Repaired = yes ; Repaired = EF ), must('most of the damage is gone', Repaired, yes),

    format("~n-- exposure fusion: two bad exposures into one good one~n"),
    cv_scale(Img, 0.4, Dark), cv_scale(Img, 1.8, Bright),
    cv_merge_mertens([Dark, Bright], Fused), cv_type(Fused, FT), must('the fusion is 32f, about the unit range', FT, '32fc3'),
    cv_minmax_any(Fused, Lo, Hi), show('its range (the blend can overshoot a little either side)', Lo-Hi),
    ( Hi < 1.3, Lo > -0.3 -> Unit = about_0_1 ; Unit = Lo-Hi ), must('about [0, 1]', Unit, about_0_1),
    cv_scale(Fused, 255, F255), cv_convert(F255, '8uc3', Fused8),
    cv_mean(Dark, [DB|_]), cv_mean(Bright, [BB|_]), cv_mean(Fused8, [FB|_]),
    show('mean blue: dark, bright, fused', [DB, BB, FB]),
    ( FB > DB, FB < BB -> Mid = between ; Mid = FB ), must('the fusion sits between the exposures', Mid, between),

    format("~n-- non-photorealistic rendering~n"),
    cv_detail_enhance(Img, Enh), cv_stylize(Img, Sty), cv_pencil_sketch(Img, Pencil, PencilC),
    cv_shape(Pencil, [_, _, 1]), cv_shape(PencilC, [_, _, 3]),
    must('the pencil sketch comes as a grey and a colour version', true, true),
    error(Img, Enh, EE), error(Img, Sty, EY), show('how far enhance and stylize move the picture', [EE, EY]),
    ( EE < EY -> Order = enhance_is_gentler ; Order = EE-EY ), must('enhance is the gentler of the two', Order, enhance_is_gentler),

    format("~n-- the pictures~n"),
    cv_hconcat([Noisy, Den, Scratched, Fixed], Row1),
    cv_cvt_color(Pencil, gray2bgr, Pencil3), cv_hconcat([Fused8, Enh, Sty, Pencil3], Row2),
    cv_vconcat([Row1, Row2], Sheet), out('19-photo.png', Path), cv_imwrite(Path, Sheet), show('written', Path),

    cv_free_all([Ph, Img, Noisy, Den, G, Gn, Gd, Scratched, Mask, Fixed, Dark, Bright, Fused, F255, Fused8, Enh, Sty, Pencil, PencilC,
                 Row1, Pencil3, Row2, Sheet]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

error(A, B, E) :- cv_absdiff(A, B, D), cv_mean(D, Ms), cv_free(D), sum_list(Ms, S), length(Ms, L), E is S / L.
cv_minmax_any(Img, Lo, Hi) :-
    cv_split(Img, Chs), findall(L-H, (member(C, Chs), cv_minmax(C, L, H, _, _)), Pairs), cv_free_all(Chs),
    findall(L1, member(L1-_, Pairs), Ls), min_list(Ls, Lo), findall(H1, member(_-H1, Pairs), Hs), max_list(Hs, Hi).

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
