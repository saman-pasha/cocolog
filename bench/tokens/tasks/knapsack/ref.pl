:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, " \n", "", Parts),
    findall(N, ( member(P, Parts), string_length(P, Len), Len > 0, number_string(N, P) ),
            [_, W|Nums]),
    ks_items(Nums, Items),
    W1 is W + 1,
    length(Best0, W1), maplist(=(0), Best0),
    foldl(ks_step, Items, Best0, Best),
    last(Best, Value),
    format("~d~n", [Value]).

ks_items([], []).
ks_items([Wt, V|Nums], [Wt-V|Items]) :- ks_items(Nums, Items).

%% Best lists, for each capacity 0..W, the most the items so far are worth.
%% With one item more, capacity C is worth the better of keeping the old
%% value and taking the item onto the old value at C - Wt.
ks_step(Wt-V, Old, New) :-
    length(Pad, Wt), maplist(=(none), Pad),
    append(Pad, Old, Shifted0),
    length(Old, L), length(Shifted, L), append(Shifted, _, Shifted0),
    maplist(ks_best(V), Old, Shifted, New).

ks_best(_, Old, none, Old) :- !.
ks_best(V, Old, Prev, New) :- New is max(Old, Prev + V).
