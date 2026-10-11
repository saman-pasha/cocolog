%% gallery.pl -- every construct library(flowchart) draws, once.
:- use_module(library(text)).

%% check(+Nums, +Text): every number has a sign word; count the positive ones.
check(Nums, Text) :-
    forall(member(N, Nums), sign_word(N, _)),
    once(member(_, Nums)),
    ignore(lines_or_none("a", Text, _)),
    aggregate_all(count, ( member(P, Nums), P > 0 ), C),
    C >= 0.

%% sign_word(+N, -W)
sign_word(N, W) :-
    (   N > 0, W = up
    ;   N < 0, W = down
    ;   W = flat
    ).

%% lines_or_none(+Pat, +Text, -Lines): the matching lines, or none.
lines_or_none(Pat, Text, Lines) :-
    catch(re_lines(Pat, Text, Lines), _, fail), !.
lines_or_none(_, _, none).
