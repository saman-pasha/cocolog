%% Which files a load reads again (cocolog 3.6.0), as swipl's: a file is a
%% source file once a read of it has defined something -- a clause or a
%% grammar rule; a dynamic, discontiguous, multifile or meta_predicate
%% declaration; module/2; an initialization/1 goal put off; an include of a
%% file that is there, though it holds nothing; a load of a file that is
%% there, whatever that file holds -- and ensure_loaded/1 and load_files/2's
%% if(not_loaded) read again a file whose reads defined none of those: a
%% file of goals alone, op/3 and the flags, assertz/1, thread_local/1 and
%% public/1, an include or a load of what is not there, a ball before
%% anything. A ball after a clause leaves the file loaded. Through 3.5.0
%% every file read once was loaded, and since the first cut of 3.6.0 every
%% file a ball ended was not. The files are test/files.pl's `sf/2', made in
%% the sandbox.

twice(F) :-
    format("~w:~n", [F]),
    catch(ensure_loaded(F), _, writeln(caught)),
    catch(ensure_loaded(F), _, writeln(caught)).

lf(F) :-
    format("load_files ~w:~n", [F]),
    catch(load_files(F, [if(not_loaded)]), _, writeln(caught)),
    catch(load_files(F, [if(not_loaded)]), _, writeln(caught)).

main :-
    forall(member(F, [g, c, dcg, d, dc, mf, mp, m, i, nw, e, en, l, le, op, fl,
                      as, tl, pb, f, nf, nb, lg, lc, sf, lm, lg2, lk, ll]),
           twice(F)),
    %% a load of the file being read finds it loaded, on its second read
    %% too: sr.pl's first read a ball ended before it defined anything
    twice(sr),
    %% load_files/2's if(not_loaded) is ensure_loaded/1's
    lf(g7), lf(c7),
    %% consult/1 reads a file whatever it holds; a load after it, as above
    writeln(consult),
    consult(c7), consult(c7), ensure_loaded(c7),
    consult(cg), ensure_loaded(cg),
    consult(cl), load_files(cl, [if(not_loaded)]),
    consult(sc), ensure_loaded(sc).
