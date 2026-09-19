%% cocolog -- library(reasoning/normalise): the generator that teaches a text
%% normaliser, and the assembler that reads what it learns.
%%
%%     :- use_module(library(reasoning/normalise)).
%%
%% TIER 2, clauses only, and it needs nothing but library(reasoning/reason). The
%% network this feeds is NOT in here: this file is the part every later
%% number depends on, and the part that runs on a box with no torch.
%%
%% WHAT A NORMALISER IS, HERE. library(reasoning/reason) reads a controlled English
%% and refuses everything else, and the way to reach it from typed prose is
%% a network that says, for every token, WHAT IT IS -- the subject, the
%% relation, the object, or noise -- so that Prolog can rebuild the
%% sentence in the shapes the grammar reads. That network is a TAGGER, not
%% a writer: it never emits a word, it labels the ones it was given, so a
%% proper noun it has never seen is copied and never guessed, and a bad
%% label costs a refusal, never a malformed term.
%%
%% THE GRAMMAR IS THE DATA. No corpus of (prose, controlled English) exists,
%% and this file makes one from the grammar's own shapes: normalise_pair/2
%% builds a clean sentence WITH its gold tags -- the generator knows which
%% word is the subject as it puts it there -- and then applies NOISE
%% TRANSFORMS that carry the tags along: a filler phrase (tagged D, drop),
%% a hedge (`I think that', D), an adverb after the subject (D) or after an
%% intransitive verb (D), a prepositional adjunct (D), a place after a noun
%% phrase (D), a relation written as two words (R R, to be joined), an
%% emphatic `does' (D), two sentences joined by `and' (B, a boundary).
%% Every transform is one the assembler can undo by dropping, joining or
%% splitting -- and none changes a word's FORM, because a tag cannot: a
%% plural, a passive, a pronoun are not in this set, and this header says
%% so rather than leaving it to be found.
%%
%% TWO KINDS OF NOISE ARE KEPT OUT ON PURPOSE, measured against the
%% grammar. A bare word after an indefinite object -- `owns a car too',
%% `owns a car now' -- is not refused but MISREAD, as the noun of the
%% phrase, so an adverb goes at the end only after an intransitive verb.
%% And a place after an intransitive verb -- `works in Rome' -- is not
%% noise: it is the relation work_in, shape 9 with a phrasal verb, and
%% dropping it once taught the network to drop `lives in Lagos' too. A
%% place is dropped only after a noun phrase, where the grammar has no
%% shape that could keep it.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     normalise_pair(+Seed, -Pair)
%%     normalise_pair(+Seed, +Options, -Pair)
%%         Pair = pair(Noisy, Tokens, Tags, Clean, Applied): the noisy text;
%%         its tokens as reason_tokens/2 gives them, the final stop dropped;
%%         one tag a token; the controlled text the noise was made from; and
%%         the names of the transforms that applied. Deterministic in Seed.
%%         Options: transforms(Names) restricts the candidates, so
%%         transforms([]) is a clean pair; always(true) applies every
%%         candidate that fits, where the default is a coin a transform.
%%
%%     normalise_corpus(+N, -Pairs)
%%     normalise_corpus(+N, +Options, -Pairs)          seeds 1..N
%%
%%     normalise_assemble(+Tokens, +Tags, -Text)
%%         The inverse: D dropped, a run of R joined with `_', B a sentence
%%         break, everything else copied in its case; each sentence
%%         capitalised and stopped. What the tagger's output is handed to,
%%         and what the round trip below holds the tags to.
%%
%%     normalise_third(+Base, -ThirdPerson)             the inflector, which
%%                                                     library(reasoning/reason)'s stemmer must invert
%%     normalise_tags(-Tags)                           the alphabet, closed
%%     normalise_transforms(-Names)                    the transforms, by name
%%     normalise_lexicon(?Class, -Words)               proper, noun, class, adj, vt, vi, vpp, modal, place
%%
%% ---- THE TAGS ---------------------------------------------------------
%%
%%     S  the subject head      Q  a quantifier (every)      C  the condition's adjective
%%     R  a relation word       K  a structural word kept as it is: `that', `does',
%%                                 the copula inside a relative clause
%%     N  not                   T  a determiner               A  an adjective
%%     O  the object head       D  drop                       B  a sentence boundary
%%
%% Only D, R and B change what the assembler emits; the rest are copied.
%% They are still worth teaching: a network told WHAT each kept word is
%% learns the sentence's shape, not only which words to lose, and an
%% assembler that one day reorders (a passive) will need them.
%%
%% ---- THE ROUND TRIP IS THE CONTRACT -----------------------------------
%%
%% For every pair: assemble the noisy tokens with their GOLD tags, parse
%% the result with reason_text/2, and it must give the same terms as the
%% clean text -- up to the names of a rule's variables. test/normalise.pl
%% holds 300 pairs to it. That is the proof that the tag scheme carries
%% enough to recover the sentence, which is the only thing that makes it a
%% possible target for a network; and the proof that every noisy text is
%% REFUSED by the grammar is what makes the noise noise.
%%
%% ---- WHAT THE NETWORK WILL AND WILL NOT LEARN ----------------------------
%%
%% It learns to undo the transforms written here. Prose has more, and the
%% grammar refuses what the tagger gets wrong -- so the cost of the gap is
%% refusals, measured by the acceptance rate on real text, and the next
%% transform to write is whichever refusal is commonest. And a well-formed
%% WRONG sentence is possible: swap S and O and `Rome owns a house' parses.
%% The grammar guarantees form; tag accuracy is the correctness number.
%%
%% THE NOISE IS DETERMINISTIC IN THE SEED, the way the tensor lessons draw
%% their data: a hash of the seed and a salt, not a random number, so a
%% corpus is reproducible and a failing pair can be named by its seed.

:- use_module(library(reasoning/reason)).

%% ---- the alphabet, the transforms, the lexicon ---------------------------

normalise_tags(['S', 'Q', 'C', 'N', 'R', 'K', 'T', 'A', 'O', 'D', 'B']).

%% in the order they are applied: the split before the emphatic (so a
%% split relation is not also a candidate for `does'), the join before the
%% fillers (so a filler or a hedge wraps the whole), the tails last -- an
%% adverb after an intransitive verb, a place after an object, a
%% prepositional adjunct after anything
normalise_transforms([split_relation, emphatic_do, conjoin, adverb, hedge_start, filler_start, filler_end,
                      adverb_end, pp_place, pp_extra]).

normalise_lexicon(proper, ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Heidi', 'Ivan', 'Judy',
                           'Karl', 'Lena', 'Mark', 'Nina', 'Omar', 'Paul', 'Quinn', 'Rosa', 'Sam', 'Tina',
                           'Uma', 'Victor', 'Wendy', 'Xavier', 'Yara', 'Zoe', 'Adam', 'Bella', 'Chris', 'Dina',
                           'Emil', 'Fiona', 'Gus', 'Hana', 'Igor', 'Jana', 'Kim', 'Leo', 'Mona', 'Nils',
                           'Otto', 'Pia', 'Rudi', 'Sara', 'Theo', 'Ulla', 'Vic', 'Wolf', 'Yuri', 'Zara']).
normalise_lexicon(noun,   [car, house, dog, badge, contract, server, flat, book, key, ticket, robot, garden,
                           boat, bike, phone, laptop, desk, chair, lamp, coat, hat, map, cup, plate,
                           knife, drone, camera, printer, guitar, piano, violin, tent, rope, ladder, bucket,
                           shovel, hammer, wallet, card, letter, parcel, bottle, jacket, scarf, clock,
                           mirror, pillow, blanket]).
normalise_lexicon(class,  [tenant, employee, landlord, person, member, student, driver, customer,
                           teacher, doctor, nurse, pilot, guard, clerk, farmer, baker, lawyer, judge,
                           officer, citizen, visitor, guest, owner, worker, manager, engineer, resident,
                           voter, patient, passenger]).
normalise_lexicon(adj,    [red, big, old, new, happy, exempt, authorized, suspended, blue, nice, banned,
                           broken, late, active, small, green, tall, short, young, rich, poor, tired,
                           busy, ready, safe, certified, insured, registered, licensed, retired, absent,
                           present, sick, healthy, careful, brave, calm, angry, clean, dirty]).
normalise_lexicon(vt,     [own, like, rent, watch, employ, sign, hold, want, need, use, close, raise,
                           have, buy, sell, read, write, drive, open, lock, paint, fix, move, love,
                           hate, keep, send, wash, build, admire, trust, visit, teach, guard, wear, hire]).
normalise_lexicon(vi,     [sleep, work, wait, vote, resign, pay, smile, run, swim, sing, dance, laugh,
                           rest, win, lose, cook, knock, jump, snore, drive]).
normalise_lexicon(vpp,    [live-in, work-at, come-from, belong-to, deal-with, look-after, work-in,
                           stay-in, move-to, travel-to, return-to, arrive-at, walk-to, drive-to,
                           sit-in, wait-for, talk-to, listen-to]).
normalise_lexicon(modal,  [may, must, can, should, will]).
normalise_lexicon(place,  ['Rome', 'Paris', 'Oslo', 'Cairo', 'Lima', 'Tokyo', 'Berlin', 'Madrid', 'Lagos',
                           'Delhi', 'Boston', 'Dublin', 'Vienna', 'Athens', 'Prague', 'Sydney']).

%% THE VERBS ARE CHOSEN TO SURVIVE THE STEMMER: library(reasoning/reason)
%% takes a third person back to its base by cutting -s, or -es after ss,
%% sh, ch, x and z, and nothing else -- so no verb here ends in a consonant
%% and y (cry, fly), in o (go, do) or in a single s (focus), whose third
%% person would come back as another word. test/normalise.pl's inflection
%% section holds every verb of every class to the round trip.

%% ---- the inflector ---------------------------------------------------------
%% Third person singular, and library(reasoning/reason)'s rs_base/2 must give the
%% base back: -es after ss, sh, ch, x, z; -s otherwise; `has' by name.

normalise_third(have, has) :- !.
normalise_third(B, T) :- ng_es_stem(B), !, atom_concat(B, es, T).
normalise_third(B, T) :- atom_concat(B, s, T).

ng_es_stem(B) :- sub_atom(B, _, 2, 0, ss), !.
ng_es_stem(B) :- sub_atom(B, _, 2, 0, sh), !.
ng_es_stem(B) :- sub_atom(B, _, 2, 0, ch), !.
ng_es_stem(B) :- sub_atom(B, _, 1, 0, x), !.
ng_es_stem(B) :- sub_atom(B, _, 1, 0, z).

%% ---- deterministic noise -----------------------------------------------------

ng_noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S).
ng_pick(Seed, Salt, N, K) :- J is Seed * 7 + Salt, ng_noise(J, R), K is truncate(abs(R) * N).
ng_choose(Seed, Salt, List, X) :- length(List, N), ng_pick(Seed, Salt, N, K), nth0(K, List, X).
ng_coin(Seed, Salt, PercentYes) :- ng_pick(Seed, Salt, 100, K), K < PercentYes.

ng_word(Class, Seed, Salt, W) :- normalise_lexicon(Class, L), ng_choose(Seed, Salt, L, W).
ng_word2(Class, Seed, Salt, W1, W2) :-
    normalise_lexicon(Class, L), ng_choose(Seed, Salt, L, W1),
    select(W1, L, L2), Salt2 is Salt + 50, ng_choose(Seed, Salt2, L2, W2).

ng_art(W, an) :- atom_codes(W, [C|_]), memberchk(C, [0'a, 0'e, 0'i, 0'o, 0'u]), !.
ng_art(_, a).

%% ---- the shapes: a clean sentence as Word-Tag pairs ----------------------------
%% Proper nouns are emitted capitalised, everything else lower; the text
%% builder capitalises a sentence's first word.

ng_sentence(Seed, Pairs) :- ng_pick(Seed, 1, 20, K), ng_shape(K, Seed, Pairs), !.

ng_shape(0, Seed, [P-'S', V3-'R'|Obj]) :-                                  % Alice owns a red car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_object(Seed, 4, Obj).
ng_shape(1, Seed, [P-'S', is-'R', A-'A']) :-                               % Alice is happy
    ng_word(proper, Seed, 2, P), ng_word(adj, Seed, 3, A).
ng_shape(2, Seed, [P-'S', is-'R', Art-'T', N-'O']) :-                      % Alice is a tenant
    ng_word(proper, Seed, 2, P), ng_word(class, Seed, 3, N), ng_art(N, Art).
ng_shape(3, Seed, [P-'S', is-'R', not-'N', A-'A']) :-                      % Alice is not happy
    ng_word(proper, Seed, 2, P), ng_word(adj, Seed, 3, A).
ng_shape(4, Seed, [P-'S', does-'K', not-'N', V-'R', Art-'T', N-'O']) :-    % Alice does not own a car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_word(noun, Seed, 4, N), ng_art(N, Art).
ng_shape(5, Seed, [P-'S', V3-'R']) :-                                      % Alice sleeps
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V), normalise_third(V, V3).
ng_shape(6, Seed, [P-'S', M-'R', V-'R', the-'T', N-'O']) :-                % Alice may use the server
    ng_word(proper, Seed, 2, P), ng_word(modal, Seed, 3, M), ng_word(vt, Seed, 4, V), ng_word(noun, Seed, 5, N).
ng_shape(7, Seed, [every-'Q', C-'S', is-'R', Art-'T', N-'O']) :-           % Every tenant is a person
    ng_word2(class, Seed, 2, C, N), ng_art(N, Art).
ng_shape(8, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-            % Every tenant that is not exempt must pay the rent
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(modal, Seed, 4, M),
    ng_word(vt, Seed, 5, V), ng_word(noun, Seed, 6, N),
    (   ng_coin(Seed, 7, 50)
    ->  Rest = [not-'N', A-'C', M-'R', V-'R', the-'T', N-'O']
    ;   Rest = [A-'C', M-'R', V-'R', the-'T', N-'O']
    ).
ng_shape(9, Seed, [P-'S', VJ-'R', Q-'O']) :-                               % Alice lives_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vpp, Seed, 3, V-Prep), normalise_third(V, V3),
    atomic_list_concat([V3, '_', Prep], VJ),
    ( ng_coin(Seed, 4, 50) -> ng_word(place, Seed, 5, Q) ; ng_word(proper, Seed, 5, Q) ).
ng_shape(10, Seed, [P-'S', V3-'R', Q-'O']) :-                              % Alice likes Bob
    ng_word2(proper, Seed, 2, P, Q), ng_word(vt, Seed, 3, V), normalise_third(V, V3).
ng_shape(11, Seed, [every-'Q', C-'S', is-'R', A-'A']) :-                   % Every tenant is exempt
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A).
ng_shape(12, Seed, [P-'S', is-'R', not-'N', Art-'T', N-'O']) :-            % Alice is not a tenant
    ng_word(proper, Seed, 2, P), ng_word(class, Seed, 3, N), ng_art(N, Art).
ng_shape(13, Seed, [P-'S', does-'K', not-'N', V-'R']) :-                   % Alice does not sleep
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V).
ng_shape(14, Seed, [every-'Q', C-'S', V3-'R', Art-'T', N-'O']) :-          % Every employee has a badge
    ng_word(class, Seed, 2, C), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_art(N, Art).
ng_shape(15, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every tenant that is insured owns a car
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(vt, Seed, 4, V), normalise_third(V, V3),
    ng_word(noun, Seed, 5, N), ng_art(N, Art),
    (   ng_coin(Seed, 6, 50)
    ->  Rest = [not-'N', A-'C', V3-'R', Art-'T', N-'O']
    ;   Rest = [A-'C', V3-'R', Art-'T', N-'O']
    ).
ng_shape(16, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every tenant that is not banned is a member
    ng_word2(class, Seed, 2, C, N), ng_word(adj, Seed, 3, A), ng_art(N, Art),
    (   ng_coin(Seed, 4, 50)
    ->  Rest = [not-'N', A-'C', is-'R', Art-'T', N-'O']
    ;   Rest = [A-'C', is-'R', Art-'T', N-'O']
    ).
ng_shape(17, Seed, [P-'S', does-'K', not-'N', VJ-'R', Q-'O']) :-           % Alice does not live_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vpp, Seed, 3, V-Prep),
    atomic_list_concat([V, '_', Prep], VJ),
    ( ng_coin(Seed, 4, 50) -> ng_word(place, Seed, 5, Q) ; ng_word(proper, Seed, 5, Q) ).
ng_shape(18, Seed, [P-'S', V3-'R', the-'T'|Obj]) :-                        % Alice owns the old car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_adjectives(Seed, 4, As), ng_word(noun, Seed, 7, N), append(As, [N-'O'], Obj).
ng_shape(19, Seed, [P-'S', VJ-'R', Q-'O']) :-                              % Alice sleeps_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V), normalise_third(V, V3),
    ng_choose(Seed, 4, [in, at, near], Prep), atomic_list_concat([V3, '_', Prep], VJ),
    ng_word(place, Seed, 5, Q).

%% none, one or two adjectives -- the grammar takes every word between the
%% determiner and the noun as one, and a network shown only one dropped the
%% noun after two
ng_adjectives(Seed, Salt, As) :-
    ng_pick(Seed, Salt, 3, K), Salt1 is Salt + 1, Salt2 is Salt + 2,
    (   K =:= 0 -> As = []
    ;   K =:= 1 -> ng_word(adj, Seed, Salt1, A), As = [A-'A']
    ;   ng_word2(adj, Seed, Salt1, A, B), As = [A-'A', B-'A'], Salt2 > 0
    ).

ng_object(Seed, Salt, [Art-'T'|Obj]) :-
    ng_word(noun, Seed, Salt, N), Salt1 is Salt + 1,
    ng_adjectives(Seed, Salt1, As), append(As, [N-'O'], Obj),
    ( As = [A-_|_] -> ng_art(A, Art) ; ng_art(N, Art) ).

%% ---- the transforms -----------------------------------------------------------------
%% Each takes and gives st(Pairs, CleanSentences): the pairs with their
%% tags, and the list of clean pair-lists the pairs were made from, which
%% `conjoin' extends.

ng_applicable(split_relation, Ps) :- member(W-'R', Ps), sub_atom(W, _, _, _, '_'), !.
ng_applicable(emphatic_do, [_-'S', V3-'R'|Rest]) :-
    ng_base_of(V3, _), ( Rest = [] ; Rest = [_-'T'|_] ; Rest = [_-'O'|_] ), !.
ng_applicable(conjoin, Ps) :- \+ member(_-'B', Ps).
ng_applicable(adverb, Ps) :- member(_-'S', Ps), !.
ng_applicable(hedge_start, _).
ng_applicable(filler_start, _).
ng_applicable(filler_end, _).
ng_applicable(adverb_end, Ps) :- last(Ps, _-'R').           % only after an intransitive verb: a bare
                                                            % word after an object reads as its noun
ng_applicable(pp_place, Ps) :- last(Ps, _-'O'), member(_-'T', Ps), !.   % a place after a noun phrase
ng_applicable(pp_extra, _).

%% the base of an inflected lexicon verb, transitive or not
ng_base_of(V3, V) :- normalise_lexicon(vt, L), member(V, L), normalise_third(V, V3), !.
ng_base_of(V3, V) :- normalise_lexicon(vi, L), member(V, L), normalise_third(V, V3), !.

ng_apply(split_relation, _, st(Ps, Cs), st(Qs, Cs)) :- ng_split_rel(Ps, Qs).
ng_apply(emphatic_do, _, st([S-'S', V3-'R'|Rest], Cs), st([S-'S', does-'D', V-'R'|Rest], Cs)) :- ng_base_of(V3, V).
ng_apply(conjoin, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    S2 is Seed * 31 + 7, ng_sentence(S2, Qs),
    ( ng_coin(Seed, 25, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    append([Ps, Join, Qs], Out), append(Cs, [Qs], Cs2).
ng_apply(adverb, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 21, [really, always, clearly, still, often, also, just, probably, usually, now,
                         definitely, certainly, actually, simply, already], Adv),
    ng_after_subject(Ps, Adv-'D', Out).
ng_apply(hedge_start, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 26, [['I', think, that], ['I', believe, that], ['I', know, that], [it, seems, that],
                         [we, know, that], [you, said, that], [it, is, clear, that], ['I', heard, that]], F),
    ng_dropped(F, Fs), append(Fs, Ps, Out).
ng_apply(filler_start, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 22, [[in, fact], [well], [actually], [in, short], [of, course], [to, be, honest],
                         [as, far, as, 'I', know], [by, the, way], [anyway], [so], [also], [then],
                         [honestly], [frankly], [as, 'I', said], [after, all], [for, example], [in, any, case]], F),
    ng_dropped(F, Fs), append(Fs, [','-'D'|Ps], Out).
ng_apply(filler_end, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 23, [[obviously], [of, course], ['I', think], [apparently], [for, sure],
                         [as, far, as, 'I', know], [to, be, honest], ['I', believe], [no, doubt],
                         [as, usual], ['I', guess], [you, know], [it, seems], ['I', suppose], [clearly]], F),
    ng_dropped(F, Fs), append(Ps, [','-'D'|Fs], Out).
ng_apply(adverb_end, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 27, [now, today, often, again, too, here, there, later, well, early], Adv),
    append(Ps, [Adv-'D'], Out).
ng_apply(pp_place, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 28, [in, at, near], Prep), ng_word(place, Seed, 29, Place),
    append(Ps, [Prep-'D', Place-'D'], Out).
ng_apply(pp_extra, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 24, [[at, home], [on, 'Monday'], [in, the, morning], [for, now], [at, night],
                         [on, 'Friday'], [in, the, evening], [at, work], [at, the, moment], [for, a, while],
                         [as, usual], [for, sure], [in, general], [at, first], [on, time], [by, now],
                         [in, the, end], [at, last], [on, the, whole], [in, practice]], F),
    ng_dropped(F, Fs), append(Ps, Fs, Out).

ng_dropped([], []).
ng_dropped([W|Ws], [W-'D'|Ds]) :- ng_dropped(Ws, Ds).

ng_split_rel([], []).
ng_split_rel([W-'R'|Ps], Out) :-
    sub_atom(W, _, _, _, '_'), !,
    atomic_list_concat(Parts, '_', W),
    findall(P-'R', member(P, Parts), Rs),
    append(Rs, Qs, Out), ng_split_rel(Ps, Qs).
ng_split_rel([P|Ps], [P|Qs]) :- ng_split_rel(Ps, Qs).

ng_after_subject([W-'S'|Ps], X, [W-'S', X|Ps]) :- !.
ng_after_subject([P|Ps], X, [P|Qs]) :- ng_after_subject(Ps, X, Qs).

%% ---- a pair, and a corpus ------------------------------------------------------------

normalise_pair(Seed, Pair) :- normalise_pair(Seed, [], Pair).

normalise_pair(Seed, Options, pair(Noisy, Tokens, Tags, Clean, Applied)) :-
    ng_sentence(Seed, Clean0),
    ( memberchk(transforms(Cands), Options) -> true ; normalise_transforms(Cands) ),
    ( memberchk(always(true), Options) -> Always = yes ; Always = no ),
    normalise_transforms(Order),
    ng_run(Order, Cands, Always, Seed, 100, st(Clean0, [Clean0]), st(Noisy0, Cleans), Applied),
    ng_text_of(Noisy0, Noisy),
    findall(T, member(_-T, Noisy0), Tags),
    findall(CT, ( member(CP, Cleans), ng_text_of(CP, CT) ), CTs),
    atomic_list_concat(CTs, ' ', Clean),
    reason_tokens(Noisy, Toks0), append(Tokens, ['.'], Toks0).

%% a transform's chance, per pair: a coin at 35 for noise, and the split
%% ALWAYS, because `lives_in' is the grammar's spelling and nobody types
%% it -- the two-word form is the only one a tagger will meet
ng_rate(split_relation, 100) :- !.
ng_rate(_, 35).

ng_run([], _, _, _, _, S, S, []).
ng_run([T|Ts], Cands, Always, Seed, Salt, S0, S, Applied) :-
    S0 = st(Ps0, _),
    (   memberchk(T, Cands), ng_applicable(T, Ps0),
        ( Always == yes -> true ; ng_rate(T, Rate), ng_coin(Seed, Salt, Rate) )
    ->  ng_apply(T, Seed, S0, S1), Applied = [T|More]
    ;   S1 = S0, Applied = More
    ),
    Salt1 is Salt + 1,
    ng_run(Ts, Cands, Always, Seed, Salt1, S1, S, More).

normalise_corpus(N, Pairs) :- normalise_corpus(N, [], Pairs).
normalise_corpus(N, Options, Pairs) :-
    findall(P, ( between(1, N, I), normalise_pair(I, Options, P) ), Pairs).

%% ---- text from words ---------------------------------------------------------------------
%% The first word capitalised, a comma attached to the word before it, a
%% stop at the end.

ng_text_of(Pairs, Text) :- findall(W, member(W-_, Pairs), Ws), ng_text(Ws, Text).

ng_text(Words, Text) :-
    ng_text_(Words, first, Parts),
    atomic_list_concat(Parts, Body), atom_concat(Body, '.', Text).

ng_text_([], _, []).
ng_text_([','|Ws], _, [','|Ps]) :- !, ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], first, [C|Ps]) :- !, ng_cap(W, C), ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], rest, [' ', W|Ps]) :- ng_text_(Ws, rest, Ps).

ng_cap(W, C) :-
    atom_codes(W, [F|R]),
    ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ),
    atom_codes(C, [F1|R]).

%% ---- the assembler -------------------------------------------------------------------------
%% D dropped, an R run joined with `_', B a break; a word keeps the case
%% its token carries, so a proper noun stays one. A comma is never emitted.

normalise_assemble(Tokens, Tags, Text) :-
    na_zip(Tokens, Tags, Zs),
    na_split(Zs, Sents),
    na_texts(Sents, Texts),
    atomic_list_concat(Texts, ' ', Text).

na_zip([], [], []).
na_zip([T|Ts], [G|Gs], [T-G|Zs]) :- na_zip(Ts, Gs, Zs).

na_split([], []) :- !.
na_split(Zs, [S|Ss]) :- na_upto_b(Zs, S, Rest), na_split(Rest, Ss).

na_upto_b([], [], []).
na_upto_b([_-'B'|Zs], [], Zs) :- !.
na_upto_b([Z|Zs], [Z|S], Rest) :- na_upto_b(Zs, S, Rest).

na_texts([], []).
na_texts([S|Ss], Ts) :-
    na_words(S, Ws),
    ( Ws == [] -> Ts = Ts1 ; ng_text(Ws, T), Ts = [T|Ts1] ),
    na_texts(Ss, Ts1).

na_words([], []).
na_words([_-'D'|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([','-_|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([word(W, _)-'R'|Zs], [J|Ws]) :- !,
    na_run(Zs, Rs, Rest), atomic_list_concat([W|Rs], '_', J), na_words(Rest, Ws).
na_words([word(W, upper)-_|Zs], [C|Ws]) :- !, ng_cap(W, C), na_words(Zs, Ws).
na_words([word(W, lower)-_|Zs], [W|Ws]) :- na_words(Zs, Ws).

na_run([word(W, _)-'R'|Zs], [W|Rs], Rest) :- !, na_run(Zs, Rs, Rest).
na_run(Zs, [], Zs).
