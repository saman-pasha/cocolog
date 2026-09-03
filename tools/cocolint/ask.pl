%% ask.pl -- the two small questions the shell drivers used to ask Python.
%%
%%     cocolog --local run ask.pl ak_main -- goal FILE... GOAL
%%     cocolog --local run ask.pl ak_main -- owner NAME/ARITY
%%     cocolog --local run ask.pl ak_main -- candidate OUT.json CANDIDATE.pl
%%
%% THREE ONE-LINERS, NOT A TOOL. verify.sh and agent.sh each had a `python3
%% -c' block doing one lookup; they are here so the shell can ask cocolog
%% instead, and they are one file because three files of nine lines each is
%% worse than one of thirty.
%%
%% `owner' READS blocklist.pl AND NOT blocklist.json, which is the same
%% choice oracle.sh made: the facts are what the linter reads, so an answer
%% derived from them cannot disagree with the linter about who owns a name.

:- use_module(library(json)).

ak_root(R) :- ( getenv('COCOLOG_ROOT', X) -> R = X ; working_directory(R, R) ).

ak_here(Rel, Abs) :-
    ak_root(R), atomic_list_concat([R, '/tools/cocolint/', Rel], Abs).

ak_main :-
    current_prolog_flag(argv, [_, Verb|Rest]),
    ak_do(Verb, Rest).

%% Does the last file define GOAL/0? The goal is the LAST argument, which is
%% the same rule `run FILE... GOAL' follows.
ak_do(goal, Args) :-
    !,
    append(Files, [Goal], Args),
    atom_concat(Goal, '/0', Key),
    (   member(F, Files),
        catch(cc_heads_of(F, Heads), _, fail),
        member(N/A, Heads),
        atomic_list_concat([N, '/', A], Key)
    ->  write(yes)
    ;   write(no)
    ),
    nl.

%% Which tier-2 library owns NAME/ARITY, if any.
ak_do(owner, [Key]) :-
    !,
    ak_here('blocklist.pl', BL),
    (   exists_file(BL)
    ->  ak_split(Key, Name, Arity),
        (   ak_owner(BL, Name, Arity, Mod)
        ->  write(Mod), nl
        ;   true
        )
    ;   true
    ).

%% The model's reply: a `code' verdict writes the file, anything else prints
%% the document and fails, which is exit 5 to the shell.
ak_do(candidate, [OutJson, Candidate]) :-
    !,
    read_file_to_codes(OutJson, Cs),
    once(json_parse(Cs, T)),
    (   ak_get(T, verdict, code),
        ak_get(T, files, [F|_]),
        ak_get(F, content, Content)
    ->  atom_codes(Content, CC),
        write_file_from_codes(Candidate, CC)
    ;   json_codes(T, Pretty, [indent(1)]),
        ak_write_codes(Pretty), nl,
        fail
    ).

ak_get(json(Ps), K, V) :- memberchk(K-V, Ps).

ak_split(Key, Name, Arity) :-
    atom_codes(Key, Cs),
    append(NCs, [0'/|ACs], Cs),
    \+ memberchk(0'/, ACs),
    !,
    atom_codes(Name, NCs),
    atom_codes(Arity, ACs).

%% cl_t2c(Mod, Name, Arity). / cl_t2p(Mod, Name, Arity). -- read as text,
%% because consulting the blocklist here would put 1300 facts in the store
%% to answer one question.
ak_owner(BL, Name, Arity, Mod) :-
    read_file_to_codes(BL, Cs),
    ak_lines(Cs, Lines),
    member(L, Lines),
    ak_t2_fact(L, Mod, Name, Arity),
    !.

ak_t2_fact(L, Mod, Name, Arity) :-
    ( append("cl_t2c('", R0, L) -> R = R0 ; append("cl_t2p('", R, L) ),
    ak_upto_q(R, ModCs, R1),
    append(", '", R2, R1),
    ak_upto_q(R2, NameCs, R3),
    append(", ", R4, R3),
    ak_upto_paren(R4, ACs),
    atom_codes(Mod, ModCs),
    atom_codes(Name, NameCs),
    atom_codes(Arity, ACs).

ak_upto_q([0''|T], [], T) :- !.
ak_upto_q([C|T], [C|R], Rest) :- ak_upto_q(T, R, Rest).

ak_upto_paren([0')|_], []) :- !.
ak_upto_paren([C|T], [C|R]) :- ak_upto_paren(T, R).

ak_lines([], []) :- !.
ak_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [], L == [] -> Ls = [] ; ak_lines(R, Ls) ).

%% ~s is capped at 8192 bytes -- see assemble.pl's note on the two walls.
ak_write_codes([]) :- !.
ak_write_codes(Cs) :-
    ak_take(4000, Cs, C1), ak_drop(4000, Cs, R),
    format("~s", [C1]), ak_write_codes(R).

ak_take(N, _, []) :- N =< 0, !.
ak_take(_, [], []) :- !.
ak_take(N, [C|T], [C|R]) :- N1 is N - 1, ak_take(N1, T, R).

ak_drop(0, L, L) :- !.
ak_drop(_, [], []) :- !.
ak_drop(N, [_|T], R) :- N1 is N - 1, ak_drop(N1, T, R).
