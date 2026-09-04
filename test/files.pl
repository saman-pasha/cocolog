%% The Files module, checked against SWI-Prolog.
%%
%% EVERY CASE IS ONE PROLOG FILE RUN TWICE -- once by swipl and once by
%% cocolog, in a freshly made empty directory that is the same absolute path
%% both times -- and the two outputs compared byte for byte. A library that
%% claims to be SWI's has to be checked against SWI rather than against its
%% own author, and this is the only way to do that which cannot be fooled by
%% the author's idea of what SWI does. It has already caught one:
%% `file_name_extension' on '.bashrc'.
%%
%% It SKIPS when there is no swipl, because "no SWI here" and "the library
%% is wrong" are different findings -- the same rule the database suites
%% follow.
%%
%%   apt-get install swi-prolog-nox     # or your system's equivalent
%%
%% The sandbox is the same path for both runs so that anything derived from
%% the working directory -- absolute_file_name/2, working_directory/2 --
%% compares equal. Each case gets a fresh one, and a case may leave whatever
%% it likes.
%%
%%     cocolog -s test/files.pl                from the checkout root
%%     cocolog -s test/files.pl -- stat        one case
%%
%% The cases are test/files/*.pl; this was test/files/run.sh. Both runs of
%% a case are children by definition -- one of them is another Prolog.

:- use_module('test/prelude.pl').

main :-
    ( getenv('SWIPL', Swipl) -> true ; Swipl = swipl ),
    sh_join(['command -v ', Swipl, ' >/dev/null 2>&1'], Have),
    (   sh_exit(Have, 0)
    ->  true
    ;   sh_join(['no ', Swipl, ' to compare against'], Why), skip(Why)
    ),
    ( getenv('TMPDIR', Tmp) -> true ; Tmp = '/tmp' ),
    atom_concat(Tmp, '/cocolog_files_sandbox', Sandbox),
    (   current_prolog_flag(argv, [_, One|_])
    ->  Cases = [One]
    ;   cases(Cases)
    ),
    forall(member(C, Cases), one_case(Swipl, Sandbox, C)),
    shl(['rm -rf ', Sandbox]),
    checks_done.

cases(Cases) :-
    directory_files('test/files', Fs),
    findall(C, ( member(F, Fs), atom_concat(C, '.pl', F) ), Cs),
    msort(Cs, Cases).

%% Fixtures a case needs before it runs. Named after the case so that adding
%% one is adding a clause here and a file next door, and so that a case that
%% needs nothing says so by not appearing.
fixtures(stat, Sandbox) :- !,
    atom_concat(Sandbox, '/five.txt', Five), write_file_from_codes(Five, "hello"),
    atom_concat(Sandbox, '/empty.txt', Empty), write_file_from_codes(Empty, []),
    shl(['cd ', Sandbox, ' && ln -s five.txt link.txt']).
fixtures(_, _).

%% The vendored SWI libraries a case needs consulted first. SWI finds them on
%% its own library path from the `:- use_module' line in the case; cocolog
%% has no library path, so they are named here and consulted ahead of the
%% case file.
%%
%% THE FILES ARE SWI'S, UNMODIFIED -- see lib/swipl/README.md. Running the
%% very same bytes under both systems is the whole point: if this passes, the
%% copy is faithful AND cocolog runs it faithfully, and if it fails only one
%% of those two can be at fault.
libs(dcg_basics,     [dcg_basics]).
libs(dcg_high_order, [dcg_basics, dcg_high_order]).
libs(pairs,          [pairs]).
libs(assoc,          [assoc]).
libs(ordsets,        [ordsets]).
libs(yall,           [yall]).
libs(aggregate,      [pairs, aggregate]).
libs(ugraphs,        [ordsets, ugraphs]).

libs_for(Root, C, Text) :-
    ( libs(C, Ls) -> true ; Ls = [] ),
    findall(P, ( member(L, Ls), sh_join([Root, '/lib/swipl/', L, '.pl '], P) ), Ps),
    atomic_list_concat(Ps, Text).

%% One run of one system in a clean sandbox.
run_one(Sandbox, C, Cmd, Text) :-
    shl(['rm -rf ', Sandbox, ' && mkdir -p ', Sandbox]),
    fixtures(C, Sandbox),
    sh_join(['cd ', Sandbox, ' && ', Cmd, ' 2>&1'], InSandbox),
    shell(InSandbox, Text, _).

one_case(Swipl, Sandbox, C) :-
    working_directory(Root, Root),
    sh_join([Root, '/test/files/', C, '.pl'], Pl),
    (   exists_file(Pl)
    ->  sh_join([Swipl, ' -q -g main -t halt ', Pl], SwiCmd),
        run_one(Sandbox, C, SwiCmd, Swi),
        %% `run' takes the LAST argument as the goal when it is given more than
        %% one, so `main' is written out even though it is also the default
        libs_for(Root, C, Libs),
        cocolog(Bin),
        sh_join([Bin, ' --local run ', Libs, Pl, ' main'], CocoCmd),
        run_one(Sandbox, C, CocoCmd, Coco),
        sh_join([C, ': agrees with SWI'], Label),
        (   Swi == Coco
        ->  atom_codes(Swi, Cs), re_lines('.', Cs, Ls), length(Ls, N),
            format("     ~w: ~w line(s)~n", [C, N]),
            check(Label, agrees, agrees)
        ;   atom_concat(Sandbox, '.swi.out', SwiOut), atom_codes(Swi, SwiCs), write_file_from_codes(SwiOut, SwiCs),
            atom_concat(Sandbox, '.coco.out', CocoOut), atom_codes(Coco, CocoCs), write_file_from_codes(CocoOut, CocoCs),
            shl(['diff ', SwiOut, ' ', CocoOut, ' | sed ''s/^/    /'' | head -20 || true']),
            check(Label, differs, agrees)
        )
    ;   sh_join([C, ': no such case'], Label), check(Label, missing, present)
    ).
