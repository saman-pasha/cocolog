%% A load directive's load runs at the directive (cocolog 3.6.0), as swipl's:
%% the files it reads print where the directive stands, a ball that ended
%% that load is the directive's -- an error(_, _) its ERROR at the
%% directive's place and the Warning that it failed, any other the end of
%% this load too -- and a file whose load a ball ended before it defined
%% anything is not loaded, so the next load that names it reads it again and
%% no goal after reads it (test/files/source_files.pl has a ball after a
%% clause, which leaves the file loaded). The files are test/files.pl's
%% `nest/2', made in the sandbox.

yes_no(G) :- ( catch(G, _, fail) -> format("~q yes~n", [G]) ; format("~q no~n", [G]) ).

main :-
    %% a nested include of nothing: the ERROR and the Warning at oe.pl:2,
    %% then oe.pl goes on; ia.pl's clause after the include was not read
    consult(oe), yes_no(oe(1)), yes_no(ia(1)),
    %% the same inside a module, loaded by use_module/1
    consult(om), yes_no(om(1)), yes_no(ma(1)),
    %% the nested file's initialization/1 goal at its own load's end
    consult(oi), yes_no(ii(1)),
    %% a ball that is no error(_, _) ends both loads, and consult/1 raises it
    catch(consult(ob), B, (print_message(error, B), writeln(caught))),
    yes_no(ob(1)), yes_no(ib(1)),
    %% a list whose first file such a ball ends: the walk ends there, and
    %% this load with it; ib.pl, which a ball ended before it defined
    %% anything, is read again
    catch(consult(obl), B2, (print_message(error, B2), writeln(caught))),
    yes_no(obl(1)), yes_no(ok2(1)),
    %% a list: each file that would not load said at the place, no Warning,
    %% and ia.pl, ended so too, read again
    consult(ol), yes_no(ok(1)),
    %% two deep: the inner failure is the middle file's directive's
    consult(od), yes_no(od(1)), yes_no(mid(1)), yes_no(inner(1)),
    %% a file loaded whole is loaded; one ended before anything is read again
    consult(oa),
    catch(ensure_loaded(sub/ia), E1, print_message(error, E1)),
    %% and a consulted one whose read a ball ended, by ensure_loaded/1
    catch(consult(f), E2, print_message(error, E2)),
    catch(ensure_loaded(f), E3, print_message(error, E3)),
    yes_no(f(1)),
    %% whatever load_files/2's IF says, a consulted one and a module
    forall(member(If, [not_loaded, changed]),
           ( catch(load_files(f, [if(If)]), E4, print_message(error, E4)),
             catch(load_files(sub/ia, [if(If)]), E5, print_message(error, E5)) )),
    writeln(end).
