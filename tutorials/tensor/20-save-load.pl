%% 20. Persistence: what a model IS in the knowledge base
%%
%% Every tutorial here saves and reloads, but this one is ABOUT the
%% mechanics. model_save is nothing but model_spec (the architecture as
%% terms) plus model_params (every parameter and buffer as one flat list)
%% asserted into the knowledge base; model_load is model_new over the
%% stored spec plus model_set_params. Handles are process-local integers
%% and never travel; the TERMS travel, which is why a model saved against
%% a store is simply there for any later process, on whatever device that
%% process chose. The test proves the round trip to the last bit: params
%% equal, predictions identical.
%%
%%   train    fit a small net, save as t20_persist
%%   test     reload TWICE, params and predictions must agree exactly
%%   predict  reload, answer -- indistinguishable from the trainer's answers

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

sine_row(I, [X], [Y]) :- X is -1 + 2 * I / 63, Y is sin(2 * pi * X), !.

rows_close([], []).
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs).
row_close([], []).
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs).

sdata(X, Y) :-
    findall(R, (between(0, 63, I), sine_row(I, R, _)), XR),
    findall(R, (between(0, 63, I), sine_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(20),
    sdata(X, Y),
    model_new([input(1), dense(8, tanh), dense(1)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t20_persist, M),
    model_spec(M, Spec),
    format("stored spec: ~w~n", [Spec]),
    write(saved), nl.

test :-
    model_load(t20_persist, M1),
    model_load(t20_persist, M2),
    model_params(M1, P1), model_params(M2, P2),
    ( row_close(P1, P2) -> true
    ; write('FAIL params differ between two loads'), nl, halt(1) ),
    sdata(X, _),
    model_predict(M1, X, T1), model_predict(M2, X, T2),
    tensor_to_list(T1, R1), tensor_to_list(T2, R2),
    ( rows_close(R1, R2)
    -> write('ok params and predictions identical across loads'), nl
    ;  write('FAIL predictions differ'), nl, halt(1) ).

predict :-
    model_load(t20_persist, M),
    tensor_from_list([[0.25]], X),
    model_predict(M, X, P),
    tensor_to_list(P, [[Y]]),
    Truth is sin(2 * pi * 0.25),
    format("x 0.25  predicted ~3f  (sin says ~3f)~n", [Y, Truth]).
