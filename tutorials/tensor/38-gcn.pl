%% 38. A graph convolutional network: the karate club, two labels, all thirty-four answers
%%
%% A GCN layer is one matmul more than a dense layer: H' = relu(A X W),
%% where A is the graph's adjacency, normalised -- D^-1/2 (A + I) D^-1/2,
%% every node averaging itself with its neighbours -- so a node's features
%% after a layer are a blend of its neighbourhood's. Two layers, and a node
%% has heard from two hops away. Kipf and Welling, 2016.
%%
%% Zachary's karate club is the graph everybody starts on: 34 members, 78
%% friendships, and a split into two factions after a quarrel between the
%% instructor (node 1) and the administrator (node 34). SEMI-SUPERVISED:
%% only those two nodes are labelled, the loss is the cross-entropy at
%% those two rows -- index_rows/2 picks them -- and the network is asked
%% for the other thirty-two, which the graph's structure decides.
%%
%% The node features are the identity matrix: a node knows nothing but
%% which node it is. Everything it learns comes through A.
%%
%%   train    200 steps of Adam on the two labelled nodes; saved as t38_gcn
%%   test     accuracy over all 34 members against the factions, at least 0.85
%%   predict  the two factions as the network sees them, with its confidence
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/38-gcn.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/38-gcn.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/38-gcn.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the graph ----------------------------------------------------------------------
%% The 78 friendships, members numbered 1 to 34 as Zachary numbered them.
edge(1,2). edge(1,3). edge(1,4). edge(1,5). edge(1,6). edge(1,7). edge(1,8). edge(1,9). edge(1,11). edge(1,12). edge(1,13). edge(1,14). edge(1,18). edge(1,20). edge(1,22). edge(1,32).
edge(2,3). edge(2,4). edge(2,8). edge(2,14). edge(2,18). edge(2,20). edge(2,22). edge(2,31).
edge(3,4). edge(3,8). edge(3,9). edge(3,10). edge(3,14). edge(3,28). edge(3,29). edge(3,33).
edge(4,8). edge(4,13). edge(4,14).
edge(5,7). edge(5,11).
edge(6,7). edge(6,11). edge(6,17).
edge(7,17).
edge(9,31). edge(9,33). edge(9,34).
edge(10,34).
edge(14,34).
edge(15,33). edge(15,34).
edge(16,33). edge(16,34).
edge(19,33). edge(19,34).
edge(20,34).
edge(21,33). edge(21,34).
edge(23,33). edge(23,34).
edge(24,26). edge(24,28). edge(24,30). edge(24,33). edge(24,34).
edge(25,26). edge(25,28). edge(25,32).
edge(26,32).
edge(27,30). edge(27,34).
edge(28,34).
edge(29,32). edge(29,34).
edge(30,33). edge(30,34).
edge(31,33). edge(31,34).
edge(32,33). edge(32,34).
edge(33,34).

%% faction(?Member, ?F): 0 went with the instructor, 1 with the administrator.
faction(M, 0) :- member(M, [1,2,3,4,5,6,7,8,9,11,12,13,14,17,18,20,22]), !.
faction(M, 1) :- member(M, [10,15,16,19,21,23,24,25,26,27,28,29,30,31,32,33,34]), !.

linked(A, B) :- ( edge(A, B) ; edge(B, A) ), !.
degree(M, D) :- findall(x, ( between(1, 34, N), N =\= M, linked(M, N) ), L), length(L, D0), D is D0 + 1, !.   % +1: the self loop

%% normalised(-A): D^-1/2 (A + I) D^-1/2 as a [34, 34] tensor.
normalised(A) -->
    { findall(Row, ( between(1, 34, I), degree(I, Di),
                   findall(V, ( between(1, 34, J), degree(J, Dj),
                                ( ( I =:= J ; linked(I, J) ) -> V is 1.0 / sqrt(Di * Dj) ; V = 0.0 ) ), Row) ), Rows) },
    A = Rows, !.

%% ---- the network ------------------------------------------------------------------------

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(34, 16)), B1 := parameter(zeros([1, 16])),
    W2 := parameter(glorot(16, 2)),  B2 := parameter(zeros([1, 2])), !.

%% forward(+Ps, +A, -Out): two graph convolutions; Out is [34, 2], a row per
%% member -- a PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees X and H.
forward([W1, B1, W2, B2], A, Out) -->
    X = eye(34),                                           % a member knows only which member it is
    H = relu(A matmul X matmul W1 + B1),                   % one hop
    Out = A matmul H matmul W2 + B2.                       % two hops

%% ---- the three goals ------------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(38),
    normalised(A),
    one_hot([0, 1], 2, Y),                                  % member 1 is faction 0, member 34 is faction 1
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(200, Ps0, St0, A, Y, Ps) },
    params_save(t38_gcn, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, A, Y, PsF) :-
    exec(forward(Ps, A, Out)),
    L := cross_entropy(index_rows(Out, [0, 33]), Y),         % the loss at the two labelled rows only
    Gs := grad(L, Ps),
    ( K mod 50 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss at the two labelled members ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, A, Y, PsF).

%% answers(+Ps, -Got, -Probs): every member's faction as the network sees it.
answers(Ps, Got, Probs) -->
    normalised(A), forward(Ps, A, Out),
    Probs = list(softmax(Out)),
    Got0 = list(argmax(Out, 1)), { findall(G, ( member(G0, Got0), G is round(G0) ), Got) }.

test -->
    params_load(t38_gcn, Ps),
    answers(Ps, Got, _),
    { findall(x, ( nth0(I, Got, G), M is I + 1, faction(M, G) ), Hits), length(Hits, H), Acc is H / 34,
      format("test: ~w of 34 members placed in their faction, accuracy ~3f, from two labels~n", [H, Acc]),
      ( Acc >= 0.85 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    params_load(t38_gcn, Ps),
    answers(Ps, Got, Probs),
    { forall(member(F, [0, 1]),
             ( findall(M, ( nth0(I, Got, F), M is I + 1 ), Ms),
               ( F =:= 0 -> Who = 'with the instructor (member 1)' ; Who = 'with the administrator (member 34)' ),
               format("   ~w: ~w~n", [Who, Ms]) )),
      findall(M-Pv, ( nth0(I, Probs, [P0, P1]), M is I + 1, faction(M, F), nth0(I, Got, G), G =\= F, ( F =:= 0 -> Pv = P0 ; Pv = P1 ) ), Wrong),
      ( Wrong == [] -> write('   every member where Zachary put them'), nl
      ; format("   misplaced, with the network's probability for their real faction: ~w~n", [Wrong]) ) }.
