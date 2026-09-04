%% The graph path on a CUDA device: forced values living there, and a
%% recurring forward replayed as one CUDA graph -- DESIGN-lazy-graph.md, gate C.
%%
%%     cocolog -s test/torch-replay.pl        SKIPs where torch_cuda_available(false)
%%
%% WHAT IS BEING CHECKED. Under tensor_execution(torch, graph) with torch_device(cuda)
%% a leaf moves to the device the first time a deferred node reads it, and the
%% forced values stay there; consumers copy back. So every producer must answer
%% what the CPU path answers, WITHIN A TOLERANCE -- a GPU's kernels are not the
%% CPU's, and bit equality is the CPU gate's claim, not this one's. Then a
%% forward forced again and again on fresh leaves must be captured the second
%% time and replayed after that, with tensor_graph_stats/1 saying so and the
%% numbers unchanged; a closure with a parameter in it must never be captured,
%% since a replay builds no tape, and its gradients must still be right. Last,
%% tutorial 29's heavy goal runs on both devices and must agree.
%%
%% Every check IS a child, two of them: the device is a process's.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/torch.so') -> true ; skip('(no library/torch.so -- sh modules/torch/build.sh)') ),
    answer_text('query "use_module(library(torch)), torch_cuda_available(B), write(answer(B)), nl"', Cuda),
    ( Cuda == true -> true ; skip('(no CUDA device here -- this gate runs on the Colab T4)') ),
    the_device, every_producer, recurring_forward, heavy,
    checks_done.

q(Goal, Got) :- sh_join(['query "use_module(library(torch)), ', Goal, '"'], Args), answer_text(Args, Got).
gpu('tensor_execution(torch, graph), torch_device(cuda), torch_seed(11)').
cpu('tensor_execution(torch, eager), torch_device(cpu), torch_seed(11)').
%% one goal on the T4 and on the CPU; the two flat answers within Tol
near(Label, Goal, Tol) :-
    gpu(GPU), sh_join([GPU, ', ', Goal], GG), q(GG, G),
    cpu(CPU), sh_join([CPU, ', ', Goal], GC), q(GC, C),
    sh_join([G, '/', C], Both), maxdiff(Both, D),
    sh_join(['within ', Tol], Want),
    ( D \== inf, D =< Tol -> W = Want ; sh_join(['off by ', D], W) ),
    check(Label, W, Want).
leaves('tensor_new([2,3], randn, A), tensor_new([3,2], randn, B), tensor_new([2,3], randn, A2)').
flat('tensor_reshape(R, [-1], F), tensor_to_list(F, L), write(answer(L)), nl').

the_device :-
    q('torch_device(cuda), torch_current_device(D), write(answer(D)), nl', Dev),
    sh_join(['the device: ', Dev], S), section(S),
    gpu(GPU),
    sh_join([GPU, ', tensor_zeros([2,2], A), tensor_scalar(add, A, 1.5, B), tensor_to_list(B, L), write(answer(L)), nl'], G1), q(G1, R1),
    check('a forced value answers through the CPU seam', R1, '[[1.5,1.5],[1.5,1.5]]').

every_producer :-
    section('every producer, on the T4, within 1e-4 of the CPU path'),
    leaves(L), flat(F),
    forall(member(Op, [neg, abs, exp, log, sqrt, relu, sigmoid, tanh, transpose]),
           ( sh_join(['unary ', Op], Lb), sh_join([L, ', tensor_unary(', Op, ', A, R), ', F], G), near(Lb, G, 1.0e-4) )),
    forall(member(Op, [add, sub, mul, div, pow]),
           ( sh_join(['scalar ', Op], Lb), sh_join([L, ', tensor_scalar(', Op, ', A, 2.5, R), ', F], G), near(Lb, G, 1.0e-4) )),
    forall(member(Op, [add, sub, mul, div]),
           ( sh_join(['binary ', Op], Lb), sh_join([L, ', tensor_binary(', Op, ', A, A2, R), ', F], G), near(Lb, G, 1.0e-4) )),
    sh_join([L, ', tensor_binary(matmul, A, B, R), ', F], G1), near('binary matmul', G1, 1.0e-4),
    sh_join([L, ', tensor_argmax(A, 1, R), ', F], G2), near(argmax, G2, 0),
    sh_join([L, ', tensor_reshape(A, [3,2], R), ', F], G3), near(reshape, G3, 0),
    sh_join([L, ', tensor_cat([A, A2], 0, R), ', F], G4), near(cat, G4, 0),
    sh_join([L, ', tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), ', F], G5), near(index_rows, G5, 0),
    sh_join([L, ', tensor_rows(A, 1, 2, R0), tensor_cols(R0, 0, 2, R), ', F], G6), near('rows and cols', G6, 0),
    sh_join([L, ', tensor_standardise(A, 2, R), ', F], G7), near(standardise, G7, 1.0e-4),
    sh_join([L, ', tensor_scalar(mul, A, 2.0, X), tensor_unary(relu, X, Y), tensor_agg(mean, Y, R), ', F], G8), near('agg mean, through a chain', G8, 1.0e-4),
    sh_join([L, ', tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_unary(abs, X7, X8), tensor_reshape(X8, [4], R), ', F], G9),
    near('an eleven-op expression', G9, 1.0e-4).

recurring_forward :-
    section('a recurring forward: plain once, captured the second time, replayed after'),
    gpu(GPU), flat(F),
    FWD = 'tensor_randn([256, 64], X), tensor_randn([64, 16], W), tensor_binary(matmul, X, W, H), tensor_unary(relu, H, R1), tensor_scalar(mul, R1, 0.5, Q), tensor_agg(sum, Q, T), tensor_item(T, S)',
    sh_join([GPU, ', findall(S, (between(1, 6, _), ', FWD, '), _), tensor_graph_stats(stats(recorded(Rc), executed(Ex), replayed(Rp), pending(P))), write(answer(Rc-Ex-Rp-P)), nl'], G1), q(G1, R1),
    check('six forces: 4 nodes executed once, 5 replays, none pending', R1, '24-4-5-0'),
    sh_join(['findall(S, (between(1, 6, _), ', FWD, '), Ss), tensor_from_list(Ss, R), ', F], G2),
    near('and the six sums match the CPU path', G2, 0.5),
    sh_join([GPU, ', tensor_randn([8, 4], X1), tensor_scalar(mul, X1, 2.0, A1), tensor_unary(relu, A1, B1), tensor_to_list(B1, _), tensor_randn([9, 4], X2), tensor_scalar(mul, X2, 2.0, A2), tensor_unary(relu, A2, B2), tensor_to_list(B2, _), tensor_graph_stats(stats(_, executed(Ex), replayed(Rp), _)), write(answer(Ex-Rp)), nl'], G3), q(G3, R3),
    check('a different shape is a different key: no replay across it', R3, '4-0'),
    sh_join([GPU, ', tensor_randn([64, 3], X), tensor_from_list([[1.0],[-2.0],[0.5]], W0), tensor_parameter(W0, W), findall(L, (between(1, 4, _), tensor_binary(matmul, X, W, P), tensor_binary(mul, P, P, P2), tensor_agg(mean, P2, M), tensor_item(M, L), tensor_grad(M, [W], [G]), tensor_free(G)), _), tensor_graph_stats(stats(_, _, replayed(Rp), _)), write(answer(Rp)), nl'], G4), q(G4, R4),
    check('a closure with a parameter is never captured', R4, '0'),
    sh_join(['tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [G]), tensor_reshape(G, [2], R), ', F], G5),
    near('and its gradient on the device matches the CPU''s', G5, 1.0e-5).

heavy :-
    section('tutorial 29''s heavy goal, both devices'),
    sh_join(['run tutorials/tensor/29-sgd-by-hand.pl "torch_device(cpu), tensor_execution(torch, graph), heavy(20000, 32, 100)" 2>&1 | grep -a ''^heavy'''], Ca),
    cocolog_run(Ca, Cpu, _, 900000),
    get_time(T0),
    sh_join(['run tutorials/tensor/29-sgd-by-hand.pl "torch_device(cuda), tensor_execution(torch, graph), heavy(20000, 32, 100)" 2>&1 | grep -a ''^heavy'''], Ga),
    cocolog_run(Ga, Gpu, _, 900000),
    get_time(T1), Secs is round(T1 - T0),
    re_replace_atom('^heavy [0-9]* rows [0-9]* features [0-9]* steps ', '', Cpu, CpuTail),
    re_replace_atom('^heavy [0-9]* rows [0-9]* features [0-9]* steps ', '', Gpu, GpuTail),
    format("     cpu:  ~w~n     cuda: ~w  (~ws)~n", [CpuTail, GpuTail, Secs]),
    ( re_first_atom('final mse [0-9.]+', Gpu, GM) -> true ; GM = '' ),
    ( re_first_atom('final mse [0-9.]+', Cpu, CM) -> true ; CM = '' ),
    check('the heavy loop reaches the same loss on both devices', GM, CM),
    ( re_first_atom('plane\\| [0-9.]+', Gpu, GP) -> true ; GP = '' ),
    ( re_first_atom('plane\\| [0-9.]+', Cpu, CP) -> true ; CP = '' ),
    check('and the same distance from the plane', GP, CP).
