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
%% IT ALSO SKIPS WHEN THE SWIPL IS NOT THE REFERENCE 9.0.4. These cases are
%% 9.0.4's answers (the repository's target), and SWI 10 answers differently
%% in ways no case can agree with both: the text of a float
%% (`9007199254740992.0' for `9.007199254740992e+15'), a NaN's order and
%% what max/min pick, `float/1' of a NaN, the float flags' default checks,
%% `print/1''s numbervars for a huge integer, quoted writes (`\'` where the
%% engine writes `'''), and the deprecation warning a load of a file found
%% through the working directory now prints. "A different SWI here" is a
%% fact about the machine, as no SWI is.
%%
%%   apt-get install swi-prolog-nox     # or your system's equivalent;
%%                                      # 9.0.4 for the comparison
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
    swipl_reference(Swipl),
    ( getenv('TMPDIR', Tmp) -> true ; Tmp = '/tmp' ),
    atom_concat(Tmp, '/cocolog_files_sandbox', Sandbox),
    (   current_prolog_flag(argv, [_, One|_])
    ->  Cases = [One]
    ;   cases(Cases)
    ),
    forall(member(C, Cases), one_case(Swipl, Sandbox, C)),
    shl(['rm -rf ', Sandbox]),
    (   nb_current(files_md5, built(So))
    ->  file_directory_name(So, Built), shl(['rm -rf ', Built])
    ;   true
    ),
    checks_done.

%% THE SWIPL IS 9.0.4, or the case stops by name: a 10.x answers some of
%% these differently (the header says which), and a comparison with it would
%% report the reference's answers as a failure of cocolog. Answered by the
%% version line swipl itself prints, so `SWIPL' may name any path.
swipl_reference(Swipl) :-
    sh_join([Swipl, ' --version'], Cmd),
    shell(Cmd, Ver, _),
    (   sub_atom(Ver, _, _, _, ' version 9.0.4 ')
    ->  true
    ;   atom_concat('not the reference SWI 9.0.4: ', Ver, Why), skip(Why)
    ).

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
    shl(['cd ', Sandbox, ' && ln -s five.txt link.txt']),
    %% a time with a fraction, the same instant for both runs (GNU and BSD
    %% touch both read this form). swipl reads the fraction only where
    %% `struct stat' has `st_mtim', which Darwin's has not, so there the
    %% fixture is a whole second and the two still compare
    shl_atom(['uname -s'], Sys),
    ( Sys == 'Darwin' -> When = '2026-10-28T12:00:00Z' ; When = '2026-10-28T12:00:00.75Z' ),
    shl(['cd ', Sandbox, ' && touch -d ', When, ' frac.txt']).
fixtures(loaded, Sandbox) :- !,
    atom_concat(Sandbox, '/sib.pl', Sib),
    fixture(Sib, ['sib_a(1).', 'sib_b(X) :- sib_a(X).']).
fixtures(consult, Sandbox) :- !,
    atom_concat(Sandbox, '/a.pl', A), fixture(A, ['a(1).', 'a(2).']),
    atom_concat(Sandbox, '/b.pl', B), fixture(B, ['b(x).']),
    atom_concat(Sandbox, '/d.pl', D),
    fixture(D, [':- initialization(writeln(init_d)).', ':- writeln(directive_d).', 'd(1).']),
    atom_concat(Sandbox, '/e.pl', E), fixture(E, [':- [b].', 'e(1).']).
%% each version at a time of its own, whole seconds (BSD touch reads them
%% too): r2.pl a second after r.pl, r3.pl an hour before it, so that
%% if(changed) has a newer file and an older one to tell apart
fixtures(reload, Sandbox) :- !,
    forall(member(F-Lines-When,
                  [ 'r.pl'-[':- writeln(read_r_v1).', 'rp(1).', 'rq(1).']-'2026-10-28T12:00:00Z',
                    'r2.pl'-[':- writeln(read_r_v2).', 'rp(2).']-'2026-10-28T12:00:01Z',
                    'r3.pl'-[':- writeln(read_r_v3).', 'rp(3).', 'rq(3).']-'2026-10-28T11:00:00Z',
                    'c.pl'-[':- writeln(read_c_v1).', 'cp(1).', 'cq(1).']-'2026-10-28T12:00:00Z',
                    'c2.pl'-[':- writeln(read_c_v2).', 'cp(2).']-'2026-10-28T12:00:01Z',
                    'g.pl'-[':- writeln(read_g_v1).', ':- dynamic gd/1.', 'gd(file).']-'2026-10-28T12:00:00Z',
                    'g2.pl'-[':- writeln(read_g_v2).', ':- dynamic gd/1.', 'gd(file2).']-'2026-10-28T12:00:01Z' ]),
           ( atomic_list_concat([Sandbox, '/', F], P), fixture(P, Lines),
             shl(['touch -d ', When, ' ', P]) )).
%% each file and the versions the case renames in its place, a version a
%% list of lines (`ro/2')
fixtures(reload_order, Sandbox) :- !,
    forall(ro(F, Lines), ( atomic_list_concat([Sandbox, '/', F], P), fixture(P, Lines) )).
%% the md5 fixture (below) in the sandbox's library/, which cocolog searches
%% after $COCOLOG_LIBRARY and swipl does not search at all: swipl's
%% use_module(library(md5)) takes its own
fixtures(module_context, Sandbox) :- !,
    md5_fixture(built(So)),
    atom_concat(Sandbox, '/library', Lib),
    shl(['mkdir -p ', Lib, ' && cp ', So, ' ', Lib, '/md5.so']).
fixtures(_, _).

%% WHAT A CASE NEEDS THAT A BOX MAY NOT HAVE, the case skipped by name where
%% it is missing, as test/library.pl skips hoot. module_context needs the
%% md5 fixture; a fixture that would not build, on a box that has what it
%% takes, is red with its compiler's words.
unready(module_context, Why) :- !,
    md5_fixture(R),
    (   R = missing(Why)
    ->  true
    ;   R = failed(Log)
    ->  check('module_context: the md5 fixture builds', Log, built),
        Why = 'its fixture would not build'
    ).

%% THE md5 FIXTURE (3.0.2): a loadable module named md5, built from
%% test/md5.cicili as test/library.pl builds hoot -- Cicili with --release,
%% then the one compiler with -O3 -- once a run, kept in a scratch directory
%% of its own until the run ends. built(So), missing(Why) or failed(Log).
md5_fixture(R) :- nb_current(files_md5, R), !.
md5_fixture(R) :- md5_build(R), nb_setval(files_md5, R).

md5_build(R) :-
    ( getenv('CICILI', Cicili) -> true ; getenv('HOME', Home), atom_concat(Home, '/cicili', Cicili) ),
    atom_concat(Cicili, '/cicili.lisp', Lisp),
    ( exists_file('tools/cc/cc') -> Cc = 'tools/cc/cc' ; Cc = clang ),
    sh_join(['command -v ', Cc, ' >/dev/null 2>&1 || test -x ', Cc], HaveCc),
    (   \+ ( sh_exit('command -v sbcl >/dev/null 2>&1', 0), exists_file(Lisp) )
    ->  R = missing('no sbcl or no CICILI checkout for the md5 fixture')
    ;   \+ sh_exit(HaveCc, 0)
    ->  R = missing('no C compiler for the md5 fixture')
    ;   scratch(D),
        working_directory(Root, Root),
        %% Cicili takes the directory it starts in as where its own library
        %% lives, so it runs from its checkout with the target named
        %% absolutely, and writes test/md5.c beside the target
        shl(['rm -f test/md5.c && cd ', Cicili, ' && sbcl --script cicili.lisp --release ', Root,
             '/test/md5.cicili > ', D, '/transpile.log 2>&1 || true']),
        atom_concat(D, '/md5.so', So),
        sh_join([Cc, ' -shared -fPIC -O3 -o ', So, ' test/md5.c > ', D, '/cc.log 2>&1'], Build),
        (   sh_exit(Build, 0)
        ->  R = built(So)
        ;   atom_concat(D, '/cc.log', Log), read_file_to_codes(Log, Cs), atom_codes(Why, Cs),
            atomic_list_concat([Why, ' (the transpile: ', D, '/transpile.log)'], Said),
            R = failed(Said)
        )
    ).

ro('s1.pl', [':- dynamic s1/1.', 's1(1).', 's1(2).']).
ro('s1.v2.pl', [':- dynamic s1/1.', 's1(3).', 's1(4).']).
ro('s2.pl', [':- dynamic s2/1.', 's2(1).', 's2(2).']).
ro('s2.v2.pl', [':- dynamic s2/1.', 's2(3).', 's2(4).']).
ro('s3.pl', [':- dynamic s3/1.', 's3(1).', 's3(2).']).
ro('s3.v2.pl', [':- dynamic s3/1.', 's3(1).', 's3(2).', 's3(3).']).
ro('s4.pl', [':- dynamic s4/1.', 's4(1).', 's4(2).']).
ro('s4.v2.pl', [':- dynamic s4/1.', 's4(0).', 's4(1).', 's4(2).']).
ro('s5.pl', [':- dynamic s5/1.', 's5(1).', 's5(2).', 's5(3).']).
ro('s5.v2.pl', [':- dynamic s5/1.', 's5(2).']).
ro('s6.pl', [':- dynamic s6/1.', 's6(1).', 's6(2).']).
ro('s6.v2.pl', [':- dynamic s6/1.', 's6(2).', 's6(1).']).
ro('s7.pl', [':- dynamic s7/1.', 's7(1).']).
ro('s7.v2.pl', [':- dynamic s7/1.', 's7(1).', 's7(2).']).
ro('s7.v3.pl', [':- dynamic s7/1.', 's7(3).']).
ro('s8.pl', [':- dynamic s8/1.', 's8(1).', 's8(2).']).
ro('s8.v2.pl', [':- dynamic s8/1.', 's8(2).', 's8(5).']).
ro('s9.pl', [':- dynamic s9/1.', 's9(1).', 's9(2).', 's9(3).']).
ro('s9.v2.pl', [':- dynamic s9/1.', 's9(1).', 's9(9).', 's9(3).']).
ro('s10.pl', [':- dynamic s10/1.', 's10(1).', 's10(2).']).
ro('s10.v2.pl', [':- dynamic s10/1.', 's10(3).']).
ro('d.pl', [':- dynamic d/1.', 'd(1).', 'd(1).']).
ro('d.v2.pl', [':- dynamic d/1.', 'd(1).', 'd(2).', 'd(1).', 'd(1).']).
ro('v.pl', [':- dynamic v/2.', 'v(X, Y) :- Y = f(X).', 'v(2, two).']).
ro('v.v2.pl', [':- dynamic v/2.', 'v(A, B) :- B = f(A).', 'v(3, three).']).
ro('st.pl', ['st(1).', 'st(2).']).
ro('st.v2.pl', ['st(2).', 'st(3).']).
ro('sp.pl', [':- dynamic sp/1.', 'sp(1).']).
ro('sp.v2.pl', [':- dynamic sp/1.', 'sp(2).', 'sp(1).']).
ro('sp.v3.pl', [':- dynamic sp/1.', 'sp(2).', 'sp(1).']).
ro('sp.v4.pl', [':- dynamic sp/1.', 'sp(1).', 'sp(2).']).
ro('k.pl', [':- dynamic k/1.', 'k(1).']).
ro('k.v2.pl', [':- dynamic k/1.', 'k(9).']).
ro('m.pl', [':- dynamic m/1.', 'm(1).', 'm(2).']).
ro('m.v2.pl', [':- dynamic m/1.', 'm(3).', ':- findall(X, m(X), L), format("mid: ~q~n", [L]).', 'm(4).']).
ro('e.pl', [':- dynamic e/1.', 'e(1).', 'e(2).']).
ro('e.v2.pl', [':- dynamic e/1.', 'e(1).', 'e(2).', 'e(3).']).
ro('e.v3.pl', [':- dynamic e/1.', 'e(1).', 'e(2).']).
ro('e2.pl', [':- dynamic e2/1.', 'e2(1).', 'e2(2).']).
ro('e2.v2.pl', [':- dynamic e2/1.', 'e2(1).', 'e2(2).', 'e2(3).']).
ro('n.pl', [':- dynamic np/1, nq/1, nr/1.', 'np(1).']).
ro('n.v2.pl', [':- dynamic np/1, nq/1, nr/1.', 'np(1).', 'nq(a).', 'nq(b).', 'nr(1).']).
ro('fresh.pl', [':- dynamic fq/1, fr/1.', 'fq(a).', 'fq(b).', 'fr(1).']).
ro('q.pl', [':- dynamic q/1.', 'q(a).', 'q(1).']).
ro('q.v2.pl', [':- dynamic q/1.', 'q(2).']).
ro('f1.pl', [':- multifile mf/1.', ':- dynamic mf/1.', 'mf(1).']).
ro('f1.v2.pl', [':- multifile mf/1.', ':- dynamic mf/1.', 'mf(3).']).
ro('f1.v3.pl', [':- multifile mf/1.', ':- dynamic mf/1.', 'mf(9).']).
ro('f2.pl', [':- multifile mf/1.', ':- dynamic mf/1.', 'mf(2).']).
ro('of.pl', [':- dynamic of/1.', 'of(1).', 'of(2).']).
ro('of.v2.pl', [':- dynamic of/1.', 'of(0).', 'of(1).', 'of(2).']).
ro('w.pl', [':- dynamic w/1.', 'w(X) :- X = 1.']).
ro('w.v2.pl', [':- dynamic w/1.', 'w(Y) :- Y = 1.', 'w(2).']).
ro('wq.pl', [':- dynamic wq/1.', 'wq(1).']).
ro('wq.v2.pl', [':- dynamic wq/1.', 'wq(''_G7'').']).
ro('wb.pl', [':- dynamic wb/1.', 'wb(1).']).
ro('wb.v2.pl', [':- dynamic wb/1.', 'wb(a_G7).']).
ro('bp.pl', [':- dynamic bp/1.', 'bp(1).']).
ro('bp.v2.pl', [':- dynamic bp/1.', 'bp(1).', 'bp(z).']).
ro('ba.pl', [':- dynamic ba/1.', 'ba(1).']).
ro('ba.v2.pl', [':- dynamic ba/1.', 'ba(x).', 'ba(w).']).
ro('sh.pl', [':- dynamic sh/2.', 'sh(1, 2).']).
ro('sh.v2.pl', [':- dynamic sh/2.', 'sh(_A, _B).']).
ro('g1.pl', [':- multifile mg/1.', ':- dynamic mg/1.', 'mg(1).']).
ro('g1.v2.pl', [':- multifile mg/1.', ':- dynamic mg/1.', 'mg(2).', 'mg(1).']).
ro('g2.pl', [':- multifile mg/1.', ':- dynamic mg/1.', 'mg(2).']).

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
    (   exists_file(Pl), unready(C, Why)
    ->  format("     ~w: skipped (~w)~n", [C, Why])
    ;   exists_file(Pl)
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
