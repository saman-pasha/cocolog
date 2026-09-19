%% library(reasoning/tagger) -- the network that labels typed text for the
%% grammar, held to what the grammar then reads: the pure half (vocabulary,
%% encoding, tag ids, the padding plan) on any box, and where library(torch)
%% is built a training, its accuracy on sentences it never saw, FORTY-THREE
%% HAND-WRITTEN SENTENCES whose names, nouns, adjectives and verbs are
%% outside the lexicon, a paragraph of such prose put to truth/2, and a
%% model one process trains and the next loads.
%%
%%     cocolog -s test/tagger.pl        from the checkout root
%%
%% The network section is a SECTION, not the case: without library/torch.so
%% it says so, indented, and the pure half still decides.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/tagger)).

main :-
    alphabet, vocabulary, encoding, padding, network,
    checks_done.

%% ---- the tag ids are the alphabet's order ---------------------------------------

alphabet :-
    section('alphabet'),
    tagger_tag_id('S', S), check('S is 0', S, 0),
    tagger_tag_id('B', B), check('B is 10', B, 10),
    tagger_tag_id(Nine, 9), check('9 is D, the tag padding carries', Nine, 'D'),
    normalise_tags(Tags),
    findall(I, ( member(T, Tags), tagger_tag_id(T, I) ), Ids), sort(Ids, Distinct),
    check('eleven tags, ids 0..10, all distinct', Distinct, [0,1,2,3,4,5,6,7,8,9,10]).

%% ---- the vocabulary -----------------------------------------------------------------

vocabulary :-
    section('vocabulary'),
    normalise_corpus(64, Pairs),
    tagger_vocabulary(Pairs, V), tagger_vocabulary(Pairs, V2),
    check('deterministic: the same pairs, the same vocabulary', V, V2),
    tagger_size(V, NV), yes_no(NV > 50, Big),
    check('64 pairs give more than 50 words', Big, yes),
    tagger_word_id(V, zed, Z), check('a word not in it is 1, <unk>', Z, 1),
    tagger_word_id(V, ',', C), check('the comma is a word, and sorts first: 2', C, 2),
    findall(W, ( member(pair(_, Toks, _, _, _), Pairs), member(word(W, _), Toks) ), Ws), sort(Ws, Words),
    findall(W, ( member(W, Words), tagger_word_id(V, W, Id), ( Id < 2 ; Id >= NV ) ), Out),
    check('every word of the pairs has an id from 2 up to the size', Out, []),
    findall(A-B, ( member(W, Words), tagger_word_id(V, W, A), member(W2, Words), W2 \== W, tagger_word_id(V, W2, B), A == B ), Dup),
    check('and no two words share one', Dup, []).

%% ---- the encoding ----------------------------------------------------------------------

encoding :-
    section('encoding'),
    normalise_corpus(64, Pairs), tagger_vocabulary(Pairs, V),
    tagger_encode(V, [word(alice, upper), word(owns, lower), ',', word(zed, upper)], Ids, Shapes),
    check('shapes: upper 2, lower with -s 4, comma 3, upper with -ed 14 (Zed ends in ed)', Shapes, [2, 4, 3, 14]),
    tagger_encode(V, [word(wholly, lower), word(walking, lower), word(walked, lower), word(cars, upper)], _, Shapes2),
    check('the ending in the shape: -ly 7, -ing 10, -ed 13, and upper with -s 5', Shapes2, [7, 10, 13, 5]),
    Ids = [A, O, C, Z],
    tagger_word_id(V, alice, A1), check('alice by its id', A, A1),
    tagger_word_id(V, owns, O1), check('owns by its id', O, O1),
    check('the comma by its id', C, 2),
    check('Zed, never seen, is <unk>', Z, 1),
    tagger_encode(V, [word(alice, lower)], [A2], [S2]),
    check('the case is the shape, not the word: alice lower has the same id', A2, A1),
    check('and shape 1', S2, 1).

%% ---- the padding plan ---------------------------------------------------------------------

padding :-
    section('padding'),
    tagger_pad([seq([5, 6, 7], [2, 1, 1], [0, 4, 8]), seq([9], [2], [0])], Plan),
    Plan = plan(N, M, IdRows, ShapeRows, MaskRows, Flat),
    check('two sequences', N, 2),
    check('three positions, the longest', M, 3),
    check('ids position-major, padding 0', IdRows, [[5, 9], [6, 0], [7, 0]]),
    check('shapes likewise', ShapeRows, [[2, 2], [1, 0], [1, 0]]),
    check('the mask 1.0 inside a sequence and 0.0 past its end, as rows', MaskRows, [[[1.0], [1.0]], [[1.0], [0.0]], [[1.0], [0.0]]]),
    check('the gold tags position-major, D (9) where there is padding', Flat, [0, 0, 4, 9, 8, 9]),
    tagger_pad([seq([5, 6], [1, 1], none)], plan(_, _, _, _, _, Flat2)),
    check('no gold at all is D throughout', Flat2, [9, 9]).

%% ---- the network -------------------------------------------------------------------------------

network :-
    section('network'),
    (   exists_file('library/torch.so')
    ->  network_checks
    ;   format("     (skipped: no library/torch.so -- sh modules/torch/build.sh against libtorch)~n", [])
    ).

network_checks :-
    get_time(T0), tagger_train(tg_case, []), get_time(T1), Secs is T1 - T0,
    format("     trained with the defaults in ~1f s~n", [Secs]),
    tagger_load(tg_case, M),
    tagger_evaluate(M, 30001, 300, report(Tok, Sent, Acc, N)),
    format("     on 300 pairs training never saw, seeds past the corpus: tokens ~4f, sentences ~4f, accepted ~4f~n", [Tok, Sent, Acc]),
    check('evaluated 300', N, 300),
    yes_no(Tok >= 0.97, TokOk), check('at least 0.97 of the tags right', TokOk, yes),
    yes_no(Sent >= 0.90, SentOk), check('at least 0.90 of the sentences wholly right', SentOk, yes),
    yes_no(Acc >= 0.90, AccOk), check('at least 0.90 assemble and parse to the clean terms', AccOk, yes),
    reason_tokens('Well, Zed really owns a red car, obviously.', Toks0), append(Toks, ['.'], Toks0),
    tagger_tag(M, Toks, Tags),
    check('a noisy sentence with a name never seen, tagged', Tags, ['D', 'D', 'S', 'D', 'R', 'T', 'A', 'O', 'D', 'D']),
    normalise_assemble(Toks, Tags, Asm),
    check('and assembled', Asm, 'Zed owns a red car.'),
    ( tagger_normalise(M, 'Well, Zed really owns a red car, obviously. In fact, Eve does not like Zed.', C, Terms) -> true ; C = refused, Terms = refused ),
    check('two sentences of prose, controlled', C, 'Zed owns a red car. Eve does not like Zed.'),
    check('and read', Terms, [car(car_1), red(car_1), own(zed, car_1), neg(like(eve, zed))]),
    ( tagger_normalise(M, 'Bob needs a ladder.', _, T2) -> true ; T2 = refused ),
    check('a noun never seen is copied', T2, [ladder(ladder_1), need(bob, ladder_1)]),
    yes_no(tagger_normalise(M, 'The dog sleeps.', _, _), Def),
    check('a definite subject is no shape of the generator: refused, not misread', Def, no),
    prose_checks(M),
    paragraph(M),
    tagger_free(M),
    across_processes.

%% ---- prose it never saw ------------------------------------------------------------------------
%% Hand-written, not generated: the names, and many of the nouns, adjectives
%% and verbs, are outside the lexicon, in every shape the grammar reads and
%% with the noise typed prose carries. Each should give the terms a careful
%% reader would write, up to the names of a rule's variables; every miss is
%% printed by name, and the floor is forty-one of the forty-three, because
%% over a lexicon of thousands two trainings do not miss the same sentence
%% -- measured, one missed `works hard' and the next `may enter the ward' --
%% and a pin on all of them would be a pin on the coin.

prose('Zed owns a bicycle.', [bicycle(bicycle_1), own(zed, bicycle_1)]).
prose('Mia is clever.', [clever(mia)]).
prose('Omar is a doctor.', [doctor(omar)]).
prose('Nadia is not tired.', [neg(tired(nadia))]).
prose('Lars does not own a truck.', [neg(own(lars, truck))]).
prose('Priya snores.', [snore(priya)]).
prose('Kai may drive the truck.', [may_drive(kai, truck)]).
prose('Every pilot is a person.', [(person(X) :- pilot(X))]).
prose('Every nurse that is not banned may enter the ward.', [(may_enter(X, ward) :- nurse(X), \+ banned(X))]).
prose('Every guard that is armed must guard the gate.', [(must_guard(X, gate) :- guard(X), armed(X))]).
prose('Ola lives in Lagos.', [lives_in(ola, lagos)]).
prose('Tom likes Ana.', [like(tom, ana)]).
prose('Yuki admires Tom.', [admire(yuki, tom)]).
prose('Well, Zed really owns a bicycle, obviously.', [bicycle(bicycle_1), own(zed, bicycle_1)]).
prose('In fact, Mia is clever, I think.', [clever(mia)]).
prose('Omar does own a truck.', [truck(truck_1), own(omar, truck_1)]).
prose('Nadia is tired and Lars is happy.', [tired(nadia), happy(lars)]).
prose('Actually, every pilot that is careful may fly the plane in the morning.', [(may_fly(X, plane) :- pilot(X), careful(X))]).
prose('Priya works at home.', [work(priya)]).
prose('Kai clearly does not like Tom.', [neg(like(kai, tom))]).
prose('Of course, Ana should sell the boat.', [should_sell(ana, boat)]).
prose('Hugo rents an old flat in Rome.', [flat(flat_1), old(flat_1), rent(hugo, flat_1)]).
prose('Every diver that is not certified must wear the vest, of course.', [(must_wear(X, vest) :- diver(X), \+ certified(X))]).
prose('Ida is a nurse and Ida is careful.', [nurse(ida), careful(ida)]).
prose('Noor buys a small blue lamp.', [lamp(lamp_1), small(lamp_1), blue(lamp_1), buy(noor, lamp_1)]).
prose('Rex drives the big red truck.', [drive(rex, truck)]).
prose('Mila waits at Oslo.', [waits_at(mila, oslo)]).
prose('Every teacher has a badge.', [(have(X, badge) :- teacher(X))]).
prose('Rex sleeps and Rex is not hungry.', [sleep(rex), neg(hungry(rex))]).
prose('Apparently, Bo does not drive.', [neg(drive(bo))]).
prose('Vera can read the map.', [can_read(vera, map)]).
prose('Every robot that is active may open the door.', [(may_open(X, door) :- robot(X), active(X))]).
prose('Every clerk is careful.', [(careful(X) :- clerk(X))]).
prose('Ana is not a pilot.', [neg(pilot(ana))]).
prose('Bo does not snore.', [neg(snore(bo))]).
prose('Every pilot owns a plane.', [(own(X, plane) :- pilot(X))]).
prose('Every nurse that is certified holds a badge.', [(hold(X, badge) :- nurse(X), certified(X))]).
prose('Kai does not live in Lagos.', [neg(live_in(kai, lagos))]).
prose('Tom likes the old map.', [like(tom, map)]).
prose('Wolf will fix the drone.', [will_fix(wolf, drone)]).
prose('I think that Zed sleeps in Tokyo.', [sleeps_in(zed, tokyo)]).
prose('By the way, every farmer that is not insured needs a permit, as far as I know.', [(need(X, permit) :- farmer(X), \+ insured(X))]).
prose('Well, every baker that is not lazy works hard, obviously.', [(work(X) :- baker(X), \+ lazy(X))]).

prose_checks(M) :-
    findall(T-W, prose(T, W), Ps), length(Ps, N),
    findall(T, ( member(T-W, Ps), \+ ( tagger_normalise(M, T, _, Got), variant(Got, W) ) ), Bad),
    forall(member(T, Bad),
           (   tagger_normalise(M, T, C, G)
           ->  format("     MISREAD  ~w~n              as ~w~n              ~q~n", [T, C, G])
           ;   format("     REFUSED  ~w~n", [T])
           )),
    length(Bad, NB), Ok is N - NB,
    format("     ~w of ~w hand-written sentences give their terms~n", [Ok, N]),
    Floor is N - 2, yes_no(Ok >= Floor, Enough),
    check('at least forty-one of the forty-three hand-written sentences give their terms', Enough, yes).

%% variants: the same term up to the names of its variables
variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), number_vars(Va, 0),
    term_variables(B1, Vb), number_vars(Vb, 0),
    A1 == B1.
number_vars([], _).
number_vars(['$v'(N)|Vs], N) :- N1 is N + 1, number_vars(Vs, N1).

%% ---- a paragraph, and then questions --------------------------------------------------------------
%% What the loop is for: prose in, terms asserted, truth/2 answering --
%% including a rule from the prose applied to a fact from the prose. The
%% paragraph is plain on purpose: the noise is the prose section's business
%% and its floor, and this section pins the reading exactly.

paragraph(M) :-
    Prose = 'Zed owns a bicycle. Mia is a nurse and Mia is careful. Every nurse that is careful may enter the ward. Omar does not like Zed. Ola lives in Lagos.',
    ( tagger_normalise(M, Prose, C, Terms) -> true ; C = refused, Terms = [] ),
    check('a paragraph of five sentences, controlled', C,
          'Zed owns a bicycle. Mia is a nurse. Mia is careful. Every nurse that is careful may_enter the ward. Omar does not like Zed. Ola lives_in Lagos.'),
    length(Terms, NT), check('seven terms', NT, 7),
    forall(member(T, Terms), assertz(T)),
    truth(own(zed, bicycle_1), V1), check('truth: Zed owns the bicycle', V1, true),
    truth(may_enter(mia, ward), V2), check('truth: Mia may enter the ward -- a rule over two facts, all from the prose', V2, true),
    truth(like(omar, zed), V3), check('truth: Omar likes Zed -- denied', V3, false),
    truth(like(zed, omar), V4), check('truth: Zed likes Omar -- never said', V4, unknown),
    truth(lives_in(ola, lagos), V5), check('truth: Ola lives in Lagos', V5, true).

%% one process trains into a store and asserts what it tagged; the next loads
%% the model from the store and tags the same sentence -- the knowledge base
%% is the model file, which an in-process check cannot claim
across_processes :-
    scratch(Dir),
    atom_concat(Dir, '/KB', KB),
    atom_concat(Dir, '/train.pl', Train),
    atom_concat(Dir, '/load.pl', Load),
    fixture(Train, [
        ':- use_module(library(reasoning/tagger)).',
        'main :- tagger_train(tg_shared, [pairs(128), steps(60), batch(64)]), tagger_load(tg_shared, M),',
        '    reason_tokens(''Actually, Mia really likes Zed, obviously.'', T0), append(T, [''.''], T0),',
        '    tagger_tag(M, T, Tags), assertz(tg_expected(Tags)), tagger_free(M), write(trained), nl.' ]),
    fixture(Load, [
        ':- use_module(library(reasoning/tagger)).',
        'main :- tagger_load(tg_shared, M),',
        '    reason_tokens(''Actually, Mia really likes Zed, obviously.'', T0), append(T, [''.''], T0),',
        '    tagger_tag(M, T, Tags), tg_expected(Want), write(Tags), nl,',
        '    ( Tags == Want -> write(''tags-agree'') ; write(''tags-differ'') ), nl,',
        '    catch(( tagger_load(nosuch, _), write(loaded) ), error(existence_error(tagger, nosuch), _), write(absent)), nl,',
        '    tagger_free(M).' ]),
    sh_join(['--embed ', KB, ' -s ', Train], A1), cocolog_out(A1, O1),
    yes_no(sub_atom(O1, _, _, _, trained), Trained),
    check('a process trains into a store', Trained, yes),
    sh_join(['--embed ', KB, ' -s ', Load], A2), cocolog_out(A2, O2),
    yes_no(sub_atom(O2, _, _, _, 'tags-agree'), Agree),
    check('the next process loads the model and tags the sentence the same', Agree, yes),
    yes_no(sub_atom(O2, _, _, _, absent), Absent),
    check('and a name nothing saved under is existence_error(tagger, Name)', Absent, yes),
    sh_join(['rm -rf ', Dir], Rm), shell(Rm, _, _).
