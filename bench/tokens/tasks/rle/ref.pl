:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "\n", "", Lines),
    forall(( member(L, Lines), string_codes(L, [Op, 32|Text]) ), rl_line(Op, Text)).

rl_line(0'E, Text) :- rl_encode(Text, Out), format("~s~n", [Out]).
rl_line(0'D, Text) :- rl_decode(Text, Out), format("~s~n", [Out]).

rl_encode([], []).
rl_encode([C|Cs], Out) :-
    rl_run(C, Cs, 1, N, Rest),
    number_codes(N, Ds),
    append(Ds, [C|Out1], Out),
    rl_encode(Rest, Out1).

rl_run(C, [C|Cs], N0, N, Rest) :- !, N1 is N0 + 1, rl_run(C, Cs, N1, N, Rest).
rl_run(_, Rest, N, N, Rest).

rl_decode([], []).
rl_decode([D|Cs], Out) :-
    rl_digits([D|Cs], Ds, [C|Rest]),
    number_codes(N, Ds),
    length(Run, N), maplist(=(C), Run),
    append(Run, Out1, Out),
    rl_decode(Rest, Out1).

rl_digits([D|Cs], [D|Ds], Rest) :- D >= 0'0, D =< 0'9, !, rl_digits(Cs, Ds, Rest).
rl_digits(Rest, [], Rest).
