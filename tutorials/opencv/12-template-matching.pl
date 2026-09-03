%% OPENCV 12 -- template matching: finding a patch by sliding it
%%
%%     ./cocolog run tutorials/opencv/12-template-matching.pl main
%%
%% OpenCV's "Template Matching". The template is slid over the image and
%% a score is written at every position; the answer is an image of
%% scores, (W - w + 1) by (H - h + 1), and cv_minmax/5 finds the best.
%% Which end is best depends on the method: the squared-difference ones
%% want the MINIMUM, the correlation ones the MAXIMUM, and the _normed
%% versions are bounded so a threshold means the same thing everywhere.
%%
%%     cv_match_template(+Img, +Template, +Method, -Scores)
%%       sqdiff sqdiff_normed ccorr ccorr_normed ccoeff ccoeff_normed

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out, cv_seed(5),
    format("~n-- the template is cut from the picture, so the match is exact~n"),
    scene(Sc), cv_roi(Sc, [130, 30, 100, 100], T),
    cv_match_template(Sc, T, ccoeff_normed, R),
    cv_shape(R, RS), must('scores: one per placement, (256 - 100 + 1) squared', RS, [157, 157, 1]),
    cv_type(R, RT), must('as 32f', RT, '32f'),
    cv_minmax(R, _, Best, _, At), must('the best score is 1.0 where it was cut, [X, Y]', At, [130, 30]),
    ( Best > 0.999 -> One = about_one ; One = Best ), must('and the score there', One, about_one),
    cv_match_template(Sc, T, sqdiff, Rs), cv_minmax(Rs, Min, _, MinAt, _),
    must('sqdiff: the MINIMUM is the match', MinAt, [130, 30]),
    ( Min < 10 -> Zero = about_zero ; Zero = Min ), must('and it is 0, to float rounding', Zero, about_zero),

    format("~n-- noise on the picture: the normalised correlation still finds it~n"),
    cv_noise(Sc, 30, Noisy), cv_match_template(Noisy, T, ccoeff_normed, Rn), cv_minmax(Rn, _, BestN, _, AtN),
    must('found in the noisy picture', AtN, [130, 30]), show('with score', BestN),
    ( BestN < Best -> Lower = yes ; Lower = no ), must('lower than the clean match', Lower, yes),

    format("~n-- a template that is not there scores badly~n"),
    cv_roi(Sc, [145, 122, 100, 24], Tt), cv_rotate(Tt, 90, Tr), cv_match_template(Sc, Tr, ccoeff_normed, Rr), cv_minmax(Rr, _, BestR, _, _),
    show('the best a rotated copy of the text can do', BestR),
    ( BestR < 0.8 -> Bad = yes ; Bad = BestR ), must('well below 1', Bad, yes),

    format("~n-- several copies: threshold the score map, count the blobs~n"),
    cv_new(200, 300, '8uc3', [50, 50, 50], Many),
    forall(member([X, Y], [[20, 30], [140, 60], [230, 120]]),
           (cv_rectangle(Many, [X, Y, 30, 30], orange, -1), Cx is X + 15, Cy is Y + 15, cv_circle(Many, [Cx, Cy], 8, black, -1))),
    cv_roi(Many, [20, 30, 30, 30], Tm), cv_match_template(Many, Tm, ccoeff_normed, Rm),
    cv_threshold(Rm, 0.95, 255, binary, Hits), cv_convert(Hits, '8u', Hits8),
    cv_find_contours(Hits8, external, simple, Blobs), length(Blobs, NB), must('three peaks above 0.95', NB, 3),
    findall([Bx, By], (member(Bl, Blobs), cv_bounding_rect(Bl, [Bx, By, _, _])), Where), msort(Where, WhereS),
    must('at the three top-left corners', WhereS, [[20, 30], [140, 60], [230, 120]]),

    format("~n-- the picture~n"),
    cv_clone(Noisy, Draw), cv_rectangle(Draw, [130, 30, 100, 100], white, 2),
    cv_normalize(Rn, 0, 255, minmax, Rn8f), cv_convert(Rn8f, '8u', Rn8), cv_cvt_color(Rn8, gray2bgr, RnC),
    cv_resize(RnC, [256, 256], RnBig), cv_hconcat([Draw, RnBig], Row),
    out('12-template.png', Path), cv_imwrite(Path, Row), show('written: the match boxed, and the score map', Path),

    cv_free_all([Sc, T, R, Rs, Noisy, Rn, Tt, Tr, Rr, Many, Tm, Rm, Hits, Hits8, Draw, Rn8f, Rn8, RnC, RnBig, Row]),
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
