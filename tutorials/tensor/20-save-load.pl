%% 20. Persistence: what a saved parameter list IS in the knowledge base
%%
%% Every tutorial here saves and reloads, but this one is ABOUT the
%% mechanics. params_save(Name, Ps) is nothing but assertion: every tensor
%% in Ps becomes its shape and its numbers, as TERMS in the knowledge base
%% -- a '$te_param'(Name, I, Shape) fact and the '$te_chunk'(Name, I, Seq,
%% Numbers) facts under it, 120 numbers a chunk -- and `Ps = params(Name)'
%% is tensor_from_list over those terms, in order, each wrapped in
%% parameter(...). Handles are process-local integers and never travel; the
%% terms travel, which is why a list saved against a store is simply there
%% for any later process, on whatever library and device that process
%% chose. And what comes back is a list of PARAMETERS, leaves that require
%% gradient: a reloaded list is where training LEFT OFF, not a frozen copy.
%%
%% `test' proves both. The round trip to the last bit -- two loads, values
%% equal, predictions identical -- and then two hundred more steps of Adam
%% on a reloaded list, whose loss must fall from where the trainer stopped.
%% (An earlier version of this file said the same of model_save and
%% model_load, which keep a model_new spec beside its parameter list;
%% tutorials/library/22-torch.pl still teaches those.)
%%
%%   train    fit a small net, save as t20_persist, and show what the store now holds
%%   test     reload TWICE, params and predictions must agree exactly; then train the reloaded list further
%%   predict  reload, answer -- indistinguishable from the trainer's answers
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/20-save-load.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/20-save-load.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/20-save-load.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

sine_row(I, [X], [Y]) :- X is -1 + 2 * I / 63, Y is sin(2 * pi * X), !.

%% sine(-X, -Y): one period of the sine, 64 rows.
sine(X, Y) -->
    { findall(R, (between(0, 63, I), sine_row(I, R, _)), XR),
      findall(R, (between(0, 63, I), sine_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------------------

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(randn([1, 8])), B1 := parameter(zeros([1, 8])),     % unit-scale weights: a sine needs steep tanh units
    W2 := parameter(glorot(8, 1)),  B2 := parameter(zeros([1, 1])), !.

%% net//3 is a PROCEDURE: a DCG rule of one binding; exec/1 runs it and
%% frees everything it made but Out.
net([W1, B1, W2, B2], X, Out) -->
    Out = tanh(X matmul W1 + B1) matmul W2 + B2.

%% fit(+K, +Ps, +St, +X, +Y, -PsF): K steps of Adam -- a predicate, since
%% adam_step frees the old parameters itself.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(net(Ps, X, Out)),
    L := mse(Out, Y),
    Gs := grad(L, Ps),
    ( K mod 200 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

%% ---- the store, looked at ----------------------------------------------------------------

%% stored(+Name): the terms params_save left under Name -- the library's own
%% facts, read here because the lesson is what they are: a shape per tensor,
%% and its numbers in chunks. Nothing else was saved; nothing else is needed.
stored(Name) :-
    findall(I-Shape, '$te_param'(Name, I, Shape), Shapes),
    findall(x, '$te_chunk'(Name, _, _, _), Chunks), length(Chunks, NC),
    format("the store holds, under ~w: shapes ~w, in ~w chunk(s) of numbers~n", [Name, Shapes, NC]), !.

%% values(+Ps, -Ls): every parameter as its list -- a rule, since list(P)
%% is an answer form.
values([], []) --> [].
values([P|Ps], [L|Ls]) --> L = list(P), values(Ps, Ls).

%% further(+K, +Name, +X, +Y, -L1): a THIRD load of Name, trained K steps
%% further, and the loss it reaches; freed as it goes, so a predicate --
%% and its own load, since the rule's loads are the rule's to free.
further(K, Name, X, Y, L1) :-
    params_load(Name, Ps), adam_init(Ps, St),
    fit(K, Ps, St, X, Y, PsF),
    exec(net(PsF, X, Out)), L1 := item(mse(Out, Y)),
    free_all([Out | PsF]), !.

%% ---- the three goals ---------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(20),
    sine(X, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(800, Ps0, St0, X, Y, Ps) },
    net(Ps, X, Out), L = item(mse(Out, Y)),
    { format("trained: mse ~4f~n", [L]) },
    params_save(t20_persist, Ps),
    { stored(t20_persist),
      write(saved), nl }.

test -->
    % two loads from the same terms: two lists of fresh parameters
    Ps1 = params(t20_persist), Ps2 = params(t20_persist),
    values(Ps1, V1), values(Ps2, V2),
    { ( V1 == V2 -> write('two loads: the same numbers, to the last bit'), nl
      ; write('FAIL params differ between two loads'), nl, halt(1) ) },
    sine(X, Y),
    net(Ps1, X, O1), net(Ps2, X, O2),
    R1 = list(O1), R2 = list(O2),
    { ( R1 == R2 -> write('two loads: identical predictions'), nl
      ; write('FAIL predictions differ'), nl, halt(1) ) },
    % and a reloaded list is a list of parameters: it trains further
    L0 = item(mse(O1, Y)),
    { further(200, t20_persist, X, Y, L1),
      format("reloaded: mse ~4f; 200 more steps on a reloaded list: mse ~4f~n", [L0, L1]),
      ( L1 < L0 -> write(ok), nl
      ; write('FAIL the reloaded list did not train further'), nl, halt(1) ) }.

predict -->
    Ps = params(t20_persist),
    net(Ps, [[0.25]], Out), [[Yh]] = list(Out),
    { Truth is sin(2 * pi * 0.25),
      format("x 0.25  predicted ~3f  (sin says ~3f)~n", [Yh, Truth]) }.
