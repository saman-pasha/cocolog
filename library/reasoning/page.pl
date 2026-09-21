%% cocolog -- library/reasoning/page.pl: a page translated, sentence by sentence.
%%
%%     cocolog --embed KB-spanish -s library/reasoning/page.pl -- page.txt
%%     cocolog --embed KB-spanish -s library/reasoning/page.pl -- page.txt english
%%
%% Over a knowledge base teach.pl has taught. Each sentence of the file
%% comes out as its translation, or as `?' with the words no lesson knows,
%% and the last line counts both. The second argument names the language
%% to translate into, as reason_translate/3 takes it; without it the words
%% decide.

:- use_module(library(reasoning/translate)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [File|More]
    ->  ( More = [Into|_] -> true ; Into = any ),
        read_file_to_codes(File, Codes), atom_codes(Text, Codes),
        reason_translate_page(Text, Into, Lines),
        forall(member(S-Out, Lines), page_line(S, Out)),
        aggregate_all(count, ( member(_-Out, Lines), Out \= refused(_) ), Done),
        length(Lines, All),
        format("~n~d of ~d sentences translated~n", [Done, All])
    ;   format("usage: cocolog --embed KB -s library/reasoning/page.pl -- FILE [english|LANGUAGE]~n", [])
    ).

page_line(S, refused(Ws)) :- !, format("? ~w~n    (untranslated: ~w)~n", [S, Ws]).
page_line(S, Out) :- format("~w~n    ~w~n", [S, Out]).
