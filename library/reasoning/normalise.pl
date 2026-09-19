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
%% intransitive verb (D), a prepositional adjunct (D), a relation written
%% as two words (R R, to be joined), an
%% emphatic `does' (D), two sentences joined by `and' (B, a boundary), and
%% a filler or a hedge right after that `and' (D) -- the position typed
%% prose puts them in and the generator did not, until `Priya is a baker
%% and, as far as I know, Priya is licensed' tagged the `and' as an object;
%% and a second fact about the SAME subject joined by `and', its subject
%% left out (`Priya is a baker and is licensed') or a pronoun (`and she is
%% licensed'). The assembler supplies the subject a break left out, and the
%% grammar resolves the pronoun: state carried from sentence to sentence.
%% Every transform is one the assembler can undo by dropping, joining or
%% splitting -- and none changes a word's FORM, because a tag cannot: a
%% plural, a passive, a pronoun are not in this set, and this header says
%% so rather than leaving it to be found.
%%
%% TWO KINDS OF NOISE ARE KEPT OUT ON PURPOSE, measured against the
%% grammar. A bare word after an indefinite object -- `owns a car too',
%% `owns a car now' -- is not refused but MISREAD, as the noun of the
%% phrase, so an adverb goes at the end only after an intransitive verb.
%% And a place is NEVER noise. After an intransitive verb -- `works in
%% Rome' -- it is the relation work_in, shape 9 with a phrasal verb, and
%% dropping it once taught the network to drop `lives in Lagos' too. After
%% an object -- `rents a flat in Rome' -- it is the third argument of
%% rent_in, shapes 23 to 26; while a transform dropped it there the network
%% dropped `rents a flat in Bristol' to `rents a flat'. So no transform
%% appends a preposition and a proper noun, and pp_extra's adjuncts are
%% lower-case throughout (`at home', never `on Monday'), because a
%% capitalised word after a preposition after an object is a place the
%% grammar reads.
%%
%% AND QUESTIONS ARE SHAPES TOO, ten of the forty-one: `Does Alice own a
%% car?', `Is Alice happy?', `May Alice use the server?', `Who owns a car?',
%% `What does Alice own?', `Where does Alice sleep?', `Does Alice pay 500
%% euros?', `How much does Alice pay?', `How many euros does Alice pay?',
%% `How much is the rent?'. The tags are the statements' -- `who' is the
%% subject asked for, `what', `where' and `how much' the object -- so the
%% assembler copies them where they stand, the text ends in `?', and the
%% grammar reads a goal with a variable there.
%%
%% AND QUANTITIES ARE EIGHT SHAPES: `Alice pays 500 euros', `Alice buys
%% two litres of milk', `Every tenant must pay 500 euros', `The rent is 500
%% euros' (the one definite subject the grammar reads), `Alice does not pay
%% 500 euros', and the three questions above. A number is a determiner to
%% the tagger -- T before the noun it counts, digits or the number words
%% (`twenty five', `a hundred'), the `of' of `two litres of milk' a K --
%% and the assembler copies it where it stands, so the grammar reads
%% quantity(500, euros). The nouns are units (lexicon/unit.txt, WordNet's
%% units of measurement and of time) and things, pluralised by the
%% inflector, because a plural is the form a number takes.
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
%%     normalise_negatives(+From, +N, -Pairs)
%%         N real sentences from prose.txt beside the lexicon -- WordNet's own
%%         example sentences, in a fixed hash order -- from the From-th, as
%%         pairs whose every tag is X and whose Clean is `none': what a
%%         tagger must REFUSE, and what tagger_refused/4 measures it
%%         against. A seventh of them the grammar reads as they are, nearly
%%         all two words -- `Vulpine cunning.' as the Name-verb fact
%%         cunning(vulpine) -- which is why a tagging is judged by the
%%         lexicon and not by the grammar alone.
%%
%%     normalise_assemble(+Tokens, +Tags, -Text)
%%         The inverse: D dropped, a run of R joined with `_', B a sentence
%%         break -- and a sentence the break leaves with no S takes the
%%         subject phrase of the one before it -- everything else copied in
%%         its case; each sentence
%%         capitalised and stopped. What the tagger's output is handed to,
%%         and what the round trip below holds the tags to.
%%
%%     normalise_third(+Base, -ThirdPerson)             the inflector, which
%%                                                     library(reasoning/reason)'s stemmer must invert
%%     normalise_tags(-Tags)                           the alphabet, closed
%%     normalise_transforms(-Names)                    the transforms, by name
%%     normalise_lexicon(+Class, -Words)               proper, noun, class, adj, vt, vi, vpp,
%%                                                     adverb, place, unit -- the files beside
%%                                                     this one, filtered by the grammar; and
%%                                                     modal, the grammar's own
%%     normalise_lexicon_dir(-Dir)                     where the files were found
%%
%% ---- THE TAGS ---------------------------------------------------------
%%
%%     S  the subject head      Q  a quantifier (every)      C  the condition's adjective
%%     R  a relation word       K  a structural word kept as it is: `that', `does',
%%                                 the copula inside a relative clause
%%     N  not                   T  a determiner               A  an adjective
%%     O  the object head       D  drop                       B  a sentence boundary
%%     X  OUTSIDE: not a sentence of the grammar's at all -- the tag a tagger
%%        gives real prose it cannot normalise, and the assembler refuses
%%
%% Only D, R and B change what the assembler emits; the rest are copied,
%% and X is refused. The generator never emits X: a tagging comes back X
%% throughout when library(reasoning/tagger)'s lexicon rules contradict it,
%% and normalise_negatives/3 hands out real sentences tagged X throughout to
%% measure that against. Without a no the first tagger labelled `Boston,
%% Mass.' S R and the grammar read mass(boston); taught to the network as a
%% twelfth label it cost a tenth of what the tagger should read, so the no
%% is the lexicon's.
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

normalise_tags(['S', 'Q', 'C', 'N', 'R', 'K', 'T', 'A', 'O', 'D', 'B', 'X']).

%% in the order they are applied: the split before the emphatic (so a
%% split relation is not also a candidate for `does'), the join before the
%% fillers (so a filler or a hedge wraps the whole; filler_join conjoins
%% itself when nothing has, and puts its filler after the `and'), the tails
%% last -- an adverb after an intransitive verb, a prepositional adjunct
%% after anything
normalise_transforms([split_relation, emphatic_do, conjoin, conjoin_shared, filler_join, adverb, hedge_start, filler_start,
                      filler_end, adverb_end, pp_extra]).

%% ---- the lexicon: files beside this one, read when first asked for ---------
%%
%% library/reasoning/lexicon/<class>.txt, one word a line, commonest first:
%% `proper' is the US Census's first names; noun, class, adj, vt, vi, vpp,
%% adverb, place and unit are WordNet 3.0 ranked by its SemCor tag counts,
%% and prose is WordNet's example sentences, real English, for
%% normalise_negatives/3 --
%% written by tools/lexicon/build.pl (cocolog, not Python: the parse of
%% WordNet's files is a DCG's job). SOURCES.md beside them says where each
%% came from and under what licence. NO WORD LIVES IN THIS FILE.
%%
%% The files are read the first time a word is asked for, held as globals
%% of this machine -- never asserted, so a knowledge base is never written
%% -- and FILTERED BY THE GRAMMAR as they load: a word library(reasoning/reason)
%% treats as closed is dropped (`will' is a modal before it is a name), and
%% a verb whose third person does not come back to it through the stemmer
%% is dropped, so the inflection round trip holds by construction. Modals
%% are the grammar's own, asked of rl_modal/1. $COCOLOG_LEXICON names
%% another directory; otherwise it is `reasoning/lexicon' under the first
%% library directory that has one -- $COCOLOG_LIBRARY, ./library, the
%% binary's own.

normalise_lexicon_dir(Dir) :-
    getenv('COCOLOG_LEXICON', Dir), Dir \== '', exists_directory(Dir), !.
normalise_lexicon_dir(Dir) :-
    ng_library_dirs(Ds), member(D, Ds),
    atom_concat(D, '/reasoning/lexicon', Dir), exists_directory(Dir), !.

ng_library_dirs(Ds) :-
    (   getenv('COCOLOG_LIBRARY', Env), Env \== ''
    ->  atomic_list_concat(Env0, ':', Env)
    ;   Env0 = []
    ),
    (   current_prolog_flag(executable, Exe),
        atomic_list_concat(Parts, '/', Exe), append(DirParts, [_], Parts), DirParts \== []
    ->  atomic_list_concat(DirParts, '/', ExeDir), atom_concat(ExeDir, '/library', ExeLib), Extra = [ExeLib]
    ;   Extra = []
    ),
    append(Env0, [library|Extra], Ds1),
    findall(D, ( member(D, Ds1), D \== '' ), Ds).

ng_class(proper). ng_class(noun). ng_class(class). ng_class(adj). ng_class(vt).
ng_class(vi). ng_class(vpp). ng_class(adverb). ng_class(place). ng_class(unit). ng_class(prose).
ng_class(known_noun). ng_class(known_verb). ng_class(known_adj). ng_class(known_adverb).   % the judge's, not the generator's

normalise_lexicon(modal, Ms) :- !, findall(M, rl_modal(M), Ms).
normalise_lexicon(Class, Words) :-
    ng_class(Class), ng_ensure_lexicon, ng_key(list, Class, K), nb_getval(K, Words).

ng_ensure_lexicon :- catch(nb_getval('$lx_ready', yes), _, fail), !.
ng_ensure_lexicon :-
    (   normalise_lexicon_dir(Dir)
    ->  true
    ;   throw(error(existence_error(directory, 'reasoning/lexicon'), normalise_lexicon/2))
    ),
    forall(ng_class(Class), ng_load_class(Dir, Class)),
    nb_setval('$lx_ready', yes).

ng_load_class(Dir, Class) :-
    atomic_list_concat([Dir, '/', Class, '.txt'], Path),
    (   exists_file(Path)
    ->  true
    ;   throw(error(existence_error(source_sink, Path), normalise_lexicon/2))
    ),
    read_file_to_codes(Path, Codes),
    split_string(Codes, [10], [32, 13, 9], Lines),
    findall(W, ( member(L, Lines), string_length(L, Len), Len > 0,
                 \+ sub_string(L, 0, 1, _, "#"),
                 atom_string(W, L), ng_keep(Class, W) ), Words),
    length(Words, N),
    ng_key(size, Class, KS), nb_setval(KS, N),
    ng_key(list, Class, KL), nb_setval(KL, Words),
    ng_blocks(Words, Class, 0).

%% what the grammar will not read as an open word is not generated; a line
%% of prose is kept as it is
ng_keep(prose, _) :- !.
ng_keep(Class, W) :- ng_known(Class), !, downcase_atom(W, Lower), \+ rl_closed(Lower).   % known to the judge: no round trip asked
ng_keep(Class, W) :-
    downcase_atom(W, Lower), \+ rl_closed(Lower),
    (   memberchk(Class, [vt, vi, vpp])
    ->  normalise_third(W, Third), rs_base(Third, W)
    ;   true
    ).

%% blocks of a hundred, one global each, so a pick copies a hundred cells
%% and not the class
ng_blocks([], _, _) :- !.
ng_blocks(Words, Class, B) :-
    (   length(Chunk, 100), append(Chunk, Rest, Words) -> true ; Chunk = Words, Rest = [] ),
    T =.. [w|Chunk], ng_key(B, Class, K), nb_setval(K, T),
    B1 is B + 1, ng_blocks(Rest, Class, B1).

ng_key(Tag, Class, Key) :- atomic_list_concat(['$lx_', Tag, '_', Class], Key).

ng_size(Class, N) :- ng_ensure_lexicon, ng_key(size, Class, K), nb_getval(K, N).
ng_nth(Class, K, W) :-
    B is K // 100, I is K mod 100 + 1,
    ng_key(B, Class, Key), nb_getval(Key, T), arg(I, T, W).

%% ---- the inflector ---------------------------------------------------------
%% Third person singular, and library(reasoning/reason)'s rs_base/2 must give the
%% base back: -es after ss, sh, ch, x, z, o; -ies for a consonant and y; -s
%% otherwise; `has' by name. The two are one pair, changed together. A
%% regular PLURAL is the same three rules (euro -> euros, inch -> inches,
%% penny -> pennies), so ng_plural/2 is this inflector; an irregular one
%% (foot, child) comes out wrong and does no harm, since the grammar takes
%% a noun as written and the tagger learns the shape, not the word.

normalise_third(have, has) :- !.
normalise_third(B, T) :- ng_es_stem(B), !, atom_concat(B, es, T).
normalise_third(B, T) :- ng_y_stem(B, Stem), !, atom_concat(Stem, ies, T).
normalise_third(B, T) :- atom_concat(B, s, T).

ng_plural(N, P) :- normalise_third(N, P).

ng_es_stem(B) :- sub_atom(B, _, 2, 0, ss), !.
ng_es_stem(B) :- sub_atom(B, _, 2, 0, sh), !.
ng_es_stem(B) :- sub_atom(B, _, 2, 0, ch), !.
ng_es_stem(B) :- sub_atom(B, _, 1, 0, x), !.
ng_es_stem(B) :- sub_atom(B, _, 1, 0, z), !.
ng_es_stem(B) :- sub_atom(B, _, 1, 0, o).

%% a consonant and y: carry -> carries; a vowel and y (play) takes -s
ng_y_stem(B, Stem) :-
    sub_atom(B, _, 1, 0, y), sub_atom(B, 0, _, 1, Stem),
    sub_atom(Stem, _, 1, 0, C), \+ memberchk(C, [a, e, i, o, u]).

%% ---- deterministic noise -----------------------------------------------------

ng_noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S).
ng_pick(Seed, Salt, N, K) :- J is Seed * 7 + Salt, ng_noise(J, R), K is truncate(abs(R) * N).
ng_choose(Seed, Salt, List, X) :- length(List, N), ng_pick(Seed, Salt, N, K), nth0(K, List, X).
ng_coin(Seed, Salt, PercentYes) :- ng_pick(Seed, Salt, 100, K), K < PercentYes.

ng_word(vpp, Seed, Salt, V-Prep) :- !,
    ng_size(vpp, N), ng_pick(Seed, Salt, N, K), ng_nth(vpp, K, V),
    Salt2 is Salt + 70, ng_choose(Seed, Salt2, [in, at, to, with, for, from, on], Prep).
ng_word(modal, Seed, Salt, M) :- !, normalise_lexicon(modal, Ms), ng_choose(Seed, Salt, Ms, M).
ng_word(Class, Seed, Salt, W) :-
    ng_size(Class, N), ng_pick(Seed, Salt, N, K), ng_nth(Class, K, W).
ng_word2(Class, Seed, Salt, W1, W2) :-
    ng_size(Class, N), ng_pick(Seed, Salt, N, K1),
    Salt2 is Salt + 50, ng_pick(Seed, Salt2, N, K2a),
    ( K2a =:= K1 -> K2 is (K1 + 1) mod N ; K2 = K2a ),
    ng_nth(Class, K1, W1), ng_nth(Class, K2, W2).

ng_art(W, an) :- atom_codes(W, [C|_]), memberchk(C, [0'a, 0'e, 0'i, 0'o, 0'u]), !.
ng_art(_, a).

%% ---- the shapes: a clean sentence as Word-Tag pairs ----------------------------
%% Proper nouns are emitted capitalised, everything else lower; the text
%% builder capitalises a sentence's first word.

ng_sentence(Seed, Pairs) :- ng_pick(Seed, 1, 41, K), ng_shape(K, Seed, Pairs), !.

ng_known(known_noun). ng_known(known_verb). ng_known(known_adj). ng_known(known_adverb).

%% a statement: a question when the seed gives one is passed over, for the
%% second half of a conjunction
ng_statement(Seed, Qs) :- ng_statement(Seed, 0, Qs).
ng_statement(Seed, K, Qs) :-
    K < 8, S2 is Seed + K, ng_sentence(S2, Qs0),
    ( ng_question(Qs0) -> K1 is K + 1, ng_statement(Seed, K1, Qs) ; Qs = Qs0 ), !.
ng_statement(Seed, _, Qs) :- S2 is Seed + 8, ng_shape(5, S2, Qs).

%% a question is known by its first word, as the grammar knows it
ng_question([W-_|_]) :- ( W == does ; W == is ; rl_question(W) ; rl_modal(W) ), !.

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

ng_shape(20, Seed, [every-'Q', C-'S', V3-'R']) :-                          % Every baker works
    ng_word(class, Seed, 2, C), ng_word(vi, Seed, 3, V), normalise_third(V, V3).
ng_shape(21, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every baker that is not lazy works
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(vi, Seed, 4, V), normalise_third(V, V3),
    (   ng_coin(Seed, 5, 50)
    ->  Rest = [not-'N', A-'C', V3-'R']
    ;   Rest = [A-'C', V3-'R']
    ).

ng_shape(22, Seed, [P-'S', does-'K', not-'N', V-'R', Q-'O']) :-           % Alice does not like Bob
    ng_word2(proper, Seed, 2, P, Q), ng_word(vt, Seed, 3, V).

%% a place after an object: the preposition is a relation word of its own
%% (a run of one, copied as it is) and the place an object, so the grammar
%% reads rent_in(alice, V, rome) -- the shape the network dropped `in
%% Bristol' for want of
ng_shape(23, Seed, [P-'S', V3-'R'|Rest]) :-                                % Alice rents a small flat in Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_object(Seed, 4, Obj), ng_place(Seed, 8, Pl), append(Obj, Pl, Rest).
ng_shape(24, Seed, [P-'S', V3-'R', the-'T', N-'O'|Pl]) :-                  % Alice keeps the key at Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_place(Seed, 5, Pl).
ng_shape(25, Seed, [every-'Q', C-'S', V3-'R', Art-'T', N-'O'|Pl]) :-       % Every tenant rents a flat in Rome
    ng_word(class, Seed, 2, C), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_art(N, Art), ng_place(Seed, 5, Pl).
ng_shape(26, Seed, [P-'S', does-'K', not-'N', V-'R', Art-'T', N-'O'|Pl]) :- % Alice does not rent a flat in Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_word(noun, Seed, 4, N), ng_art(N, Art),
    ng_place(Seed, 5, Pl).

ng_place(Seed, Salt, [Prep-'R', Q-'O']) :-
    ng_choose(Seed, Salt, [in, at, near], Prep), Salt1 is Salt + 1, ng_word(place, Seed, Salt1, Q).

%% questions, six shapes: the first word says so and the text ends in `?',
%% which the tokeniser makes a stop; `who' is the subject it asks for and
%% `what' or `where' the object, so the assembler copies them where they
%% stand and the grammar reads a goal with a variable there
ng_shape(27, Seed, [does-'K', P-'S', V-'R'|Obj]) :-                        % Does Alice own a red car?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_object(Seed, 4, Obj).
ng_shape(28, Seed, [is-'R', P-'S'|Rest]) :-                                 % Is Alice happy? Is Alice a tenant?
    ng_word(proper, Seed, 2, P),
    (   ng_coin(Seed, 3, 50)
    ->  ng_word(adj, Seed, 4, A), Rest = [A-'A']
    ;   ng_word(class, Seed, 4, N), ng_art(N, Art), Rest = [Art-'T', N-'O']
    ).
ng_shape(29, Seed, [M-'R', P-'S', V-'R', the-'T', N-'O']) :-                % May Alice use the server?
    ng_word(modal, Seed, 2, M), ng_word(proper, Seed, 3, P), ng_word(vt, Seed, 4, V), ng_word(noun, Seed, 5, N).
ng_shape(30, Seed, [who-'S'|Rest]) :-                                        % Who owns a car? Who is happy?
    (   ng_coin(Seed, 2, 50)
    ->  ng_word(vt, Seed, 3, V), normalise_third(V, V3), ng_object(Seed, 4, Obj), Rest = [V3-'R'|Obj]
    ;   ng_word(adj, Seed, 3, A), Rest = [is-'R', A-'A']
    ).
ng_shape(31, Seed, [what-'O', does-'K', P-'S', V-'R'|Pl]) :-                 % What does Alice own? What does Alice keep in Rome?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    ( ng_coin(Seed, 4, 40) -> ng_place(Seed, 5, Pl) ; Pl = [] ).
ng_shape(32, Seed, [where-'O', does-'K', P-'S', V-'R']) :-                   % Where does Alice sleep?
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V).

%% quantities, eight shapes: a number tagged T before the noun it counts,
%% the `of' between a unit and its noun a K, the noun O -- the grammar
%% reads quantity(500, euros) and quantity(2, litres, milk) where the
%% assembler copies them; `the N is NUM UNIT' the amount sentence, the one
%% definite subject the grammar reads, and its yes-or-no question; and the
%% `how much' and `how many' questions, their question words O like `what'
%% and the noun of a `how many' with them
ng_shape(33, Seed, [P-'S', V3-'R'|Q]) :-                                   % Alice pays 500 euros / buys two litres of milk
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3), ng_quantity(Seed, 40, Q).
ng_shape(34, Seed, [every-'Q', C-'S', M-'R', V-'R'|Q]) :-                   % Every tenant must pay 500 euros
    ng_word(class, Seed, 2, C), ng_word(modal, Seed, 3, M), ng_word(vt, Seed, 4, V), ng_quantity(Seed, 40, Q).
ng_shape(35, Seed, Pairs) :-                                                % The rent is 500 euros / is 500 / Is the rent 500 euros?
    ng_word(noun, Seed, 2, N),
    (   ng_coin(Seed, 3, 25)
    ->  ng_number(Seed, 4, Num), findall(W-'O', member(W-_, Num), Q)       % a bare number is the object
    ;   ng_quantity(Seed, 40, Q)
    ),
    (   ng_coin(Seed, 8, 20) -> Pairs = [is-'R', the-'T', N-'S'|Q] ; Pairs = [the-'T', N-'S', is-'R'|Q] ).
ng_shape(36, Seed, [P-'S', does-'K', not-'N', V-'R'|Q]) :-                 % Alice does not pay 500 euros
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_quantity(Seed, 40, Q).
ng_shape(37, Seed, [does-'K', P-'S', V-'R'|Q]) :-                          % Does Alice pay 500 euros?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_quantity(Seed, 40, Q).
ng_shape(38, Seed, [how-'O', much-'O'|Rest]) :-                            % How much does Alice pay? How much must Alice pay?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    (   ng_coin(Seed, 4, 30)
    ->  ng_word(modal, Seed, 5, M), Rest = [M-'R', P-'S', V-'R']
    ;   Rest = [does-'K', P-'S', V-'R']
    ).
ng_shape(39, Seed, [how-'O', many-'O', Us-'O', does-'K', P-'S', V-'R']) :- % How many euros does Alice pay?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    ( ng_coin(Seed, 4, 70) -> ng_word(unit, Seed, 5, U) ; ng_word(noun, Seed, 5, U) ), ng_plural(U, Us).
ng_shape(40, Seed, [how-'O', much-'O', is-'R', the-'T', N-'S']) :-         % How much is the rent?
    ng_word(noun, Seed, 2, N).

%% a quantity as an object: a number and its noun -- a unit pluralised
%% (`500 euros') or a thing pluralised (`three vineyards') -- and one time
%% in four with an `of' part, `two litres of milk' or `a litre of milk'
ng_quantity(Seed, Salt, Pairs) :-
    Salt1 is Salt + 1, Salt2 is Salt + 2, Salt3 is Salt + 3, Salt4 is Salt + 4,
    (   ng_coin(Seed, Salt, 25)
    ->  ng_word(unit, Seed, Salt1, U), ng_word(noun, Seed, Salt2, N),
        (   ng_coin(Seed, Salt3, 40)
        ->  ng_art(U, Art), Pairs = [Art-'T', U-'O', of-'K', N-'O']
        ;   ng_number(Seed, Salt4, Num), ng_plural(U, Us), append(Num, [Us-'O', of-'K', N-'O'], Pairs)
        )
    ;   ( ng_coin(Seed, Salt1, 70) -> ng_word(unit, Seed, Salt2, W) ; ng_word(noun, Seed, Salt2, W) ),
        ng_number(Seed, Salt4, Num), ng_plural(W, Ws), append(Num, [Ws-'O'], Pairs)
    ).

%% a number, each word of it tagged T: digits mostly (2 to 999, a decimal, a
%% round thousand), and the number words the grammar reads -- `five', `twenty
%% five', `two hundred', `a hundred', `three thousand'. Digits are an ATOM
%% here, because the text is joined with atomic_list_concat/3 and read back
%% by reason_tokens/2 as num(N); the pair's tokens carry the num.
ng_number(Seed, Salt, Pairs) :-
    Salt1 is Salt + 5, Salt2 is Salt + 6,
    ng_pick(Seed, Salt, 10, K),
    (   K < 5   -> ng_pick(Seed, Salt1, 998, N0), N is N0 + 2, format(atom(A), "~w", [N]), Pairs = [A-'T']
    ;   K =:= 5 -> ng_pick(Seed, Salt1, 99, N0), N is N0 + 1, ng_pick(Seed, Salt2, 9, D0), D is D0 + 1,
                   format(atom(A), "~w.~w", [N, D]), Pairs = [A-'T']
    ;   K =:= 6 -> ng_pick(Seed, Salt1, 20, N0), N is (N0 + 1) * 1000, format(atom(A), "~w", [N]), Pairs = [A-'T']
    ;   K =:= 7 -> findall(W, ( rl_number(W, V), V >= 2, V =< 19 ), Ws), ng_choose(Seed, Salt1, Ws, W1), Pairs = [W1-'T']
    ;   K =:= 8 -> findall(W, ( rl_number(W, V), V >= 20 ), Tens), ng_choose(Seed, Salt1, Tens, T1),
                   findall(W, ( rl_number(W, V), V >= 1, V =< 9 ), Units), ng_choose(Seed, Salt2, Units, U1),
                   Pairs = [T1-'T', U1-'T']
    ;   findall(W, ( rl_number(W, V), V >= 2, V =< 9 ), Small), ng_choose(Seed, Salt1, Small, S1),
        ng_choose(Seed, Salt2, [hundred, thousand, a], Scale),
        ( Scale == a -> Pairs = [a-'T', hundred-'T'] ; Pairs = [S1-'T', Scale-'T'] )
    ).

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
ng_applicable(emphatic_do, [S-'S', V3-'R'|Rest]) :-
    \+ rl_question(S), ng_base_of(V3, _), ( Rest = [] ; Rest = [_-'T'|_] ; Rest = [_-'O'|_] ), !.
ng_applicable(conjoin, Ps) :- \+ member(_-'B', Ps), \+ ng_question(Ps).
ng_applicable(conjoin_shared, [S-'S'|Ps]) :- \+ rl_question(S), \+ member(_-'B', Ps).   % a fact, not yet joined
ng_applicable(filler_join, Ps) :- \+ ng_question(Ps).
ng_applicable(adverb, Ps) :- member(_-'S', Ps), !.
ng_applicable(hedge_start, Ps) :- \+ ng_question(Ps).                  % `I think that does Alice...' is nobody's prose
ng_applicable(filler_start, _).
ng_applicable(filler_end, _).
ng_applicable(adverb_end, Ps) :- last(Ps, _-'R').           % only after an intransitive verb: a bare
                                                            % word after an object reads as its noun
ng_applicable(pp_extra, _).

%% the base of an inflected verb, by the grammar's own stemmer -- which every
%% loaded verb round-trips through -- and only of a real inflection: `is'
%% stems to itself and takes no `does'; a joined `lives_in' stems to live_in
%% and would take one, but split_relation, first and always, has split it
%% by then. (The first
%% draft walked the whole vt and vi lists with the inflector for every pair,
%% which was nothing over twenty verbs and eighty milliseconds a pair over
%% four thousand.)
ng_base_of(V3, V) :- \+ rl_closed(V3), rs_base(V3, V), V \== V3.

ng_apply(split_relation, _, st(Ps, Cs), st(Qs, Cs)) :- ng_split_rel(Ps, Qs).
ng_apply(emphatic_do, _, st([S-'S', V3-'R'|Rest], Cs), st([S-'S', does-'D', V-'R'|Rest], Cs)) :- ng_base_of(V3, V).
ng_apply(conjoin, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    S2 is Seed * 31 + 7, ng_statement(S2, Qs),
    ( ng_coin(Seed, 25, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    append([Ps, Join, Qs], Out), append(Cs, [Qs], Cs2).
%% a second fact about the same subject, joined by `and' with its subject
%% left out (`Alice is a baker and is licensed') or as a pronoun (`and she
%% is licensed'); the clean text has both sentences whole
ng_apply(conjoin_shared, Seed, st([P-'S'|Ps], Cs), st(Out, Cs2)) :-
    ng_fact_rest(Seed, 0, Rest),
    ( ng_coin(Seed, 42, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    (   ng_coin(Seed, 43, 50)
    ->  Second = Rest
    ;   ng_choose(Seed, 44, [she, he], Pro), Second = [Pro-'S'|Rest]
    ),
    append([[P-'S'|Ps], Join, Second], Out), append(Cs, [[P-'S'|Rest]], Cs2).

%% a fact shape for it, its own subject taken off: a few seeds tried, and
%% `sleeps' when none of them is a fact
ng_fact_rest(Seed, K, Rest) :-
    K < 8, S2 is Seed * 41 + K,
    ng_sentence(S2, Qs),
    (   Qs = [_-'S'|Rest0], \+ ng_question(Qs) -> Rest = Rest0
    ;   K1 is K + 1, ng_fact_rest(Seed, K1, Rest)
    ), !.
ng_fact_rest(Seed, _, Rest) :- S2 is Seed * 41 + 8, ng_shape(5, S2, [_-'S'|Rest]).

%% a filler or a hedge after the `and': joins a second sentence itself when
%% none has been joined, so the transform stands alone in a test
ng_apply(filler_join, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    (   append(Before, [and-'B'|After], Ps)
    ->  Cs2 = Cs, Join = [and-'B']
    ;   S2 is Seed * 37 + 11, ng_statement(S2, After), Before = Ps, append(Cs, [After], Cs2),
        ( ng_coin(Seed, 33, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] )
    ),
    (   ng_coin(Seed, 30, 50)
    ->  ng_choose(Seed, 31, [[in, fact], [well], [actually], [of, course], [to, be, honest], [as, far, as, 'I', know],
                             [by, the, way], [anyway], [honestly], [frankly], [as, 'I', said], [after, all], [for, example],
                             [in, any, case], [as, usual], [no, doubt]], F),
        ng_dropped(F, Fs), append([','-'D'|Fs], [','-'D'], Filler)
    ;   ng_choose(Seed, 32, [['I', think, that], ['I', believe, that], [it, seems, that], [you, said, that],
                             ['I', heard, that], [we, know, that], [it, is, clear, that]], H),
        ng_dropped(H, Filler)
    ),
    append([Before, Join, Filler, After], Out).
ng_apply(adverb, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_word(adverb, Seed, 21, Adv),
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
    ng_word(adverb, Seed, 27, Adv),
    append(Ps, [Adv-'D'], Out).
ng_apply(pp_extra, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 24, [[at, home], [on, weekdays], [in, the, morning], [for, now], [at, night],
                         [on, holiday], [in, the, evening], [at, work], [at, the, moment], [for, a, while],
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

%% real sentences, every tag X: a tagger's negatives
normalise_negatives(From, N, Pairs) :-
    To is From + N - 1, ng_size(prose, Size), To =< Size,
    findall(pair(Text, Toks, Tags, none, [outside]),
            ( between(From, To, I), K is I - 1, ng_nth(prose, K, Text),
              reason_tokens(Text, Toks0), ( append(Toks1, ['.'], Toks0) -> true ; Toks1 = Toks0 ),
              Toks1 \== [], Toks = Toks1,
              length(Toks, L), findall('X', between(1, L, _), Tags) ),
            Pairs).

normalise_corpus(N, Pairs) :- normalise_corpus(N, [], Pairs).
normalise_corpus(N, Options, Pairs) :-
    findall(P, ( between(1, N, I), normalise_pair(I, Options, P) ), Pairs).

%% ---- text from words ---------------------------------------------------------------------
%% The first word capitalised, a comma attached to the word before it, a
%% stop at the end.

ng_text_of(Pairs, Text) :- findall(W, member(W-_, Pairs), Ws), ng_stop(Pairs, Stop), ng_text(Ws, Stop, Text).

%% `?' after a question, `.' after anything else: the first word that is
%% not noise says which, in the generator's pairs and the assembler's alike
ng_stop(Pairs, Stop) :-
    (   member(P-T, Pairs), T \== 'D', P \== ',',
        ( P = word(W, _) -> true ; W = P )
    ->  ( ng_question([W-T]) -> Stop = '?' ; Stop = '.' )
    ;   Stop = '.'
    ).

ng_text(Words, Text) :- ng_text(Words, '.', Text).
ng_text(Words, Stop, Text) :-
    ng_text_(Words, first, Parts),
    atomic_list_concat(Parts, Body), atom_concat(Body, Stop, Text).

ng_text_([], _, []).
ng_text_([','|Ws], _, [','|Ps]) :- !, ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], first, [C|Ps]) :- !, ng_cap(W, C), ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], rest, [' ', W|Ps]) :- ng_text_(Ws, rest, Ps).

ng_cap(W, C) :-
    atom_codes(W, [F|R]),
    ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ),
    atom_codes(C, [F1|R]).

%% ---- the assembler -------------------------------------------------------------------------
%% D dropped, an R run joined with `_', B a break, X refused outright; a
%% word keeps the case its token carries, so a proper noun stays one, and
%% a number is written as its digits. A comma is never emitted.

normalise_assemble(_, Tags, _) :- memberchk('X', Tags), !, fail.      % outside: refused
normalise_assemble(Tokens, Tags, Text) :-
    na_zip(Tokens, Tags, Zs),
    na_split(Zs, Sents),
    na_texts(Sents, [], Texts),
    atomic_list_concat(Texts, ' ', Text).

na_zip([], [], []).
na_zip([T|Ts], [G|Gs], [T-G|Zs]) :- na_zip(Ts, Gs, Zs).

na_split([], []) :- !.
na_split(Zs, [S|Ss]) :- na_upto_b(Zs, S, Rest), na_split(Rest, Ss).

na_upto_b([], [], []).
na_upto_b([_-'B'|Zs], [], Zs) :- !.
na_upto_b([Z|Zs], [Z|S], Rest) :- na_upto_b(Zs, S, Rest).

%% a sentence a break left with no subject -- `Priya is a baker and is
%% licensed' -- takes the subject phrase of the sentence before it: the
%% state the assembler carries, as the grammar carries the last subject
na_texts([], _, []).
na_texts([S0|Ss], Last, Ts) :-
    (   \+ memberchk(_-'S', S0), Last \== [] -> append(Last, S0, S) ; S = S0 ),
    na_words(S, Ws),
    ( Ws == [] -> Ts = Ts1 ; ng_stop(S, Stop), ng_text(Ws, Stop, T), Ts = [T|Ts1] ),
    na_subject(S, Last, Last1),
    na_texts(Ss, Last1, Ts1).

%% the subject phrase: what stands before the S (a quantifier), the S, and
%% a relative clause `that is [not] ADJ' when one follows -- D and commas
%% aside, and never the `does not' before a verb: `Priya', or `every baker
%% that is licensed'
na_subject(S, Last, Sub) :-
    (   append(Pre, [Subj-'S'|After], S)
    ->  findall(Z, ( member(Z, Pre), Z \= _-'D', Z \= ','-_ ), Pre1),
        na_relative(After, Rel),
        append(Pre1, [Subj-'S'|Rel], Sub)
    ;   Sub = Last
    ).
na_relative(After, [word(that, lower)-'K'|Rel]) :-
    na_skip_d(After, [word(that, _)-'K'|Rest]), !,
    na_through_c(Rest, Rel).
na_relative(_, []).
na_skip_d([_-'D'|Zs], Out) :- !, na_skip_d(Zs, Out).
na_skip_d([','-_|Zs], Out) :- !, na_skip_d(Zs, Out).
na_skip_d(Zs, Zs).
na_through_c([Z-'C'|_], [Z-'C']) :- !.
na_through_c([Z|Zs], [Z|Rest]) :- na_through_c(Zs, Rest).
na_through_c([], []).

na_words([], []).
na_words([_-'D'|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([','-_|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([num(N)-_|Zs], [A|Ws]) :- !, format(atom(A), "~w", [N]), na_words(Zs, Ws).   % a number as its digits
na_words([word(W, _)-'R'|Zs], [J|Ws]) :- !,
    na_run(Zs, Rs, Rest), atomic_list_concat([W|Rs], '_', J), na_words(Rest, Ws).
na_words([word(W, upper)-_|Zs], [C|Ws]) :- !, ng_cap(W, C), na_words(Zs, Ws).
na_words([word(W, lower)-_|Zs], [W|Ws]) :- na_words(Zs, Ws).

na_run([word(W, _)-'R'|Zs], [W|Rs], Rest) :- !, na_run(Zs, Rs, Rest).
na_run(Zs, [], Zs).
