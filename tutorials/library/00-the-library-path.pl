%% LIBRARY 00 -- two tiers, and which one a library is in
%%
%%     ./cocolog run tutorials/library/00-the-library-path.pl main
%%
%% READ THIS ONE FIRST. Every other file in this directory begins by
%% saying "tier 1, no import" or "tier 2, needs one", and this is what
%% that means.
%%
%% TIER 1 -- ALWAYS PRESENT, AND NO `use_module' NEEDED. Sixteen libraries
%% are registered before your first goal runs:
%%
%%     apply  builtins  dcg  files  library  lists  zigurat
%%     assoc  pairs  ordsets  yall  aggregate  ugraphs
%%     dcg_basics  dcg_high_order
%%
%% The first row is compiled into the binary. The second is SWI's own
%% libraries, vendored under their own BSD-2 headers in `lib/swipl' and
%% read from disk beside the binary at start-up.
%%
%% THEY ARE PART OF PROLOG HERE, not an optional extra. A program that has
%% to say `use_module(library(assoc))' before it can use an association
%% list is doing the interpreter's bookkeeping. So **an import for any of
%% the sixteen is a directive that does nothing**, and none is written
%% anywhere in this repository.
%%
%% It is a LOAD rather than an autoload because it measured free: 469ms
%% bare against 459ms with all eight of the vendored ones, then 441/446,
%% then 458/443 -- inside the noise of a start-up dominated by the
%% embedded store.
%%
%% TIER 2 -- ON THE LIBRARY PATH, LOADED WHEN ASKED. `$COCOLOG_LIBRARY'
%% (colon-separated, like PATH), then `./library', then `library/' and
%% `lib/swipl/' BESIDE THE BINARY -- found through /proc/self/exe, so an
%% installed cocolog finds its own libraries and one run inside somebody
%% else's tree does not prefer theirs.
%%
%%     library(tcp)  library(thread)  library(curl)  library(bigint)
%%     library(torch)                          -- .so, built from modules/
%%     library(http)  library(httpd)
%%     library(json)  library(xml)  library(html)   -- .pl, clauses only
%%
%% A THING BELONGS IN TIER 2 WHEN ITS DEPENDENCY SHOULD NOT BE
%% EVERYBODY'S. tcp, torch and bigint used to be in the binary, so every
%% link needed libtorch and libCore for modules most programs never call.
%% The binary went from 936 KB to 585 KB when they moved out.

main :-
    format("~n-- tier 1 is simply there~n"),
    list_to_assoc([a-1], Assoc),
    get_assoc(a, Assoc, V),
    must('library(assoc), with no import at all', V, 1),
    pairs_keys_values(Pairs, [x], [9]),
    must('library(pairs), likewise', Pairs, [x-9]),

    format("~n-- and asking for it succeeds AT ONCE, doing nothing~n"),
    ( use_module(library(lists)) -> U = succeeded ; U = failed ),
    must('use_module(library(lists))', U, succeeded),
    format("   A registered module answers the call for nothing. Which is~n"),
    format("   why writing the line is harmless -- and why writing it is~n"),
    format("   still a line that says `dependency' and means nothing.~n"),

    format("~n-- tier 2 has to be asked for, and CAN be missing~n"),
    (   catch(use_module(library(json)), _, fail)
    ->  Json = loaded
    ;   Json = not_on_the_path
    ),
    must('library(json)', Json, loaded),
    json_atom(json([ok- @(true)]), Doc),
    must('and then it is just there too', Doc, '{"ok":true}'),

    format("~n-- a library that does not exist says so, and names itself~n"),
    catch(use_module(library(no_such_library_here)), error(E, _), true),
    ( E = cocolog_error(Msg) -> true ; Msg = E ),
    ( sub_atom(Msg, _, _, _, 'no_such_library_here') -> K = named_it ; K = Msg ),
    must('the error names the library', K, named_it),
    ( sub_atom(Msg, _, _, _, 'library path') -> W = and_where ; W = Msg ),
    must('...and where it looked', W, and_where),
    format("   The ball is `cocolog_error(Text)', not one of ISO's --~n"),
    format("   this is the loader's own failure and there is no ISO~n"),
    format("   formal that fits it. Match on error(cocolog_error(_), _).~n"),

    format("~n-- HOW TO CHECK WHICH TIER SOMETHING IS IN, rather than~n"),
    format("   remembering. Copy the binary somewhere with no library/~n"),
    format("   beside it, point COCOLOG_LIBRARY at nothing, and see what~n"),
    format("   still loads:~n"),
    format("~n"),
    format("     D=$(mktemp -d); cp cocolog \"$D/\"~n"),
    format("     COCOLOG_LIBRARY=\"$D/none\" \"$D/cocolog\" \\~n"),
    format("        query \"use_module(library(lists)), write(yes), nl\"~n"),
    format("~n"),
    format("   Answering `yes' from a directory with no path at all is~n"),
    format("   what compiled-in means.~n"),

    format("~n-- AND THE PATH IS A LIST YOU CAN ADD TO~n"),
    format("     export COCOLOG_LIBRARY=/opt/mine:/opt/vendor~n"),
    format("   Your directories are searched first, then ./library, then~n"),
    format("   what shipped beside the binary.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
