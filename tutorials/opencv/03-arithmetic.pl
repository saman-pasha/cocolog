%% OPENCV 03 -- arithmetic: images as numbers, saturating
%%
%%     ./cocolog run tutorials/opencv/03-arithmetic.pl main
%%
%% OpenCV's "Operations with images", "Adding (blending) two images" and
%% "Changing contrast and brightness" lessons. The rule underneath every
%% one of them is SATURATION: 8-bit arithmetic clamps at 0 and 255 rather
%% than wrapping, which is why 200 + 100 is 255 here and 44 in C.
%%
%%     cv_add/3 cv_sub/3 cv_mul/3 cv_div/3 cv_absdiff/3 cv_max/3 cv_min/3
%%     cv_add_scalar(+Img, +Color, -Out)   cv_pow(+Img, +P, -Out)
%%     cv_add_weighted(+A, +Alpha, +B, +Beta, +Gamma, -Out)
%%     cv_and/3 cv_or/3 cv_xor/3 cv_not/2         bitwise, for masks
%%     cv_compare(+A, +B, +Op, -Mask)   cv_in_range(+Img, +Lo, +Hi, -Mask)
%%     cv_mean/2 cv_mean_std/3 cv_minmax/5 cv_sum/2 cv_count_nonzero/2
%%     cv_normalize(+Img, +Lo, +Hi, +Norm, -Out)
%%     cv_flip/3 cv_rotate/3 cv_transpose/2 cv_split/2 cv_merge/2 cv_hconcat/2 cv_vconcat/2

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- saturating arithmetic~n"),
    cv_from_list([[200, 100, 0]], '8u', A),
    cv_from_list([[100, 100, 100]], '8u', B),
    cv_add(A, B, Sum), cv_to_list(Sum, SL), must('200 + 100 saturates to 255', SL, [[255, 200, 100]]),
    cv_sub(A, B, Dif), cv_to_list(Dif, DL), must('0 - 100 floors at 0', DL, [[100, 0, 0]]),
    cv_absdiff(A, B, Abs), cv_to_list(Abs, AL), must('absdiff does not floor', AL, [[100, 0, 100]]),
    cv_max(A, B, Mx), cv_to_list(Mx, ML), must('elementwise max', ML, [[200, 100, 100]]),
    cv_add_scalar(A, 60, Br), cv_to_list(Br, BL), must('brightness: a scalar added to every pixel', BL, [[255, 160, 60]]),
    cv_from_list([[2.0, 3.0]], '64f', F), cv_pow(F, 2, F2), cv_to_list(F2, FL), must('cv_pow/3', FL, [[4.0, 9.0]]),

    format("~n-- blending is a weighted sum~n"),
    cv_new(2, 2, '8u', 100, C1), cv_new(2, 2, '8u', 200, C2),
    cv_add_weighted(C1, 0.5, C2, 0.5, 0, Blend), cv_get(Blend, 0, 0, Bv),
    must('0.5 * 100 + 0.5 * 200', Bv, 150),
    cv_add_weighted(C1, 0.25, C2, 0.75, 10, Blend2), cv_get(Blend2, 0, 0, Bv2),
    must('alpha, beta, and gamma added after', Bv2, 185),

    format("~n-- masks: 0 or 255, combined bitwise~n"),
    cv_from_list([[255, 255, 0, 0]], '8u', M1),
    cv_from_list([[255, 0, 255, 0]], '8u', M2),
    cv_and(M1, M2, And), cv_to_list(And, AndL), must('and', AndL, [[255, 0, 0, 0]]),
    cv_or(M1, M2, Or), cv_to_list(Or, OrL), must('or', OrL, [[255, 255, 255, 0]]),
    cv_xor(M1, M2, Xor), cv_to_list(Xor, XorL), must('xor', XorL, [[0, 255, 255, 0]]),
    cv_not(M1, Not), cv_to_list(Not, NotL), must('not', NotL, [[0, 0, 255, 255]]),
    cv_compare(A, B, gt, Gt), cv_to_list(Gt, GtL), must('compare answers a mask: 255 where A > B', GtL, [[255, 0, 0]]),
    cv_in_range(A, 50, 150, InR), cv_to_list(InR, InL), must('in_range: 255 where Lo =< V =< Hi', InL, [[0, 255, 0]]),
    cv_count_nonzero(Or, NZ), must('count_nonzero counts the mask', NZ, 3),

    format("~n-- statistics answer one number per channel~n"),
    cv_mean(A, [Mean]), must('mean of 200, 100, 0', Mean, 100.0),
    cv_new(3, 3, '8uc3', [10, 20, 30], K),
    cv_mean(K, KM), must('a colour image: three means, [B, G, R]', KM, [10.0, 20.0, 30.0]),
    cv_mean_std(K, _, [Sb, _, _]), must('a constant image has no deviation', Sb, 0.0),
    cv_sum(A, [S]), must('sum', S, 300.0),
    cv_from_list([[5, 1], [9, 3]], '8u', Q),
    cv_minmax(Q, Lo, Hi, LoAt, HiAt),
    must('min and max', Lo-Hi, 1.0-9.0),
    must('where the min is, as [X, Y]', LoAt, [1, 0]),
    must('where the max is', HiAt, [0, 1]),

    format("~n-- normalize stretches; the range becomes the range you name~n"),
    cv_from_list([[0, 20, 100]], '8u', Nm), cv_normalize(Nm, 0, 255, minmax, Nz), cv_to_list(Nz, NzL),
    must('minmax to 0..255', NzL, [[0, 51, 255]]),

    format("~n-- rearranging: flip, rotate, transpose, split, merge, concat~n"),
    cv_from_list([[1, 2, 3]], '8u', Row), cv_flip(Row, horizontal, FH), cv_to_list(FH, FHL), must('flip horizontal', FHL, [[3, 2, 1]]),
    cv_from_list([[1], [2]], '8u', Col), cv_flip(Col, vertical, FV), cv_to_list(FV, FVL), must('flip vertical', FVL, [[2], [1]]),
    cv_from_list([[1, 2], [3, 4]], '8u', Sq),
    cv_rotate(Sq, 90, R90), cv_to_list(R90, R90L), must('rotate 90 clockwise', R90L, [[3, 1], [4, 2]]),
    cv_transpose(Sq, Tr), cv_to_list(Tr, TrL), must('transpose', TrL, [[1, 3], [2, 4]]),
    cv_split(K, Chans), length(Chans, NC), must('split gives one grey image per channel', NC, 3),
    Chans = [Bc, Gc, Rc], cv_get(Rc, 0, 0, Rv), must('the third is red', Rv, 30),
    cv_merge([Rc, Gc, Bc], Swapped), cv_get(Swapped, 0, 0, Sw), must('merge in another order swaps channels', Sw, [30, 20, 10]),
    cv_hconcat([Sq, Sq], Hc), cv_shape(Hc, HcS), must('hconcat widens', HcS, [2, 4, 1]),
    cv_vconcat([Sq, Sq], Vc), cv_shape(Vc, VcS), must('vconcat heightens', VcS, [4, 2, 1]),

    format("~n-- the picture: a photograph blended with its own negative~n"),
    photo(P), cv_imread(P, Ph), cv_not(Ph, Neg), cv_add_weighted(Ph, 0.6, Neg, 0.4, 0, Mix),
    cv_hconcat([Ph, Mix], Side), out('03-blend.png', Path), cv_imwrite(Path, Side), show('written', Path),

    cv_free_all([A, B, Sum, Dif, Abs, Mx, Br, F, F2, C1, C2, Blend, Blend2, M1, M2, And, Or, Xor, Not, Gt, InR,
                 K, Q, Nm, Nz, Row, FH, Col, FV, Sq, R90, Tr, Bc, Gc, Rc, Swapped, Hc, Vc, Ph, Neg, Mix, Side]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

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
