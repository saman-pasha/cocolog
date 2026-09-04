%% library(torch)'s GRAPH execution path, held to EQUALITY against eager.
%%
%%     cocolog -s test/torch-graph.pl               the predicates, and six tutorials
%%     ALL=1 cocolog -s test/torch-graph.pl         the predicates, and all 28 tutorials
%%
%% THE RULE UNDER TEST is DESIGN-lazy-graph.md's first sentence: a program
%% written for the eager path runs unchanged under tensor_execution(torch, graph) --
%% same predicates, same answers. So nearly every check here runs ONE goal
%% twice, in two fresh processes, one per mode, and demands that the two
%% answers be EQUAL, not close. That is possible because the graph path
%% forces through the very raw workers eager calls, on the same CPU, and
%% because stochastic leaves execute at record time, so `torch_seed' draws
%% the same numbers in the same order under both.
%%
%% The rest checks what eager cannot do and the graph path must: know a
%% shape without executing, raise a shape error at the same goal, skip work
%% a failed branch asked for, survive tensor_free of an input, and say all
%% of that in tensor_graph_stats/1.
%%
%% Every check IS a child, two of them: the mode is a process's.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/torch.so') -> true ; skip('(no library/torch.so -- sh modules/torch/build.sh)') ),
    answer_text('query "use_module(library(torch)), tensor_execution(M), write(answer(M)), nl"', Mode),
    ( Mode == eager -> true ; skip('(library(torch) will not load, or has no graph path)') ),
    the_switch, every_producer, without_executing, the_tutorials,
    checks_done.

u('use_module(library(torch))').

q(Goal, Got) :- u(U), sh_join(['query "', U, ', ', Goal, '"'], Args), answer_text(Args, Got).
%% the same, with the engine's variable names normalised: a goal one call
%% longer numbers its variables differently, and an error term carries them
qn(Goal, Got) :- q(Goal, Raw), re_replace_atom('_G[0-9]+', '_', Raw, Got).
%% the same goal under both modes, in two fresh processes; equal or FAIL
both(Label, Goal) :-
    sh_join(['tensor_execution(torch, eager), torch_seed(11), ', Goal], GE), q(GE, E),
    sh_join(['tensor_execution(torch, graph), torch_seed(11), ', Goal], GG), q(GG, G),
    check(Label, G, E).
%% the leaves every check below starts from
leaves('tensor_new([2,3], randn, A), tensor_new([3,2], randn, B), tensor_new([2,3], randn, A2)').

the_switch :-
    section('the switch'),
    q('tensor_execution(M), write(answer(M)), nl', G1),
    check('eager is the default', G1, eager),
    q('tensor_execution(torch, graph), tensor_execution(M), write(answer(M)), nl', G2),
    check('graph, once asked for, is what it answers', G2, graph),
    q('catch(tensor_execution(fast), error(E, _), true), write(answer(E)), nl', G3),
    check('an unknown mode is a domain error', G3, 'domain_error(tensor_execution,fast)').

every_producer :-
    section('every producer, equal to eager'),
    leaves(L),
    forall(member(Op, [neg, abs, exp, log, sqrt, relu, sigmoid, tanh, transpose]),
           ( sh_join(['unary ', Op], Lb), sh_join([L, ', tensor_unary(', Op, ', A, R), tensor_to_list(R, L), write(answer(L)), nl'], G), both(Lb, G) )),
    forall(member(Op, [add, sub, mul, div, pow]),
           ( sh_join(['scalar ', Op], Lb), sh_join([L, ', tensor_scalar(', Op, ', A, 2.5, R), tensor_to_list(R, L), write(answer(L)), nl'], G), both(Lb, G) )),
    forall(member(Op, [add, sub, mul, div]),
           ( sh_join(['binary ', Op], Lb), sh_join([L, ', tensor_binary(', Op, ', A, A2, R), tensor_to_list(R, L), write(answer(L)), nl'], G), both(Lb, G) )),
    sh_join([L, ', tensor_binary(matmul, A, B, R), tensor_to_list(R, L), write(answer(L)), nl'], G1), both('binary matmul', G1),
    sh_join([L, ', tensor_argmax(A, 1, R), tensor_to_list(R, L), write(answer(L)), nl'], G2), both(argmax, G2),
    sh_join([L, ', tensor_reshape(A, [3,2], R), tensor_to_list(R, L), write(answer(L)), nl'], G3), both(reshape, G3),
    sh_join([L, ', tensor_cat([A, A2], 0, R), tensor_to_list(R, L), write(answer(L)), nl'], G4), both(cat, G4),
    sh_join([L, ', tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), tensor_to_list(R, L), write(answer(L)), nl'], G5), both(index_rows, G5),
    sh_join([L, ', tensor_rows(A, 1, 2, R), tensor_to_list(R, L), write(answer(L)), nl'], G6), both(rows, G6),
    sh_join([L, ', tensor_cols(A, 0, 2, R), tensor_to_list(R, L), write(answer(L)), nl'], G7), both(cols, G7),
    sh_join([L, ', tensor_standardise(A, 2, R), tensor_to_list(R, L), write(answer(L)), nl'], G8), both(standardise, G8),
    both(zeros, 'tensor_zeros([2,2], R), tensor_to_list(R, L), write(answer(L)), nl'),
    both(ones, 'tensor_ones([1,3], R), tensor_to_list(R, L), write(answer(L)), nl'),
    both(full, 'tensor_full([2,2], 3.5, R), tensor_to_list(R, L), write(answer(L)), nl'),
    both(eye, 'tensor_eye(3, R), tensor_to_list(R, L), write(answer(L)), nl'),
    both(arange, 'tensor_arange(5, R), tensor_to_list(R, L), write(answer(L)), nl'),
    both('randn, rand and randperm draw in program order',
         'tensor_randn([2], A), tensor_rand([2], B), tensor_randperm(4, P), tensor_to_list(A, LA), tensor_to_list(B, LB), tensor_to_list(P, LP), write(answer(LA-LB-LP)), nl'),
    sh_join([L, ', tensor_scalar(mul, A, 2.0, X), tensor_unary(relu, X, Y), tensor_reduce(sum, Y, S), write(answer(S)), nl'], G9),
    both('reduce, sum through a deferred chain', G9),
    both('item, through a deferred chain',
         'tensor_full([1], 2.0, A), tensor_scalar(pow, A, 3.0, B), tensor_item(B, V), write(answer(V)), nl'),
    sh_join([L, ', tensor_binary(matmul, A, B, R), tensor_shape(R, S), write(answer(S)), nl'], G10),
    both('shape of a deferred result', G10),
    sh_join([L, ', tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_unary(abs, X7, X8), tensor_reshape(X8, [4], X9), tensor_reduce(mean, X9, M), tensor_to_list(X9, L), write(answer(M-L)), nl'], G11),
    both('an eleven-op expression', G11),
    both('model_train forces its data, then trains the same',
         'torch_seed(3), tensor_new([64, 3], randn, X0), tensor_scalar(mul, X0, 2.0, X), tensor_cols(X, 0, 1, Y0), tensor_scalar(add, Y0, 0.5, Y), model_new([input(3), dense(8, relu), dense(1)], M), model_train(M, X, Y, [epochs(5), batch(16), lr(0.01), final_loss(Loss)]), model_predict(M, X, P), tensor_shape(P, S), write(answer(S-Loss)), nl').

without_executing :-
    section('what the graph path knows without executing, and says'),
    G = 'tensor_execution(torch, graph)',
    sh_join([G, ', tensor_zeros([3,4], A), tensor_ones([4,5], B), tensor_binary(matmul, A, B, C), tensor_shape(C, S), tensor_graph_stats(stats(_, executed(X), _, pending(P))), write(answer(S-X-P)), nl'], G1), q(G1, R1),
    check('a shape is known with nothing executed', R1, '[3,5]-0-3'),
    sh_join([G, ', tensor_zeros([3,4], A), tensor_ones([5,6], B), catch(tensor_binary(matmul, A, B, _), error(E, _), true), write(answer(E)), nl'], G2a), qn(G2a, R2a),
    qn('tensor_zeros([3,4], A), tensor_ones([5,6], B), catch(tensor_binary(matmul, A, B, _), error(E, _), true), write(answer(E)), nl', R2b),
    check('a shape error is raised at the goal, as eager raises it', R2a, R2b),
    sh_join([G, ', tensor_zeros([2,3], A), catch(tensor_standardise(A, 5, _), error(E, _), true), write(answer(E)), nl'], G3a), qn(G3a, R3a),
    qn('tensor_zeros([2,3], A), catch(tensor_standardise(A, 5, _), error(E, _), true), write(answer(E)), nl', R3b),
    check('standardise past the rows: the same error, at the goal', R3a, R3b),
    sh_join([G, ', tensor_zeros([2,2], A), tensor_scalar(add, A, 1.0, B), tensor_unary(exp, B, C), tensor_to_list(C, _), tensor_to_list(C, _), tensor_reduce(sum, C, _), tensor_graph_stats(stats(recorded(R), executed(X), _, _)), write(answer(R-X)), nl'], G4), q(G4, R4),
    check('a second read executes nothing new', R4, '3-3'),
    sh_join([G, ', tensor_zeros([2,2], A), ( tensor_scalar(mul, A, 2.0, _), tensor_unary(exp, A, _), fail ; true ), tensor_graph_stats(stats(recorded(R), executed(X), _, pending(P))), write(answer(R-X-P)), nl'], G5), q(G5, R5),
    check('work asked for on a failed branch never happens', R5, '3-0-3'),
    sh_join([G, ', tensor_zeros([2,2], A), tensor_scalar(mul, A, 2.0, B), tensor_unary(exp, B, C), tensor_force(C), tensor_graph_stats(stats(_, executed(X), _, pending(P))), write(answer(X-P)), nl'], G6), q(G6, R6),
    check('tensor_force executes what a handle depends on', R6, '3-0'),
    both('tensor_free of an input leaves the dependant its own value',
         'tensor_zeros([2,2], A), tensor_scalar(add, A, 1.0, B), tensor_free(A), tensor_zeros([2,2], C), tensor_scalar(add, C, 5.0, D), tensor_to_list(D, _), tensor_to_list(B, L), write(answer(L)), nl'),
    both('randn leaves forced in reverse order still hold their draws',
         'tensor_randn([2], A), tensor_randn([2], B), tensor_scalar(mul, B, 1.0, B2), tensor_scalar(mul, A, 1.0, A2), tensor_to_list(B2, LB), tensor_to_list(A2, LA), write(answer(LA-LB)), nl'),
    sh_join([G, ', tensor_zeros([2], A), tensor_free(A), catch(tensor_to_list(A, _), error(E, _), true), write(answer(E)), nl'], G7a), q(G7a, R7a),
    q('tensor_zeros([2], A), tensor_free(A), catch(tensor_to_list(A, _), error(E, _), true), write(answer(E)), nl', R7b),
    check('a freed handle is not a tensor, in either mode', R7a, R7b).

the_tutorials :-
    section('the tutorials: the same program, the same printed result'),
    %% Each tutorial's `train' goal, run under eager and under graph against
    %% fresh stores, its whole stdout compared. The training loop is C++ in
    %% both modes and only the data preparation is deferred, so the outputs
    %% must be equal.
    scratch(D),
    (   getenv('ALL', '1')
    ->  directory_files('tutorials/tensor', Fs),
        findall(P, ( member(F, Fs), re_match('^[0-9].*\\.pl$', F), atom_concat('tutorials/tensor/', F, P) ), Ps),
        msort(Ps, Tuts)
    ;   %% 31 is tutorial 30 -- the one ABOUT the two paths -- again as
        %% expressions, on a CPU: 30 itself runs on a GPU or not at all. Its
        %% train runs both paths itself and refuses to save unless they agree,
        %% so under either prefix it prints the same lines
        Tuts = [ 'tutorials/tensor/01-linear-regression.pl', 'tutorials/tensor/04-sine-approximation.pl',
                 'tutorials/tensor/07-xor.pl', 'tutorials/tensor/14-autoencoder.pl',
                 'tutorials/tensor/20-save-load.pl', 'tutorials/tensor/31-tensor-expressions.pl' ]
    ),
    forall(member(Pl, Tuts), tutorial(D, Pl)),
    shl(['rm -rf ', D]).

tutorial(D, Pl) :-
    file_base_name(Pl, Base), atom_concat(Name, '.pl', Base),
    sh_join(['--kb tutorials --embed ', D, '/eager-', Name, ' run ', Pl, ' "tensor_execution(torch, eager), train" 2>&1 | tr -d ''\\r'' | tail -3 | tr ''\\n'' '' '''], Ea),
    cocolog_run(Ea, E, _, 1200000),
    sh_join(['--kb tutorials --embed ', D, '/graph-', Name, ' run ', Pl, ' "tensor_execution(torch, graph), train" 2>&1 | tr -d ''\\r'' | tail -3 | tr ''\\n'' '' '''], Ga),
    cocolog_run(Ga, G, _, 1200000),
    sh_join(['tutorial ', Name], Label),
    check(Label, G, E).

%% the file part of a path
file_base_name(Path, Base) :-
    ( sub_atom(Path, B, _, 0, After), \+ sub_atom(After, _, _, _, '/'), sub_atom(Path, _, 1, B, '/') -> Base = After ; Base = Path ).
