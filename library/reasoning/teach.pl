%% cocolog -- library/reasoning/teach.pl: a language's lessons learned into the knowledge base.
%%
%%     cocolog --embed KB-spanish -s library/reasoning/teach.pl -- spanish
%%     cocolog --embed KB-italian -s library/reasoning/teach.pl -- italian
%%
%% Reads corpus/<language>.txt -- the grammar, written by hand -- and then
%% corpus/vocabulary/<language>.txt -- the words, written by build.pl -- and
%% learns both with reason_learn/2, in chunks of a few hundred lines so the
%% reader's heap stays small, into whatever knowledge base this process
%% proves against. Under --embed that is a store on disk, and every later
%% process over the same store finds the lesson learned: page.pl and any
%% program that calls reason_translate/2 start in a second where the
%% learning takes a minute or two. ONE LANGUAGE A STORE: a lesson learned
%% plain is the language with no name, so two of them in one store would
%% answer for each other's words.
%%
%% The grammar goes first, so its meaning of a word is the first the
%% translator finds (`casa' means `house' before it means `home').

:- use_module(library(reasoning/translate)).
:- use_module(library(reasoning/normalise)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [Lang|_] -> true ; Lang = spanish ),
    teach(Lang).

teach(Lang) :-
    normalise_corpus_dir(Dir),
    atomic_list_concat([Dir, '/', Lang, '.txt'], Grammar),
    atomic_list_concat([Dir, '/vocabulary/', Lang, '.txt'], Words),
    teach_file(Grammar, N1), format("~w: ~d terms~n", [Grammar, N1]),
    ( exists_file(Words) -> teach_file(Words, N2), format("~w: ~d terms~n", [Words, N2]) ; format("no vocabulary file ~w~n", [Words]) ).

%% the lines of a lesson file that are not comments, learned 400 at a time
teach_file(File, N) :-
    read_file_to_codes(File, Codes), split_string(Codes, "\n", " \t\r", Lines0),
    findall(L, ( member(S, Lines0), S \== "", \+ sub_string(S, 0, 1, _, "#"), atom_string(L, S) ), Lines),
    teach_chunks(Lines, 0, N).

teach_chunks([], N, N).
teach_chunks(Lines, N0, N) :-
    ( length(Chunk, 400), append(Chunk, Rest, Lines) -> true ; Chunk = Lines, Rest = [] ),
    atomic_list_concat(Chunk, ' ', Text),
    reason_learn(Text, Terms), length(Terms, K), N1 is N0 + K,
    teach_chunks(Rest, N1, N).
