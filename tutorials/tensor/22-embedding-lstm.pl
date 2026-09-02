%% 22. Embedding + LSTM: remembering whether a token ever appeared
%%
%% The shape of every text classifier: tokens (small integers) become
%% learned vectors through embedding(8, 4) -- a vocabulary of eight, four
%% dimensions each -- and an LSTM reads the vector sequence and keeps what
%% matters in its cell state. The task is pure memory: did token 3 appear
%% ANYWHERE in the six-token sequence? A bag of words could answer this
%% one too, but the machinery -- ids in, embedding, recurrence, class out
%% -- is exactly the sentiment-analysis pipeline at toy scale. Note the
%% input rows are just numbers 0..7; sequence(6) followed by embedding
%% makes the module treat them as ids rather than magnitudes.
%%
%%   train    learn to spot token 3, save as t22_embed
%%   test     reload, accuracy at 95%
%%   predict  reload, probe with and without the token

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

tok_row(I, Row, L) :-
    findall(T, (between(0, 5, J),
                noise(I * 6 + J + 70000, F),
                T is truncate(abs(F) * 7.99)), Row),
    ( member(3, Row) -> L = 1 ; L = 0 ), !.

tok_data(X, Y) :-
    findall(R, (between(0, 95, I), tok_row(I, R, _)), XR),
    findall(L, (between(0, 95, I), tok_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(22),
    tok_data(X, Y),
    model_new([sequence(6), embedding(8, 4), lstm(16), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t22_embed, M),
    write(saved), nl.

test :-
    model_load(t22_embed, M),
    tok_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t22_embed, M),
    Rows = [[0, 1, 2, 3, 4, 5],    % contains 3
            [0, 1, 2, 4, 5, 6],    % does not
            [3, 0, 0, 0, 0, 0],    % 3 at the very start: the memory test
            [7, 7, 7, 7, 7, 7]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, Picks),
    forall(( nth0(I, Picks, Pk), nth0(I, Rows, Row) ),
           ( C is truncate(Pk),
             ( C =:= 1 -> V = 'contains token 3' ; V = 'no token 3' ),
             format("~w  ->  ~w~n", [Row, V]) )).
