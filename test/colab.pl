%% colab/: the notebook and the scripts beside it, checked without a VM.
%%
%% WHAT IS BEING PINNED, and why any of it is worth a case:
%%
%%   THE VERSION IS DECLARED TWICE, and it has to be. colab/VERSION is
%%   the repository's answer; NOTEBOOK_VERSION inside the notebook is the
%%   BROWSER's answer, and the whole point of the check in section 1 is
%%   that the second one can be stale. A fact in two places will disagree
%%   with itself eventually -- so the two copies that live in THIS
%%   repository are compared here, and what remains free to drift is
%%   exactly the copy that is supposed to: the one in somebody's browser.
%%
%%   A NOTEBOOK IS JSON, and a broken one fails in Colab rather than
%%   here, twenty minutes into a session, with a message about a cell
%%   nobody can see. It is cheap to parse it now: valid JSON, nbformat 4,
%%   every cell well-formed.
%%
%%   AND THE SCRIPTS THE NOTEBOOK CALLS MUST EXIST. The cell runs
%%   prereqs.sh, preflight.sh and build.sh by name from the clone. A
%%   renamed script is a build that dies on the VM and nowhere else.
%%
%%     cocolog -s test/colab.pl        from the checkout root
%%
%% THE NOTEBOOK IS READ BY COCOLOG. test/colab-check.pl answers the five
%% questions five python3 blocks used to, printing the same one word each
%% so the checks are unchanged. One clause did not survive the move and
%% that file says which: the old shape check also ran ast.parse over every
%% code cell, and cocolog has no Python parser. The quarantine section RUNS
%% a fragment of colab/build.sh -- a shell script that stays one, since it
%% runs on the VM before there is a cocolog to run it.

:- use_module('test/prelude.pl').

main :-
    %% A MISSING NOTEBOOK IS A FAILURE, NOT A SKIP -- once colab/ is here.
    %% `SKIP' means "this checkout has no colab/ to check"; it must not also
    %% mean "the notebook is not where everything says it is", which is
    %% exactly the state a half-finished rename leaves behind. red: 0 does
    %% not mean the suite passed, and a case that skips its own subject is
    %% how that happens.
    ( exists_directory(colab) -> true ; skip('(no colab/ in this checkout)') ),
    NB = 'colab/cocolog_colab.ipynb',
    (   exists_file(NB)
    ->  true
    ;   check('the notebook is at colab/cocolog_colab.ipynb', missing, present),
        checks_done
    ),
    the_version(NB), the_scripts(NB), the_quarantine, the_documentation(NB),
    checks_done.

%% test/colab-check.pl, in a child: VERB NOTEBOOK [ARG], one word back
cb(Args, Word) :-
    sh_join(['--local run test/colab-check.pl cb_main -- ', Args, ' 2>&1'], A),
    cocolog_run(A, Word, _).

the_version(NB) :-
    section('the version, declared twice'),
    shell('head -1 colab/VERSION 2>/dev/null | grep -cE ''^[0-9]+$''', G1, _),
    check('colab/VERSION declares a version', G1, '1'),
    %% The two declarations, compared. The notebook's is a Python
    %% assignment in the cell; the repository's is the first line of the
    %% file.
    sh_join(['version ', NB, ' colab/VERSION'], A2), cb(A2, G2),
    check('and the notebook carries the same one', G2, agree),
    sh_join(['first ', NB], A3), cb(A3, G3),
    check('the version is printed before anything is installed', G3, first),
    sh_join(['named ', NB], A4), cb(A4, G4),
    check('and a stale notebook is named rather than guessed at', G4, named),
    sh_join(['shape ', NB], A5), cb(A5, G5),
    check('the notebook is valid JSON, nbformat 4, cells well-formed', G5, ok).

the_scripts(NB) :-
    section('the scripts the notebook calls'),
    read_file_to_codes(NB, Cs), atom_codes(Text, Cs),
    %% The cell calls these by name from the clone; a rename is a failure
    %% that can only happen on the VM.
    forall(member(S, ['prereqs.sh', 'preflight.sh', 'build.sh']),
           ( atom_concat('colab/', S, P),
             ( exists_file(P), sub_atom(Text, _, _, _, S) -> V = present ; V = missing ),
             sh_join(['the notebook''s ', S, ' is there to be called'], Label),
             check(Label, V, present) )),
    %% NO CELL MAY DEPEND ON WHERE A PREVIOUS CELL LEFT THE PROCESS. A
    %% notebook cell inherits the last cell's working directory, so
    %% `./cocolog' is a bet on execution order -- and section 2 lost it the
    %% first time anyone ran the notebook without running section 4 first:
    %% the server cell used to %cd into ZiguratIP and %cd back, and section
    %% 2 runs before it. `./cocolog: Is a directory', because
    %% /content/cocolog is the checkout and the binary is inside it.
    %% Absolute paths everywhere, checked here so the next cell added does
    %% not reintroduce it.
    sh_join(['relpath ', NB], A), cb(A, G),
    check('no cell runs cocolog by a relative path', G, none).

the_quarantine :-
    section('the compiler pages must not survive the build'),
    %% System/compiler.parsi is a web page whose POST handler compiles what
    %% you send it, and the ordinary ZiguratIP `make' produces it every time
    %% -- so a build meant to be tunnelled has to move it out of home/ld.
    %% Checked by RUNNING that part of build.sh against a fixture, because
    %% grepping for the code would pass on code that does not work.
    scratch(Fix),
    forall(member(Sub, ['/home/ld', '/home/catalog']), ( atom_concat(Fix, Sub, P), make_directory_p(P) )),
    forall(member(F, ['/home/ld/lib_COMPILER_.so', '/home/ld/lib_COMPILERDRAWER_.so', '/home/ld/lib_CONNECTOR_.so',
                      '/home/catalog/_COMPILER_.conf', '/home/catalog/_CONNECTOR_.conf']),
           ( atom_concat(Fix, F, P), write_file_from_codes(P, []) )),
    %% the fragment: from the section's banner to the `fi' that closes it
    read_file_to_codes('colab/build.sh', BCs), codes_lines(BCs, BLines),
    fragment(BLines, Frag),
    atom_concat(Fix, '/quar.sh', Quar),
    sh_join(['ZIGURATIP_HOME=', Fix, '/home'], HomeLine),
    findall(A, ( member(L, Frag), atom_codes(A, L) ), FragAtoms),
    fixture(Quar, ['set -u', HomeLine|FragAtoms]),
    shl(['sh ', Quar, ' >/dev/null 2>&1 || true']),
    shl_atom(['ls ', Fix, '/home/ld | grep -c COMPILER || true'], G1),
    check('the build moves the compiler page out of home/ld', G1, '0'),
    atom_concat(Fix, '/home/ld-disabled/lib_COMPILERDRAWER_.so', Drawer),
    ( exists_file(Drawer) -> V2 = quarantined ; V2 = lost ),
    check('and the drawer that renders it', V2, quarantined),
    atom_concat(Fix, '/home/ld-disabled/_COMPILER_.conf', Conf),
    ( exists_file(Conf) -> V3 = together ; V3 = split ),
    check('each object travels with its catalogue entry', V3, together),
    atom_concat(Fix, '/home/ld-disabled/lib_COMPILER_.so', Moved),
    ( exists_file(Moved) -> V4 = recoverable ; V4 = gone ),
    check('it is MOVED, not deleted', V4, recoverable),
    atom_concat(Fix, '/home/ld/lib_CONNECTOR_.so', Conn),
    ( exists_file(Conn) -> V5 = untouched ; V5 = 'TAKEN' ),
    check('and every other page is left alone', V5, untouched),
    shl_atom(['sh ', Quar, ' 2>&1 | wc -l | tr -d '' '''], G6),
    check('a second build is a silent no-op', G6, '0'),
    atom_concat(Fix, '/home/ld/lib_COMPILER_.so', Again), write_file_from_codes(Again, []),
    shl_atom(['KEEP_COMPILER_PAGES=1 sh ', Quar, ' 2>&1 | grep -c ''DO NOT open a tunnel'''], G7),
    check('KEEP_COMPILER_PAGES=1 leaves them and says so', G7, '1'),
    shl(['rm -rf ', Fix]).

%% `sed -n '/---- the compiler pages, moved out of reach/,/^fi$/p''
fragment(Lines, Frag) :-
    append(_, [Start|Rest], Lines),
    atom_codes(SA, Start), sub_atom(SA, _, _, _, '---- the compiler pages, moved out of reach'), !,
    up_to_fi(Rest, Tail),
    Frag = [Start|Tail].
up_to_fi([], []).
up_to_fi([L|Ls], [L|T]) :- ( L == "fi" -> T = [] ; up_to_fi(Ls, T) ).

%% mkdir -p
make_directory_p(P) :- shl(['mkdir -p ', P]).

the_documentation(NB) :-
    section('the rename has to reach the documentation too'),
    %% COLAB.md carries the link people actually click -- the raw
    %% colab.research.google.com URL -- and a notebook renamed without it is
    %% a 404 for everyone but the person who did the renaming.
    atom_concat('colab/', NBName, NB),
    sh_join(['grep -c ''', NBName, ''' colab/COLAB.md 2>/dev/null | head -1'], C1), shell(C1, G1, _),
    check('COLAB.md names the notebook that exists', G1, '2'),
    %% Only LINKS are policed, not prose: COLAB.md says what the notebook
    %% used to be called, on purpose, so that a stale bookmark's 404 has an
    %% explanation. A link target ends in `)' or `>'; a name being discussed
    %% ends in a backtick. That distinction is the whole check.
    sh_join(['grep -ohE ''[A-Za-z0-9_/.-]+\\.ipynb[)>]'' colab/COLAB.md 2>/dev/null | sed ''s/.*\\///; s/[)>]$//'' | sort -u | grep -vc ''^', NBName, '$'''], C2), shell(C2, G2, _),
    check('and every .ipynb LINK points at it', G2, '0').
