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
    check('twelve tags', NT, 12),
    normalise_corpus(200, Pairs),
    findall(N, ( member(pair(N, Toks, Tgs, _, _), Pairs), length(Toks, A), length(Tgs, B), A =\= B ), Mis),
    check('one tag a token, over 200 pairs', Mis, []),
    findall(T, ( member(pair(_, _, Tgs, _, _), Pairs), member(T, Tgs), \+ memberchk(T, Tags) ), Unk),
    check('every tag is in the alphabet', Unk, []),
    findall(N, ( member(pair(N, Toks, _, _, _), Pairs), reason_tokens(N, All), \+ append(Toks, ['.'], All) ), Tk),
    check('the tokens are reason_tokens/2''s, the stop dropped', Tk, []),
    normalise_transforms(Ts), length(Ts, NTr),
    check('eleven transforms', NTr, 11),
    normalise_lexicon_dir(Dir), yes_no(sub_atom(Dir, _, _, 0, 'reasoning/lexicon'), Found),
    check('the lexicon is the files under reasoning/lexicon', Found, yes),
    forall(member(Class-Least, [proper-1000, noun-3000, class-1000, adj-2000, vt-1500, vi-800, adverb-300, place-500, unit-300]),
           ( normalise_lexicon(Class, Ws), length(Ws, NW), yes_no(NW >= Least, Big),
             atomic_list_concat(['at least ', Least, ' words of ', Class, ' loaded'], Label), check(Label, Big, yes) )),
    forall(member(Class-Least, [known_noun-8000, known_verb-3000, known_adj-4000, known_adverb-1000]),
           ( normalise_lexicon(Class, Ws), length(Ws, NW), yes_no(NW >= Least, Big),
             atomic_list_concat(['at least ', Least, ' words of ', Class, ' known to the judge'], Label), check(Label, Big, yes) )),
    normalise_lexicon(known_noun, KN), yes_no(memberchk(death, KN), Death),
    check('death is a noun the judge knows, though no thing to own', Death, yes),
    findall(W, ( member(C, [proper, noun, class, adj, vt, vi, vpp, adverb, place, unit, known_noun, known_verb, known_adj, known_adverb]),
                 normalise_lexicon(C, Ws), member(W, Ws),
                 downcase_atom(W, L), rl_closed(L) ), Closed),
    check('and no closed word of the grammar in any class', Closed, []),
    yes_no(normalise_assemble([word(boston, upper), ',', word(mass, upper)], ['X', 'X', 'X'], _), Xa),
    check('X, outside, is refused by the assembler', Xa, no),
    normalise_negatives(1, 200, Negs), length(Negs, NNeg),
    check('200 negatives from prose.txt', NNeg, 200),
    findall(T, ( member(pair(_, _, Tgs, C, _), Negs), ( C \== none ; member(T, Tgs), T \== 'X' ) ), NotX),
    check('every negative is X throughout and has no clean text', NotX, []),
    findall(T, ( member(pair(T, _, _, _, _), Negs), catch(reason_text(T, _), _, fail) ), RawRead),
    length(RawRead, NRaw), yes_no(NRaw =< 40, FewRaw),
    check('the grammar reads fewer than a fifth of the two hundred as they are (measured 31)', FewRaw, yes),
    findall(T, ( member(T, RawRead), reason_tokens(T, Toks), length(Toks, L), L > 3 ), LongRaw),
    length(LongRaw, NLong), yes_no(NLong =< 5, FewLong),
    check('and all but a few of those are two words, `Vulpine cunning.'' read as a Name-verb fact (measured one longer)', FewLong, yes).

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
    findall(C, ( member(pair(_, Toks, _, C, _), Pairs), member(num(_), Toks) ), Numbered), length(Numbered, NNum),
    yes_no(NNum >= 10, SomeNum), check('a number in some of 200 clean sentences', SomeNum, yes),
    findall(C, ( member(pair(_, _, _, C, _), Pairs), sub_atom(C, 0, _, _, 'How m') ), Hows),
    yes_no(Hows \== [], SomeHow), check('and a how-much or how-many question among them', SomeHow, yes),
    findall(C, ( member(pair(_, _, _, C, _), Pairs), sub_atom(C, 0, _, _, 'Why ') ), Whys),
    yes_no(Whys \== [], SomeWhy), check('and a why question', SomeWhy, yes),
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
    findall(q, ( member(pair(_, _, _, C, _), Pairs), reason_text(C, Ts), member(T, Ts), functor(T, question, _) ), Qs),
    length(Qs, NQ), yes_no(NQ > 10, ManyQs),
    check('and questions, read as question/1 or question/2 goals', ManyQs, yes),
    findall(C, ( member(pair(_, _, _, C, _), Pairs), reason_text(C, Ts), member(T, Ts), functor(T, question, _), \+ sub_atom(C, _, 1, 0, '?') ), NoMark),
    check('every question ends in ?', NoMark, []),
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
    check('nothing in, nothing out', T6, ''),
    normalise_assemble([word(alice, upper), word(sleeps, lower), word(and, lower), ',', word(in, lower), word(fact, lower), ',',
                        word(bob, upper), word(works, lower)],
                       ['S', 'R', 'B', 'D', 'D', 'D', 'D', 'S', 'R'], T7),
    check('a filler after the conjunction is dropped with its commas', T7, 'Alice sleeps. Bob works.'),
    normalise_assemble([word(priya, upper), word(is, lower), word(a, lower), word(baker, lower), word(and, lower),
                        word(is, lower), word(licensed, lower)],
                       ['S', 'R', 'T', 'O', 'B', 'R', 'A'], T8),
    check('a break that leaves no subject: the sentence before supplies it', T8, 'Priya is a baker. Priya is licensed.'),
    normalise_assemble([word(every, lower), word(baker, lower), word(that, lower), word(is, lower), word(licensed, lower),
                        word(is, lower), word(happy, lower), word(and, lower), word(may, lower), word(sell, lower),
                        word(the, lower), word(bread, lower)],
                       ['Q', 'S', 'K', 'K', 'C', 'R', 'A', 'B', 'R', 'R', 'T', 'O'], T9),
    check('the whole subject phrase, relative clause included', T9,
          'Every baker that is licensed is happy. Every baker that is licensed may_sell the bread.'),
    normalise_assemble([word(priya, upper), word(is, lower), word(a, lower), word(baker, lower), word(and, lower),
                        word(she, lower), word(is, lower), word(licensed, lower)],
                       ['S', 'R', 'T', 'O', 'B', 'S', 'R', 'A'], T10),
    check('a pronoun subject is copied as it is: the grammar resolves it', T10, 'Priya is a baker. She is licensed.'),
    normalise_assemble([word(well, upper), ',', word(does, lower), word(alice, upper), word(really, lower), word(own, lower),
                        word(a, lower), word(car, lower)],
                       ['D', 'D', 'K', 'S', 'D', 'R', 'T', 'O'], T11),
    check('a question, and it ends in ?', T11, 'Does Alice own a car?'),
    normalise_assemble([word(who, upper), word(is, lower), word(licensed, lower)], ['S', 'R', 'A'], T12),
    check('who as the subject, copied where it stands', T12, 'Who is licensed?'),
    normalise_assemble([word(nadia, upper), word(really, lower), word(pays, lower), num(500), word(euros, lower)],
                       ['S', 'D', 'R', 'T', 'O'], T13),
    check('a number is written as its digits', T13, 'Nadia pays 500 euros.'),
    normalise_assemble([word(the, upper), word(rent, lower), word(is, lower), num(5.5), word(percent, lower)],
                       ['T', 'S', 'R', 'T', 'O'], T14),
    check('a decimal too', T14, 'The rent is 5.5 percent.'),
    normalise_assemble([word(how, upper), word(much, lower), word(does, lower), word(nadia, upper), word(pay, lower)],
                       ['O', 'O', 'K', 'S', 'R'], T15),
    check('how much, copied where it stands, and a question', T15, 'How much does Nadia pay?').

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
