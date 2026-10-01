%% The language benchmark's programs still compute the same thing.
%%
%% bench/langs.sh times cocolog against CPython on five tasks, and its first
%% rule is that every lane must answer the SAME value or nothing is printed.
%% That rule protects a RUN; it does not protect the FILES, and the likeliest
%% way for the comparison to go quietly wrong is somebody improving one side
%% of a pair and not the other. So the pairs are checked here, at sizes small
%% enough to cost nothing: same task, same answer, both languages -- and each
%% task's sqlite program against its dict one, because those must also stay
%% the same question asked twice.
%%
%% MOVED FROM THE COCO with the benchmark (its test/bench.pl, `lang_half'),
%% which checked lookup's sqlite twin only: the other four were written
%% after it, and all five are checked now.
%%
%% A LANE THAT NEVER STARTED IS NOT AN AGREEMENT. Two lanes that both failed
%% to print an answer agree perfectly, and The Coco's shell version once
%% printed ok for exactly that; `none' on either side is a failure here.
%%
%%     cocolog -s test/langs.pl        from the checkout root

:- use_module('test/prelude.pl').

main :-
    python(Py),
    root(R),
    atom_concat(R, '/bench/langs', D),
    scratch(S),
    forall(task(T, N, Reps), ( pair(Py, D, T, N, Reps), twin(Py, D, S, T, N, Reps) )),
    shl(['rm -rf ', S]),
    checks_done.

%% task(Name, N, Reps): one rep of each, at a size that answers at once
task(nrev,     '60',   '2').
task(queens,   '6',    '1').
task(loop,     '1000', '1').
task(lookup,   '200',  '1').
task(sortnums, '300',  '1').

%% THE INTERPRETER, NOT A SHIM IN FRONT OF IT. `python3' on the box the
%% benchmark was last run on resolves through a pyenv shim that spends two
%% seconds choosing an interpreter; bench/langs.sh looks through it, and so
%% does this. PYTHON names one outright.
python(Py) :-
    (   getenv('PYTHON', P), P \== ''
    ->  Py = P
    ;   shell('command -v python3', P0, E0),
        (   E0 =\= 0 -> skip('no python3 -- the language pairs are not checked') ; true ),
        (   sub_atom(P0, _, _, _, '/.pyenv/shims/'),
            shell('pyenv which python3 2>/dev/null', P1, 0)
        ->  Py = P1
        ;   Py = P0
        )
    ).

%% cocolog and python, the same task
pair(Py, D, T, N, Reps) :-
    cocolog(C),
    answer_of([C, ' run ', D, '/', T, '.pl "main(', N, ',', Reps, ')"'], PL),
    answer_of([Py, ' ', D, '/', T, '.py ', N, ' ', Reps], PY),
    agree(PL, PY, Got),
    atom_concat(T, ': cocolog and python answer the same', Label),
    check(Label, Got, agree).

%% the dict and the sqlite store, the same task -- a fresh file each, as
%% bench/langs.sh gives every sqlite run
twin(Py, D, S, T, N, Reps) :-
    sh_join([S, '/', T, '.db'], Db),
    answer_of([Py, ' ', D, '/', T, '.py ', N, ' ', Reps], Dict),
    answer_of([Py, ' ', D, '/', T, '_sqlite.py ', N, ' ', Reps, ' ', Db], Sq),
    agree(Sq, Dict, Got),
    atom_concat(T, ': the dict and the sqlite store answer the same', Label),
    check(Label, Got, agree).

%% one process, its first `answer(...)', or `none'
answer_of(Parts, A) :-
    sh_join(Parts, Cmd0),
    sh_join([Cmd0, ' 2>/dev/null'], Cmd),
    shell(Cmd, Text, _, 60000),
    (   re_first_atom('answer\\([^)]*\\)', Text, A0) -> A = A0 ; A = none ).

agree(A, B, agree) :- A \== none, A == B, !.
agree(A, B, differ(A, B)).
