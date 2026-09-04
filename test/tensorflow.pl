%% library(tensorflow): the tensor_* predicates over TensorFlow's C library, as
%% the second backend behind tensor_execution(Backend, Mode).
%%
%%     cocolog -s test/tensorflow.pl        SKIPs where library/tensorflow.so is not built
%%
%% WHAT IS BEING CHECKED. Under tensor_execution(tensorflow, eager) every
%% producer answers what the torch backend answers, within a tolerance -- two
%% libraries' kernels, not one. Under (tensorflow, graph) a loss built of the
%% predicates differentiates through TF_AddGradients to the analytic gradient,
%% a step answers a new parameter, a random leaf read twice is one draw, and a
%% shape is known with nothing executed. Under (tensorflow, eager) the same
%% gradients come out -- the recorded structure compiled and differentiated
%% the same way, after the values are already there -- and a loss read by
%% item first still differentiates. Last, tutorial 31's fit under tensorflow,
%% eager then graph in one process, is IDENTICAL across its two paths and
%% reaches torch's numbers within a tolerance -- the same program, the other
%% library.
%%
%% Every check IS a child, two of them where both backends run: a backend
%% and its mode are a process's.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/torch.so') -> true ; skip('(no library/torch.so)') ),
    ( exists_file('library/tensorflow.so') -> true ; skip('(no library/tensorflow.so -- sh modules/tensorflow/build.sh)') ),
    q('tensorflow_version(V), write(answer(V)), nl', Version),
    tf(TF), sh_join([TF, ', tensor_execution(B, M), write(answer(B-M)), nl'], GS), q(GS, Switch),
    sh_join([Version, ' is the TensorFlow; the switch answers ', Switch], S), section(S),
    every_producer, under_graph, under_eager, tutorial31,
    checks_done.

u('use_module(library(torch)), use_module(library(tensorflow))').
q(Goal, Got) :- u(U), sh_join(['query "', U, ', ', Goal, '"'], Args), answer_text(Args, Got).
%% the child's stderr too, for the `running on cpu' notice
q_both(Goal, Text) :- u(U), cocolog(C), sh_join([C, ' query "', U, ', ', Goal, '" 2>&1'], Cmd), shell(Cmd, Text, _).
tf('tensor_execution(tensorflow, eager), tensorflow_seed(11), torch_seed(11)').
torch('tensor_execution(torch, eager), torch_seed(11), tensorflow_seed(11)').
%% the same goal on both backends, with the same leaves written out, within Tol
near(Label, Goal, Tol) :-
    tf(TF), sh_join([TF, ', ', Goal], GT), q(GT, T),
    torch(TO), sh_join([TO, ', ', Goal], GO), q(GO, O),
    sh_join([T, '/', O], Both), maxdiff(Both, D),
    sh_join(['within ', Tol], Want),
    ( D \== inf, D =< Tol -> W = Want ; sh_join(['off by ', D], W) ),
    check(Label, W, Want).
leaves('tensor_from_list([[0.5, -1.0, 2.0], [1.5, 0.25, -0.75]], A), tensor_from_list([[1.0, 2.0], [-1.0, 0.5], [0.0, 1.0]], B), tensor_from_list([[2.0, 1.0, -1.0], [0.5, 0.5, 0.5]], A2)').
flat('tensor_reshape(R, [-1], F), tensor_to_list(F, L), write(answer(L)), nl').
lsq('tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_reshape(Gr, [-1], F), tensor_to_list(F, GL), write(answer(GL)), nl').

every_producer :-
    section('every producer under (tensorflow, eager), within 1e-5 of the torch backend'),
    leaves(L), flat(F),
    forall(member(Op, [neg, abs, exp, relu, sigmoid, tanh, transpose]),
           ( sh_join(['unary ', Op], Lb), sh_join([L, ', tensor_unary(', Op, ', A, R), ', F], G), near(Lb, G, 1.0e-5) )),
    sh_join([L, ', tensor_unary(abs, A, P), tensor_scalar(add, P, 1.0, Q), tensor_unary(log, Q, R), ', F], G1), near('unary log, on a positive tensor', G1, 1.0e-5),
    sh_join([L, ', tensor_unary(abs, A, P), tensor_unary(sqrt, P, R), ', F], G2), near('unary sqrt, likewise', G2, 1.0e-5),
    forall(member(Op, [add, sub, mul, div, pow]),
           ( sh_join(['scalar ', Op], Lb), sh_join([L, ', tensor_scalar(', Op, ', A, 2.5, R), ', F], G), near(Lb, G, 1.0e-5) )),
    forall(member(Op, [add, sub, mul, div]),
           ( sh_join(['binary ', Op], Lb), sh_join([L, ', tensor_binary(', Op, ', A, A2, R), ', F], G), near(Lb, G, 1.0e-5) )),
    sh_join([L, ', tensor_binary(matmul, A, B, R), ', F], G3), near('binary matmul', G3, 1.0e-5),
    forall(member(Op, [sum, mean, max, min, std]),
           ( sh_join(['agg ', Op], Lb), sh_join([L, ', tensor_agg(', Op, ', A, R), ', F], G), near(Lb, G, 1.0e-5) )),
    sh_join([L, ', tensor_argmax(A, 1, R), ', F], G4), near(argmax, G4, 0),
    sh_join([L, ', tensor_reshape(A, [3, 2], R), ', F], G5), near(reshape, G5, 0),
    sh_join([L, ', tensor_cat([A, A2], 0, R), ', F], G6), near(cat, G6, 0),
    sh_join([L, ', tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), ', F], G7), near(index_rows, G7, 0),
    sh_join([L, ', tensor_rows(A, 1, 2, R0), tensor_cols(R0, 0, 2, R), ', F], G8), near('rows and cols', G8, 0),
    sh_join([L, ', tensor_standardise(A, 2, R), ', F], G9), near(standardise, G9, 1.0e-5),
    sh_join(['tensor_eye(3, E), tensor_arange(3, Ar), tensor_full([3], 2.0, Fu), tensor_reshape(Ar, [3, 1], Ar2), tensor_binary(matmul, E, Ar2, X1), tensor_reshape(Fu, [3, 1], Fu2), tensor_binary(add, X1, Fu2, R), ', F], G10), near('eye, arange, full', G10, 0),
    sh_join([L, ', tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_agg(mean, X7, R), ', F], G11), near('a ten-op expression', G11, 1.0e-4),
    tf(TF),
    sh_join([TF, ', ', L, ', tensor_shape(A, S), write(answer(S)), nl'], G12), q(G12, R12),
    check('a shape asks nothing of the values', R12, '[2,3]'),
    sh_join([TF, ', tensor_new([2, 3], randn, R), tensor_to_list(R, L1), tensor_to_list(R, L2), (L1 == L2 -> write(answer(same)) ; write(answer(different))), nl'], G13), q(G13, R13),
    check('a random leaf is drawn once, whichever backend', R13, same).

under_graph :-
    section('under (tensorflow, graph): the gradient, the step, the shape before anything runs'),
    G = 'tensor_execution(tensorflow, graph), tensorflow_seed(11)',
    lsq(LSQ), torch(TO),
    sh_join([G, ', ', LSQ], G1), q(G1, LsqTf),
    sh_join([TO, ', ', LSQ], G1b), q(G1b, LsqTo),
    sh_join([LsqTf, '/', LsqTo], B1), maxdiff(B1, D1),
    ( D1 \== inf, D1 =< 1.0e-5 -> W1 = 'within 1e-5' ; sh_join(['off by ', D1], W1) ),
    check('the least-squares gradient, within 1e-5 of torch''s', W1, 'within 1e-5'),
    sh_join([G, ', tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(GL)), nl'], G2), q(G2, R2),
    check('grad of sum(W*W) is 2W, exactly', R2, '[[3.0],[-4.0]]'),
    sh_join([G, ', tensor_from_list([1.0, 2.0], A0), tensor_parameter(A0, A), tensor_from_list([1.0], U0), tensor_parameter(U0, U), tensor_agg(sum, A, L), tensor_grad(L, [A, U], [_, GU]), tensor_to_list(GU, GL), write(answer(GL)), nl'], G3), q(G3, R3),
    check('a parameter the loss never reached gets zeros', R3, '[0.0]'),
    sh_join([G, ', tensor_from_list([1.0], W0), tensor_parameter(W0, W), tensor_scalar(sub, W, 3.0, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_step(W, Gr, 0.5, W2), tensor_to_list(W2, L2), write(answer(L2)), nl'], G4), q(G4, R4),
    check('a step is a new leaf: W - 0.5 G from W = 1 on (w - 3)^2 is 3', R4, '[3.0]'),
    sh_join([G, ', tensor_new([3, 4], zeros, A), tensor_new([4, 5], ones, B), tensor_binary(matmul, A, B, C), tensor_shape(C, S), tensor_graph_stats(stats(_, executed(E), _, _)), write(answer(S-E)), nl'], G5), q(G5, R5),
    check('the shape of a matmul, executed nothing', R5, '[3,5]-0'),
    sh_join([G, ', tensor_new([3, 4], zeros, A), tensor_new([5, 6], ones, B), catch((tensor_binary(matmul, A, B, _), write(answer(accepted))), error(domain_error(_, _), _), write(answer(refused))), nl'], G6), q(G6, R6),
    check('a shape error is refused when the op is added', R6, refused).

under_eager :-
    section('under (tensorflow, eager): the same gradients, from the tape the recorded structure is'),
    E = 'tensor_execution(tensorflow, eager), tensorflow_seed(11)',
    lsq(LSQ), torch(TO),
    sh_join([E, ', ', LSQ], G1), q(G1, LsqE),
    sh_join([TO, ', ', LSQ], G1b), q(G1b, LsqTo),
    sh_join([LsqE, '/', LsqTo], B1), maxdiff(B1, D1),
    ( D1 \== inf, D1 =< 1.0e-5 -> W1 = 'within 1e-5' ; sh_join(['off by ', D1], W1) ),
    check('the least-squares gradient under eager, within 1e-5 of torch''s', W1, 'within 1e-5'),
    sh_join([E, ', tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(GL)), nl'], G2), q(G2, R2),
    check('grad of sum(W*W) under eager is 2W, exactly', R2, '[[3.0],[-4.0]]'),
    sh_join([E, ', tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_item(L, V), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(V-GL)), nl'], G3), q(G3, R3),
    check('a loss read by item first still differentiates, under eager', R3, '6.25-[[3.0],[-4.0]]'),
    sh_join([E, ', tensor_from_list([1.0], W0), tensor_parameter(W0, W), tensor_scalar(sub, W, 3.0, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_step(W, Gr, 0.5, W2), tensor_to_list(W2, L2), write(answer(L2)), nl'], G4), q(G4, R4),
    check('a step under eager: W - 0.5 G from W = 1 on (w - 3)^2 is 3', R4, '[3.0]'),
    sh_join([E, ', tensor_from_list([1.0, 2.0], A0), tensor_parameter(A0, A), tensor_from_list([1.0], U0), tensor_parameter(U0, U), tensor_agg(sum, A, L), tensor_grad(L, [A, U], [_, GU]), tensor_to_list(GU, GL), write(answer(GL)), nl'], G5), q(G5, R5),
    check('a parameter the loss never reached gets zeros, under eager', R5, '[0.0]'),
    %% the device, third: asked for cuda on a machine without one, the run
    %% is on cpu and stderr says so; auto is quiet either way
    q('tensor_execution(tensorflow, eager, cuda), tensor_execution(_, _, D), write(answer(D)), nl', TfDev),
    notices('tensor_execution(tensorflow, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl', tensorflow, N6),
    sh_join([E, ', tensor_execution(tensorflow, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl'], G6), q(G6, R6),
    sh_join([N6, '-', R6], Got6),
    ( TfDev == cuda -> Want6 = '0-tensorflow-eager-cuda' ; Want6 = '1-tensorflow-eager-cpu' ),
    check('the device, third: cuda asked for on a machine without one runs on cpu, and says so', Got6, Want6),
    notices('tensor_execution(tensorflow, graph, auto), tensor_execution(_, M, D), write(answer(M-D)), nl', tensorflow, N7),
    q('tensor_execution(tensorflow, graph, auto), tensor_execution(_, M, D), write(answer(M-D)), nl', R7),
    sh_join([N7, '-', R7], Got7),
    q('tensor_execution(tensorflow, graph, auto), tensor_execution(_, _, D), write(answer(D)), nl', AutoDev),
    sh_join(['0-graph-', AutoDev], Want7),
    check('auto is cuda where there is one and cpu elsewhere, quietly', Got7, Want7),
    notices('tensor_execution(torch, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl', torch, N8),
    q('tensor_execution(torch, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl', R8),
    sh_join([N8, '-', R8], Got8),
    q('torch_cuda_available(A), write(answer(A)), nl', TorchCuda),
    ( TorchCuda == true -> Want8 = '0-torch-eager-cuda' ; Want8 = '1-torch-eager-cpu' ),
    check('and the same three arguments on torch', Got8, Want8),
    sh_join([E, ', tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [G1]), tensor_grad(L, [W], [G2]), tensor_to_list(G1, L1), tensor_to_list(G2, L2), (L1 == L2 -> write(answer(same)) ; write(answer(different))), nl'], G9), q(G9, R9),
    check('a gradient twice of one loss is the same gradient', R9, same).

%% how many `running on cpu' lines naming Lib a goal's run printed, both streams
notices(Goal, Lib, N) :-
    q_both(Goal, Text), atom_codes(Text, Cs),
    re_lines('running on cpu', Cs, Ls),
    findall(x, ( member(L, Ls), atom_codes(A, L), sub_atom(A, _, _, _, Lib) ), Xs), length(Xs, N).

tutorial31 :-
    section('tutorial 31''s fit, the same program on the other library, identical across its two paths'),
    T31 = 'tutorials/tensor/31-tensor-expressions.pl',
    (   exists_file(T31)
    ->  scratch(D1), scratch(D2),
        sh_join(['--kb tutorials --embed ', D1, ' run ', T31, ' "tensor_execution(tensorflow, graph), train" 2>/dev/null'], A1),
        cocolog_run(A1, TfOut, _, 600000),
        ( re_first_atom('graph: loss[^\n]*', TfOut, Tf) -> true ; Tf = '' ),
        sh_join(['--kb tutorials --embed ', D2, ' run ', T31, ' "tensor_execution(torch, graph), train" 2>/dev/null'], A2),
        cocolog_run(A2, ToOut, _, 600000),
        ( re_first_atom('graph: loss[^\n]*', ToOut, To) -> true ; To = '' ),
        format("     tensorflow: ~w~n     torch:      ~w~n", [Tf, To]),
        atom_codes(TfOut, TfCs), re_lines('^identical', TfCs, IdL), length(IdL, NId),
        check('eager and graph on tensorflow, identical', NId, 1),
        ( re_first_atom('w \\[[^]]*\\]', Tf, TwRaw) -> re_replace_atom('[w ]', '', TwRaw, Tw) ; Tw = '' ),
        ( re_first_atom('w \\[[^]]*\\]', To, OwRaw) -> re_replace_atom('[w ]', '', OwRaw, Ow) ; Ow = '' ),
        ( Tw == '' -> D = inf ; sh_join([Tw, '/', Ow], Both), maxdiff(Both, D) ),
        %% two libraries' float32, two hundred steps apart: 1e-2, not the 1e-5 of one op
        ( D \== inf, D =< 1.0e-2 -> W = 'within 1e-2' ; sh_join(['off by ', D], W) ),
        check('the weights agree within 1e-2', W, 'within 1e-2'),
        shl(['rm -rf ', D1, ' ', D2])
    ;   true
    ).
