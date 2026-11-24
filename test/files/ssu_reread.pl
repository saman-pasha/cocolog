%% test/files/ssu_reread.pl: a file of single-sided rules read again --
%% the calls its goals make reach the rules read so far and raise for
%% none, its rules go in before the last clause, and the clause another
%% file's rules end on stands for both, as swipl 9.0.4's (3.78.13).
%% test/files.pl writes each file and the version swap/2 renames in its
%% place (`sr/2').

:- multifile mr/1.

t(G) :- catch(( G -> R = yes ; R = no ), E, ( E = error(F, _) -> R = F ; R = E )), writeq(G-R), nl.
order(Name, P) :- findall(X, ( G =.. [P, X], clause(G, _) ), L), writeq(Name-L), nl.
swap(F, V) :- atomic_list_concat([F, '.', V, '.pl'], From), atomic_list_concat([F, '.pl'], To), rename_file(From, To).

main :- asserted, past, shared.

%% a rule the program asserted between the reads, and a directive of the
%% second read's after its first rule and after a new one
asserted :-
    consult(g), assertz((gp(5) => true)), t(gp(5)),
    swap(g, v2), consult(g),
    order(g, gp), t(gp(1)), t(gp(2)), t(gp(5)), t(gp(7)).

%% a new rule the second read places after every clause it holds -- the
%% asserted one it took for its own -- where an initialization(G, now) put
%% the last clause before it
past :-
    consult(h), assertz((hp(5) => true)),
    swap(h, v2), consult(h),
    order(h, hp), t(hp(7)), t(hp(9)).

%% a module file's rules for a predicate another file gave its rules, read
%% again: the first file's last clause stands for both, so a call no rule
%% matched names the predicate as its own
shared :-
    consult(ma), consult(mb), t(mr(2)), t(mr(9)),
    swap(mb, v2), consult(mb),
    order(m, mr), t(mr(1)), t(mr(2)), t(mr(3)), t(mr(9)).
