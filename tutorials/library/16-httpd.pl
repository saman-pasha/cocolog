%% LIBRARY 16 -- library(httpd): a server whose pages are clauses
%%
%%     ./cocolog run tutorials/library/16-httpd.pl main
%%
%% TIER 2: `use_module(library(httpd))', which pulls in library(tcp),
%% library(http) and library(thread). Clauses only -- the sockets are
%% tcp's C and the parse is http's grammar; routing, path safety, content
%% types, keep-alive and the loop are all here, in Prolog.
%%
%% THIS FILE DOES NOT START A SERVER. It shows you the pieces, checks the
%% ones that can be checked without a socket, and tells you how to run
%% one. Starting a listener inside a tutorial that the suite runs would
%% mean a port, a race and a cleanup, and none of that teaches anything.
%%
%% THE POINT IS THE LAST WORD OF THE TITLE. Zeytun serves a knowledge base
%% over HTTP and answers with rows. This answers with whatever a CLAUSE
%% can compute, in the same process that holds the store -- so a page sees
%% the knowledge base directly, with no protocol in between.
%%
%% ---- A PAGE ----------------------------------------------------------
%%
%%     httpd_page('/hello', _Request, reply(200, [], 'hi')).
%%
%%     httpd_page('/who', request(_,_,Query,_,_,_), reply(200, [], Answer)) :-
%%         memberchk(name-N, Query),
%%         atom_concat('hello ', N, Answer).
%%
%% A page that FAILS is a 404 -- it did not claim the path, so the static
%% half gets its turn. One that THROWS is a 500 and does not fall
%% through, because an error is a page saying "this is mine and it broke".
%% One that LOOPS is a 500 too, after `page_limit' inferences.
%%
%% ---- LOAD PAGES WITH `use_module', NEVER A CONSULT -------------------
%%
%% It matters in every arrangement but --local: a module's clauses are
%% MUTED, so they belong to this process and are never written through to
%% the shared knowledge base. A page consulted instead would be saved into
%% the database and listed as somebody's own program.
%%
%% AND WITH `workers(N)' IT IS THE ONLY THING THAT WORKS, with a silent
%% 404 as the failure. A worker answers each request as an ISOLATED PROOF
%% -- fresh machine, fresh store -- and a fresh store is filled from the
%% process-wide MODULE REGISTRY, which `use_module' writes and a consult
%% does not.

:- use_module(library(httpd)).

%% Pages, as clauses. In a real program these live in their own file and
%% are loaded with use_module -- see the note above.
httpd_page('/hello', _, reply(200, [], 'hello, world')).

httpd_page('/greet', request(_, _, Query, _, _, _), reply(200, [], Body)) :-
    memberchk(name-Name, Query),
    atom_concat('hello ', Name, Body).

httpd_page('/boom', _, _) :- throw(error(demo_failure, '/boom')).

main :-
    format("~n-- a page is a clause, and answering one is calling it~n"),
    httpd_page('/hello', request(get, '/hello', [], http(1,1), [], []), R1),
    must('the /hello page', R1, reply(200, [], 'hello, world')),

    format("~n-- ...and the request is a TERM, so the query is just a list~n"),
    Req = request(get, '/greet', [name-ada], http(1,1), [], []),
    httpd_page('/greet', Req, reply(_, _, Body)),
    must('/greet?name=ada', Body, 'hello ada'),

    format("~n-- a page that does not claim the path simply FAILS~n"),
    ( httpd_page('/nothing', request(get, '/nothing', [], http(1,1), [], []), _)
    -> P = answered ; P = failed ),
    must('an unclaimed path', P, failed),
    format("   ...which is what makes it a 404: the static half gets its~n"),
    format("   turn, and only then is it really not there.~n"),

    format("~n-- and one that throws is a 500, not a 404~n"),
    ( catch(httpd_page('/boom', request(get, '/boom', [], http(1,1), [], []), _),
            error(demo_failure, _), true)
    -> T = threw ; T = quiet ),
    must('/boom', T, threw),
    format("   An error is a page saying `this is mine and it broke'.~n"),
    format("   Falling through to the static half there would serve a~n"),
    format("   404 for a bug, which is the wrong answer twice.~n"),

    format("~n-- path safety is a predicate, and it is worth reading~n"),
    checks_safe('/a/b', safe),
    checks_safe('/../etc/passwd', refused),
    checks_safe('/a/../../b', refused),

    format("~n-- content types come from the extension~n"),
    %% TWO PREDICATES, and the split is worth noticing. The TABLE is keyed
    %% on the bare extension; `httpd_type/2' is the one that takes a file
    %% name, pulls the extension off it and falls back when the table has
    %% nothing. A table you can read at a glance, and one place that
    %% decides what "unknown" means.
    httpd_content_type(html, CT1),
    must('the table, keyed on the extension', CT1, 'text/html; charset=utf-8'),
    httpd_type('index.html', T1), must('httpd_type/2 on a file name', T1, CT1),
    httpd_type('a.css', T2), must('css', T2, 'text/css; charset=utf-8'),
    httpd_type('a.json', T3), must('json', T3, 'application/json'),
    httpd_type('a.unknown', T4),
    must('and anything the table has not got', T4, 'application/octet-stream'),
    format("   `charset=utf-8' on the text types is deliberate: a browser~n"),
    format("   that has to guess an encoding guesses wrong eventually,~n"),
    format("   and everything this library writes is UTF-8 bytes.~n"),

    format("~n-- HOW TO ACTUALLY RUN ONE~n"),
    format("~n"),
    format("     %% pages.pl~n"),
    format("     httpd_page('/hello', _, reply(200, [], 'hi')).~n"),
    format("~n"),
    format("     %% server.pl~n"),
    format("     :- use_module(library(httpd)).~n"),
    format("     :- use_module('pages.pl').        %% a MODULE, not a consult~n"),
    format("     main :- httpd_serve(8080, [root('./public'), workers(4)]).~n"),
    format("~n"),
    format("     $ ./cocolog run server.pl main~n"),
    format("~n"),
    format("   THE OPTIONS worth knowing: root(Dir) serves static files~n"),
    format("   under it; workers(N) is a pool over library(thread);~n"),
    format("   page_limit(N) is how many inferences ONE page may spend~n"),
    format("   before it is a 500, which is what keeps a looping page~n"),
    format("   from ending the service; keep_alive(Bool) and~n"),
    format("   max_keep_alive(N) bound a persistent connection.~n"),

    format("~n-- AND EACH REQUEST IS ITS OWN TURN, under a pool~n"),
    format("   A worker's goal runs for the life of the server and a~n"),
    format("   store CACHES, so two workers answering writes would hold~n"),
    format("   two pictures of the same predicate and the second commit~n"),
    format("   would overwrite the first. Measured, before the fix:~n"),
    format("   three sequential POSTs through a pool of three left TWO~n"),
    format("   facts in the database. So a request runs isolated: fresh~n"),
    format("   machine, fresh store, fresh connection, one commit.~n~n"),
    format("done~n").

checks_safe(Path, Want) :-
    ( httpd_safe_path(Path, _) -> Got = safe ; Got = refused ),
    must(Path, Got, Want).

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
