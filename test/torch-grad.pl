%% Autograd through library(torch), from Prolog: tensor_parameter/2,
%% tensor_agg/3, tensor_grad/3, tensor_step/4 -- DESIGN-lazy-graph.md, gate B.
%%
%%     cocolog -s test/torch-grad.pl        from the checkout root
%%
%% WHAT IS BEING CHECKED. A gradient is a number libtorch computes from a
%% tape it recorded while the loss was computed. Three things can go wrong
%% with that from Prolog, and each has a check here: the tape may not be
%% there (a loss built from deferred nodes must be FORCED before it is
%% differentiated, and forcing is what builds the tape); the number may be
%% wrong (so one gradient is held to the analytic formula, and one to a
%% hand-computable constant, exactly); and the two execution paths may
%% disagree (so every check that can run under both does, and demands
%% equality). Then thirty steps of plain SGD have to reach a known line, and
%% a step must be a NEW leaf that leaves the old parameter as it was.
%%
%% Every check IS a child, two of them where both paths run: the mode is a
%% process's.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/torch.so') -> true ; skip('(no library/torch.so -- sh modules/torch/build.sh)') ),
    answer_text('query "use_module(library(torch)), tensor_zeros([1], Z), tensor_parameter(Z, _), write(answer(ok)), nl"', Probe),
    ( Probe == ok -> true ; skip('(library(torch) has no tensor_parameter/2)') ),
    the_number, a_step, refusals, thirty_steps, the_device, exec_frees, lent_operators,
    checks_done.

q(Goal, Got) :- sh_join(['query "use_module(library(torch)), ', Goal, '"'], Args), answer_text(Args, Got).
qn(Goal, Got) :- q(Goal, Raw), re_replace_atom('_G[0-9]+', '_', Raw, Got).
both(Label, Goal) :-
    sh_join(['tensor_execution(torch, eager), torch_seed(11), ', Goal], GE), q(GE, E),
    sh_join(['tensor_execution(torch, graph), torch_seed(11), ', Goal], GG), q(GG, G),
    check(Label, G, E).
within(Label, Text, Tol) :-
    maxdiff(Text, D),
    ( D \== inf, D < Tol -> W = within ; sh_join(['off by ', D], W) ),
    check(Label, W, within).

%% least squares: d/dW mean((XW - Y)^2) = (2/N) X^T (XW - Y), computed with the same ops
lsq('tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [G]), tensor_unary(transpose, X, XT), tensor_binary(matmul, XT, D, A0), tensor_scalar(mul, A0, 0.5, A), tensor_reshape(G, [2], G1), tensor_reshape(A, [2], A1), tensor_to_list(G1, LG), tensor_to_list(A1, LA), write(answer(LG/LA)), nl').

the_number :-
    section('a gradient is a number libtorch computed, and it is the right one'),
    both('the gradient of sum(W*W) is exactly 2W',
         'tensor_from_list([1.0, -2.0, 3.5], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(LG)), nl'),
    q('tensor_from_list([1.0, -2.0, 3.5], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(LG)), nl', G1),
    check('and it is [2.0,-4.0,7.0]', G1, '[2.0,-4.0,7.0]'),
    lsq(LSQ),
    q(LSQ, L2),
    within('least squares: autograd within 1e-6 of the analytic gradient', L2, 1.0e-6),
    both('and the two execution paths agree on it exactly', LSQ),
    both('a parameter the loss never touched gets zeros',
         'tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_from_list([5.0, 5.0, 5.0], V0), tensor_parameter(V0, V), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W, V], [_, GV]), tensor_to_list(GV, LV), write(answer(LV)), nl'),
    both('two gradients of one loss are the same gradient',
         'tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_scalar(pow, W, 3.0, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G1]), tensor_grad(L, [W], [G2]), tensor_to_list(G1, L1), tensor_to_list(G2, L2), write(answer(L1-L2)), nl'),
    both('a loss read as a number first is still differentiable',
         'tensor_from_list([2.0], W0), tensor_parameter(W0, W), tensor_scalar(pow, W, 2.0, S), tensor_agg(sum, S, L), tensor_item(L, V), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(V-LG)), nl').

a_step :-
    section('a step is a new leaf; the old parameter stands'),
    both('W2 = W - lr*G, exactly, and W is untouched',
         'tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_to_list(W, LW), tensor_to_list(W2, LW2), write(answer(LW-LW2)), nl'),
    q('tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_to_list(W, LW), tensor_to_list(W2, LW2), write(answer(LW-LW2)), nl', G1),
    check('and the numbers are those', G1, '[1.0,-2.0]-[0.5,-1.0]'),
    both('the new leaf differentiates on its own',
         'tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_binary(mul, W2, W2, S2), tensor_agg(sum, S2, L2), tensor_grad(L2, [W2], [G2]), tensor_to_list(G2, LG2), write(answer(LG2)), nl').

refusals :-
    section('what is refused, and how'),
    qn('tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), catch(tensor_grad(S, [W], _), error(E, _), true), write(answer(E)), nl', G1),
    check('a loss that is not one number', G1, 'domain_error(scalar_tensor,3)'),
    qn('tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_zeros([2], Z), tensor_agg(sum, Z, L), catch(tensor_grad(L, [W], _), error(E, _), true), write(answer(E)), nl', G2),
    check('a loss no parameter reaches', G2, 'domain_error(differentiable,4)'),
    q('tensor_from_list([1.0, 2.0, 3.0, 4.0], T), findall(V, (member(Op, [sum, mean, max, min, std]), tensor_agg(Op, T, A), tensor_item(A, V)), Vs), findall(V, (member(Op, [sum, mean, max, min, std]), tensor_reduce(Op, T, V)), Rs), ( Vs == Rs -> R = same ; R = differ(Vs, Rs) ), write(answer(R)), nl', G3),
    check('tensor_agg over the same five reductions answers as tensor_reduce', G3, same).

thirty_steps :-
    section('thirty steps of SGD, written in Prolog, reach the line'),
    scratch(D),
    atom_concat(D, '/sgd.pl', F),
    fixture(F,
            [ ':- use_module(library(torch)).',
              '% x in (-1,1) from the sin-hash; y = 3 x1 - 2 x2 + 0.5 x3 + 1, no noise',
              'noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.',
              'row(I, [X1, X2, X3], [Y]) :-',
              '    noise(I, X1), J is I + 1000, noise(J, X2), K is I + 2000, noise(K, X3),',
              '    Y is 3*X1 - 2*X2 + 0.5*X3 + 1, !.',
              'data(N, X, Y) :-',
              '    N1 is N - 1,',
              '    findall(R, (between(0, N1, I), row(I, R, _)), XR),',
              '    findall(R, (between(0, N1, I), row(I, _, R)), YR),',
              '    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.',
              'step(X, Y, W, B, LR, W2, B2, Loss) :-',
              '    tensor_binary(matmul, X, W, XW), tensor_binary(add, XW, B, P),',
              '    tensor_binary(sub, P, Y, D), tensor_binary(mul, D, D, D2),',
              '    tensor_agg(mean, D2, L), tensor_item(L, Loss),',
              '    tensor_grad(L, [W, B], [GW, GB]),',
              '    tensor_step(W, GW, LR, W2), tensor_step(B, GB, LR, B2),',
              '    tensor_free(XW), tensor_free(P), tensor_free(D), tensor_free(D2),',
              '    tensor_free(L), tensor_free(GW), tensor_free(GB), tensor_free(W), tensor_free(B).',
              'sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.',
              'sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-',
              '    step(X, Y, W, B, LR, W2, B2, Loss), K1 is K - 1,',
              '    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).',
              'main(Mode) :-',
              '    tensor_execution(Mode),',
              '    data(64, X, Y),',
              '    tensor_zeros([3, 1], W0), tensor_parameter(W0, W1),',
              '    tensor_zeros([1], B0), tensor_parameter(B0, B1),',
              '    step(X, Y, W1, B1, 0.3, _, _, First),',
              '    tensor_parameter(W0, W), tensor_parameter(B0, B),',
              '    sgd(30, X, Y, W, B, 0.3, WF, BF, none, Last),',
              '    tensor_to_list(WF, LW), tensor_to_list(BF, LB),',
              '    tensor_graph_stats(S),',
              '    format("first ~6f last ~6f~n", [First, Last]),',
              '    format("w ~w b ~w~n", [LW, LB]),',
              '    ( Last < First / 20 -> write(fell), nl ; write(did_not_fall), nl ),',
              '    LW = [[W1v], [W2v], [W3v]], LB = [Bv],',
              '    ( abs(W1v - 3) < 0.15, abs(W2v + 2) < 0.15, abs(W3v - 0.5) < 0.15, abs(Bv - 1) < 0.15',
              '    -> write(near_the_line), nl ; write(far_from_the_line), nl ),',
              '    write(S), nl.' ]),
    sh_join(['run ', F, ' "main(eager)" 2>&1 | tr -d ''\\r'''], Ea), cocolog_run(Ea, E, _, 300000),
    sh_join(['run ', F, ' "main(graph)" 2>&1 | tr -d ''\\r'''], Ga), cocolog_run(Ga, G, _, 300000),
    first_matching('fell|did_not_fall', E, Fell),
    check('the loss fell by twenty times or more', Fell, fell),
    first_matching('[a-z_]*the_line', E, Line),
    check('and the weights are within 0.15 of 3, -2, 0.5 and 1', Line, near_the_line),
    without_stats(G, Gs), without_stats(E, Es),
    check('thirty steps under graph print the same as under eager', Gs, Es),
    (   re_first_atom('stats\\(recorded\\([0-9]+\\),executed\\([0-9]+\\),replayed\\([0-9]+\\),pending\\([0-9]+\\)\\)', G, Stats),
        re_replace_atom('[^0-9]+', ',', Stats, Digits),
        numbers_of(Digits, [Rec, Ex, _, Pend])
    ->  ( Rec =:= Ex, Pend =:= 0 -> V = 'all executed, none pending' ; sh_join(['recorded ', Rec, ' executed ', Ex, ' pending ', Pend], V) )
    ;   V = 'no stats line'
    ),
    check('and the graph path recorded and executed every node, none pending', V, 'all executed, none pending'),
    shl(['rm -rf ', D]).

%% grep -m1 -oE: the first match of a pattern in a text, or ''
first_matching(Pat, Text, M) :- ( re_first_atom(Pat, Text, M) -> true ; M = '' ).
%% grep -v '^stats': the lines that do not start with stats, rejoined
without_stats(Text, Out) :-
    atom_codes(Text, Cs), codes_lines(Cs, Ls),
    findall(L, ( member(L, Ls), \+ ( L = [0's, 0't, 0'a, 0't, 0's|_] ) ), Kept),
    codes_lines(OutCs, Kept), atom_codes(Out, OutCs).

the_device :-
    section('the device, third: auto, whichever this machine has, and a parameter read twice'),
    %% `auto' is cuda:0 where there is a card and cpu elsewhere. A parameter
    %% the loss reads TWICE must stay one leaf across both reads, under either
    %% path -- on a T4 it did not: `cuda' with no index compared unequal to
    %% `cuda:0' and every touch re-made the parameter, so the gradient reached
    %% nothing and thirty tutorials trained to chance without an error. Here
    %% the gradient of sum(W*W) + sum(W) at W = [1, 2] is 2W + 1, both paths.
    q('tensor_execution(torch, eager, auto), tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, A), tensor_agg(sum, W, B), tensor_binary(add, A, B, L), tensor_grad(L, [W], [G]), tensor_to_list(G, GL), write(answer(GL)), nl', G1),
    check('sum(W*W) + sum(W) differentiates to 2W + 1 under eager auto', G1, '[3.0,5.0]'),
    q('tensor_execution(torch, graph, auto), tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, A), tensor_agg(sum, W, B), tensor_binary(add, A, B, L), tensor_grad(L, [W], [G]), tensor_to_list(G, GL), write(answer(GL)), nl', G2),
    check('and under graph auto', G2, '[3.0,5.0]'),
    %% a value made BEFORE the switch follows it: the other library does this
    %% on its own, and the graph path always did at force; eager places at
    %% the read
    q('tensor_execution(torch, eager, cpu), tensor_from_list([[1.0, 2.0]], X), tensor_execution(torch, eager, auto), tensor_from_list([[1.0], [1.0]], Y), tensor_binary(matmul, X, Y, Z), tensor_to_list(Z, ZL), write(answer(ZL)), nl', G3),
    check('a tensor made under cpu is read by an op under eager auto', G3, '[[3.0]]'),
    scratch(D),
    sh_join(['--kb tutorials --embed ', D, ' run tutorials/tensor/31-tensor-expressions.pl "tensor_execution(torch, graph, auto), train" 2>&1 | grep -ac ''^identical'''], A4),
    cocolog_run(A4, G4, _, 300000),
    shl(['rm -rf ', D]),
    check('and its eager and graph fits of tutorial 31 agree under auto', G4, '1').

exec_frees :-
    section('exec/1 frees what a procedure made, even when an input is the same integer'),
    %% Handles start at 1 and a freed slot is reused, so in a fresh process
    %% the first tensor a procedure makes IS handle 1 -- and `exec(p(1))',
    %% with the 1 a count, once read that 1 as a handle to keep: a tensor
    %% kept alive by a hyperparameter that happened to equal its number. Only
    %% the head's outputs can carry a handle the call made; an input never
    %% can, and is not searched. The rules are asserted as their translated
    %% clauses, `V = E' being =//2.
    TE = 'use_module(library(tensor_expr)), assertz((te_gate_count(N, S0, S) :- ''=''(_, zeros([N]), S0, S))), assertz((te_gate_return(N, T, S0, S) :- ''=''(T, zeros([N]), S0, S)))',
    sh_join([TE, ', exec(te_gate_count(1)), ( catch(tensor_shape(1, _), _, fail) -> A = kept ; A = freed ), write(answer(A)), nl'], G1a), q(G1a, G1),
    check('a count of 1 in the head does not keep handle 1 alive', G1, freed),
    sh_join([TE, ', exec(te_gate_return(1, H)), tensor_shape(H, Sh), write(answer(H-Sh)), nl'], G2a), q(G2a, G2),
    check('and handle 1 returned through the head is kept, with its shape', G2, '1-[1]').

lent_operators :-
    section('use_module lends the library''s operators to the file that names it'),
    %% The operator table is the process's, and a library's `:- op' reached a
    %% file only when the library's clauses were consulted -- at the first
    %% goal, after the file had been read whole -- so every tensor program
    %% opened with the library's three declarations copied out. The load
    %% applies them as the directive runs now. This file writes `:=' and
    %% `matmul' with no op/3 of its own, and is consulted by `run', which is
    %% how a program is read.
    scratch(D),
    atom_concat(D, '/lent.pl', F),
    fixture(F, [ ':- use_module(library(torch)).',
                 ':- use_module(library(tensor_expr)).',
                 'lent(L) :- X := [[1.0, 2.0]] matmul [[3.0], [4.0]], L := list(X).' ]),
    sh_join(['--local run ', F, ' "lent(L), write(answer(L)), nl"'], A),
    answer_text(A, G),
    shl(['rm -rf ', D]),
    check('a file with no op/3 of its own reads := and matmul after use_module', G, '[[11.0]]').
