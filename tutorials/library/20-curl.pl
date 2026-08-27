%% LIBRARY 20 -- library(curl): an HTTP client
%%
%%     ./cocolog run tutorials/library/20-curl.pl main
%%
%% TIER 2: `use_module(library(curl))', a `.so' from `modules/curl'. It
%% needs libcurl: `sh modules/curl/build.sh'.
%%
%% WHY NOT BUILD ONE ON library(tcp)? Because the interesting part of an
%% HTTP client is not the request -- it is TLS, certificate verification,
%% redirects, proxies, connection reuse, chunked decoding and the twenty
%% years of protocol reality libcurl already has. Writing that again in
%% Prolog would be writing it badly.
%%
%% THE SURFACE:
%%
%%     curl_get(+Url, -Status, -Body)
%%     curl_get(+Url, +Options, -Status, -Body)
%%     curl_post(+Url, +Type, +Data, -Status, -Body)
%%     curl_post(+Url, +Type, +Data, +Options, -Status, -Body)
%%     curl_version(-Atom)      curl_ssl(-Backend)
%%
%% NOTE THE STATUS IS ALWAYS THERE. There is no arity that hides it,
%% which is deliberate: a client that quietly hands you the body of a 500
%% is one that turns an outage into corrupt data. You have to look.
%%
%% THIS FILE MAKES NO NETWORK CALL. A tutorial the suite runs must not
%% depend on somebody else's server being up, and a lesson that SKIPs on a
%% laptop with no network teaches nothing. So it checks what can be
%% checked offline -- that the module loads, that a bad URL is a catchable
%% error rather than a hang -- and shows you the calls to make.

:- use_module(library(curl)).

main :-
    format("~n-- the module loads, and it can tell you about itself~n"),
    curl_version(V),
    ( atom(V) -> K = an_atom ; K = V ),
    must('curl_version/1', K, an_atom),
    show('libcurl', V),
    curl_ssl(SSL),
    show('and its TLS backend', SSL),
    %% `current_predicate/1' IS THE WRONG QUESTION HERE, and it is worth
    %% knowing why: it answers about the KNOWLEDGE BASE, and a module's
    %% predicates are not clauses in it. `current_predicate(curl_get/3)'
    %% is FALSE while curl_get/3 works perfectly. Call the thing.
    ( current_predicate(curl_get/3) -> CP = yes ; CP = no ),
    must('current_predicate(curl_get/3) -- a module is not the store', CP, no),

    format("~n-- a URL that cannot resolve is an ERROR, not a hang~n"),
    (   catch(curl_get('http://no.such.host.invalid./', _, _), _, true)
    ->  R = returned
    ;   R = failed
    ),
    ( member(R, [returned, failed]) -> Told = told_us ; Told = R ),
    must('a bad host', Told, told_us),
    format("   Either way it comes back. A binding that could hang the~n"),
    format("   interpreter on a DNS timeout would be worse than none, so~n"),
    format("   `timeout(Secs)' is the option to reach for first.~n"),

    format("~n-- WHAT THE CALLS LOOK LIKE~n"),
    format("~n"),
    format("     ?- curl_get('https://example.org/', Status, Body).~n"),
    format("~n"),
    format("     ?- curl_get('https://api.example.org/v1/things',~n"),
    format("                 [ timeout(10),~n"),
    format("                   header('Authorization: Bearer xyz') ],~n"),
    format("                 Status, Body).~n"),
    format("~n"),
    format("     ?- curl_post('https://api.example.org/v1/things',~n"),
    format("                  'application/json', Payload,~n"),
    format("                  Status, Reply).~n"),
    format("~n"),

    format("-- AND THE ONE IT COMPOSES WITH, which is the point~n"),
    format("   A JSON API is two libraries and no glue:~n"),
    format("~n"),
    format("     fetch(Url, Term) :-~n"),
    format("         curl_get(Url, [timeout(10)], 200, Body),~n"),
    format("         json_parse(Body, Term).~n"),
    format("~n"),
    format("     send(Url, Term, Reply) :-~n"),
    format("         json_atom(Term, Payload),~n"),
    format("         curl_post(Url, 'application/json', Payload, 200, R),~n"),
    format("         json_parse(R, Reply).~n"),
    format("~n"),
    format("   `curl_get/4' answers the body as CODES, which is what~n"),
    format("   `json_parse/2' takes -- so nothing converts in between.~n"),
    format("   That is not a coincidence: every library here that~n"),
    format("   carries bytes carries them as codes, for the reason~n"),
    format("   library(http) gives at length.~n"),

    format("~n-- BEWARE `insecure(true)'. It turns OFF certificate~n"),
    format("   verification, which is the whole of what TLS buys you.~n"),
    format("   It exists because a self-signed certificate in a test~n"),
    format("   harness is a real situation; it is not a way to make a~n"),
    format("   handshake error go away.~n~n"),
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
