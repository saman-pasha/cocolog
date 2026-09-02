%% library(tensor_expr) -- tensor expressions over library(torch)
%%
%% An expression names a tensor; a DCG, expr//2, turns it into the LIST OF
%% TENSOR GOALS it stands for, one per node in dependency order with fresh
%% variables for the results, and `:=' runs that list and frees every result
%% but the last. The list is the same under torch_execution(eager) and
%% torch_execution(graph): eager computes each goal as it runs, graph records
%% a node and computes at the first read, and the grammar cannot tell which.
%%
%%     L := mean((X matmul W + B - Y) ^ 2.0)
%%
%% THE OPERATORS ARE DECLARED WHERE THEY ARE READ. cocolog's reader applies
%% op/3 to the file it is reading, so a file that writes expressions declares
%% the two it needs itself, before its first clause:
%%
%%     :- op(700, xfx, :=).
%%     :- op(400, yfx, matmul).
%%
%% and any of the prefix ones it likes (`:- op(200, fy, relu).' lets it write
%% `relu X'); the functional forms `relu(X)', `mean(X)' need no declaration.
%%
%% THE FORMS.  A FLOAT IS A NUMBER, AN INTEGER IS A HANDLE (a handle is one).
%%
%%   X matmul W             tensor_binary(matmul)     A + B  A - B  A * B  A / B   tensor_binary
%%   A + 1.5   A ^ 2.0      tensor_scalar             1.5 - A  2.0 / A  go through neg, pow -1.0
%%   - A  relu(A) sigmoid(A) tanh(A) exp(A) log(A) sqrt(A) abs(A) transpose(A)     tensor_unary
%%   mean(A) sum(A) max(A) min(A) std(A)     tensor_agg: a one-element TENSOR, so it differentiates
%%   [[1.0],[2.0]]  zeros(S) ones(S) randn(S) rand(S) full(S, V) eye(N) arange(N) randperm(N) csv(Path)  leaves
%%   reshape(A, S) cat([A, B], Dim) argmax(A, Dim) rows(A, F, T) cols(A, F, T) standardise(A, N) index_rows(A, I)
%%   parameter(A)           a fresh leaf that requires gradient, with A's values
%%   step(W, G, LR)         W - LR*G as a NEW leaf -- a function, not a `-': a step makes a parameter, not a node
%%   glorot(R, C)           randn([R, C]) scaled by sqrt(2/(R+C)); wrap it in parameter(...)
%%
%% AND THE COMPOSITES, each a helper goal that reads the shapes it needs when it runs:
%%
%%   softmax(A) log_softmax(A)     row-wise, over the last dimension
%%   layer_norm(A)                 row-wise, no affine; write `layer_norm(A) * G + B' for one
%%   gelu(A)                       the tanh approximation
%%   row_sum(A) row_mean(A)        [N, D] -> [N, 1]
%%   mean_rows(A, L)               [N*L, D] -> [N, D]: every L consecutive rows averaged into one
%%   conv2d(A, K, Shifts)          A is [N*H*W, Cin] PIXELS AS ROWS, channels last; K is [9*Cin, Cout], the
%%                                 nine 3x3 taps stacked; Shifts from shifts(H, W, Shifts). Zero padding, same size.
%%   pool2(A, P)  up2(A, U)        2x2 average pooling and nearest upsampling, with pool_matrix/3 and up_matrix/3
%%   cross_entropy(Logits, OneHot) bce(P, Y)  mse(P, Y)     each a one-element tensor, the mean over rows
%%
%% AND THE ANSWERS -- the forms that ask about a tensor rather than make one.
%% They stand OUTERMOST on the right of `:=', and what they answer is a
%% Prolog term, never freed: answer//2 is their grammar, beside expr//2.
%%
%%   L := list(E)              tensor_to_list        V := item(E)          tensor_item
%%   S := shape(E)             tensor_shape          V := reduce(mean, E)  tensor_reduce: sum mean max min std, a NUMBER
%%   Gs := grad(E, Ps)         tensor_grad: Ps a list of parameter handles, Gs one gradient each
%%   Tr-Te := split(E, N)      tensor_train_test     T := force(E)         tensor_force, and the handle
%%   S := stats                tensor_graph_stats
%%
%% Freeing is the one thing left as a goal: tensor_free/1 and free_all/1 for
%% the handles a program NAMED; the intermediates inside an expression are
%% freed by `:=' itself.
%%
%% THE PREDICATES: sgd_step/4, adam_init/2,3, adam_step/6, params_save/2,
%% params_load/2, one_hot/3, block_mask/3, causal_mask/3, shifts/3,
%% pool_matrix/3, up_matrix/3, accuracy/3, free_all/1 -- documented at each.

:- use_module(library(torch)).

:- op(700, xfx, :=).
:- op(400, yfx, matmul).
:- op(200, fy, relu).
:- op(200, fy, sigmoid).
:- op(200, fy, tanh).
:- op(200, fy, exp).
:- op(200, fy, log).
:- op(200, fy, sqrt).
:- op(200, fy, abs).
:- op(200, fy, transpose).
:- op(200, fy, mean).
:- op(200, fy, sum).
:- op(200, fy, max).
:- op(200, fy, min).
:- op(200, fy, std).

%% ---- the grammar -------------------------------------------------------------
%% At grammar time a compound's result is still a VARIABLE -- its goal has not
%% run -- so the one test made here is float or not: a float is a number, and
%% anything else on a tensor's side of an operator is a tensor.

expr(V, _) --> { var(V) }, !, { throw(error(instantiation_error, tensor_expression)) }.
expr(T, T) --> { integer(T) }, !.
expr(N, N) --> { float(N) }, !.
expr(L, T) --> { is_list(L) }, !, [tensor_from_list(L, T)].
expr(A matmul B, T) --> !, expr(A, TA), expr(B, TB),
    { '$te_tensor_only'(A matmul B, TA), '$te_tensor_only'(A matmul B, TB) },
    [tensor_binary(matmul, TA, TB, T)].
expr(A + B, T) --> !, '$te_binary'(add, A, B, T).
expr(A - B, T) --> !, '$te_binary'(sub, A, B, T).
expr(A * B, T) --> !, '$te_binary'(mul, A, B, T).
expr(A / B, T) --> !, '$te_binary'(div, A, B, T).
expr(A ^ B, T) --> !, '$te_binary'(pow, A, B, T).
expr(- A, T)         --> !, '$te_unary'(neg, A, T).
expr(relu A, T)      --> !, '$te_unary'(relu, A, T).
expr(sigmoid A, T)   --> !, '$te_unary'(sigmoid, A, T).
expr(tanh A, T)      --> !, '$te_unary'(tanh, A, T).
expr(exp A, T)       --> !, '$te_unary'(exp, A, T).
expr(log A, T)       --> !, '$te_unary'(log, A, T).
expr(sqrt A, T)      --> !, '$te_unary'(sqrt, A, T).
expr(abs A, T)       --> !, '$te_unary'(abs, A, T).
expr(transpose A, T) --> !, '$te_unary'(transpose, A, T).
expr(mean A, T) --> !, '$te_agg'(mean, A, T).
expr(sum A, T)  --> !, '$te_agg'(sum, A, T).
expr(max A, T)  --> !, '$te_agg'(max, A, T).
expr(min A, T)  --> !, '$te_agg'(min, A, T).
expr(std A, T)  --> !, '$te_agg'(std, A, T).
expr(zeros(S), T)   --> !, [tensor_new(S, zeros, T)].
expr(ones(S), T)    --> !, [tensor_new(S, ones, T)].
expr(randn(S), T)   --> !, [tensor_new(S, randn, T)].
expr(rand(S), T)    --> !, [tensor_new(S, rand, T)].
expr(eye(N), T)     --> !, [tensor_eye(N, T)].
expr(arange(N), T)  --> !, [tensor_arange(N, T)].
expr(randperm(N), T) --> !, [tensor_randperm(N, T)].
expr(csv(Path), T)   --> !, [tensor_load_csv(Path, T)].
expr(full(S, V), T) --> !, [tensor_full(S, V, T)].
expr(glorot(R, C), T) --> !, { S is sqrt(2.0 / (R + C)) }, [tensor_new([R, C], randn, T0), tensor_scalar(mul, T0, S, T)].
expr(reshape(A, S), T)     --> !, expr(A, TA), [tensor_reshape(TA, S, T)].
expr(argmax(A, Dim), T)    --> !, expr(A, TA), [tensor_argmax(TA, Dim, T)].
expr(rows(A, From, To), T) --> !, expr(A, TA), [tensor_rows(TA, From, To, T)].
expr(cols(A, From, To), T) --> !, expr(A, TA), [tensor_cols(TA, From, To, T)].
expr(standardise(A, N), T) --> !, expr(A, TA), [tensor_standardise(TA, N, T)].
expr(index_rows(A, I), T)  --> !, expr(A, TA), expr(I, TI), [tensor_index_rows(TA, TI, T)].
expr(cat(Es, Dim), T)      --> !, '$te_exprs'(Es, Ts), [tensor_cat(Ts, Dim, T)].
expr(parameter(A), T)      --> !, expr(A, TA), [tensor_parameter(TA, T)].
expr(step(W, G, LR), T)    --> !, expr(W, TW), expr(G, TG), [tensor_step(TW, TG, LR, T)].
expr(softmax(A), T)        --> !, expr(A, TA), ['$te_softmax'(TA, T)].
expr(log_softmax(A), T)    --> !, expr(A, TA), ['$te_log_softmax'(TA, T)].
expr(layer_norm(A), T)     --> !, expr(A, TA), ['$te_layer_norm'(TA, T)].
expr(gelu(A), T)           --> !, expr(A, TA), ['$te_gelu'(TA, T)].
expr(row_sum(A), T)        --> !, expr(A, TA), ['$te_row_sum'(TA, T)].
expr(row_mean(A), T)       --> !, expr(A, TA), ['$te_row_mean'(TA, T)].
expr(mean_rows(A, L), T)   --> !, expr(A, TA), ['$te_mean_rows'(TA, L, T)].
expr(conv2d(A, K, Sh), T)  --> !, expr(A, TA), expr(K, TK), ['$te_conv2d'(TA, TK, Sh, T)].
expr(pool2(A, P), T)       --> !, expr(A, TA), ['$te_pixels'(TA, P, T)].
expr(up2(A, U), T)         --> !, expr(A, TA), ['$te_pixels'(TA, U, T)].
expr(cross_entropy(A, Y), T) --> !, expr(A, TA), expr(Y, TY), ['$te_cross_entropy'(TA, TY, T)].
expr(bce(A, Y), T)         --> !, expr(A, TA), expr(Y, TY), ['$te_bce'(TA, TY, T)].
expr(mse(A, Y), T)         --> !, expr(A, TA), expr(Y, TY), ['$te_mse'(TA, TY, T)].
expr(E, _) --> { throw(error(domain_error(tensor_expression, E), tensor_expression)) }.

'$te_exprs'([], []) --> [].
'$te_exprs'([E|Es], [T|Ts]) --> expr(E, T), '$te_exprs'(Es, Ts).

%% A number meeting a tensor is tensor_scalar; two numbers are arithmetic;
%% two tensors are tensor_binary. A number on the LEFT of `-' or `/' has no
%% tensor_scalar shape, so it goes through neg, or through pow -1.0.
'$te_binary'(Op, A, B, T) --> expr(A, TA), expr(B, TB), '$te_combine'(Op, TA, TB, T).
'$te_combine'(Op, A, B, T) --> { float(A), float(B) }, !, { '$te_arith'(Op, A, B, T) }.
'$te_combine'(Op, A, B, T) --> { float(B) }, !, [tensor_scalar(Op, A, B, T)].
'$te_combine'(Op, A, B, T) --> { float(A) }, !, '$te_scalar_left'(Op, A, B, T).
'$te_combine'(Op, A, B, T) --> [tensor_binary(Op, A, B, T)].
'$te_scalar_left'(add, A, B, T) --> !, [tensor_scalar(add, B, A, T)].
'$te_scalar_left'(mul, A, B, T) --> !, [tensor_scalar(mul, B, A, T)].
'$te_scalar_left'(sub, A, B, T) --> !, [tensor_unary(neg, B, N), tensor_scalar(add, N, A, T)].
'$te_scalar_left'(div, A, B, T) --> !, [tensor_scalar(pow, B, -1.0, R), tensor_scalar(mul, R, A, T)].
'$te_scalar_left'(pow, A, B, _) --> { throw(error(domain_error(tensor_expression, A ^ B), tensor_expression)) }.
'$te_unary'(Op, A, T) --> expr(A, TA), { '$te_tensor_only'(Op, TA) }, [tensor_unary(Op, TA, T)].
'$te_agg'(Op, A, T)   --> expr(A, TA), { '$te_tensor_only'(Op, TA) }, [tensor_agg(Op, TA, T)].
'$te_tensor_only'(E, X) :-
    ( float(X) -> throw(error(domain_error(tensor_expression, E), tensor_expression)) ; true ).
'$te_arith'(add, A, B, C) :- C is A + B.
'$te_arith'(sub, A, B, C) :- C is A - B.
'$te_arith'(mul, A, B, C) :- C is A * B.
'$te_arith'(div, A, B, C) :- C is A / B.
'$te_arith'(pow, A, B, C) :- C is A ** B.

%% ---- the answers: what asks about a tensor ------------------------------------
%% answer(+Form, -Answer)//: the outermost form of a `:=' whose right side
%% asks rather than makes. The tensor it asks about is an expression, run
%% first; the answer is a term, and the driver leaves it alone.

answer(list(A), L)         --> expr(A, TA), [tensor_to_list(TA, L)].
answer(item(A), V)         --> expr(A, TA), [tensor_item(TA, V)].
answer(shape(A), S)        --> expr(A, TA), [tensor_shape(TA, S)].
answer(reduce(Op, A), V)   --> expr(A, TA), [tensor_reduce(Op, TA, V)].
answer(grad(A, Ps), Gs)    --> expr(A, TA), [tensor_grad(TA, Ps, Gs)].
answer(split(A, N), Tr-Te) --> expr(A, TA), [tensor_train_test(TA, N, Tr, Te)].
answer(force(A), T)        --> expr(A, T), [tensor_force(T)].
answer(stats, S)           --> [tensor_graph_stats(S)].

'$te_answer_goal'(tensor_to_list). '$te_answer_goal'(tensor_item). '$te_answer_goal'(tensor_shape).
'$te_answer_goal'(tensor_reduce).  '$te_answer_goal'(tensor_grad). '$te_answer_goal'(tensor_train_test).
'$te_answer_goal'(tensor_force).   '$te_answer_goal'(tensor_graph_stats).

%% ---- the driver ----------------------------------------------------------------
%% T := Expr: make the tensor Expr names -- or, when Expr is an answer form,
%% answer it -- and free every intermediate. Every goal the grammar emits
%% ends in its result, which is how the driver knows what it made; a handle
%% that came IN is never freed, and neither is an answer.

T := Expr :-
    ( '$te_answer_form'(Expr) -> phrase(answer(Expr, T), Goals) ; phrase(expr(Expr, T), Goals) ), !,
    '$te_run'(Goals),
    forall(( member(G, Goals), G =.. [F|Args], \+ '$te_answer_goal'(F),
             append(_, [R], Args), integer(R), R \== T ),
           tensor_free(R)).
'$te_answer_form'(E) :- nonvar(E), ( E = stats -> true ; E =.. [F|_], memberchk(F, [list, item, shape, reduce, grad, split, force]) ).


'$te_run'([]).
'$te_run'([G|Gs]) :- call(G), '$te_run'(Gs).

%% free_all(+Handles): tensor_free each; a list of parameters, gradients, or
%% anything else the program is done naming.
free_all([]).
free_all([H|Hs]) :- tensor_free(H), free_all(Hs).

%% ---- the composites --------------------------------------------------------------
%% Each reads the shape it needs when it runs -- free under the graph path,
%% where a recorded node knows its shape -- and frees its own intermediates.

'$te_last_dim'(X, D) :- tensor_shape(X, Sh), append(_, [D], Sh).

'$te_row_sum'(X, T) :- '$te_last_dim'(X, D), T := X matmul ones([D, 1]).
'$te_row_mean'(X, T) :- '$te_last_dim'(X, D), Inv is 1.0 / D, T := X matmul full([D, 1], Inv).

%% softmax over the last dimension. The shift is the tensor's largest value --
%% every row moves by the same constant, which softmax cannot see, and it
%% keeps exp from overflowing.
'$te_softmax'(X, T) :-
    '$te_last_dim'(X, D),
    M := max(X), E := exp(X - M), S := E matmul ones([D, 1]),
    T := E / S,
    free_all([M, E, S]).
'$te_log_softmax'(X, T) :-
    '$te_last_dim'(X, D),
    M := max(X), Z := X - M, S := log(exp(Z) matmul ones([D, 1])),
    T := Z - S,
    free_all([M, Z, S]).
'$te_layer_norm'(X, T) :-
    '$te_last_dim'(X, D), Inv is 1.0 / D,
    Mu := X matmul full([D, 1], Inv), C := X - Mu,
    V := (C ^ 2.0) matmul full([D, 1], Inv),
    T := C / sqrt(V + 1.0e-5),
    free_all([Mu, C, V]).
'$te_gelu'(X, T) :-
    T := X * 0.5 * (1.0 + tanh((X + (X ^ 3.0) * 0.044715) * 0.7978845608)).

%% mean_rows: [N*L, D] -> [N, D]. Through the transpose: [D, N*L] reshaped to
%% [D*N, L] averages each group of L along its row.
'$te_mean_rows'(X, L, T) :-
    tensor_shape(X, [NL, D]), N is NL // L, DN is D * N, Inv is 1.0 / L,
    T := transpose(reshape(reshape(transpose(X), [DN, L]) matmul full([L, 1], Inv), [D, N])).

%% conv2d, pixels as rows. For each of the nine taps: move the pixel axis into
%% the rows ([Cin*N, H*W]), shift it with the tap's [H*W, H*W] 0/1 matrix, move
%% it back, and multiply by the tap's [Cin, Cout] slice of the kernel; the nine
%% products are summed. Zero padding is a row of the shift matrix with no 1.
'$te_conv2d'(X, K, Shifts, T) :-
    tensor_shape(X, [NHW, Cin]), Shifts = [S0|_], tensor_shape(S0, [HW, _]),
    N is NHW // HW, CN is Cin * N,
    Xr := reshape(transpose(X), [CN, HW]),
    '$te_taps'(Shifts, 0, Xr, K, Cin, NHW, none, T),
    tensor_free(Xr).
'$te_taps'([], _, _, _, _, _, Acc, Acc).
'$te_taps'([S|Ss], I, Xr, K, Cin, NHW, Acc, T) :-
    F is I * Cin, To is F + Cin,
    Y := transpose(reshape(Xr matmul S, [Cin, NHW])) matmul rows(K, F, To),
    ( Acc == none -> Acc2 = Y ; Acc2 := Acc + Y, free_all([Acc, Y]) ),
    I1 is I + 1,
    '$te_taps'(Ss, I1, Xr, K, Cin, NHW, Acc2, T).

%% pool2 and up2 are the same move with a [H*W, H*W/4] or [H*W/4, H*W] matrix.
'$te_pixels'(X, P, T) :-
    tensor_shape(X, [NHW, C]), tensor_shape(P, [HW, HW2]),
    N is NHW // HW, CN is C * N, NHW2 is N * HW2,
    T := transpose(reshape(reshape(transpose(X), [CN, HW]) matmul P, [C, NHW2])).

'$te_cross_entropy'(Logits, OneHot, T) :-
    tensor_shape(Logits, [N|_]), NegInv is -1.0 / N,
    T := sum(OneHot * log_softmax(Logits)) * NegInv.
'$te_bce'(P, Y, T) :-
    T := - mean(Y * log(P + 1.0e-7) + (1.0 - Y) * log(1.0 - P + 1.0e-7)).
'$te_mse'(P, Y, T) :-
    T := mean((P - Y) ^ 2.0).

%% ---- the constants a program builds once and passes -----------------------------

%% shifts(+H, +W, -Shifts): the nine [H*W, H*W] tap matrices for a 3x3
%% convolution over an H by W picture, in row-major tap order (dy, dx) from
%% (-1, -1) to (1, 1). S[q, p] is 1 when output pixel p reads input pixel q.
shifts(H, W, Shifts) :-
    findall(S, ( member(DY, [-1, 0, 1]), member(DX, [-1, 0, 1]),
                 '$te_shift'(H, W, DY, DX, S) ), Shifts).
'$te_shift'(H, W, DY, DX, S) :-
    HW is H * W, HW1 is HW - 1,
    findall(Row, ( between(0, HW1, Q), QY is Q // W, QX is Q mod W,
                   findall(V, ( between(0, HW1, P), PY is P // W, PX is P mod W,
                                ( QY =:= PY + DY, QX =:= PX + DX -> V = 1.0 ; V = 0.0 ) ), Row) ), Rows),
    tensor_from_list(Rows, S).

%% pool_matrix(+H, +W, -P): [H*W, H*W/4], each 2x2 block averaged into one
%% pixel of the half-size picture; up_matrix(+H, +W, -U): [H*W/4, H*W], the
%% inverse move, each small pixel copied into its four. H and W are even.
pool_matrix(H, W, P) :-
    HW is H * W, HW1 is HW - 1, W2 is W // 2, HW4 is HW // 4, HW41 is HW4 - 1,
    findall(Row, ( between(0, HW1, Q), QY is Q // W, QX is Q mod W, B is (QY // 2) * W2 + QX // 2,
                   findall(V, ( between(0, HW41, C), ( C =:= B -> V = 0.25 ; V = 0.0 ) ), Row) ), Rows),
    tensor_from_list(Rows, P).
up_matrix(H, W, U) :-
    HW is H * W, HW1 is HW - 1, W2 is W // 2, HW4 is HW // 4, HW41 is HW4 - 1,
    findall(Row, ( between(0, HW41, C), CY is C // W2, CX is C mod W2,
                   findall(V, ( between(0, HW1, Q), QY is Q // W, QX is Q mod W,
                                ( QY // 2 =:= CY, QX // 2 =:= CX -> V = 1.0 ; V = 0.0 ) ), Row) ), Rows),
    tensor_from_list(Rows, U).

%% block_mask(+N, +L, -M): [N*L, N*L] of 0.0 where two positions belong to the
%% same sequence and -1.0e9 elsewhere, added to attention scores before the
%% softmax so a batch of N sequences of L attends within itself.
%% causal_mask(+N, +L, -M): the same, and a position sees only itself and
%% what came before it.
block_mask(N, L, M) :- '$te_mask'(N, L, false, M).
causal_mask(N, L, M) :- '$te_mask'(N, L, true, M).
'$te_mask'(N, L, Causal, M) :-
    NL is N * L, NL1 is NL - 1,
    findall(Row, ( between(0, NL1, I), IS is I // L,
                   findall(V, ( between(0, NL1, J), JS is J // L,
                                ( IS =:= JS, ( Causal == false ; J =< I ) -> V = 0.0 ; V = -1.0e9 ) ), Row) ), Rows),
    tensor_from_list(Rows, M).

%% one_hot(+Ids, +K, -T): a list of N class numbers in [0, K) as an [N, K]
%% tensor of 0.0 and 1.0 -- what cross_entropy/2 wants beside the logits.
one_hot(Ids, K, T) :-
    K1 is K - 1,
    findall(Row, ( member(Id, Ids), findall(V, ( between(0, K1, C), ( C =:= Id -> V = 1.0 ; V = 0.0 ) ), Row) ), Rows),
    tensor_from_list(Rows, T).

%% accuracy(+Logits, +Ids, -Acc): the fraction of rows whose argmax is the id.
accuracy(Logits, Ids, Acc) :-
    tensor_argmax(Logits, 1, A), tensor_to_list(A, Got), tensor_free(A),
    length(Ids, N),
    findall(x, ( nth0(I, Ids, Id), nth0(I, Got, G), round(G) =:= Id ), Hits), length(Hits, H),
    Acc is H / N.

%% ---- the optimisers ---------------------------------------------------------
%% Nothing is mutated: a step answers NEW parameters, and the old ones and
%% the gradients are freed here, so a loop threads the lists.

%% sgd_step(+Ps, +Gs, +LR, -Ps2)
sgd_step([], [], _, []).
sgd_step([P|Ps], [G|Gs], LR, [P2|Ps2]) :-
    P2 := step(P, G, LR), free_all([P, G]),
    sgd_step(Ps, Gs, LR, Ps2).

%% adam_init(+Ps, -State) and adam_step(+Ps, +Gs, +State, +LR, -Ps2, -State2):
%% Adam with beta1 0.9, beta2 0.999, eps 1e-8 and the bias correction folded
%% into the step size. State is adam(T, Ms, Vs, Beta1), the moments as
%% tensors; adam_init(+Ps, +Options, -State) takes [beta1(B)] -- 0.5 is
%% what a GAN wants, so the direction forgets faster than the scale does.
adam_init(Ps, State) :- adam_init(Ps, [], State).
adam_init(Ps, Options, adam(0, Ms, Vs, B1)) :-
    ( member(beta1(B1), Options) -> true ; B1 = 0.9 ),
    findall(M-V, ( member(P, Ps), tensor_shape(P, S), M := zeros(S), V := zeros(S) ), Pairs),
    '$te_unzip'(Pairs, Ms, Vs).
'$te_unzip'([], [], []).
'$te_unzip'([M-V|R], [M|Ms], [V|Vs]) :- '$te_unzip'(R, Ms, Vs).
adam_step(Ps, Gs, adam(T, Ms, Vs, B1), LR, Ps2, adam(T1, Ms2, Vs2, B1)) :-
    T1 is T + 1,
    LRt is LR * sqrt(1.0 - 0.999 ** T1) / (1.0 - B1 ** T1),
    '$te_adam'(Ps, Gs, Ms, Vs, LRt, B1, Ps2, Ms2, Vs2).
'$te_adam'([], [], [], [], _, _, [], [], []).
'$te_adam'([P|Ps], [G|Gs], [M|Ms], [V|Vs], LRt, B1, [P2|Ps2], [M2|Ms2], [V2|Vs2]) :-
    OneMinus is 1.0 - B1,
    M2 := M * B1 + G * OneMinus,
    V2 := V * 0.999 + (G ^ 2.0) * 0.001,
    D := M2 / (sqrt(V2) + 1.0e-8),
    P2 := step(P, D, LRt),
    free_all([P, G, M, V, D]),
    '$te_adam'(Ps, Gs, Ms, Vs, LRt, B1, Ps2, Ms2, Vs2).

%% ---- the store ------------------------------------------------------------------
%% params_save(+Name, +Ps) asserts every tensor in Ps as its shape and its
%% values, in chunks of 120 numbers, under Name; params_load(+Name, -Ps)
%% reads them back as PARAMETERS, in order. The facts live in the knowledge
%% base like any other, so a model trained by one process is loaded by the
%% next -- what model_save/model_load do for a model_new model.
:- dynamic '$te_param'/3.
:- dynamic '$te_chunk'/4.
params_save(Name, Ps) :-
    '$te_forget'(Name),
    '$te_save'(Ps, Name, 0).
'$te_forget'(Name) :-
    ( retract('$te_param'(Name, _, _)) -> '$te_forget'(Name) ; true ),
    ( retract('$te_chunk'(Name, _, _, _)) -> '$te_forget'(Name) ; true ).
'$te_save'([], _, _).
'$te_save'([P|Ps], Name, I) :-
    tensor_shape(P, Shape), tensor_to_list(P, L), flatten(L, Flat),
    assertz('$te_param'(Name, I, Shape)),
    '$te_chunks'(Flat, Name, I, 0),
    I1 is I + 1,
    '$te_save'(Ps, Name, I1).
'$te_chunks'([], _, _, _) :- !.
'$te_chunks'(Flat, Name, I, Seq) :-
    '$te_take'(Flat, 120, Chunk, Rest),
    assertz('$te_chunk'(Name, I, Seq, Chunk)),
    Seq1 is Seq + 1,
    '$te_chunks'(Rest, Name, I, Seq1).
'$te_take'(Xs, 0, [], Xs) :- !.
'$te_take'([], _, [], []) :- !.
'$te_take'([X|Xs], N, [X|Cs], Rest) :- N1 is N - 1, '$te_take'(Xs, N1, Cs, Rest).
params_load(Name, Ps) :-
    findall(I-Shape, '$te_param'(Name, I, Shape), Pairs0), msort(Pairs0, Pairs),
    ( Pairs == [] -> throw(error(existence_error(params, Name), params_load/2)) ; true ),
    findall(P, ( member(I-Shape, Pairs),
                 findall(Seq-Chunk, '$te_chunk'(Name, I, Seq, Chunk), Cs0), msort(Cs0, Cs),
                 findall(X, ( member(_-Chunk, Cs), member(X, Chunk) ), Flat),
                 tensor_from_list(Flat, T0), P := parameter(reshape(T0, Shape)), tensor_free(T0) ), Ps).
