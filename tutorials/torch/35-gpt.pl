%% 35. GPT: a decoder that writes, one character at a time
%%
%% The same block as tutorial 34 with two changes that make it a language
%% model: the mask is CAUSAL -- a position sees itself and what came before
%% it, never after, so the prediction at position t is honest about t+1 --
%% and the head answers at EVERY position, a distribution over the next
%% character. Trained on a small text of sentences that share a grammar,
%% it is then asked to continue a prompt, greedily, its own output fed back
%% as the next context. That loop, in Prolog, is what `predict' is.
%%
%% Characters are the tokens: an alphabet of 28 (a-z, space, full stop),
%% windows of 8 characters, the target at each position the character after
%% it. D = 32, two heads of 16, the feed-forward 64 wide, GELU in it, and a
%% final layer norm before the output -- the GPT-2 arrangement, one block.
%%
%%   train    windows from the first 300 characters, sixteen batches of 64, Adam, 800 steps; saved as t35_gpt
%%   test     windows from the rest of the text, next-character accuracy at least 0.5
%%   predict  the model continues two prompts
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/35-gpt.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/35-gpt.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/35-gpt.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the text and its windows ----------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

text('the cat sat on the mat. the dog sat on the log. the cat saw the dog. the dog saw the cat. the cat ran to the mat. the dog ran to the log. the cat ate the fish. the dog ate the bone. the cat sat on the log. the dog sat on the mat. the cat saw the fish. the dog saw the bone. the cat ran to the log. the dog ran to the mat. the cat ate the bone. the dog ate the fish. the cat sat on the mat. the dog sat on the log.').
alphabet("abcdefghijklmnopqrstuvwxyz .").

%% id(?Char, ?Id): a character code and its token id, both ways.
id(Char, Id) :- alphabet(A), nth0(Id, A, Char), !.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

%% windows(+Lo, +Hi, +Salt, +N, -Ids, -PosIds, -Targets): N windows of 8
%% characters starting at offsets in [Lo, Hi), chosen by the noise; the
%% inputs as N*8 token ids, their positions, and the N*8 next characters.
windows(Lo, Hi, Salt, N, Ids, PosIds, Targets) :-
    text(T), atom_codes(T, Codes), findall(I, ( member(C, Codes), id(C, I) ), All),
    Span is Hi - Lo, N1 is N - 1,
    findall(O, ( between(0, N1, K), J is K * 31 + Salt, noise(J, R), O is Lo + truncate(abs(R) * Span) ), Offsets),
    findall(X, ( member(O, Offsets), between(0, 7, P), Q is O + P, nth0(Q, All, X) ), In),
    findall(Y, ( member(O, Offsets), between(1, 8, P), Q is O + P, nth0(Q, All, Y) ), Targets),
    findall(P, ( member(_, Offsets), between(0, 7, P) ), Pos),
    tensor_from_list(In, Ids), tensor_from_list(Pos, PosIds), !.

%% ---- the network ------------------------------------------------------------

parameters([Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, G3, Bt3, Wout, Bout]) :-
    Emb := parameter(randn([28, 32]) * 0.3), Pos := parameter(randn([8, 32]) * 0.3),
    G1 := parameter(ones([1, 32])), Bt1 := parameter(zeros([1, 32])),
    Wq := parameter(glorot(32, 32)), Wk := parameter(glorot(32, 32)), Wv := parameter(glorot(32, 32)), Wo := parameter(glorot(32, 32)),
    G2 := parameter(ones([1, 32])), Bt2 := parameter(zeros([1, 32])),
    W1 := parameter(glorot(32, 64)), B1 := parameter(zeros([1, 64])),
    W2 := parameter(glorot(64, 32)), B2 := parameter(zeros([1, 32])),
    G3 := parameter(ones([1, 32])), Bt3 := parameter(zeros([1, 32])),
    Wout := parameter(glorot(32, 28)), Bout := parameter(zeros([1, 28])), !.

head(Q, K, V, Mask, H, O) :-
    F is H * 16, T is F + 16,
    O := softmax(cols(Q, F, T) matmul transpose(cols(K, F, T)) * 0.25 + Mask) matmul cols(V, F, T), !.

%% forward(+Ps, +Ids, +PosIds, +Mask, -Logits): logits at every position, [N*8, 28].
forward([Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, G3, Bt3, Wout, Bout], Ids, PosIds, Mask, Logits) :-
    E := index_rows(Emb, Ids) + index_rows(Pos, PosIds),
    X1 := layer_norm(E) * G1 + Bt1,
    Q := X1 matmul Wq, K := X1 matmul Wk, V := X1 matmul Wv,
    head(Q, K, V, Mask, 0, O0), head(Q, K, V, Mask, 1, O1),
    H := E + cat([O0, O1], 1) matmul Wo,
    X2 := layer_norm(H) * G2 + Bt2,
    Ff := H + gelu(X2 matmul W1 + B1) matmul W2 + B2,
    Xf := layer_norm(Ff) * G3 + Bt3,
    Logits := Xf matmul Wout + Bout,
    free_all([E, X1, Q, K, V, O0, O1, H, X2, Ff, Xf]), !.

%% ---- the three goals ----------------------------------------------------------

train :-
    torch_seed(35),
    findall(batch(Ids, PosIds, Y), ( between(0, 15, B), Salt is B * 977 + 5, windows(0, 292, Salt, 64, Ids, PosIds, Ts), one_hot(Ts, 28, Y) ), Batches),
    causal_mask(64, 8, Mask),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(800, Ps0, St0, Batches, Mask, Ps),
    Batches = [batch(Ids0, PosIds0, _)|_], windows(0, 292, 5, 64, _, _, Ts0),
    forward(Ps, Ids0, PosIds0, Mask, Logits), accuracy(Logits, Ts0, Acc), tensor_free(Logits),
    format("trained: next-character accuracy on the first batch ~2f~n", [Acc]),
    params_save(t35_gpt, Ps),
    write(saved), nl.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, Batches, Mask, PsF) :-
    B is K mod 16, nth0(B, Batches, batch(Ids, PosIds, Y)),
    forward(Ps, Ids, PosIds, Mask, Logits),
    L := cross_entropy(Logits, Y),
    tensor_grad(L, Ps, Gs),
    ( K mod 200 =:= 0 -> tensor_item(L, Lv), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.003, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, Mask, PsF).

test :-
    params_load(t35_gpt, Ps),
    text(T), atom_length(T, Len), Hi is Len - 9,
    windows(300, Hi, 4242, 64, Ids, PosIds, Ts),
    causal_mask(64, 8, Mask),
    forward(Ps, Ids, PosIds, Mask, Logits), accuracy(Logits, Ts, Acc),
    format("test next-character accuracy ~2f on 64 windows the training never saw~n", [Acc]),
    ( Acc >= 0.5 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

%% generate(+Ps, +Mask, +Context, +N, -Out): N more characters, greedily --
%% the last eight characters are the context, the argmax at the last
%% position is the next character, and it joins the context for the next.
generate(_, _, Context, 0, Context) :- !.
generate(Ps, Mask, Context, N, Out) :-
    length(Context, Len), Skip is Len - 8, length(Head, Skip), append(Head, Last8, Context),
    findall(I, ( member(C, Last8), id(C, I) ), In), tensor_from_list(In, Ids),
    tensor_from_list([0, 1, 2, 3, 4, 5, 6, 7], PosIds),
    forward(Ps, Ids, PosIds, Mask, Logits),
    Next := argmax(rows(Logits, 7, 8), 1), tensor_to_list(Next, [G]), tensor_free(Next), tensor_free(Logits),
    Gi is round(G), id(Char, Gi),
    append(Context, [Char], Context2),
    N1 is N - 1,
    generate(Ps, Mask, Context2, N1, Out).

predict :-
    params_load(t35_gpt, Ps),
    causal_mask(1, 8, Mask),
    forall(member(Prompt, ['the cat ', 'the dog ']),
           ( atom_codes(Prompt, Codes), generate(Ps, Mask, Codes, 40, Out), atom_codes(Text, Out),
             format("   ~w|~w~n", [Prompt, Text]) )).
