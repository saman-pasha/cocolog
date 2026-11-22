%  library(Name) loaded again, as swipl 9.0.4's consult/1, `[File]' and
%  load_files/2 load it ('$noload'/3 is false of if(true)): a file of the
%  library path that a load read is read again under if(true) always, and
%  under if(changed) and if(exists) once its time is past its last read's,
%  where if(not_loaded), ensure_loaded/1 and use_module/1 read nothing. A
%  module is read again as that module. Each read says so (its first
%  directive), and the clauses the program retracted since are back, an
%  asserted one kept after them. cocolog 3.73.2; through 3.73.1 a library
%  was loaded once whatever IF said, and a clause retracted never came
%  back -- the reasoning session's templates, read by
%  consult(library(reasoning/templates/Name)). Run by BOTH SWI-Prolog and
%  cocolog, output compared byte for byte. The files are test/files.pl's
%  fixture, in the sandbox's library/, at 12:00:00 on 2026-10-28: cocolog
%  finds them there after $COCOLOG_LIBRARY, and swipl through the
%  file_search_path/2 clause main/0 asserts.

:- multifile user:file_search_path/2.
:- dynamic user:file_search_path/2.

pr(T) :- print(T), nl.
la_now(T) :- findall(X, la(X), L), pr(T-L).

main :-
    working_directory(D, D), atom_concat(D, library, Lib),
    assertz(user:file_search_path(library, Lib)),
    consult(library(lr_a)), la_now(c1),
    retractall(la(_)), la_now(gone),
    consult(library(lr_a)), la_now(c2),
    consult(library(lr_a)), la_now(c3),
    retractall(la(_)), load_files(library(lr_a), []), la_now(lf),
    retractall(la(_)), load_files(library(lr_a), [if(true)]), la_now(lf_true),
    retractall(la(_)), [library(lr_a)], la_now(brackets),
    retractall(la(_)), consult(user:library(lr_a)), la_now(user),
    retractall(la(_)), load_files(library(lr_a), [if(changed)]), la_now(changed_same),
    load_files(library(lr_a), [if(not_loaded)]), la_now(not_loaded),
    ensure_loaded(library(lr_a)), la_now(ensure),
    load_files(library(lr_a), [if(exists)]), la_now(exists_same),
    shell('touch -d 2026-10-28T12:00:05Z library/lr_a.pl'),
    load_files(library(lr_a), [if(changed)]), la_now(changed_newer),
    retractall(la(_)), load_files(library(lr_a), [if(exists)]), la_now(exists_newer),
    assertz(la(9)), consult(library(lr_a)), la_now(asserted),
    use_module(library(lr_m)), findall(X, lm(X), M0), pr(m0-M0),
    retractall(lm(_)), consult(library(lr_m)), findall(X, lm(X), M1), pr(m1-M1),
    retractall(lm(_)), use_module(library(lr_m)), findall(X, lm(X), M2), pr(m2-M2),
    consult(library(lr_m)), findall(X, lm(X), M3), pr(m3-M3),
    consult(library(sub/lr_s)), findall(X, ls(X), S0), pr(s0-S0),
    retractall(ls(_)), consult([library(sub/lr_s), library(lr_a)]),
    findall(X, ls(X), S1), pr(s1-S1), la_now(list),
    catch(consult(library(lr_none)), error(E, _), pr(caught(E))),
    load_files(library(lr_none), [if(exists)]), pr(exists_none),
    more.

%  a file first named by its path, then by library(Name); a file of goals
%  alone, which no read makes loaded, read again by if(changed) too; an
%  encoding(E) that names none, refused once the file is to be read; a file
%  that is gone; a file whose one directive loads the library, which that
%  load makes loaded, so that ensure_loaded/1 reads it no more; and an
%  encoding(E) that is the read's alone, a file loaded after it read in
%  UTF-8
more :-
    use_module('library/lr_p.pl'), retractall(lp(_)), consult(library(lr_p)),
    findall(X, lp(X), P0), pr(p0-P0),
    consult(library(lr_g)), load_files(library(lr_g), [if(changed)]), pr(g_again),
    catch(load_files(library(lr_a), [encoding(nosuch)]), error(E1, _), pr(caught(E1))),
    consult(library(lr_x)), shell('rm library/lr_x.pl'),
    catch(consult(library(lr_x)), error(E2, _), pr(caught(E2))),
    consult(lr_w), consult(lr_w), ensure_loaded(lr_w), pr(w_done),
    load_files(library(lr_a), [encoding(iso_latin_1)]),
    consult(library(lr_u)), lu(A), atom_length(A, N), pr(lu(N)).
