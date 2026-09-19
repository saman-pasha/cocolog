%% library(reasoning/normalise) -- the generator held to the grammar: every clean
%% sentence parses, every noisy one is refused, the inflector and the
%% stemmer are inverses, and the gold tags assemble back into the terms
%% the clean text gives. The round trip is the contract.
%%
%%     cocolog -s test/normalise.pl        from the checkout root
%%
%% One process, no server, no torch: the network this feeds is not here,
%% and everything that decides whether it CAN be trained is.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

main :-
    alphabet, determinism, clean, inflection, noise, assemble, roundtrip,
    checks_done.

%% ---- the alphabet, and the shape of a pair ---------------------------------

alphabet :-
    section('alphabet'),
    normalise_tags(Tags), length(Tags, NT),
    check('eleven tags', NT, 11),
    normalise_corpus(200, Pairs),
    findall(N, ( member(pair(N, Toks, Tgs, _, _), Pairs), length(Toks, A), length(Tgs, B), A =\= B ), Mis),
    check('one tag a token, over 200 pairs', Mis, []),
    findall(T, ( member(pair(_, _, Tgs, _, _), Pairs), member(T, Tgs), \+ memberchk(T, Tags) ), Unk),
    check('every tag is in the alphabet', Unk, []),
    findall(N, ( member(pair(N, Toks, _, _, _), Pairs), reason_tokens(N, All), \+ append(Toks, ['.'], All) ), Tk),
    check('the tokens are reason_tokens/2''s, the stop dropped', Tk, []),
    normalise_transforms(Ts), length(Ts, NTr),
    check('ten transforms', NTr, 10),
    normalise_lexicon_dir(Dir), yes_no(sub_atom(Dir, _, _, 0, 'reasoning/lexicon'), Found),
    check('the lexicon is the files under reasoning/lexicon', Found, yes),
    forall(member(Class-Least, [proper-1000, noun-3000, class-1000, adj-2000, vt-1500, vi-800, adverb-300, place-500]),
           ( normalise_lexicon(Class, Ws), length(Ws, NW), yes_no(NW >= Least, Big),
             atomic_list_concat(['at least ', Least, ' words of ', Class, ' loaded'], Label), check(Label, Big, yes) )),
    findall(W, ( member(C, [proper, noun, class, adj, vt, vi, vpp, adverb, place]), normalise_lexicon(C, Ws), member(W, Ws),
                 downcase_atom(W, L), rl_closed(L) ), Closed),
    check('and no closed word of the grammar in any class', Closed, []).

%% ---- the same seed, the same pair ----------------------------------------------

determinism :-
    section('determinism'),
    normalise_pair(7, P1), normalise_pair(7, P2),
    check('the same seed, the same pair', P1, P2),
    normalise_pair(7, [always(true)], P3), normalise_pair(7, [always(true)], P4),
    check('with options too', P3, P4),
    normalise_pair(7, pair(_, _, _, C7, _)), normalise_pair(8, pair(_, _, _, C8, _)),
    yes_no(C7 == C8, Same),
    check('and two seeds differ', Same, no),
    normalise_corpus(50, Ps), length(Ps, N),
    check('a corpus of 50', N, 50).

%% ---- every clean sentence is one the grammar reads -------------------------------

clean :-
    section('clean'),
    normalise_corpus(200, [transforms([])], Pairs),
    findall(C, ( member(pair(_, _, _, C, _), Pairs), \+ reason_text(C, _) ), Bad),
    check('every clean sentence parses, 200 of them', Bad, []),
    findall(N, ( member(pair(N, _, _, C, _), Pairs), N \== C ), Diff),
    check('with no transforms the noisy text IS the clean text', Diff, []),
    findall(T, ( member(pair(_, _, Tgs, _, _), Pairs), member(T, Tgs), memberchk(T, ['D', 'B']) ), DB),
    check('and carries no D or B', DB, []),
    findall(A, ( member(pair(_, _, _, _, A), Pairs), A \== [] ), Ap),
    check('and applied nothing', Ap, []),
    findall(r, ( member(pair(_, _, _, C, _), Pairs), reason_text(C, Ts), member((_ :- _), Ts) ), Rules),
    length(Rules, NR), yes_no(NR > 20, ManyRules),
    check('the shapes include rules', ManyRules, yes),
    findall(n, ( member(pair(_, _, _, C, _), Pairs), reason_text(C, Ts), member(neg(_), Ts) ), Negs),
    length(Negs, NN), yes_no(NN > 10, ManyNegs),
    check('and negations', ManyNegs, yes),
    findall(C, member(pair(_, _, _, C, _), Pairs), Cs), sort(Cs, Distinct), length(Distinct, ND),
    yes_no(ND > 100, Varied),
    check('and more than 100 distinct sentences in 200', Varied, yes).

%% ---- the inflector and the stemmer are inverses ----------------------------------------

inflection :-
    section('inflection'),
    normalise_lexicon(vt, VT),
    findall(V-F, ( member(V, VT), normalise_third(V, V3),
                   atomic_list_concat(['Alice ', V3, ' Bob.'], S),
                   reason_sentence(S, [T]), functor(T, F, 2), F \== V ), BadT),
    check('every transitive verb: third person in, base out', BadT, []),
    normalise_lexicon(vi, VI),
    findall(V-F, ( member(V, VI), normalise_third(V, V3),
                   atomic_list_concat(['Alice ', V3, '.'], S),
                   reason_sentence(S, [T]), functor(T, F, 1), F \== V ), BadI),
    check('every intransitive verb too', BadI, []),
    normalise_third(use, U),   check('use -> uses', U, uses),
    normalise_third(watch, W), check('watch -> watches', W, watches),
    normalise_third(pass, P),  check('pass -> passes', P, passes),
    normalise_third(fix, X),   check('fix -> fixes', X, fixes),
    normalise_third(have, H),  check('have -> has', H, has).

%% ---- every transform makes a sentence the grammar refuses -----------------------------

noise :-
    section('noise'),
    normalise_transforms(Ts),
    forall(member(T, Ts), noise_one(T)),
    normalise_corpus(300, All),
    findall(A, ( member(pair(_, _, _, _, A), All), A \== [] ), Noisy), length(Noisy, NNoisy),
    yes_no(NNoisy > 200, Most),
    check('by default most of 300 pairs carry noise', Most, yes),
    findall(N, ( member(pair(N, _, _, _, A), All), A \== [], reason_text(N, _) ), Slipped),
    check('and not one noisy text parses', Slipped, []).

noise_one(T) :-
    findall(N, ( between(1, 80, I), normalise_pair(I, [transforms([T]), always(true)], pair(N, _, _, _, A)), A == [T] ), Ns),
    length(Ns, Count), yes_no(Count > 0, Applied),
    atomic_list_concat([T, ': applies to some of 80 seeds'], L1),
    check(L1, Applied, yes),
    findall(N, ( member(N, Ns), reason_text(N, _) ), Parsed),
    atomic_list_concat([T, ': every noisy text is refused'], L2),
    check(L2, Parsed, []).

%% ---- the assembler, by hand -----------------------------------------------------------------

assemble :-
    section('assemble'),
    normalise_assemble([word(alice, upper), word(really, lower), word(owns, lower), word(a, lower), word(car, lower)],
                       ['S', 'D', 'R', 'T', 'O'], T1),
    check('D dropped', T1, 'Alice owns a car.'),
    normalise_assemble([word(alice, upper), word(lives, lower), word(in, lower), word(rome, upper)],
                       ['S', 'R', 'R', 'O'], T2),
    check('an R run joined with _, a proper noun keeps its case', T2, 'Alice lives_in Rome.'),
    normalise_assemble([word(alice, upper), word(sleeps, lower), word(and, lower), word(bob, upper), word(works, lower)],
                       ['S', 'R', 'B', 'S', 'R'], T3),
    check('B breaks the sentence', T3, 'Alice sleeps. Bob works.'),
    normalise_assemble([word(in, upper), word(fact, lower), ',', word(every, lower), word(tenant, lower),
                        word(is, lower), word(a, lower), word(person, lower)],
                       ['D', 'D', 'D', 'Q', 'S', 'R', 'T', 'O'], T4),
    check('a comma goes with its D, and the sentence is capitalised', T4, 'Every tenant is a person.'),
    normalise_assemble([word(alice, upper), word(does, lower), word(not, lower), word(own, lower), word(a, lower), word(car, lower)],
                       ['S', 'K', 'N', 'R', 'T', 'O'], T5),
    check('K and N copied as they are', T5, 'Alice does not own a car.'),
    normalise_assemble([], [], T6),
    check('nothing in, nothing out', T6, '').

%% ---- the contract: gold tags assemble into the clean text's terms ---------------------------

roundtrip :-
    section('round trip'),
    normalise_corpus(300, Pairs),
    findall(N-V, ( member(pair(N, Toks, Tgs, C, _), Pairs), rt_verdict(Toks, Tgs, C, V), V \== ok ), Bad),
    check('300 of 300 assemble, parse, and match the clean terms', Bad, []),
    normalise_corpus(120, [always(true)], Hard),
    findall(N-V, ( member(pair(N, Toks, Tgs, C, _), Hard), rt_verdict(Toks, Tgs, C, V), V \== ok ), BadHard),
    check('and 120 of 120 with every transform that fits applied at once', BadHard, []).

rt_verdict(Toks, Tgs, C, V) :-
    normalise_assemble(Toks, Tgs, Asm),
    (   \+ reason_text(Asm, _) -> V = refused(Asm)
    ;   \+ reason_text(C, _)   -> V = clean_refused(C)
    ;   reason_text(Asm, T2), reason_text(C, T1),
        ( rt_variant(T1, T2) -> V = ok ; V = differ(C, Asm) )
    ).

%% variants: the same term up to the names of its variables. Both copies
%% have their variables bound to '$v'(K) in order of first occurrence.
rt_variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), rt_number(Va, 0),
    term_variables(B1, Vb), rt_number(Vb, 0),
    A1 == B1.
rt_number([], _).
rt_number(['$v'(N)|Vs], N) :- N1 is N + 1, rt_number(Vs, N1).
