%% 36. A variational autoencoder: a latent space you can walk
%%
%% An autoencoder (tutorial 14) squeezes a picture through a bottleneck and
%% back. A VARIATIONAL one makes the bottleneck a distribution: the encoder
%% answers a mean and a log-variance, a point is DRAWN from that Gaussian,
%% and the decoder rebuilds the picture from the point. Two terms train it:
%% the reconstruction, and a KL penalty pulling every picture's Gaussian
%% toward the standard one, so that the space between pictures means
%% something and a point drawn from N(0, I) decodes to a picture too.
%%
%% The draw is the reparameterisation trick, and it is one expression:
%% Z := Mu + exp(LogVar * 0.5) * randn([N, 2]). The randn is a leaf that
%% draws when it is written, the arithmetic around it is differentiable,
%% and so the gradient reaches Mu and LogVar through the noise.
%%
%% The pictures are 8x8 bars, horizontal or vertical, at six positions
%% each, with noise; the latent space is two-dimensional so `predict' can
%% draw a grid of it.
%%
%%   train    96 pictures, Adam, 800 steps; saved as t36_vae
%%   test     24 fresh pictures, pixel accuracy of the reconstruction at least 0.95
%%   predict  a 3x3 walk over the latent space, decoded and drawn
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/36-vae.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/36-vae.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/36-vae.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the pictures --------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

%% picture(+I, -Pixels, -Clean): bar I mod 12 -- horizontal on row 1..6,
%% then vertical on column 1..6 -- with noise, and without.
picture(I, Pixels, Clean) :-
    Kind is I mod 12,
    findall(V-C, ( between(0, 63, P), Y is P // 8, X is P mod 8,
                   ( bar(Kind, Y, X) -> C = 1.0 ; C = 0.0 ),
                   J is I * 97 + P, noise(J, R), V is C + 0.1 * R ), Pairs),
    findall(V, member(V-_, Pairs), Pixels), findall(C, member(_-C, Pairs), Clean), !.
bar(Kind, Y, X) :- Kind < 6, Y =:= Kind + 1, X >= 1, X =< 6, !.
bar(Kind, Y, X) :- Kind >= 6, X =:= Kind - 5, Y >= 1, Y =< 6, !.

%% pictures(+From, +N, -X, -Clean): N pictures as [N, 64] rows, and their clean masks.
pictures(From, N, X, Clean) :-
    To is From + N - 1,
    findall(Ps, ( between(From, To, I), picture(I, Ps, _) ), XR),
    findall(Cs, ( between(From, To, I), picture(I, _, Cs) ), CR),
    X := XR, Clean := CR, !.

draw(Values) :-
    forall(between(0, 7, Y),
           ( write('   '), forall(between(0, 7, X), ( P is Y * 8 + X, nth0(P, Values, V), ( V > 0.5 -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network --------------------------------------------------------------------

parameters([We, Be, Wm, Bm, Wv, Bv, Wd, Bd, Wo, Bo]) :-
    We := parameter(glorot(64, 32)), Be := parameter(zeros([1, 32])),      % encoder
    Wm := parameter(glorot(32, 2)),  Bm := parameter(zeros([1, 2])),       % -> mean
    Wv := parameter(glorot(32, 2)),  Bv := parameter(zeros([1, 2])),       % -> log variance
    Wd := parameter(glorot(2, 32)),  Bd := parameter(zeros([1, 32])),      % decoder
    Wo := parameter(glorot(32, 64)), Bo := parameter(zeros([1, 64])), !.

%% encode//4, decode//3 and loss//4 are PROCEDURES: DCG rules of bindings; a
%% procedure called inside another threads what it made up to the caller,
%% and proc/1 at the top frees all of it but what the head returns.
encode([We, Be, Wm, Bm, Wv, Bv | _], X, Mu, LogVar) -->
    H = relu(X matmul We + Be),
    Mu = H matmul Wm + Bm, LogVar = H matmul Wv + Bv.
decode([_, _, _, _, _, _, Wd, Bd, Wo, Bo], Z, Out) -->
    Out = sigmoid(relu(Z matmul Wd + Bd) matmul Wo + Bo).

%% loss(+Ps, +X, -L, -Parts): the ELBO, negated: the reconstruction as the
%% summed bce per picture, and the KL to N(0, I), both averaged over the batch.
loss(Ps, X, L, recon(Rv)-kl(Kv)) -->
    [N, _] = shape(X), { NegHalfOverN is -0.5 / N },
    encode(Ps, X, Mu, LogVar),
    Z = Mu + exp(LogVar * 0.5) * randn([N, 2]),                              % the reparameterisation trick
    decode(Ps, Z, Out),
    Recon = bce(Out, X) * 64.0,
    KL = sum(1.0 + LogVar - Mu ^ 2.0 - exp(LogVar)) * NegHalfOverN,
    L = Recon + KL,
    Rv = item(Recon), Kv = item(KL).

%% ---- the three goals -------------------------------------------------------------------

train :-
    torch_seed(36),
    pictures(0, 96, X, _),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(800, Ps0, St0, X, Ps),
    params_save(t36_vae, Ps),
    write(saved), nl.

fit(0, Ps, _, _, Ps) :- !.
fit(K, Ps, St, X, PsF) :-
    proc(loss(Ps, X, L, Parts)),
    Gs := grad(L, Ps),
    ( K mod 200 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~3f  ~w~n", [K, Lv, Parts]) ; true ),
    adam_step(Ps, Gs, St, 0.005, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, PsF).

%% reconstruct through the MEAN, no draw: what the network thinks the picture is
reconstruct(Ps, X, Out) --> encode(Ps, X, Mu, _), decode(Ps, Mu, Out).

test :-
    params_load(t36_vae, Ps),
    pictures(1000, 24, X, Clean),
    proc(reconstruct(Ps, X, Out)),
    OL := list(Out), CL := list(Clean),
    findall(x, ( nth0(I, OL, ORow), nth0(I, CL, CRow), nth0(P, ORow, V), nth0(P, CRow, C), ( V > 0.5 -> B = 1.0 ; B = 0.0 ), B =:= C ), Hits),
    length(Hits, H), Acc is H / (24 * 64),
    format("test pixel accuracy of the reconstruction ~3f on 24 fresh pictures~n", [Acc]),
    ( Acc >= 0.95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    params_load(t36_vae, Ps),
    pictures(2000, 2, X, _), proc(encode(Ps, X, Mu, _)), MuL := list(Mu),
    format("two pictures land at ~w in the latent plane~n", [MuL]),
    write('and a 3x3 walk over it, z1 across, z2 down, each decoded:'), nl, nl,
    forall(member(Z2, [-1.5, 0.0, 1.5]),
           ( forall(member(Z1, [-1.5, 0.0, 1.5]),
                    ( proc(decode(Ps, [[Z1, Z2]], Out)), [Vals] := list(Out), tensor_free(Out),
                      format("   z = (~1f, ~1f)~n", [Z1, Z2]), draw(Vals) )),
             nl )).
