%% 15. A denoising autoencoder: noisy in, clean out
%%
%% The same eight patterns as tutorial 14, but the input carries six times
%% the noise and the TARGET is the clean pattern -- the network learns the
%% signal by being forbidden to learn the noise. That asymmetry (X noisy,
%% Y clean) is the whole difference between an autoencoder and a denoiser.
%%
%%   train    learn to clean, save as t15_denoise
%%   test     reload, rmse of cleaned-vs-clean under 0.12
%%   predict  reload, clean one noisy pattern before your eyes

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

dn_rows(I, Noisy, Clean) :-
    H is I mod 8,
    findall(V, (between(0, 7, J), ( J =:= H -> V = 1.0 ; V = 0.0 )), Clean),
    findall(V, (between(0, 7, J),
                noise(I * 8 + J + 40000, E),
                ( J =:= H -> V is 1 + 0.3 * E ; V is 0.3 * E )), Noisy), !.

dn_data(X, Y) :-
    findall(R, (between(0, 127, I), dn_rows(I, R, _)), XR),
    findall(R, (between(0, 127, I), dn_rows(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(15),
    dn_data(X, Y),
    model_new([input(8), dense(8, tanh), dense(8)], M),
    model_train(M, X, Y, [epochs(800), batch(32), lr(0.02), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t15_denoise, M),
    write(saved), nl.

test :-
    model_load(t15_denoise, M),
    dn_data(X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("denoised rmse ~4f~n", [S]),
    ( S < 0.12 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t15_denoise, M),
    dn_rows(999, Noisy, Clean),
    tensor_from_list([Noisy], X),
    model_predict(M, X, P),
    tensor_to_list(P, [Out]),
    write('noisy:   '), forall(member(V, Noisy), format("~2f ", [V])), nl,
    write('cleaned: '), forall(member(V, Out), format("~2f ", [V])), nl,
    write('truth:   '), forall(member(V, Clean), format("~2f ", [V])), nl.
