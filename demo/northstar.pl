%  The north-star sample: everything the three seams are for, in one
%  program about one star.
%
%  demo/stars.csv is a Hertzsprung-Russell diagram as numbers: 240 stars,
%  four features each -- log temperature, log luminosity, log radius,
%  absolute magnitude -- and a class: dwarf, main-sequence star, giant,
%  supergiant. The FILES module vouches for the file, the TORCH module
%  loads and learns it, and the trained model goes into ZIGURAT as plain
%  terms, where the next process -- any next process -- finds it.
%
%  The probe is Polaris. The North Star is an F7 Ib yellow supergiant
%  (T ~ 6015 K, L ~ 1260 Lsun, R ~ 37.5 Rsun), and a model that learned
%  the diagram should say so.
%
%    ./cocolog --embed /tmp/northstar run demo/northstar.pl train
%    ./cocolog --embed /tmp/northstar run demo/northstar.pl polaris
%
%  `train' learns the sky and saves the model; `polaris' -- in a fresh
%  process, with nothing but the store -- loads it back and answers.

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

star_class(0, dwarf).
star_class(1, main_sequence).
star_class(2, giant).
star_class(3, supergiant).

%  log10(6015), log10(1260), log10(37.5), 4.83 - 2.5*log10(1260)
polaris_features([[3.7792, 3.1004, 1.5740, -2.9209]]).

%  the class a model answers for one row of features: the position of
%  the largest log-probability
argmax([X|Xs], A) :- argmax_(Xs, X, 0, 1, A).
argmax_([], _, A, _, A).
argmax_([X|Xs], Best, A0, I, A) :-
    I1 is I + 1,
    ( X > Best -> argmax_(Xs, X, I, I1, A) ; argmax_(Xs, Best, A0, I1, A) ).

train :-
    exists_file('demo/stars.csv'),
    tensor_load_csv('demo/stars.csv', All),
    tensor_shape(All, [N, 5]),
    tensor_cols(All, 0, 4, X0),
    tensor_cols(All, 4, 5, Y),
    NTrain is (N * 4) // 5,
    tensor_standardise(X0, NTrain, X),
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    torch_seed(1054),                    % the year SN 1054 lit the sky
    model_new([input(4), dense(32, relu), dense(16, relu),
               dense(4, log_softmax)], M),
    model_train(M, XTr, YTr, [epochs(120), batch(24), lr(0.01),
                              loss(nll), shuffle(true), final_loss(L)]),
    model_evaluate(M, XTe, YTe, accuracy, A),
    format("learned the diagram: train nll ~4f, held-out accuracy ~2f~n", [L, A]),
    %  Polaris rides through the SAME standardisation the model saw:
    %  append its raw features, standardise with the training statistics
    polaris_features(PF),
    tensor_from_list(PF, PRaw),
    standardise_like(PRaw, X0, NTrain, PStd),
    classify_t(M, PStd, Class),
    format("the model says Polaris is a ~w~n", [Class]),
    %  the model becomes terms, and the terms become rows in Zigurat
    model_save(north_star, M),
    assertz(north_star_probe(PF)),
    write(saved), nl.

%  standardising ONE row with the statistics of the training block:
%  append it under the training rows, standardise, take the last row
standardise_like(Row, X0, NTrain, Out) :-
    tensor_to_list(X0, Rows),
    tensor_to_list(Row, [R]),
    append(Rows, [R], Rows1),
    tensor_from_list(Rows1, T1),
    tensor_standardise(T1, NTrain, T2),
    tensor_shape(T2, [M, _]),
    From is M - 1,
    tensor_rows(T2, From, M, Out),
    tensor_free(T1), tensor_free(T2).

classify_t(M, X, Class) :-
    model_predict(M, X, P),
    tensor_to_list(P, [Row]),
    argmax(Row, N),
    star_class(N, Class),
    tensor_free(P).

polaris :-
    %  a fresh process: nothing here but what Zigurat kept
    model_load(north_star, M),
    north_star_probe(PF),
    exists_file('demo/stars.csv'),
    tensor_load_csv('demo/stars.csv', All),
    tensor_shape(All, [N, 5]),
    tensor_cols(All, 0, 4, X0),
    NTrain is (N * 4) // 5,
    tensor_from_list(PF, PRaw),
    standardise_like(PRaw, X0, NTrain, PStd),
    classify_t(M, PStd, Class),
    format("out of the store, the model still says Polaris is a ~w~n", [Class]),
    ( Class == supergiant -> write(the_sky_agrees) ; write(the_sky_disagrees) ), nl.
