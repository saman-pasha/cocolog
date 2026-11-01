%% Where a load looks for a file, and what it says when there is none,
%% as swipl 9.0.4 does (cocolog 3.4.0). The sandbox holds the fixtures
%% (test/files.pl's fixtures(load_paths, _)): this file is in test/files,
%% the working directory is the sandbox.

yes_no(G) :- ( catch(G, _, fail) -> format("~w yes~n", [G]) ; format("~w no~n", [G]) ).

err(N-G) :- ( catch(G, E, (print_message(error, E), fail)) -> format("~w ok~n", [N]) ; format("~w failed~n", [N]) ).

main :-
    %% a file reached through a link is named by the link's path -- FIRST,
    %% because swipl names a directory by the first path it met it through
    %% (pl-os.c's canonicaliseDir, by device and inode), and sub/main below
    %% reads sub/deeper, the link's target, by its own name
    consult('sym/n4'), yes_no(n4),
    %% a file's own directives look beside it first, then here; an
    %% initialization/1 goal of it only here
    consult('sub/main'),
    forall(member(P, [sub_main, both_cwd, both_sub, n1, n2, n3_deeper, n3_sub,
                      twin_sub, twin_cwd, h7_cwd, h7_sub]), yes_no(P)),
    %% the same name beside two files is two files
    consult('other/b'),
    yes_no(twin_other),
    %% swipl's extensions before the name as it is, .prolog among them
    consult(x), yes_no(x_pl), yes_no(x_noext),
    consult(y), yes_no(y_prolog),
    %% a goal's spec, after the load, is the working directory's; a list
    %% of codes is one name ("q1" reads as codes here, a string in swipl)
    ensure_loaded(g1), yes_no(g1),
    ensure_loaded("q1"), yes_no(q1),
    %% the errors of a goal, swipl's terms
    atom_string(nope_s, S),
    forall(nth1(N, [use_module(f(x)), use_module(123), use_module(1.5), use_module(-1),
                    use_module(library(nope_lib)), use_module(foo/bar), use_module(nope),
                    use_module(''), use_module(sub/dir), consult(sub/dir), consult(123),
                    consult(1.5), load_files(123, []), load_files(1.5, []),
                    load_files(nope, [if(exists)]), load_files(sub/dir, [if(exists)]),
                    ensure_loaded(_), ensure_loaded([g1, nope_a, g2]), ensure_loaded([]),
                    consult(nope/x), use_module(sub/nope), ensure_loaded(f(x, y)),
                    use_module([g1|_]), consult([g1|g2]), consult(S), load_files(S, []),
                    use_module(S), consult(library(_)), load_files(library(_), []),
                    use_module(library(_))], G),
           err(N-G)),
    %% a directive's, reported where it stands, by the file's absolute path
    consult('sub/errs'),
    yes_no(errs_done),
    %% a list's tail that is no list, and swipl's comments on a ball
    consult(ex),
    yes_no(ex_done).
