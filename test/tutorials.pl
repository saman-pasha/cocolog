%% EVERY TUTORIAL, ALL FOUR CATEGORIES.
%%
%%   basics/   eleven files, one process each, goal `main'. No library, no
%%             database, no build flag.
%%   library/  forty-two files, one process each, goal `main'. Tier 2
%%             needs $COCOLOG_LIBRARY, which the runner sets.
%%   opencv/   twenty-three files, one process each, goal `main', from the
%%             repo root; the dnn two end early without their models.
%%   tensor/   forty-two networks, THREE processes each and a store per
%%             tutorial: train saves the model into the store, test reloads
%%             and judges it, predict reloads and answers.
%%
%% WHY THE FIRST TWO ARE TESTS AT ALL: every claim in them is a `must/3',
%% so a lesson that stops being true FAILS and names both answers. That is
%% not decoration -- writing them found that `once/1' and `ignore/1' did
%% not exist and that `retractall/1' was a clause short of correct.
%%
%% EACH TORCH TUTORIAL GETS ITS OWN STORE: consulted clauses live in the
%% knowledge base exactly as models do, so two tutorials sharing a store
%% would also share their train/test/predict clauses -- and the first one
%% consulted would answer for all of them.
%%
%% THREE KINDS OF SKIP, all because "not built here" and "wrong" are
%% different findings: the torch category needs the torch module,
%% `library/22-torch.pl' needs it too, 23 to 28 need ZiguratIP's
%% cryptography and its sample certificate directory, 29 needs the ray
%% module and 40 the numpy one. A lesson skipped says so INDENTED, because
%% a SKIP at column 0 would skip the whole case.
%%
%%     cocolog -s test/tutorials.pl        from the checkout root
%%
%% Every lesson IS a child, and a tensor lesson three: a lesson is a
%% program with a main of its own, and two of them in one store would
%% answer for each other.

:- use_module('test/prelude.pl').

:- dynamic skipped/1.

main :-
    retractall(skipped(_)),
    scratch(D),
    %% Is the torch module loadable? Ask it, rather than looking for a
    %% file: the module may be compiled in, beside the binary, or on the
    %% path.
    loadable('use_module(library(torch)), torch_cuda_available(_)', Torch),
    %% The same question for ZiguratIP's cryptography: four modules that
    %% need a BUILT ZiguratIP, and a sample authority to read. 26 and 27
    %% also want the certificate directory, which only exists in a built
    %% home.
    ( getenv('ZIGURATIP', Z) -> true ; getenv('HOME', H), atom_concat(H, '/ZiguratIP', Z) ),
    atom_concat(Z, '/home/etc/cert/dont-use-certificate.crt', CaCrt),
    loadable('use_module(library(x509)), use_module(library(der)), use_module(library(tls))', Crypto0),
    ( Crypto0 == yes, exists_file(CaCrt) -> Crypto = yes ; Crypto = no ),
    %% And for the window: the lesson opens none (it cannot assume a
    %% display, as the curl lesson cannot assume a network), so loadable is
    %% enough.
    loadable('use_module(library(ray))', Ray),
    %% And for the arrays: the module starts an interpreter at its first
    %% predicate, so loadable is asked with one, not with use_module alone.
    loadable('use_module(library(numpy)), np_zeros([1], A), np_free(A)', Numpy),
    loadable('use_module(library(opencv)), cv_new(1, 1, ''8u'', I), cv_free(I)', Opencv),
    basics_and_library(Torch, Crypto, Ray, Numpy),
    opencv(Opencv),
    tensor(D, Torch),
    shl(['rm -rf ', D]),
    findall(x, skipped(_), Ss), length(Ss, NSkipped),
    format("~w lesson(s) skipped~n", [NSkipped]),
    checks_done.

%% does a goal prove in a child? `query' exits 0 when it did
loadable(Goal, YesNo) :-
    sh_join(['query "', Goal, '" >/dev/null 2>&1'], Args),
    ( cocolog_run(Args, _, 0) -> YesNo = yes ; YesNo = no ).

skip_lesson(Name, Why) :-
    assertz(skipped(Name)),
    format("     (skipped: ~w -- ~w)~n", [Name, Why]).

%% the numbered .pl files of a tutorial directory, sorted
lessons(Dir, Paths) :-
    directory_files(Dir, Fs),
    findall(P, ( member(F, Fs), re_match('^[0-9].*\\.pl$', F), sh_join([Dir, '/', F], P) ), Ps),
    msort(Ps, Paths).

lesson_name(Dir, Path, Name) :-
    atom_concat(Dir, '/', Prefix), atom_concat(Prefix, File, Path),
    atom_concat(Stem, '.pl', File),
    sh_join([Dir, '/', Stem], Name).

%% one lesson, one process, goal `main', from the repo root: its last line
%% must be `done'
one_lesson(Name, Path, TimeoutMs) :-
    sh_join(['run ', Path, ' main 2>&1'], Args),
    cocolog_run(Args, Out, Rc, TimeoutMs),
    atom_codes(Out, Cs),
    ( codes_lines(Cs, Ls), Ls \== [], last(Ls, L) -> atom_codes(Last, L) ; Last = '' ),
    (   Rc =:= 0, Last == done
    ->  check(Name, done, done)
    ;   check(Name, Last, done),
        tail_lines(4, Ls, Tail),
        forall(member(T, Tail), ( atom_codes(TA, T), format("      ~w~n", [TA]) ))
    ).

basics_and_library(Torch, Crypto, Ray, Numpy) :-
    section('basics and library: one process, goal `main'''),
    lessons('tutorials/basics', Basics), lessons('tutorials/library', Library),
    append(Basics, Library, All),
    forall(member(Path, All),
           ( ( sub_atom(Path, _, _, _, 'tutorials/basics/') -> lesson_name('tutorials/basics', Path, Name)
             ; lesson_name('tutorials/library', Path, Name) ),
             (   member(Name, ['tutorials/library/22-torch', 'tutorials/library/39-tensor-expr']), Torch == no
             ->  skip_lesson(Name, 'no torch module')
             ;   member(Name, ['tutorials/library/23-sha', 'tutorials/library/24-aes', 'tutorials/library/25-der',
                               'tutorials/library/26-x509', 'tutorials/library/27-ca', 'tutorials/library/28-tls']), Crypto == no
             ->  skip_lesson(Name, 'no ZiguratIP cryptography built')
             ;   Name == 'tutorials/library/29-ray', Ray == no
             ->  skip_lesson(Name, 'no ray module')
             ;   Name == 'tutorials/library/40-numpy', Numpy == no
             ->  skip_lesson(Name, 'no numpy module')
             ;   %% FROM THE REPO ROOT, which `library/03-files.pl' depends on:
                 %% it reads its own source through the relative path the
                 %% header tells you to use.
                 one_lesson(Name, Path, 300000)
             ) )).

opencv(Opencv) :-
    section('opencv: one process, goal `main'', from the repo root'),
    %% The photographs are ../tensor/42-detection-*.jpg by relative path,
    %% and the two dnn lessons END EARLY with a notice when their models are
    %% not downloaded, so the category is green offline.
    (   Opencv == no
    ->  skip_lesson('tutorials/opencv/ (23 tutorials)', 'no opencv module')
    ;   lessons('tutorials/opencv', Ps),
        forall(member(Path, Ps), ( lesson_name('tutorials/opencv', Path, Name), one_lesson(Name, Path, 600000) ))
    ).

tensor(D, Torch) :-
    section('tensor: three processes and a store each'),
    (   Torch == no
    ->  skip_lesson('tutorials/tensor/ (42 tutorials)', 'no torch module')
    ;   lessons('tutorials/tensor', Ps),
        forall(member(Path, Ps), tensor_lesson(D, Path))
    ).

%% TWENTY MINUTES, AND 27-induction IS WHY. Its `train' fits four models at
%% 60 epochs each -- MEASURED at 8m10s wall, 3723s of CPU at 791%, on an
%% i9-9880H running libtorch on the CPU. The 300s that every other goal
%% here finishes inside killed it at rc=124, and a kill takes the output
%% with it: the case printed `FAIL tensor/27-induction train' over three
%% blank lines, with no way to tell a slow model from a broken one. A
%% budget must be bigger than the thing it is measuring, and a timeout
%% should say it is one.
tensor_lesson(D, Path) :-
    lesson_name('tutorials/tensor', Path, Name),
    atom_concat(Name, '.', _),
    sub_atom(Path, _, _, 3, Base0), sub_atom(Base0, 17, _, 0, Stem),
    sh_join([D, '/store-', Stem], Store),
    (   forall_goals([train, test, predict], D, Store, Path, Name)
    ->  check(Name, done, done)
    ;   true
    ).

%% each goal in turn; the first that fails is reported and ends the lesson
forall_goals([], _, _, _, _).
forall_goals([Goal|Gs], D, Store, Path, Name) :-
    sh_join(['--kb tutorials --embed ', Store, ' run ', Path, ' ', Goal, ' 2>&1'], Args),
    cocolog_run(Args, Out, Rc, 1200000),
    (   Rc =:= 0
    ->  forall_goals(Gs, D, Store, Path, Name)
    ;   sh_join([Name, ' ', Goal], Label),
        ( Rc =:= 124 -> check(Label, 'TIMEOUT at 1200s -- no output survives a kill', done) ; check(Label, Rc, done) ),
        atom_codes(Out, Cs), codes_lines(Cs, Ls), tail_lines(3, Ls, Tail),
        forall(member(T, Tail), ( atom_codes(TA, T), format("      ~w~n", [TA]) )),
        fail
    ).
