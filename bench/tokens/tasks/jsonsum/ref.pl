:- use_module(library(stream)).
:- use_module(library(json)).

main :-
    read_stream_to_codes(user_input, Cs),
    json_parse(Cs, Json),
    js_sum(Json, Sum),
    format("~d~n", [Sum]).

js_sum(N, N) :- integer(N), !.
js_sum(json(Pairs), Sum) :- !, foldl(js_add_value, Pairs, 0, Sum).
js_sum(List, Sum) :- is_list(List), !, foldl(js_add, List, 0, Sum).
js_sum(_, 0).

js_add_value(_-V, S0, S) :- js_add(V, S0, S).

js_add(V, S0, S) :- js_sum(V, X), S is S0 + X.
